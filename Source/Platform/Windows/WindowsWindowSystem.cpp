#include "WindowsWindowSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <dwmapi.h>

#include <array>
#include <string>
#include <utility>

namespace kde_windows
{
namespace
{
std::wstring window_text(HWND window)
{
    const int length = GetWindowTextLengthW(window);
    if (length <= 0)
        return {};

    std::wstring text(static_cast<std::size_t>(length) + 1, L'\0');
    const int copied = GetWindowTextW(window, text.data(), static_cast<int>(text.size()));
    if (copied <= 0)
        return {};
    text.resize(static_cast<std::size_t>(copied));
    return text;
}

std::wstring executable_path(DWORD processId)
{
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (!process)
        return {};

    std::wstring path(32768, L'\0');
    DWORD size = static_cast<DWORD>(path.size());
    if (!QueryFullProcessImageNameW(process, 0, path.data(), &size)) {
        CloseHandle(process);
        return {};
    }

    CloseHandle(process);
    path.resize(size);
    return path;
}

std::wstring application_user_model_id(DWORD processId)
{
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (!process)
        return {};

    using GetApplicationUserModelIdFn = LONG(WINAPI*)(HANDLE, UINT32*, PWSTR);
    const HMODULE kernel = GetModuleHandleW(L"kernel32.dll");
    const auto getId = reinterpret_cast<GetApplicationUserModelIdFn>(GetProcAddress(kernel, "GetApplicationUserModelId"));
    if (!getId) {
        CloseHandle(process);
        return {};
    }

    UINT32 length = 0;
    LONG result = getId(process, &length, nullptr);
    if (result != ERROR_INSUFFICIENT_BUFFER || length == 0) {
        CloseHandle(process);
        return {};
    }

    std::wstring id(length, L'\0');
    result = getId(process, &length, id.data());
    CloseHandle(process);
    if (result != ERROR_SUCCESS)
        return {};

    while (!id.empty() && id.back() == L'\0')
        id.pop_back();
    return id;
}

bool is_cloaked(HWND window)
{
    DWORD cloaked = 0;
    return SUCCEEDED(DwmGetWindowAttribute(window, DWMWA_CLOAKED, &cloaked, sizeof(cloaked))) && cloaked != 0;
}

WindowSnapshot make_snapshot(HWND window, HWND foreground)
{
    WindowSnapshot snapshot;
    snapshot.id = reinterpret_cast<WindowId>(window);

    DWORD processId = 0;
    GetWindowThreadProcessId(window, &processId);
    snapshot.processId = processId;
    snapshot.title = window_text(window);
    snapshot.executable = executable_path(processId);
    snapshot.appId = application_user_model_id(processId);
    snapshot.visible = IsWindowVisible(window) != FALSE;
    snapshot.minimized = IsIconic(window) != FALSE;
    snapshot.maximized = IsZoomed(window) != FALSE;
    snapshot.active = window == foreground;
    snapshot.cloaked = is_cloaked(window);

    const LONG_PTR exStyle = GetWindowLongPtrW(window, GWL_EXSTYLE);
    const HWND owner = GetWindow(window, GW_OWNER);
    snapshot.toolWindow = (exStyle & WS_EX_TOOLWINDOW) != 0 || (owner != nullptr && (exStyle & WS_EX_APPWINDOW) == 0);
    return snapshot;
}

HWND as_hwnd(WindowId id)
{
    return reinterpret_cast<HWND>(id);
}
}

struct WindowsWindowSystem::Impl
{
    ChangeCallback callback;
    std::array<HWINEVENTHOOK, 4> hooks{};

    static Impl* active;

    static void CALLBACK eventCallback(HWINEVENTHOOK, DWORD event, HWND window, LONG objectId, LONG childId, DWORD, DWORD)
    {
        if (!active || !active->callback)
            return;

        if (event >= EVENT_OBJECT_CREATE && event <= EVENT_OBJECT_NAMECHANGE) {
            if (!window || objectId != OBJID_WINDOW || childId != CHILDID_SELF)
                return;
        }
        active->callback();
    }
};

WindowsWindowSystem::Impl* WindowsWindowSystem::Impl::active = nullptr;

WindowsWindowSystem::WindowsWindowSystem()
    : impl_(std::make_unique<Impl>())
{
}

WindowsWindowSystem::~WindowsWindowSystem()
{
    stop();
}

std::vector<WindowSnapshot> WindowsWindowSystem::snapshot() const
{
    struct Context
    {
        std::vector<WindowSnapshot> windows;
        HWND foreground = GetForegroundWindow();
    } context;

    EnumWindows([](HWND window, LPARAM data) -> BOOL {
        auto& context = *reinterpret_cast<Context*>(data);
        context.windows.push_back(make_snapshot(window, context.foreground));
        return TRUE;
    }, reinterpret_cast<LPARAM>(&context));

    return context.windows;
}

bool WindowsWindowSystem::activate(WindowId id) const
{
    const HWND window = as_hwnd(id);
    if (!IsWindow(window))
        return false;

    if (IsIconic(window))
        ShowWindow(window, SW_RESTORE);
    BringWindowToTop(window);
    return SetForegroundWindow(window) != FALSE;
}

bool WindowsWindowSystem::minimize(WindowId id) const
{
    const HWND window = as_hwnd(id);
    return IsWindow(window) && ShowWindow(window, SW_MINIMIZE) != FALSE;
}

bool WindowsWindowSystem::toggleMaximize(WindowId id) const
{
    const HWND window = as_hwnd(id);
    if (!IsWindow(window))
        return false;
    ShowWindow(window, IsZoomed(window) ? SW_RESTORE : SW_MAXIMIZE);
    return true;
}

bool WindowsWindowSystem::close(WindowId id) const
{
    const HWND window = as_hwnd(id);
    return IsWindow(window) && PostMessageW(window, WM_CLOSE, 0, 0) != FALSE;
}

bool WindowsWindowSystem::start(ChangeCallback callback)
{
    stop();
    impl_->callback = std::move(callback);
    Impl::active = impl_.get();

    constexpr DWORD flags = WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS;
    impl_->hooks[0] = SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, nullptr, Impl::eventCallback, 0, 0, flags);
    impl_->hooks[1] = SetWinEventHook(EVENT_SYSTEM_MINIMIZESTART, EVENT_SYSTEM_MINIMIZEEND, nullptr, Impl::eventCallback, 0, 0, flags);
    impl_->hooks[2] = SetWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_HIDE, nullptr, Impl::eventCallback, 0, 0, flags);
    impl_->hooks[3] = SetWinEventHook(EVENT_OBJECT_NAMECHANGE, EVENT_OBJECT_NAMECHANGE, nullptr, Impl::eventCallback, 0, 0, flags);

    for (const auto hook : impl_->hooks) {
        if (!hook) {
            stop();
            return false;
        }
    }
    return true;
}

void WindowsWindowSystem::stop()
{
    for (auto& hook : impl_->hooks) {
        if (hook) {
            UnhookWinEvent(hook);
            hook = nullptr;
        }
    }
    if (Impl::active == impl_.get())
        Impl::active = nullptr;
    impl_->callback = {};
}
}
