#include "WindowsNetworkSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <netlistmgr.h>
#include <wlanapi.h>

#include <string>
#include <vector>

namespace kde_windows
{
namespace
{
bool hasNetworkConnectivity()
{
    INetworkListManager* manager = nullptr;
    const HRESULT createResult = CoCreateInstance(CLSID_NetworkListManager,
                                                   nullptr,
                                                   CLSCTX_ALL,
                                                   IID_PPV_ARGS(&manager));
    if (FAILED(createResult) || !manager)
        return false;

    VARIANT_BOOL connected = VARIANT_FALSE;
    const HRESULT result = manager->get_IsConnected(&connected);
    manager->Release();
    return SUCCEEDED(result) && connected == VARIANT_TRUE;
}

std::wstring ssidToWide(const DOT11_SSID& ssid)
{
    if (ssid.uSSIDLength == 0)
        return {};

    const char* bytes = reinterpret_cast<const char*>(ssid.ucSSID);
    const int length = static_cast<int>(ssid.uSSIDLength);

    int required = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes, length, nullptr, 0);
    UINT codePage = CP_UTF8;
    DWORD flags = MB_ERR_INVALID_CHARS;
    if (required <= 0) {
        codePage = CP_ACP;
        flags = 0;
        required = MultiByteToWideChar(codePage, flags, bytes, length, nullptr, 0);
    }
    if (required <= 0)
        return {};

    std::wstring result(static_cast<std::size_t>(required), L'\0');
    MultiByteToWideChar(codePage, flags, bytes, length, result.data(), required);
    return result;
}

bool openClient(HANDLE& client, PWLAN_INTERFACE_INFO_LIST& interfaces)
{
    client = nullptr;
    interfaces = nullptr;
    DWORD negotiatedVersion = 0;
    if (WlanOpenHandle(2, nullptr, &negotiatedVersion, &client) != ERROR_SUCCESS)
        return false;
    if (WlanEnumInterfaces(client, nullptr, &interfaces) != ERROR_SUCCESS || !interfaces) {
        WlanCloseHandle(client, nullptr);
        client = nullptr;
        return false;
    }
    return true;
}

bool queryWifi(NetworkState& state)
{
    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool found = false;
    for (DWORD index = 0; index < interfaces->dwNumberOfItems && !found; ++index) {
        const WLAN_INTERFACE_INFO& interfaceInfo = interfaces->InterfaceInfo[index];
        if (interfaceInfo.isState != wlan_interface_state_connected)
            continue;

        DWORD dataSize = 0;
        PVOID data = nullptr;
        WLAN_OPCODE_VALUE_TYPE valueType = wlan_opcode_value_type_invalid;
        const DWORD queryResult = WlanQueryInterface(client,
                                                     &interfaceInfo.InterfaceGuid,
                                                     wlan_intf_opcode_current_connection,
                                                     nullptr,
                                                     &dataSize,
                                                     &data,
                                                     &valueType);
        if (queryResult != ERROR_SUCCESS || !data)
            continue;

        const auto* connection = static_cast<const WLAN_CONNECTION_ATTRIBUTES*>(data);
        state.connected = true;
        state.wifi = true;
        state.name = ssidToWide(connection->wlanAssociationAttributes.dot11Ssid);
        state.signalQuality = clampSignalQuality(static_cast<int>(connection->wlanAssociationAttributes.wlanSignalQuality));
        found = true;
        WlanFreeMemory(data);
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    return found;
}

bool interfaceRadioOn(HANDLE client, const GUID& guid)
{
    DWORD dataSize = 0;
    PVOID data = nullptr;
    WLAN_OPCODE_VALUE_TYPE valueType = wlan_opcode_value_type_invalid;
    if (WlanQueryInterface(client,
                           &guid,
                           wlan_intf_opcode_radio_state,
                           nullptr,
                           &dataSize,
                           &data,
                           &valueType) != ERROR_SUCCESS || !data) {
        return false;
    }

    const auto* radio = static_cast<const WLAN_RADIO_STATE*>(data);
    bool on = false;
    for (DWORD i = 0; i < radio->dwNumberOfPhys; ++i) {
        const auto& phy = radio->PhyRadioState[i];
        if (phy.dot11SoftwareRadioState == dot11_radio_state_on &&
            phy.dot11HardwareRadioState == dot11_radio_state_on) {
            on = true;
            break;
        }
    }
    WlanFreeMemory(data);
    return on;
}
}

NetworkState WindowsNetworkSystem::state() const
{
    NetworkState result;
    result.connected = hasNetworkConnectivity();
    queryWifi(result);
    if (result.connected && result.name.empty())
        result.name = result.wifi ? L"Wi-Fi" : L"Wired network";
    return result;
}

std::vector<WifiNetworkSnapshot> WindowsNetworkSystem::networks() const
{
    std::vector<WifiNetworkSnapshot> result;
    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return result;

    for (DWORD index = 0; index < interfaces->dwNumberOfItems; ++index) {
        const GUID& guid = interfaces->InterfaceInfo[index].InterfaceGuid;
        WlanScan(client, &guid, nullptr, nullptr, nullptr);

        PWLAN_AVAILABLE_NETWORK_LIST networks = nullptr;
        if (WlanGetAvailableNetworkList(client, &guid, 0, nullptr, &networks) != ERROR_SUCCESS || !networks)
            continue;

        for (DWORD networkIndex = 0; networkIndex < networks->dwNumberOfItems; ++networkIndex) {
            const WLAN_AVAILABLE_NETWORK& network = networks->Network[networkIndex];
            const std::wstring name = ssidToWide(network.dot11Ssid);
            if (name.empty())
                continue;

            WifiNetworkSnapshot snapshot;
            snapshot.id = name;
            snapshot.name = name;
            snapshot.profileName = network.strProfileName;
            snapshot.signalQuality = clampSignalQuality(static_cast<int>(network.wlanSignalQuality));
            snapshot.connected = (network.dwFlags & WLAN_AVAILABLE_NETWORK_CONNECTED) != 0;
            snapshot.known = network.strProfileName[0] != L'\0';
            snapshot.secure = network.bSecurityEnabled != FALSE;
            result.push_back(std::move(snapshot));
        }
        WlanFreeMemory(networks);
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    normalizeWifiNetworks(result);
    return result;
}

bool WindowsNetworkSystem::radioEnabled() const
{
    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool enabled = false;
    for (DWORD index = 0; index < interfaces->dwNumberOfItems; ++index) {
        if (interfaceRadioOn(client, interfaces->InterfaceInfo[index].InterfaceGuid)) {
            enabled = true;
            break;
        }
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    return enabled;
}

bool WindowsNetworkSystem::setRadioEnabled(bool enabled) const
{
    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool changed = false;
    for (DWORD index = 0; index < interfaces->dwNumberOfItems; ++index) {
        const GUID& guid = interfaces->InterfaceInfo[index].InterfaceGuid;
        DWORD dataSize = 0;
        PVOID data = nullptr;
        WLAN_OPCODE_VALUE_TYPE valueType = wlan_opcode_value_type_invalid;
        if (WlanQueryInterface(client,
                               &guid,
                               wlan_intf_opcode_radio_state,
                               nullptr,
                               &dataSize,
                               &data,
                               &valueType) != ERROR_SUCCESS || !data) {
            continue;
        }

        const auto* radio = static_cast<const WLAN_RADIO_STATE*>(data);
        for (DWORD phyIndex = 0; phyIndex < radio->dwNumberOfPhys; ++phyIndex) {
            WLAN_PHY_RADIO_STATE desired{};
            desired.dwPhyIndex = radio->PhyRadioState[phyIndex].dwPhyIndex;
            desired.dot11SoftwareRadioState = enabled ? dot11_radio_state_on : dot11_radio_state_off;
            desired.dot11HardwareRadioState = radio->PhyRadioState[phyIndex].dot11HardwareRadioState;
            if (WlanSetInterface(client,
                                 &guid,
                                 wlan_intf_opcode_radio_state,
                                 sizeof(desired),
                                 &desired,
                                 nullptr) == ERROR_SUCCESS) {
                changed = true;
            }
        }
        WlanFreeMemory(data);
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    return changed;
}

bool WindowsNetworkSystem::connectKnown(const std::wstring& networkId) const
{
    if (networkId.empty())
        return false;

    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool requested = false;
    for (DWORD index = 0; index < interfaces->dwNumberOfItems && !requested; ++index) {
        const GUID& guid = interfaces->InterfaceInfo[index].InterfaceGuid;
        PWLAN_AVAILABLE_NETWORK_LIST networks = nullptr;
        if (WlanGetAvailableNetworkList(client, &guid, 0, nullptr, &networks) != ERROR_SUCCESS || !networks)
            continue;

        for (DWORD networkIndex = 0; networkIndex < networks->dwNumberOfItems; ++networkIndex) {
            const WLAN_AVAILABLE_NETWORK& network = networks->Network[networkIndex];
            if (ssidToWide(network.dot11Ssid) != networkId || network.strProfileName[0] == L'\0')
                continue;

            WLAN_CONNECTION_PARAMETERS parameters{};
            parameters.wlanConnectionMode = wlan_connection_mode_profile;
            parameters.strProfile = network.strProfileName;
            parameters.dot11BssType = dot11_BSS_type_any;
            parameters.dwFlags = 0;
            requested = WlanConnect(client, &guid, &parameters, nullptr) == ERROR_SUCCESS;
            break;
        }
        WlanFreeMemory(networks);
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    return requested;
}

bool WindowsNetworkSystem::disconnect() const
{
    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool disconnected = false;
    for (DWORD index = 0; index < interfaces->dwNumberOfItems; ++index) {
        if (WlanDisconnect(client, &interfaces->InterfaceInfo[index].InterfaceGuid, nullptr) == ERROR_SUCCESS)
            disconnected = true;
    }

    WlanFreeMemory(interfaces);
    WlanCloseHandle(client, nullptr);
    return disconnected;
}
}
