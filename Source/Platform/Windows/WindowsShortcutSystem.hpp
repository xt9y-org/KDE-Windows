#pragma once

#include "Core/ShortcutAction.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

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

private:
    static LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam);

    HWND window_ = nullptr;
    ATOM classAtom_ = 0;
    Callback callback_;
};
}
