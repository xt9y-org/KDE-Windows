#pragma once

#include "Core/ShortcutAction.hpp"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <atomic>
#include <functional>

namespace kde_windows
{
class WindowsShortcutSystem final
{
public:
    using Callback = std::function<void(ShortcutAction)>;

    WindowsShortcutSystem() = default;
    ~WindowsShortcutSystem();

    WindowsShortcutSystem(const WindowsShortcutSystem&) = delete;
    WindowsShortcutSystem& operator=(const WindowsShortcutSystem&) = delete;

    bool start(Callback callback);
    void stop();
    bool takeLauncherRequest() { return launcherRequest_.exchange(false); }

private:
    static LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam);
    static LRESULT CALLBACK keyboardProc(int code, WPARAM wparam, LPARAM lparam);

    HWND window_ = nullptr;
    HHOOK keyboardHook_ = nullptr;
    ATOM classAtom_ = 0;
    bool switching_ = false;
    bool winTapCandidate_ = false;
    bool winInjectedForCombo_ = false;
    std::atomic_bool launcherRequest_{false};
    Callback callback_;
};
}
