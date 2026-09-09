#pragma once

#include "Core/DisplayModel.hpp"

#include <string>
#include <vector>

namespace kde_windows
{
class WindowsDisplaySystem final
{
public:
    [[nodiscard]] std::vector<DisplaySnapshot> scan() const;
    [[nodiscard]] bool setBrightness(const std::wstring& displayId, int percent) const;
};
}
