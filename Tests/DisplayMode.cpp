#include "Core/DisplayMode.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    std::vector<DisplayModeSnapshot> modes{
        {1920, 1080, 60, 32},
        {2560, 1440, 144, 32},
        {1920, 1080, 144, 32},
        {1920, 1080, 144, 24},
        {0, 1080, 60, 32},
    };
    normalizeDisplayModes(modes);

    assert(modes.size() == 3);
    assert(modes[0].width == 2560);
    assert(modes[1].refreshRate == 144);
    assert(modes[2].refreshRate == 60);
    return 0;
}
