#include "WindowsNetworkSystem.hpp"
#include "Core/WifiProfile.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <wlanapi.h>

#include <string>
#include <vector>

namespace kde_windows
{
namespace
{
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

std::wstring ssidHex(const DOT11_SSID& ssid)
{
    static constexpr wchar_t digits[] = L"0123456789ABCDEF";
    std::wstring result;
    result.reserve(static_cast<std::size_t>(ssid.uSSIDLength) * 2);
    for (ULONG i = 0; i < ssid.uSSIDLength; ++i) {
        const unsigned char byte = ssid.ucSSID[i];
        result += digits[(byte >> 4) & 0x0f];
        result += digits[byte & 0x0f];
    }
    return result;
}

WifiProfileSecurity securityFor(const WLAN_AVAILABLE_NETWORK& network)
{
    return wifiProfileSecurity(network.bSecurityEnabled != FALSE,
                               static_cast<int>(network.dot11DefaultAuthAlgorithm),
                               static_cast<int>(network.dot11DefaultCipherAlgorithm) == static_cast<int>(DOT11_CIPHER_ALGO_TKIP));
}
}

bool WindowsNetworkSystem::connectWithPassword(const std::wstring& networkId, const std::wstring& password) const
{
    if (networkId.empty())
        return false;

    HANDLE client = nullptr;
    PWLAN_INTERFACE_INFO_LIST interfaces = nullptr;
    if (!openClient(client, interfaces))
        return false;

    bool requested = false;
    for (DWORD interfaceIndex = 0; interfaceIndex < interfaces->dwNumberOfItems && !requested; ++interfaceIndex) {
        const GUID& guid = interfaces->InterfaceInfo[interfaceIndex].InterfaceGuid;
        PWLAN_AVAILABLE_NETWORK_LIST networks = nullptr;
        if (WlanGetAvailableNetworkList(client, &guid, 0, nullptr, &networks) != ERROR_SUCCESS || !networks)
            continue;

        for (DWORD networkIndex = 0; networkIndex < networks->dwNumberOfItems; ++networkIndex) {
            const WLAN_AVAILABLE_NETWORK& network = networks->Network[networkIndex];
            if (ssidToWide(network.dot11Ssid) != networkId)
                continue;

            const WifiProfileSecurity security = securityFor(network);
            const std::wstring profileName = ssidToWide(network.dot11Ssid);
            const std::wstring profileXml = buildWifiProfileXml(profileName,
                                                                ssidHex(network.dot11Ssid),
                                                                security,
                                                                password);
            if (profileXml.empty())
                break;

            DWORD reason = 0;
            if (WlanSetProfile(client, &guid, 0, profileXml.c_str(), nullptr, TRUE, nullptr, &reason) != ERROR_SUCCESS)
                break;

            WLAN_CONNECTION_PARAMETERS parameters{};
            parameters.wlanConnectionMode = wlan_connection_mode_profile;
            parameters.strProfile = profileName.c_str();
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
}
