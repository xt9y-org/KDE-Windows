#pragma once

#include <algorithm>
#include <cwctype>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
struct WifiNetworkSnapshot
{
    std::wstring id;
    std::wstring name;
    std::wstring profileName;
    int signalQuality = 0;
    bool connected = false;
    bool known = false;
    bool secure = false;

    bool operator==(const WifiNetworkSnapshot&) const = default;
};

inline std::wstring networkLower(std::wstring value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](wchar_t c) {
        return static_cast<wchar_t>(std::towlower(c));
    });
    return value;
}

inline void normalizeWifiNetworks(std::vector<WifiNetworkSnapshot>& networks)
{
    for (auto& network : networks)
        network.signalQuality = std::clamp(network.signalQuality, 0, 100);

    std::stable_sort(networks.begin(), networks.end(), [](const WifiNetworkSnapshot& a, const WifiNetworkSnapshot& b) {
        if (a.connected != b.connected)
            return a.connected > b.connected;
        if (a.known != b.known)
            return a.known > b.known;
        if (a.signalQuality != b.signalQuality)
            return a.signalQuality > b.signalQuality;
        return networkLower(a.name) < networkLower(b.name);
    });

    networks.erase(std::unique(networks.begin(), networks.end(), [](const WifiNetworkSnapshot& a, const WifiNetworkSnapshot& b) {
        return a.id == b.id;
    }), networks.end());
}
}
