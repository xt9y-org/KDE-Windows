#include "Core/VirtualDesktopAction.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;
    assert(virtualDesktopShortcut(VirtualDesktopAction::Left).key == 0x25);
    assert(virtualDesktopShortcut(VirtualDesktopAction::Right).key == 0x27);
    assert(virtualDesktopShortcut(VirtualDesktopAction::Create).key == 'D');
    assert(virtualDesktopShortcut(VirtualDesktopAction::Close).key == 0x73);
    return 0;
}
