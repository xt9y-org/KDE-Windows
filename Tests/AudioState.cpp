#include "Core/AudioState.hpp"

#include <cassert>

int main()
{
    using kde_windows::clampVolume;
    assert(clampVolume(-50) == 0);
    assert(clampVolume(0) == 0);
    assert(clampVolume(42) == 42);
    assert(clampVolume(100) == 100);
    assert(clampVolume(500) == 100);
    return 0;
}
