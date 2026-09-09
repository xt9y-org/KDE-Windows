#pragma once

#include <algorithm>
#include <string>

namespace kde_windows
{
struct PowerState
{
    bool batteryAvailable = false;
    int batteryPercent = -1;
    bool charging = false;
    bool onAc = false;
    int secondsRemaining = -1;
};

struct NetworkState
{
    bool connected = false;
    bool wifi = false;
    std::wstring name;
    int signalQuality = 0;
};

constexpr int normalizeBatteryPercent(int percent)
{
    if (percent < 0 || percent == 255)
        return -1;
    return std::clamp(percent, 0, 100);
}

constexpr int clampSignalQuality(int quality)
{
    return std::clamp(quality, 0, 100);
}
}
