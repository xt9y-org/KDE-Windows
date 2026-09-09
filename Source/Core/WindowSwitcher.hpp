#pragma once

#include <cstddef>
#include <limits>

namespace kde_windows
{
inline constexpr std::size_t kNoWindowSelection = std::numeric_limits<std::size_t>::max();

constexpr std::size_t cycleWindowSelection(std::size_t count, std::size_t current, bool reverse)
{
    if (count == 0)
        return kNoWindowSelection;
    if (current >= count)
        return reverse ? count - 1 : 0;
    if (count == 1)
        return 0;
    return reverse ? (current == 0 ? count - 1 : current - 1)
                   : (current + 1) % count;
}
}
