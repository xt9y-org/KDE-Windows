#pragma once

namespace kde_windows
{
enum class PlasmaRunResult
{
    Unavailable,
    LaunchFailed,
    ExitedDuringWarmup,
    CrashedAfterWarmup,
    ExitedCleanlyAfterWarmup,
};

constexpr bool shouldStartRecoveryShell(PlasmaRunResult result)
{
    return result != PlasmaRunResult::ExitedCleanlyAfterWarmup;
}
}
