#include "Core/ShellPolicy.hpp"

#include <cassert>

int main()
{
    using kde_windows::PlasmaRunResult;
    using kde_windows::shouldStartRecoveryShell;

    assert(shouldStartRecoveryShell(PlasmaRunResult::Unavailable));
    assert(shouldStartRecoveryShell(PlasmaRunResult::LaunchFailed));
    assert(shouldStartRecoveryShell(PlasmaRunResult::ExitedDuringWarmup));
    assert(shouldStartRecoveryShell(PlasmaRunResult::ExitedAfterWarmup));
    return 0;
}
