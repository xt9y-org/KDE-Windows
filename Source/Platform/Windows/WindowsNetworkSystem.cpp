#include "WindowsNetworkSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <netlistmgr.h>
#include <wlanapi.h>

#include <string>

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

bool queryWifi(NetworkState& state)
{
    HANDLE client = nullptr;
    DWORD negotiatedVersion = 0;
    if (WlanOpenHandle(2, nullptr, &negotiatedVersion, &client) != ERROR_SUCCESS)
        return false;

    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    const DWORD enumResult = WlanEnumInterfaces(client, nullptr, &interfaces);
    if (enumResult != ERROR_SUCCESS || !interfaces) {
        WlanCloseHandle(client, nullptr);
        return false;
    }

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
}
