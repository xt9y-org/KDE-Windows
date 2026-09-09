#include "Core/BluetoothState.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    BluetoothState state;
    state.available = true;
    state.devices = {
        {L"3", L"Keyboard", false, true, true},
        {L"1", L"Headphones", true, true, true},
        {L"2", L"Mouse", false, true, true},
        {L"1", L"Duplicate", false, false, false},
    };

    normalizeBluetoothState(state);
    assert(state.devices.size() == 3);
    assert(state.devices[0].id == L"1");
    assert(state.devices[0].connected);
    assert(state.devices[1].name == L"Keyboard");
    assert(state.devices[2].name == L"Mouse");
    return 0;
}
