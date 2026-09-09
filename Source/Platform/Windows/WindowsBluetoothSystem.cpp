#include "WindowsBluetoothSystem.hpp"
#include "Core/BluetoothAddress.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <bluetoothapis.h>

#include <string>

namespace kde_windows
{
namespace
{
void collectDevices(HANDLE radio, BluetoothState& state, bool inquiry)
{
    BLUETOOTH_DEVICE_SEARCH_PARAMS search{};
    search.dwSize = sizeof(search);
    search.fReturnAuthenticated = TRUE;
    search.fReturnRemembered = TRUE;
    search.fReturnUnknown = TRUE;
    search.fReturnConnected = TRUE;
    search.fIssueInquiry = inquiry ? TRUE : FALSE;
    search.cTimeoutMultiplier = inquiry ? 2 : 0;
    search.hRadio = radio;

    BLUETOOTH_DEVICE_INFO info{};
    info.dwSize = sizeof(info);

    HBLUETOOTH_DEVICE_FIND find = BluetoothFindFirstDevice(&search, &info);
    if (!find)
        return;

    do {
        BluetoothDeviceSnapshot device;
        device.id = formatBluetoothAddress(static_cast<std::uint64_t>(info.Address.ullLong));
        device.name = info.szName[0] ? info.szName : device.id;
        device.connected = info.fConnected != FALSE;
        device.paired = info.fAuthenticated != FALSE;
        device.remembered = info.fRemembered != FALSE;
        state.devices.push_back(std::move(device));
        info = {};
        info.dwSize = sizeof(info);
    } while (BluetoothFindNextDevice(find, &info));

    BluetoothFindDeviceClose(find);
}

BluetoothState readState(bool inquiry)
{
    BluetoothState result;

    BLUETOOTH_FIND_RADIO_PARAMS params{};
    params.dwSize = sizeof(params);
    HANDLE radio = nullptr;
    HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
    if (!find)
        return result;

    bool first = true;
    do {
        result.available = true;
        result.discoverable = result.discoverable || BluetoothIsDiscoverable(radio) != FALSE;

        BLUETOOTH_RADIO_INFO radioInfo{};
        radioInfo.dwSize = sizeof(radioInfo);
        if (first && BluetoothGetRadioInfo(radio, &radioInfo) == ERROR_SUCCESS)
            result.radioName = radioInfo.szName;

        collectDevices(radio, result, inquiry);
        CloseHandle(radio);
        radio = nullptr;
        first = false;
    } while (BluetoothFindNextRadio(find, &radio));

    if (radio)
        CloseHandle(radio);
    BluetoothFindRadioClose(find);
    normalizeBluetoothState(result);
    return result;
}
}

BluetoothState WindowsBluetoothSystem::state() const
{
    return readState(false);
}

BluetoothState WindowsBluetoothSystem::scan() const
{
    return readState(true);
}

bool WindowsBluetoothSystem::setDiscoverable(bool enabled) const
{
    BLUETOOTH_FIND_RADIO_PARAMS params{};
    params.dwSize = sizeof(params);
    HANDLE radio = nullptr;
    HBLUETOOTH_RADIO_FIND find = BluetoothFindFirstRadio(&params, &radio);
    if (!find)
        return false;

    bool changed = false;
    do {
        if (enabled)
            BluetoothEnableIncomingConnections(radio, TRUE);
        if (BluetoothEnableDiscovery(radio, enabled ? TRUE : FALSE))
            changed = true;
        CloseHandle(radio);
        radio = nullptr;
    } while (BluetoothFindNextRadio(find, &radio));

    if (radio)
        CloseHandle(radio);
    BluetoothFindRadioClose(find);
    return changed;
}
}
