#include "WindowsShortcutSystem.hpp"

#include <utility>

namespace kde_windows
{
namespace
{
constexpr wchar_t kShortcutClass[] = L"KDEWindowsShortcutHost";
}

WindowsShortcutSystem::~WindowsShortcutSystem()
{
    stop();
}

bool WindowsShortcutSystem::start(Callback callback)
{
    if (window_)
        return true;

    callback_ = std::move(callback);
    const HINSTANCE instance = GetModuleHandleW(nullptr);

    WNDCLASSEXW windowClass{};
    windowClass.cbSize = sizeof(windowClass);
    windowClass.hInstance = instance;
    windowClass.lpfnWndProc = &WindowsShortcutSystem::windowProc;
    windowClass.lpszClassName = kShortcutClass;

    classAtom_ = RegisterClassExW(&windowClass);
    if (!classAtom_) {
        callback_ = {};
        return false;
    }

    window_ = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
                              kShortcutClass,
                              L"KDE Windows Shortcuts",
                              WS_POPUP,
                              -32000, -32000, 1, 1,
                              nullptr, nullptr, instance, this);
    if (!window_) {
        UnregisterClassW(kShortcutClass, instance);
        classAtom_ = 0;
        callback_ = {};
        return false;
    }

    const bool runner = RegisterHotKey(window_, kRunnerHotkeyId, MOD_ALT | MOD_NOREPEAT, VK_SPACE) != FALSE;
    const bool clipboard = RegisterHotKey(window_, kClipboardHotkeyId, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, 'V') != FALSE;
    return runner || clipboard;
}

void WindowsShortcutSystem::stop()
{
    if (window_) {
        UnregisterHotKey(window_, kRunnerHotkeyId);
        UnregisterHotKey(window_, kClipboardHotkeyId);
        DestroyWindow(window_);
        window_ = nullptr;
    }

    if (classAtom_) {
        UnregisterClassW(kShortcutClass, GetModuleHandleW(nullptr));
        classAtom_ = 0;
    }
    callback_ = {};
}

LRESULT CALLBACK WindowsShortcutSystem::windowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
{
    WindowsShortcutSystem* self = reinterpret_cast<WindowsShortcutSystem*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
        const auto* create = reinterpret_cast<const CREATESTRUCTW*>(lparam);
        self = static_cast<WindowsShortcutSystem*>(create->lpCreateParams);
        SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    }

    if (self && message == WM_HOTKEY && self->callback_) {
        const ShortcutAction action = shortcutActionForId(static_cast<int>(wparam));
        if (action != ShortcutAction::None) {
            self->callback_(action);
            return 0;
        }
    }

    return DefWindowProcW(window, message, wparam, lparam);
}
}
