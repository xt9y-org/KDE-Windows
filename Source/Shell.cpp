#include "ShellConfig.hpp"
#include "Core/ApplicationModel.hpp"
#include "Core/PanelLayout.hpp"
#include "Core/ShellPolicy.hpp"
#include "Core/WindowModel.hpp"
#include "Platform/Windows/WindowsApplications.hpp"
#include "Platform/Windows/WindowsWindowSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <objbase.h>

#include <algorithm>
#include <filesystem>
#include <iterator>
#include <memory>
#include <string>
#include <vector>

namespace
{
constexpr wchar_t kDesktopClass[] = L"KDEWindowsDesktop";
constexpr wchar_t kPanelClass[] = L"Shell_TrayWnd";
constexpr int kPanelHeight = 44;
constexpr UINT_PTR kClockTimer = 1;
constexpr UINT kAppBarMessage = WM_APP + 1;
constexpr UINT kWindowModelChanged = WM_APP + 2;

constexpr int kLauncherId = 100;
constexpr int kTaskBaseId = 1000;
constexpr int kApplicationBaseId = 3000;
constexpr int kCommandPromptId = 200;
constexpr int kPowerShellId = 201;
constexpr int kLockId = 202;
constexpr int kLogOutId = 203;
constexpr int kRestartId = 204;
constexpr int kShutdownId = 205;
constexpr int kTaskMinimizeId = 4000;
constexpr int kTaskMaximizeId = 4001;
constexpr int kTaskCloseId = 4002;
constexpr int kAltSpaceHotkey = 5000;

HWND g_desktop = nullptr;
HWND g_panel = nullptr;
HWND g_launcher = nullptr;
HWND g_clock = nullptr;
HFONT g_font = nullptr;
HBRUSH g_desktopBrush = nullptr;
HBRUSH g_panelBrush = nullptr;
std::wstring g_root;
bool g_appBarRegistered = false;

kde_windows::WindowModel g_windowModel;
kde_windows::ApplicationModel g_applicationModel;
std::unique_ptr<kde_windows::WindowsWindowSystem> g_windowSystem;
std::unique_ptr<kde_windows::WindowsApplications> g_applications;
std::vector<HWND> g_taskButtons;
std::vector<kde_windows::WindowId> g_taskIds;
std::vector<const kde_windows::ApplicationEntry*> g_launcherEntries;
kde_windows::WindowId g_contextTask = 0;

std::wstring executable_directory()
{
    std::wstring path(32768, L'\0');
    const DWORD length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
    path.resize(length);
    return std::filesystem::path(path).parent_path().wstring();
}

bool launch(const std::wstring& executable, const std::wstring& arguments = L"")
{
    std::wstring command = kde_windows::shell_command(executable);
    if (!arguments.empty()) {
        command += L" ";
        command += arguments;
    }

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};

    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE, 0, nullptr, nullptr, &startup, &process))
        return false;

    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return true;
}

bool enable_shutdown_privilege()
{
    HANDLE token = nullptr;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &token))
        return false;

    LUID luid{};
    if (!LookupPrivilegeValueW(nullptr, SE_SHUTDOWN_NAME, &luid)) {
        CloseHandle(token);
        return false;
    }

    TOKEN_PRIVILEGES privileges{};
    privileges.PrivilegeCount = 1;
    privileges.Privileges[0].Luid = luid;
    privileges.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    SetLastError(ERROR_SUCCESS);
    AdjustTokenPrivileges(token, FALSE, &privileges, 0, nullptr, nullptr);
    const bool enabled = GetLastError() == ERROR_SUCCESS;
    CloseHandle(token);
    return enabled;
}

void request_exit(UINT flags)
{
    if ((flags & (EWX_REBOOT | EWX_POWEROFF | EWX_SHUTDOWN)) != 0 && !enable_shutdown_privilege())
        return;
    ExitWindowsEx(flags, SHTDN_REASON_MAJOR_OTHER | SHTDN_REASON_MINOR_OTHER);
}

void update_clock()
{
    if (!g_clock)
        return;

    SYSTEMTIME time{};
    GetLocalTime(&time);

    wchar_t text[64]{};
    swprintf_s(text, L"%02u:%02u", time.wHour, time.wMinute);
    SetWindowTextW(g_clock, text);
}

void unregister_appbar()
{
    if (!g_appBarRegistered || !g_panel)
        return;
    APPBARDATA data{};
    data.cbSize = sizeof(data);
    data.hWnd = g_panel;
    SHAppBarMessage(ABM_REMOVE, &data);
    g_appBarRegistered = false;
}

void position_appbar()
{
    if (!g_panel)
        return;

    APPBARDATA data{};
    data.cbSize = sizeof(data);
    data.hWnd = g_panel;
    data.uCallbackMessage = kAppBarMessage;

    if (!g_appBarRegistered)
        g_appBarRegistered = SHAppBarMessage(ABM_NEW, &data) != 0;

    data.uEdge = ABE_BOTTOM;
    data.rc.left = 0;
    data.rc.right = GetSystemMetrics(SM_CXSCREEN);
    data.rc.top = GetSystemMetrics(SM_CYSCREEN) - kPanelHeight;
    data.rc.bottom = GetSystemMetrics(SM_CYSCREEN);

    SHAppBarMessage(ABM_QUERYPOS, &data);
    data.rc.top = data.rc.bottom - kPanelHeight;
    SHAppBarMessage(ABM_SETPOS, &data);

    SetWindowPos(g_panel, HWND_TOPMOST, data.rc.left, data.rc.top,
                 data.rc.right - data.rc.left, data.rc.bottom - data.rc.top,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void layout_panel()
{
    if (!g_panel)
        return;

    RECT client{};
    GetClientRect(g_panel, &client);
    const auto layout = kde_windows::panelLayout(client.right - client.left, client.bottom - client.top, g_taskButtons.size());

    if (g_launcher)
        SetWindowPos(g_launcher, nullptr, layout.launcher.x, layout.launcher.y, layout.launcher.width, layout.launcher.height,
                     SWP_NOZORDER | SWP_NOACTIVATE);
    if (g_clock)
        SetWindowPos(g_clock, nullptr, layout.clock.x, layout.clock.y, layout.clock.width, layout.clock.height,
                     SWP_NOZORDER | SWP_NOACTIVATE);

    const std::size_t visibleTasks = std::min(layout.tasks.size(), g_taskButtons.size());
    for (std::size_t i = 0; i < g_taskButtons.size(); ++i) {
        if (i >= visibleTasks) {
            ShowWindow(g_taskButtons[i], SW_HIDE);
            continue;
        }
        const auto& rect = layout.tasks[i];
        SetWindowPos(g_taskButtons[i], nullptr, rect.x, rect.y, rect.width, rect.height,
                     SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW);
    }
}

void resize_shell()
{
    if (!g_desktop || !g_panel)
        return;

    const int x = GetSystemMetrics(SM_XVIRTUALSCREEN);
    const int y = GetSystemMetrics(SM_YVIRTUALSCREEN);
    const int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    const int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
    SetWindowPos(g_desktop, HWND_BOTTOM, x, y, width, height, SWP_NOACTIVATE | SWP_SHOWWINDOW);

    position_appbar();
    layout_panel();
}

std::wstring task_label(const kde_windows::WindowSnapshot& window)
{
    constexpr std::size_t limit = 32;
    if (window.title.size() <= limit)
        return window.title;
    return window.title.substr(0, limit - 1) + L"…";
}

void destroy_task_buttons()
{
    for (const HWND button : g_taskButtons) {
        if (button)
            DestroyWindow(button);
    }
    g_taskButtons.clear();
    g_taskIds.clear();
}

void refresh_tasks()
{
    if (!g_windowSystem || !g_panel)
        return;

    g_windowModel.replace(g_windowSystem->snapshot(), GetCurrentProcessId());
    destroy_task_buttons();

    const auto& windows = g_windowModel.windows();
    g_taskButtons.reserve(windows.size());
    g_taskIds.reserve(windows.size());

    for (std::size_t i = 0; i < windows.size(); ++i) {
        const auto& window = windows[i];
        const auto label = task_label(window);
        HWND button = CreateWindowExW(0, L"BUTTON", label.c_str(),
                                      WS_CHILD | WS_VISIBLE | BS_FLAT | BS_PUSHBUTTON,
                                      0, 0, 1, 1, g_panel,
                                      reinterpret_cast<HMENU>(static_cast<INT_PTR>(kTaskBaseId + i)),
                                      GetModuleHandleW(nullptr), nullptr);
        if (!button)
            continue;
        if (g_font)
            SendMessageW(button, WM_SETFONT, reinterpret_cast<WPARAM>(g_font), TRUE);
        g_taskButtons.push_back(button);
        g_taskIds.push_back(window.id);
    }
    layout_panel();
}

void refresh_applications()
{
    if (!g_applications)
        return;
    g_applicationModel.replace(g_applications->scan());
}

void show_task_context_menu(kde_windows::WindowId task, POINT screenPoint)
{
    g_contextTask = task;
    HMENU menu = CreatePopupMenu();
    if (!menu)
        return;
    AppendMenuW(menu, MF_STRING, kTaskMinimizeId, L"Minimize");
    AppendMenuW(menu, MF_STRING, kTaskMaximizeId, L"Maximize / Restore");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, kTaskCloseId, L"Close");

    const UINT command = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON,
                                        screenPoint.x, screenPoint.y, 0, g_panel, nullptr);
    DestroyMenu(menu);

    if (!g_windowSystem)
        return;
    switch (command) {
    case kTaskMinimizeId:
        g_windowSystem->minimize(task);
        break;
    case kTaskMaximizeId:
        g_windowSystem->toggleMaximize(task);
        break;
    case kTaskCloseId:
        g_windowSystem->close(task);
        break;
    default:
        break;
    }
}

void show_launcher()
{
    HMENU menu = CreatePopupMenu();
    if (!menu)
        return;

    g_launcherEntries.clear();
    constexpr std::size_t maxEntries = 48;
    const auto& applications = g_applicationModel.applications();
    const std::size_t count = std::min(maxEntries, applications.size());
    for (std::size_t i = 0; i < count; ++i) {
        g_launcherEntries.push_back(&applications[i]);
        AppendMenuW(menu, MF_STRING, kApplicationBaseId + static_cast<UINT>(i), applications[i].name.c_str());
    }

    if (count > 0)
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, kCommandPromptId, L"Command Prompt");
    AppendMenuW(menu, MF_STRING, kPowerShellId, L"PowerShell");

    HMENU session = CreatePopupMenu();
    AppendMenuW(session, MF_STRING, kLockId, L"Lock");
    AppendMenuW(session, MF_STRING, kLogOutId, L"Log Out");
    AppendMenuW(session, MF_STRING, kRestartId, L"Restart");
    AppendMenuW(session, MF_STRING, kShutdownId, L"Shut Down");
    AppendMenuW(menu, MF_POPUP, reinterpret_cast<UINT_PTR>(session), L"Session");

    RECT button{};
    GetWindowRect(g_launcher, &button);
    const UINT command = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_BOTTOMALIGN,
                                        button.left, button.top, 0, g_panel, nullptr);
    DestroyMenu(menu);

    if (command >= kApplicationBaseId && command < kApplicationBaseId + g_launcherEntries.size()) {
        const auto index = static_cast<std::size_t>(command - kApplicationBaseId);
        if (g_applications && index < g_launcherEntries.size())
            g_applications->launch(*g_launcherEntries[index]);
        return;
    }

    switch (command) {
    case kCommandPromptId:
        launch(L"cmd.exe");
        break;
    case kPowerShellId:
        launch(L"powershell.exe");
        break;
    case kLockId:
        LockWorkStation();
        break;
    case kLogOutId:
        request_exit(EWX_LOGOFF);
        break;
    case kRestartId:
        request_exit(EWX_REBOOT);
        break;
    case kShutdownId:
        request_exit(EWX_POWEROFF);
        break;
    default:
        break;
    }
}

LRESULT CALLBACK desktop_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
{
    switch (message) {
    case WM_DISPLAYCHANGE:
        resize_shell();
        return 0;
    case WM_ERASEBKGND: {
        RECT rect{};
        GetClientRect(window, &rect);
        FillRect(reinterpret_cast<HDC>(wparam), &rect, g_desktopBrush);
        return 1;
    }
    case WM_CLOSE:
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    default:
        return DefWindowProcW(window, message, wparam, lparam);
    }
}

LRESULT CALLBACK panel_proc(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
{
    if (message == kAppBarMessage) {
        if (wparam == ABN_POSCHANGED)
            resize_shell();
        return 0;
    }

    switch (message) {
    case kWindowModelChanged:
        refresh_tasks();
        return 0;
    case WM_HOTKEY:
        if (wparam == kAltSpaceHotkey) {
            show_launcher();
            return 0;
        }
        break;
    case WM_COMMAND: {
        const int id = LOWORD(wparam);
        if (id == kLauncherId && HIWORD(wparam) == BN_CLICKED) {
            show_launcher();
            return 0;
        }
        if (id >= kTaskBaseId && id < kTaskBaseId + static_cast<int>(g_taskIds.size()) && HIWORD(wparam) == BN_CLICKED) {
            const std::size_t index = static_cast<std::size_t>(id - kTaskBaseId);
            if (index < g_taskIds.size() && g_windowSystem) {
                const auto task = g_windowModel.find(g_taskIds[index]);
                if (task && task->active)
                    g_windowSystem->minimize(task->id);
                else
                    g_windowSystem->activate(g_taskIds[index]);
            }
            return 0;
        }
        break;
    }
    case WM_CONTEXTMENU: {
        const HWND child = reinterpret_cast<HWND>(wparam);
        const auto it = std::find(g_taskButtons.begin(), g_taskButtons.end(), child);
        if (it != g_taskButtons.end()) {
            const std::size_t index = static_cast<std::size_t>(std::distance(g_taskButtons.begin(), it));
            if (index < g_taskIds.size()) {
                POINT point{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
                if (point.x == -1 && point.y == -1) {
                    RECT rect{};
                    GetWindowRect(child, &rect);
                    point = {rect.left, rect.top};
                }
                show_task_context_menu(g_taskIds[index], point);
                return 0;
            }
        }
        break;
    }
    case WM_TIMER:
        if (wparam == kClockTimer) {
            update_clock();
            return 0;
        }
        break;
    case WM_DISPLAYCHANGE:
        resize_shell();
        return 0;
    case WM_SIZE:
        layout_panel();
        return 0;
    case WM_ERASEBKGND: {
        RECT rect{};
        GetClientRect(window, &rect);
        FillRect(reinterpret_cast<HDC>(wparam), &rect, g_panelBrush);
        return 1;
    }
    case WM_CLOSE:
        return 0;
    case WM_DESTROY:
        unregister_appbar();
        return 0;
    default:
        break;
    }

    return DefWindowProcW(window, message, wparam, lparam);
}

bool register_classes(HINSTANCE instance)
{
    WNDCLASSEXW desktop{};
    desktop.cbSize = sizeof(desktop);
    desktop.hInstance = instance;
    desktop.lpfnWndProc = desktop_proc;
    desktop.lpszClassName = kDesktopClass;
    desktop.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    desktop.hbrBackground = g_desktopBrush;

    WNDCLASSEXW panel = desktop;
    panel.lpfnWndProc = panel_proc;
    panel.lpszClassName = kPanelClass;
    panel.hbrBackground = g_panelBrush;

    return RegisterClassExW(&desktop) != 0 && RegisterClassExW(&panel) != 0;
}

bool create_fallback_shell(HINSTANCE instance)
{
    g_desktopBrush = CreateSolidBrush(RGB(35, 38, 41));
    g_panelBrush = CreateSolidBrush(RGB(49, 54, 59));
    g_font = CreateFontW(-16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                         OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                         DEFAULT_PITCH | FF_DONTCARE, L"Noto Sans");

    if (!register_classes(instance))
        return false;

    g_desktop = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, kDesktopClass, L"KDE Plasma",
                                WS_POPUP | WS_VISIBLE, 0, 0, 1, 1, nullptr, nullptr, instance, nullptr);
    g_panel = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_TOPMOST, kPanelClass, L"Plasma Panel",
                              WS_POPUP | WS_VISIBLE, 0, 0, 1, kPanelHeight, nullptr, nullptr, instance, nullptr);
    if (!g_desktop || !g_panel)
        return false;

    g_launcher = CreateWindowExW(0, L"BUTTON", L"K", WS_CHILD | WS_VISIBLE | BS_FLAT,
                                 0, 0, 44, 34, g_panel, reinterpret_cast<HMENU>(kLauncherId), instance, nullptr);
    g_clock = CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE | SS_CENTER | SS_CENTERIMAGE,
                              0, 0, 84, 34, g_panel, nullptr, instance, nullptr);

    if (g_font) {
        SendMessageW(g_launcher, WM_SETFONT, reinterpret_cast<WPARAM>(g_font), TRUE);
        SendMessageW(g_clock, WM_SETFONT, reinterpret_cast<WPARAM>(g_font), TRUE);
    }

    g_windowSystem = std::make_unique<kde_windows::WindowsWindowSystem>();
    g_applications = std::make_unique<kde_windows::WindowsApplications>();
    refresh_applications();
    refresh_tasks();

    g_windowSystem->start([] {
        if (g_panel)
            PostMessageW(g_panel, kWindowModelChanged, 0, 0);
    });

    RegisterHotKey(g_panel, kAltSpaceHotkey, MOD_ALT | MOD_NOREPEAT, VK_SPACE);
    resize_shell();
    update_clock();
    SetTimer(g_panel, kClockTimer, 1000, nullptr);
    return true;
}

kde_windows::PlasmaRunResult run_real_plasma_if_available()
{
    const std::wstring plasma = kde_windows::plasma_executable(g_root);
    if (!std::filesystem::exists(plasma))
        return kde_windows::PlasmaRunResult::Unavailable;

    SetEnvironmentVariableW(L"XDG_CURRENT_DESKTOP", L"KDE");
    SetEnvironmentVariableW(L"KDE_FULL_SESSION", L"true");
    SetEnvironmentVariableW(L"KDE_SESSION_VERSION", L"6");
    SetEnvironmentVariableW(L"QT_QPA_PLATFORM", L"windows");
    SetEnvironmentVariableW(L"QT_QPA_PLATFORMTHEME", L"KDE");

    std::wstring command = kde_windows::shell_command(plasma);
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};

    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE, 0, nullptr,
                        std::filesystem::path(plasma).parent_path().c_str(), &startup, &process))
        return kde_windows::PlasmaRunResult::LaunchFailed;

    CloseHandle(process.hThread);
    const DWORD warmup = WaitForSingleObject(process.hProcess, 1500);
    if (warmup != WAIT_TIMEOUT) {
        CloseHandle(process.hProcess);
        return kde_windows::PlasmaRunResult::ExitedDuringWarmup;
    }

    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD exitCode = 1;
    if (!GetExitCodeProcess(process.hProcess, &exitCode))
        exitCode = 1;
    CloseHandle(process.hProcess);

    return exitCode == 0
        ? kde_windows::PlasmaRunResult::ExitedCleanlyAfterWarmup
        : kde_windows::PlasmaRunResult::CrashedAfterWarmup;
}

void launch_explorer_recovery()
{
    ShellExecuteW(nullptr, L"open", L"explorer.exe", nullptr, nullptr, SW_SHOWNORMAL);
}
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int)
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    g_root = executable_directory();

    const auto plasmaResult = run_real_plasma_if_available();
    if (!kde_windows::shouldStartRecoveryShell(plasmaResult)) {
        CoUninitialize();
        return 0;
    }

    if (!create_fallback_shell(instance)) {
        launch_explorer_recovery();
        CoUninitialize();
        return 1;
    }

    MSG message{};
    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }

    if (g_panel)
        UnregisterHotKey(g_panel, kAltSpaceHotkey);
    if (g_windowSystem)
        g_windowSystem->stop();
    unregister_appbar();
    destroy_task_buttons();

    if (g_font)
        DeleteObject(g_font);
    if (g_desktopBrush)
        DeleteObject(g_desktopBrush);
    if (g_panelBrush)
        DeleteObject(g_panelBrush);

    CoUninitialize();
    return static_cast<int>(message.wParam);
}
