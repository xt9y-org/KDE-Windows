#include "Core/SystemState.hpp"

#include <cassert>

int main()
{
    using kde_windows::clampSignalQuality;
    using kde_windows::normalizeBatteryPercent;

    assert(normalizeBatteryPercent(255) == -1);
    assert(normalizeBatteryPercent(-5) == -1);
    assert(normalizeBatteryPercent(0) == 0);
    assert(normalizeBatteryPercent(55) == 55);
    assert(normalizeBatteryPercent(150) == 100);

    assert(clampSignalQuality(-1) == 0);
    assert(clampSignalQuality(73) == 73);
    assert(clampSignalQuality(200) == 100);
    return 0;
}
