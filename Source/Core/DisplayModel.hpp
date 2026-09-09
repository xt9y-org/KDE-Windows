#pragma once

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
struct DisplaySnapshot
{
    std::wstring id;
    std::wstring name;
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    int workX = 0;
    int workY = 0;
    int workWidth = 0;
    int workHeight = 0;
    bool primary = false;
    bool brightnessAvailable = false;
    int brightnessPercent = -1;

    bool operator==(const DisplaySnapshot&) const = default;
};

class DisplayModel final
{
public:
    void replace(std::vector<DisplaySnapshot> displays)
    {
        displays.erase(std::remove_if(displays.begin(), displays.end(), [](const DisplaySnapshot& display) {
            return display.width <= 0 || display.height <= 0;
        }), displays.end());

        for (auto& display : displays) {
            if (display.brightnessAvailable)
                display.brightnessPercent = std::clamp(display.brightnessPercent, 0, 100);
            else
                display.brightnessPercent = -1;
        }

        std::stable_sort(displays.begin(), displays.end(), [](const DisplaySnapshot& a, const DisplaySnapshot& b) {
            if (a.primary != b.primary)
                return a.primary > b.primary;
            if (a.x != b.x)
                return a.x < b.x;
            return a.y < b.y;
        });
        displays_ = std::move(displays);
    }

    [[nodiscard]] const std::vector<DisplaySnapshot>& displays() const noexcept { return displays_; }

    [[nodiscard]] const DisplaySnapshot* primary() const noexcept
    {
        const auto it = std::find_if(displays_.begin(), displays_.end(), [](const DisplaySnapshot& display) {
            return display.primary;
        });
        return it != displays_.end() ? &*it : (displays_.empty() ? nullptr : &displays_.front());
    }

    [[nodiscard]] const DisplaySnapshot* find(const std::wstring& id) const noexcept
    {
        const auto it = std::find_if(displays_.begin(), displays_.end(), [&](const DisplaySnapshot& display) {
            return display.id == id;
        });
        return it == displays_.end() ? nullptr : &*it;
    }

private:
    std::vector<DisplaySnapshot> displays_;
};
}
