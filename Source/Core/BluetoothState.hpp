#pragma once

#include <algorithm>
#include <cwctype>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
struct BluetoothDeviceSnapshot
{
    std::wstring id;
    std::wstring name;
    bool connected = false;
    bool paired = false;
    bool remembered = false;

    bool operator==(const BluetoothDeviceSnapshot&) const = default;
};

struct BluetoothState
{
    bool available = false;
    bool discoverable = false;
    std::wstring radioName;
    std::vector<BluetoothDeviceSnapshot> devices;

    bool operator==(const BluetoothState&) const = default;
};

inline std::wstring bluetoothLower(std::wstring value)
{
    std::transform(value.begin(), value.end(), value.begin(), [](wchar_t c) {
        return static_cast<wchar_t>(std::towlower(c));
    });
    return value;
}

inline void normalizeBluetoothState(BluetoothState& state)
{
    std::stable_sort(state.devices.begin(), state.devices.end(), [](const BluetoothDeviceSnapshot& a, const BluetoothDeviceSnapshot& b) {
        if (a.connected != b.connected)
            return a.connected > b.connected;
        if (a.paired != b.paired)
            return a.paired > b.paired;
        return bluetoothLower(a.name) < bluetoothLower(b.name);
    });

    state.devices.erase(std::unique(state.devices.begin(), state.devices.end(), [](const BluetoothDeviceSnapshot& a, const BluetoothDeviceSnapshot& b) {
        return a.id == b.id;
    }), state.devices.end());
}
}
