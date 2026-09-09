#include "Core/WifiProfile.hpp"

#include <cassert>
#include <string>

int main()
{
    using namespace kde_windows;

    assert(wifiXmlEscape(L"A&B") == L"A&amp;B");
    assert(wifiXmlEscape(L"<x>") == L"&lt;x&gt;");
    assert(!wifiValidPersonalPassword(L"short"));
    assert(wifiValidPersonalPassword(L"12345678"));
    assert(wifiValidPersonalPassword(std::wstring(64, L'a')));
    assert(!wifiHexKey(std::wstring(64, L'z')));

    const auto open = wifiProfileSecurity(false, kWifiAuthOpen, false);
    assert(open.supported && !open.needsKey);
    assert(open.authentication == L"open");
    assert(open.encryption == L"none");

    const auto wpa2 = wifiProfileSecurity(true, kWifiAuthWpa2Psk, false);
    assert(wpa2.supported && wpa2.needsKey);
    assert(wpa2.authentication == L"WPA2PSK");
    assert(wpa2.encryption == L"AES");

    const auto wpa3 = wifiProfileSecurity(true, kWifiAuthWpa3Sae, true);
    assert(wpa3.supported);
    assert(wpa3.authentication == L"WPA3SAE");
    assert(wpa3.encryption == L"AES");

    const auto enterprise = wifiProfileSecurity(true, 6, false);
    assert(!enterprise.supported);

    const auto xml = buildWifiProfileXml(L"A&B", L"412642", wpa2, L"password123");
    assert(xml.find(L"<name>A&amp;B</name>") != std::wstring::npos);
    assert(xml.find(L"<authentication>WPA2PSK</authentication>") != std::wstring::npos);
    assert(xml.find(L"<keyMaterial>password123</keyMaterial>") != std::wstring::npos);
    assert(buildWifiProfileXml(L"A", L"41", wpa2, L"bad").empty());
    return 0;
}
