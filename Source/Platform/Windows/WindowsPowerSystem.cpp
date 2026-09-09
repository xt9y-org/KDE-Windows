#include "WindowsPowerSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <powrprof.h>

namespace kde_windows
{
PowerState WindowsPowerSystem::state() const
{
    PowerState result;
    SYSTEM_POWER_STATUS status{};
    if (!GetSystemPowerStatus(&status))
        return result;

    const bool batteryUnknown = status.BatteryFlag == 255;
    const bool noBattery = !batteryUnknown && (status.BatteryFlag & 128) != 0;
    result.batteryAvailable = !batteryUnknown && !noBattery;
    result.batteryPercent = result.batteryAvailable
        ? normalizeBatteryPercent(static_cast<int>(status.BatteryLifePercent))
        : -1;
    result.charging = result.batteryAvailable && (status.BatteryFlag & 8) != 0;
    result.onAc = status.ACLineStatus == 1;
    result.secondsRemaining = status.BatteryLifeTime == static_cast<DWORD>(-1)
        ? -1
        : static_cast<int>(status.BatteryLifeTime);
    return result;
}

bool WindowsPowerSystem::suspend() const
{
    return SetSuspendState(FALSE, FALSE, FALSE) != FALSE;
}
}
