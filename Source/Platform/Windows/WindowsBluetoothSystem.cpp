#include "WindowsBluetoothSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <bluetoothapis.h>

#include <cwchar>
#include <string>

namespace kde_windows
{
namespace
{
std::wstring addressId(const BLUETOOTH_ADDRESS& address)
{
    wchar_t buffer[32]{};
    const auto value = address.ullLong;
    std::swprintf(buffer,
                  sizeof(buffer) / sizeof(buffer[0]),
                  L"%02X:%02X:%02X:%02X:%02X:%02X",
                  static_cast<unsigned>((value >> 40) & 0xff),
                  static_cast<unsigned>((value >> 32) & 0xff),
                  static_cast<unsigned>((value >> 24) & 0xff),
                  static_cast<unsigned>((value >> 16) & 0xff),
                  static_cast<unsigned>((value >> 8) & 0xff),
                  static_cast<unsigned>(value & 0xff));
    return buffer;
}

void collectDevices(HANDLE radio, BluetoothState& state)
{
    BLUETOOTH_DEVICE_SEARCH_PARAMS search{};
    search.dwSize = sizeof(search);
    search.fReturnAuthenticated = TRUE;
    search.fReturnRemembered = TRUE;
    search.fReturnUnknown = TRUE;
    search.fReturnConnected = TRUE;
    search.fIssueInquiry = FALSE;
    search.cTimeoutMultiplier = 0;
    search.hRadio = radio;

    BLUETOOTH_DEVICE_INFO info{};
    info.dwSize = sizeof(info);

    HBLUETOOTH_DEVICE_FIND find = BluetoothFindFirstDevice(&search, &info);
    if (!find)
        return;

    do {
        BluetoothDeviceSnapshot device;
        device.id = addressId(info.Address);
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
}

BluetoothState WindowsBluetoothSystem::state() const
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

        collectDevices(radio, result);
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
