#pragma once

#include <cwctype>
#include <string>

namespace kde_windows
{
inline constexpr int kWifiAuthOpen = 1;
inline constexpr int kWifiAuthWpaPsk = 4;
inline constexpr int kWifiAuthWpa2Psk = 7;
inline constexpr int kWifiAuthWpa3Sae = 9;

struct WifiProfileSecurity
{
    std::wstring authentication;
    std::wstring encryption;
    bool needsKey = false;
    bool supported = false;
};

inline std::wstring wifiXmlEscape(const std::wstring& value)
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

inline bool wifiHexKey(const std::wstring& password)
{
    if (password.size() != 64)
        return false;
    for (const wchar_t c : password) {
        if (!std::iswxdigit(c))
            return false;
    }
    return true;
}

inline bool wifiValidPersonalPassword(const std::wstring& password)
{
    return (password.size() >= 8 && password.size() <= 63) || wifiHexKey(password);
}

inline WifiProfileSecurity wifiProfileSecurity(bool secure, int authAlgorithm, bool tkip)
{
    WifiProfileSecurity result;
    result.needsKey = secure;

    if (!secure && authAlgorithm == kWifiAuthOpen) {
        result.authentication = L"open";
        result.encryption = L"none";
        result.supported = true;
        return result;
    }

    switch (authAlgorithm) {
    case kWifiAuthWpaPsk: result.authentication = L"WPAPSK"; break;
    case kWifiAuthWpa2Psk: result.authentication = L"WPA2PSK"; break;
    case kWifiAuthWpa3Sae: result.authentication = L"WPA3SAE"; break;
    default: return result;
    }

    result.encryption = (tkip && authAlgorithm != kWifiAuthWpa3Sae) ? L"TKIP" : L"AES";
    result.supported = true;
    return result;
}

inline std::wstring buildWifiProfileXml(const std::wstring& name,
                                        const std::wstring& hexSsid,
                                        const WifiProfileSecurity& security,
                                        const std::wstring& password)
{
    if (!security.supported || name.empty() || hexSsid.empty())
        return {};
    if (security.needsKey && !wifiValidPersonalPassword(password))
        return {};

    const std::wstring escapedName = wifiXmlEscape(name);
    std::wstring xml =
        L"<?xml version=\"1.0\"?><WLANProfile xmlns=\"http://www.microsoft.com/networking/WLAN/profile/v1\"><name>" +
        escapedName +
        L"</name><SSIDConfig><SSID><hex>" + hexSsid + L"</hex><name>" + escapedName +
        L"</name></SSID></SSIDConfig><connectionType>ESS</connectionType><connectionMode>auto</connectionMode>"
        L"<autoSwitch>false</autoSwitch><MSM><security><authEncryption><authentication>" + security.authentication +
        L"</authentication><encryption>" + security.encryption + L"</encryption><useOneX>false</useOneX></authEncryption>";

    if (security.needsKey) {
        const bool networkKey = wifiHexKey(password) && security.authentication != L"WPA3SAE";
        xml += L"<sharedKey><keyType>";
        xml += networkKey ? L"networkKey" : L"passPhrase";
        xml += L"</keyType><protected>false</protected><keyMaterial>" + wifiXmlEscape(password) + L"</keyMaterial></sharedKey>";
    }

    xml += L"</security></MSM></WLANProfile>";
    return xml;
}
}
