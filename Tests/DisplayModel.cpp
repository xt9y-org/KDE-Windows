#include "Core/DisplayModel.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    DisplayModel model;
    model.replace({
        {L"right", L"Right", 1920, 0, 1920, 1080, 1920, 0, 1920, 1080, false, true, 120},
        {L"bad", L"Bad", 0, 0, 0, 1080, 0, 0, 0, 1080, false},
        {L"primary", L"Primary", 0, 0, 1920, 1080, 0, 0, 1920, 1032, true, true, 65},
        {L"left", L"Left", -1280, 0, 1280, 1024, -1280, 0, 1280, 1024, false, false, 80},
    });

    const auto& displays = model.displays();
    assert(displays.size() == 3);
    assert(displays[0].id == L"primary");
    assert(displays[0].brightnessPercent == 65);
    assert(displays[1].id == L"left");
    assert(displays[1].brightnessPercent == -1);
    assert(displays[2].id == L"right");
    assert(displays[2].brightnessPercent == 100);
    assert(model.primary() != nullptr);
    assert(model.primary()->id == L"primary");
    assert(model.find(L"right") != nullptr);
    assert(model.find(L"missing") == nullptr);
    return 0;
}
