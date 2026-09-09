#include "Core/DisplayModel.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    DisplayModel model;
    model.replace({
        {L"right", L"Right", 1920, 0, 1920, 1080, 1920, 0, 1920, 1080, false},
        {L"bad", L"Bad", 0, 0, 0, 1080, 0, 0, 0, 1080, false},
        {L"primary", L"Primary", 0, 0, 1920, 1080, 0, 0, 1920, 1032, true},
        {L"left", L"Left", -1280, 0, 1280, 1024, -1280, 0, 1280, 1024, false},
    });

    const auto& displays = model.displays();
    assert(displays.size() == 3);
    assert(displays[0].id == L"primary");
    assert(displays[1].id == L"left");
    assert(displays[2].id == L"right");
    assert(model.primary() != nullptr);
    assert(model.primary()->id == L"primary");
    return 0;
}
