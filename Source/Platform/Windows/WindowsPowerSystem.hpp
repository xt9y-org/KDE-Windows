#pragma once

#include "Core/SystemState.hpp"

namespace kde_windows
{
class WindowsPowerSystem final
{
public:
    [[nodiscard]] PowerState state() const;
    bool suspend() const;
};
}
