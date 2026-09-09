#include "WindowsDisplaySystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <highlevelmonitorconfigurationapi.h>
#include <physicalmonitorenumerationapi.h>

#include <algorithm>
#include <cwchar>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
namespace
{
bool readBrightness(HMONITOR monitor, int& percent)
{
    DWORD count = 0;
    if (!GetNumberOfPhysicalMonitorsFromHMONITOR(monitor, &count) || count == 0)
        return false;

    std::vector<PHYSICAL_MONITOR> physical(count);
    if (!GetPhysicalMonitorsFromHMONITOR(monitor, count, physical.data()))
        return false;

    bool found = false;
    for (const auto& item : physical) {
        DWORD minimum = 0;
        DWORD current = 0;
        DWORD maximum = 0;
        DWORD capabilities = 0;
        DWORD colorTemperatures = 0;
        if (GetMonitorCapabilities(item.hPhysicalMonitor, &capabilities, &colorTemperatures) &&
            (capabilities & MC_CAPS_BRIGHTNESS) &&
            GetMonitorBrightness(item.hPhysicalMonitor, &minimum, &current, &maximum) &&
            maximum > minimum) {
            percent = static_cast<int>(((current - minimum) * 100ULL) / (maximum - minimum));
            percent = std::clamp(percent, 0, 100);
            found = true;
            break;
        }
    }

    DestroyPhysicalMonitors(count, physical.data());
    return found;
}

bool writeBrightness(HMONITOR monitor, int percent)
{
    DWORD count = 0;
    if (!GetNumberOfPhysicalMonitorsFromHMONITOR(monitor, &count) || count == 0)
        return false;

    std::vector<PHYSICAL_MONITOR> physical(count);
    if (!GetPhysicalMonitorsFromHMONITOR(monitor, count, physical.data()))
        return false;

    const DWORD clamped = static_cast<DWORD>(std::clamp(percent, 0, 100));
    bool changed = false;
    for (const auto& item : physical) {
        DWORD minimum = 0;
        DWORD current = 0;
        DWORD maximum = 0;
        DWORD capabilities = 0;
        DWORD colorTemperatures = 0;
        if (!GetMonitorCapabilities(item.hPhysicalMonitor, &capabilities, &colorTemperatures) ||
            !(capabilities & MC_CAPS_BRIGHTNESS) ||
            !GetMonitorBrightness(item.hPhysicalMonitor, &minimum, &current, &maximum) ||
            maximum <= minimum) {
            continue;
        }

        const DWORD target = minimum + static_cast<DWORD>(((maximum - minimum) * static_cast<unsigned long long>(clamped)) / 100ULL);
        if (SetMonitorBrightness(item.hPhysicalMonitor, target))
            changed = true;
    }

    DestroyPhysicalMonitors(count, physical.data());
    return changed;
}

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
    display.brightnessAvailable = readBrightness(monitor, display.brightnessPercent);
    displays->push_back(std::move(display));
    return TRUE;
}

struct BrightnessRequest
{
    std::wstring displayId;
    int percent = 0;
    bool changed = false;
};

BOOL CALLBACK setMonitorBrightness(HMONITOR monitor, HDC, LPRECT, LPARAM data)
{
    auto* request = reinterpret_cast<BrightnessRequest*>(data);
    if (!request)
        return FALSE;

    MONITORINFOEXW info{};
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoW(monitor, &info))
        return TRUE;

    if (_wcsicmp(info.szDevice, request->displayId.c_str()) != 0)
        return TRUE;

    request->changed = writeBrightness(monitor, request->percent);
    return FALSE;
}
}

std::vector<DisplaySnapshot> WindowsDisplaySystem::scan() const
{
    std::vector<DisplaySnapshot> displays;
    EnumDisplayMonitors(nullptr, nullptr, collectMonitor, reinterpret_cast<LPARAM>(&displays));
    return displays;
}

bool WindowsDisplaySystem::setBrightness(const std::wstring& displayId, int percent) const
{
    if (displayId.empty())
        return false;

    BrightnessRequest request{displayId, std::clamp(percent, 0, 100), false};
    EnumDisplayMonitors(nullptr, nullptr, setMonitorBrightness, reinterpret_cast<LPARAM>(&request));
    return request.changed;
}
}
