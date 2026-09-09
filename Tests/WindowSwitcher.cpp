#include "Core/WindowSwitcher.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;
    assert(cycleWindowSelection(0, 0, false) == kNoWindowSelection);
    assert(cycleWindowSelection(1, 0, false) == 0);
    assert(cycleWindowSelection(3, 0, false) == 1);
    assert(cycleWindowSelection(3, 2, false) == 0);
    assert(cycleWindowSelection(3, 0, true) == 2);
    assert(cycleWindowSelection(3, 2, true) == 1);
    assert(cycleWindowSelection(3, 99, false) == 0);
    assert(cycleWindowSelection(3, 99, true) == 2);
    return 0;
}
