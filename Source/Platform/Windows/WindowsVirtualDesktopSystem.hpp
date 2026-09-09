#pragma once

#include "Core/VirtualDesktopAction.hpp"

namespace kde_windows
{
class WindowsVirtualDesktopSystem final
{
public:
    [[nodiscard]] bool perform(VirtualDesktopAction action) const;
};
}
