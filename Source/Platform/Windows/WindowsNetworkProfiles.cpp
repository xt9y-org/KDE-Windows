#include "WindowsNetworkSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <wlanapi.h>

#include <cwctype>
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

std::wstring xmlEscape(const std::wstring& value)
{
    std::wstring result;
    result.reserve(value.size() + 16);
    for (const wchar_t c : value) {
        switch (c) {
        case L'&': result += L"&amp;"; break;
        case L'<': result += L"&lt;"; break;
        case L'>': result += L"&gt;"; break;
        case L'\"': result += L"&quot;"; break;
        case L'\'': result += L"&apos;"; break;
        default: result += c; break;
        }
    }
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

bool isHexKey(const std::wstring& password)
{
    if (password.size() != 64)
        return false;
    for (const wchar_t c : password) {
        if (!std::iswxdigit(c))
            return false;
    }
    return true;
}

bool personalProfileParameters(const WLAN_AVAILABLE_NETWORK& network,
                               std::wstring& authentication,
                               std::wstring& encryption,
                               bool& needsKey)
{
    needsKey = network.bSecurityEnabled != FALSE;
    const int auth = static_cast<int>(network.dot11DefaultAuthAlgorithm);
    if (!needsKey && auth == static_cast<int>(DOT11_AUTH_ALGO_80211_OPEN)) {
        authentication = L"open";
        encryption = L"none";
        return true;
    }

    switch (auth) {
    case static_cast<int>(DOT11_AUTH_ALGO_WPA_PSK):
        authentication = L"WPAPSK";
        break;
    case static_cast<int>(DOT11_AUTH_ALGO_RSNA_PSK):
        authentication = L"WPA2PSK";
        break;
    case 9:
        authentication = L"WPA3SAE";
        break;
    default:
        return false;
    }

    const int cipher = static_cast<int>(network.dot11DefaultCipherAlgorithm);
    encryption = cipher == static_cast<int>(DOT11_CIPHER_ALGO_TKIP) ? L"TKIP" : L"AES";
    if (authentication == L"WPA3SAE")
        encryption = L"AES";
    return true;
}

std::wstring buildProfile(const WLAN_AVAILABLE_NETWORK& network,
                          const std::wstring& password,
                          const std::wstring& authentication,
                          const std::wstring& encryption,
                          bool needsKey)
{
    const std::wstring name = ssidToWide(network.dot11Ssid);
    const std::wstring escapedName = xmlEscape(name);

    std::wstring xml =
        L"<?xml version=\"1.0\"?><WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\"><name>" +
        escapedName +
        L"</name><SSIDConfig><SSID><hex>" + ssidHex(network.dot11Ssid) + L"</hex><name>" + escapedName +
        L"</name></SSID></SSIDConfig><connectionType>ESS</connectionType><connectionMode>auto</connectionMode>"
        L"<autoSwitch>false</autoSwitch><MSM><security><authEncryption><authentication>" + authentication +
        L"</authentication><encryption>" + encryption + L"</encryption><useOneX>false</useOneX></authEncryption>";

    if (needsKey) {
        const bool networkKey = isHexKey(password) && authentication != L"WPA3SAE";
        xml += L"<sharedKey><keyType>";
        xml += networkKey ? L"networkKey" : L"passPhrase";
        xml += L"</keyType><protected>false</protected><keyMaterial>" + xmlEscape(password) + L"</keyMaterial></sharedKey>";
    }

    xml += L"</security></MSM></WLANProfile>";
    return xml;
}

bool validPassword(const std::wstring& password)
{
    return (password.size() >= 8 && password.size() <= 63) || isHexKey(password);
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

            std::wstring authentication;
            std::wstring encryption;
            bool needsKey = false;
            if (!personalProfileParameters(network, authentication, encryption, needsKey))
                break;
            if (needsKey && !validPassword(password))
                break;

            const std::wstring profileName = ssidToWide(network.dot11Ssid);
            const std::wstring profileXml = buildProfile(network, password, authentication, encryption, needsKey);
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
