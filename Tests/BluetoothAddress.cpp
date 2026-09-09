#include "Core/BluetoothAddress.hpp"

#include <cassert>
#include <cstdint>

int main()
{
    using namespace kde_windows;

    std::uint64_t value = 0;
    assert(parseBluetoothAddress(L"01:23:45:67:89:AB", value));
    assert(value == 0x0123456789ABULL);
    assert(formatBluetoothAddress(value) == L"01:23:45:67:89:AB");

    std::uint64_t lower = 0;
    assert(parseBluetoothAddress(L"aa:bb:cc:dd:ee:ff", lower));
    assert(formatBluetoothAddress(lower) == L"AA:BB:CC:DD:EE:FF");

    assert(!parseBluetoothAddress(L"bad", value));
    assert(!parseBluetoothAddress(L"01:23:45:67:89", value));
    return 0;
}
