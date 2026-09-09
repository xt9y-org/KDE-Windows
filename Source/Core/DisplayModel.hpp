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

private:
    std::vector<DisplaySnapshot> displays_;
};
}
