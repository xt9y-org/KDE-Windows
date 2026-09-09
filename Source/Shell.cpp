#include "ShellConfig.hpp"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>

#include <filesystem>
#include <iterator>
#include <string>

namespace
{
constexpr wchar_t kDesktopClass[] = L"KDEWindowsDesktop";
constexpr wchar_t kPanelClass[] = L"KDEWindowsPanel";
constexpr int kPanelHeight = 44;
constexpr UINT_PTR kClockTimer = 1;

constexpr int kLauncherId = 100;
constexpr int kDolphinId = 200;
constexpr int kKonsoleId = 201;
constexpr int kSystemSettingsId = 202;
constexpr int kCommandPromptId = 203;
constexpr int kPowerShellId = 204;
constexpr int kLogOutId = 205;

HWND g_desktop = nullptr;
HWND g_panel = nullptr;
HWND g_launcher = nullptr;
HWND g_clock = nullptr;
HFONT g_font = nullptr;
HBRUSH g_desktopBrush = nullptr;
HBRUSH g_panelBrush = nullptr;
std::wstring g_root;

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

std::wstring find_program(const wchar_t* name)
{
    const auto bundled = std::filesystem::path(g_root) / L"Plasma" / L"bin" / name;
    if (std::filesystem::exists(bundled))
        return bundled.wstring();

    wchar_t buffer[32768]{};
    if (SearchPathW(nullptr, name, nullptr, static_cast<DWORD>(std::size(buffer)), buffer, nullptr) > 0)
        return buffer;

    return {};
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

void resize_shell()
{
    if (!g_desktop || !g_panel)
        return;

    const int x = GetSystemMetrics(SM_XVIRTUALSCREEN);
    const int y = GetSystemMetrics(SM_YVIRTUALSCREEN);
    const int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    const int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);

    SetWindowPos(g_desktop, HWND_BOTTOM, x, y, width, height, SWP_NOACTIVATE | SWP_SHOWWINDOW);

    const int primaryWidth = GetSystemMetrics(SM_CXSCREEN);
    const int primaryHeight = GetSystemMetrics(SM_CYSCREEN);
    SetWindowPos(g_panel, HWND_TOPMOST, 0, primaryHeight - kPanelHeight, primaryWidth, kPanelHeight,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);

    if (g_launcher)
        SetWindowPos(g_launcher, nullptr, 6, 5, 44, 34, SWP_NOZORDER | SWP_NOACTIVATE);

    if (g_clock)
        SetWindowPos(g_clock, nullptr, primaryWidth - 94, 5, 84, 34, SWP_NOZORDER | SWP_NOACTIVATE);
}

void add_program_item(HMENU menu, int id, const wchar_t* label, const wchar_t* executable)
{
    if (!find_program(executable).empty())
        AppendMenuW(menu, MF_STRING, id, label);
}

void show_launcher()
{
    HMENU menu = CreatePopupMenu();
    if (!menu)
        return;

    add_program_item(menu, kDolphinId, L"Dolphin", L"dolphin.exe");
    add_program_item(menu, kKonsoleId, L"Konsole", L"konsole.exe");
    add_program_item(menu, kSystemSettingsId, L"System Settings", L"systemsettings.exe");

    if (GetMenuItemCount(menu) > 0)
        AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);

    AppendMenuW(menu, MF_STRING, kCommandPromptId, L"Command Prompt");
    AppendMenuW(menu, MF_STRING, kPowerShellId, L"PowerShell");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, kLogOutId, L"Log Out");

    RECT button{};
    GetWindowRect(g_launcher, &button);
    const UINT command = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_LEFTALIGN | TPM_BOTTOMALIGN,
                                        button.left, button.top, 0, g_panel, nullptr);
    DestroyMenu(menu);

    switch (command) {
    case kDolphinId:
        launch(find_program(L"dolphin.exe"));
        break;
    case kKonsoleId:
        launch(find_program(L"konsole.exe"));
        break;
    case kSystemSettingsId:
        launch(find_program(L"systemsettings.exe"));
        break;
    case kCommandPromptId:
        launch(L"cmd.exe");
        break;
    case kPowerShellId:
        launch(L"powershell.exe");
        break;
    case kLogOutId:
        ExitWindowsEx(EWX_LOGOFF, 0);
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
    switch (message) {
    case WM_COMMAND:
        if (LOWORD(wparam) == kLauncherId && HIWORD(wparam) == BN_CLICKED) {
            show_launcher();
            return 0;
        }
        break;
    case WM_TIMER:
        if (wparam == kClockTimer) {
            update_clock();
            return 0;
        }
        break;
    case WM_ERASEBKGND: {
        RECT rect{};
        GetClientRect(window, &rect);
        FillRect(reinterpret_cast<HDC>(wparam), &rect, g_panelBrush);
        return 1;
    }
    case WM_CLOSE:
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

    resize_shell();
    update_clock();
    SetTimer(g_panel, kClockTimer, 1000, nullptr);
    return true;
}

bool run_real_plasma_if_available()
{
    const std::wstring plasma = kde_windows::plasma_executable(g_root);
    if (!std::filesystem::exists(plasma))
        return false;

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
        return false;

    CloseHandle(process.hThread);

    const DWORD warmup = WaitForSingleObject(process.hProcess, 1500);
    if (warmup == WAIT_TIMEOUT) {
        WaitForSingleObject(process.hProcess, INFINITE);
        CloseHandle(process.hProcess);
        return true;
    }

    CloseHandle(process.hProcess);
    return false;
}

void launch_explorer_recovery()
{
    ShellExecuteW(nullptr, L"open", L"explorer.exe", nullptr, nullptr, SW_SHOWNORMAL);
}
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int)
{
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    g_root = executable_directory();

    if (run_real_plasma_if_available())
        return 0;

    if (!create_fallback_shell(instance)) {
        launch_explorer_recovery();
        return 1;
    }

    MSG message{};
    while (GetMessageW(&message, nullptr, 0, 0) > 0) {
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }

    if (g_font)
        DeleteObject(g_font);
    if (g_desktopBrush)
        DeleteObject(g_desktopBrush);
    if (g_panelBrush)
        DeleteObject(g_panelBrush);
    return static_cast<int>(message.wParam);
}
