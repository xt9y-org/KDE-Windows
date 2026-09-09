#pragma once

#include "Core/DisplayMode.hpp"
#include "Core/DisplayModel.hpp"

#include <string>
#include <vector>

namespace kde_windows
{
class WindowsDisplaySystem final
{
public:
    [[nodiscard]] std::vector<DisplaySnapshot> scan() const;
    [[nodiscard]] std::vector<DisplayModeSnapshot> modes(const std::wstring& displayId) const;
    [[nodiscard]] bool setMode(const std::wstring& displayId, int width, int height, int refreshRate) const;
    [[nodiscard]] bool setPrimary(const std::wstring& displayId) const;
    [[nodiscard]] bool setBrightness(const std::wstring& displayId, int percent) const;
};
}
