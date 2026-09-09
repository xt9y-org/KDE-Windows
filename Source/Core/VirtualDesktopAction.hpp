#pragma once

namespace kde_windows
{
enum class VirtualDesktopAction
{
    Left,
    Right,
    Create,
    Close,
};

struct VirtualDesktopShortcut
{
    unsigned short key = 0;
    bool control = true;
};

constexpr VirtualDesktopShortcut virtualDesktopShortcut(VirtualDesktopAction action)
{
    switch (action) {
    case VirtualDesktopAction::Left:
        return {0x25, true};
    case VirtualDesktopAction::Right:
        return {0x27, true};
    case VirtualDesktopAction::Create:
        return {'D', true};
    case VirtualDesktopAction::Close:
        return {0x73, true};
    }
    return {};
}
}
