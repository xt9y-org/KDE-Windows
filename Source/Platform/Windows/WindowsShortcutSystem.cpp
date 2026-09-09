#include "WindowsShortcutSystem.hpp"

#include <utility>

namespace kde_windows
{
namespace
{
constexpr wchar_t kShortcutClass[] = L"KDEWindowsShortcutHost";
WindowsShortcutSystem* g_shortcutSystem = nullptr;
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

    g_shortcutSystem = this;
    keyboardHook_ = SetWindowsHookExW(WH_KEYBOARD_LL, &WindowsShortcutSystem::keyboardProc, instance, 0);
    if (!runner && !clipboard && !keyboardHook_) {
        stop();
        return false;
    }
    return true;
}

void WindowsShortcutSystem::stop()
{
    if (keyboardHook_) {
        UnhookWindowsHookEx(keyboardHook_);
        keyboardHook_ = nullptr;
    }
    if (g_shortcutSystem == this)
        g_shortcutSystem = nullptr;
    switching_ = false;

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

LRESULT CALLBACK WindowsShortcutSystem::keyboardProc(int code, WPARAM wparam, LPARAM lparam)
{
    WindowsShortcutSystem* self = g_shortcutSystem;
    if (code != HC_ACTION || !self || !self->callback_)
        return CallNextHookEx(nullptr, code, wparam, lparam);

    const auto* key = reinterpret_cast<const KBDLLHOOKSTRUCT*>(lparam);
    if (!key)
        return CallNextHookEx(nullptr, code, wparam, lparam);

    const bool keyDown = wparam == WM_KEYDOWN || wparam == WM_SYSKEYDOWN;
    const bool keyUp = wparam == WM_KEYUP || wparam == WM_SYSKEYUP;

    if (keyDown && key->vkCode == VK_TAB && (GetAsyncKeyState(VK_MENU) & 0x8000)) {
        const bool reverse = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
        self->switching_ = true;
        self->callback_(reverse ? ShortcutAction::WindowPrevious : ShortcutAction::WindowNext);
        return 1;
    }

    if (self->switching_ && keyUp &&
        (key->vkCode == VK_MENU || key->vkCode == VK_LMENU || key->vkCode == VK_RMENU)) {
        self->switching_ = false;
        self->callback_(ShortcutAction::WindowCommit);
        return 1;
    }

    return CallNextHookEx(nullptr, code, wparam, lparam);
}
}
