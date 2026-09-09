#include "WindowsDisplaySystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
namespace
{
BOOL CALLBACK collectMonitor(HMONITOR monitor, HDC, LPRECT, LPARAM data)
{
    auto* displays = reinterpret_cast<std::vector<DisplaySnapshot>*>(data);
    if (!displays)
        return FALSE;

    MONITORINFOEXW info{};
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoW(monitor, &info))
        return TRUE;

    DisplaySnapshot display;
    display.id = info.szDevice;
    display.name = info.szDevice;
    display.x = info.rcMonitor.left;
    display.y = info.rcMonitor.top;
    display.width = info.rcMonitor.right - info.rcMonitor.left;
    display.height = info.rcMonitor.bottom - info.rcMonitor.top;
    display.workX = info.rcWork.left;
    display.workY = info.rcWork.top;
    display.workWidth = info.rcWork.right - info.rcWork.left;
    display.workHeight = info.rcWork.bottom - info.rcWork.top;
    display.primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
    displays->push_back(std::move(display));
    return TRUE;
}
}

std::vector<DisplaySnapshot> WindowsDisplaySystem::scan() const
{
    std::vector<DisplaySnapshot> displays;
    EnumDisplayMonitors(nullptr, nullptr, collectMonitor, reinterpret_cast<LPARAM>(&displays));
    return displays;
}
}
