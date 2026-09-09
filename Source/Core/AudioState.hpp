#pragma once

#include <algorithm>

namespace kde_windows
{
struct AudioState
{
    bool available = false;
    int volume = 0;
    bool muted = false;
};

constexpr int clampVolume(int volume)
{
    return std::clamp(volume, 0, 100);
}
}
