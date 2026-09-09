#pragma once

#include "Core/DisplayModel.hpp"

#include <vector>

namespace kde_windows
{
class WindowsDisplaySystem final
{
public:
    [[nodiscard]] std::vector<DisplaySnapshot> scan() const;
};
}
