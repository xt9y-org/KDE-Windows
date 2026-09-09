#pragma once

namespace kde_windows
{
enum class PlasmaRunResult
{
    Unavailable,
    LaunchFailed,
    ExitedDuringWarmup,
    ExitedAfterWarmup,
};

constexpr bool shouldStartRecoveryShell(PlasmaRunResult result)
{
    switch (result) {
    case PlasmaRunResult::Unavailable:
    case PlasmaRunResult::LaunchFailed:
    case PlasmaRunResult::ExitedDuringWarmup:
    case PlasmaRunResult::ExitedAfterWarmup:
        return true;
    }
    return true;
}
}
