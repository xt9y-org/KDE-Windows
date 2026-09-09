#pragma once

#include <algorithm>
#include <vector>

namespace kde_windows
{
struct DisplayModeSnapshot
{
    int width = 0;
    int height = 0;
    int refreshRate = 0;
    int bitsPerPixel = 0;

    bool operator==(const DisplayModeSnapshot&) const = default;
};

inline void normalizeDisplayModes(std::vector<DisplayModeSnapshot>& modes)
{
    modes.erase(std::remove_if(modes.begin(), modes.end(), [](const DisplayModeSnapshot& mode) {
        return mode.width <= 0 || mode.height <= 0 || mode.refreshRate <= 0;
    }), modes.end());

    std::sort(modes.begin(), modes.end(), [](const DisplayModeSnapshot& a, const DisplayModeSnapshot& b) {
        if (a.width != b.width)
            return a.width > b.width;
        if (a.height != b.height)
            return a.height > b.height;
        return a.refreshRate > b.refreshRate;
    });

    modes.erase(std::unique(modes.begin(), modes.end(), [](const DisplayModeSnapshot& a, const DisplayModeSnapshot& b) {
        return a.width == b.width && a.height == b.height && a.refreshRate == b.refreshRate;
    }), modes.end());
}
}
