#include "WindowsVirtualDesktopSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

#include <array>

namespace kde_windows
{
namespace
{
INPUT keyInput(WORD key, bool up)
{
    INPUT input{};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = key;
    input.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;
    return input;
}
}

bool WindowsVirtualDesktopSystem::perform(VirtualDesktopAction action) const
{
    const VirtualDesktopShortcut shortcut = virtualDesktopShortcut(action);
    if (!shortcut.key)
        return false;

    const WORD key = static_cast<WORD>(shortcut.key);
    std::array<INPUT, 6> inputs{
        keyInput(VK_LWIN, false),
        keyInput(VK_CONTROL, false),
        keyInput(key, false),
        keyInput(key, true),
        keyInput(VK_CONTROL, true),
        keyInput(VK_LWIN, true),
    };

    return SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT)) == inputs.size();
}
}
