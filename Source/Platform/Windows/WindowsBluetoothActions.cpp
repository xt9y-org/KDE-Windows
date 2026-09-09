#include "WindowsBluetoothSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <bluetoothapis.h>

#include <cwchar>

namespace kde_windows
{
namespace
{
bool parseAddress(const std::wstring& text, BLUETOOTH_ADDRESS& address)
{
    unsigned values[6]{};
    if (std::swscanf(text.c_str(),
                     L"%2x:%2x:%2x:%2x:%2x:%2x",
                     &values[0], &values[1], &values[2],
                     &values[3], &values[4], &values[5]) != 6) {
        return false;
    }

    ULONGLONG value = 0;
    for (const unsigned part : values) {
        if (part > 0xff)
            return false;
        value = (value << 8) | static_cast<ULONGLONG>(part);
    }
    address.ullLong = value;
    return true;
}
}

bool WindowsBluetoothSystem::pair(const std::wstring& deviceId) const
{
    BLUETOOTH_ADDRESS address{};
    if (!parseAddress(deviceId, address))
        return false;

    BLUETOOTH_DEVICE_INFO info{};
    info.dwSize = sizeof(info);
    info.Address = address;

    const DWORD result = BluetoothAuthenticateDeviceEx(nullptr,
                                                       nullptr,
                                                       &info,
                                                       nullptr,
                                                       MITMProtectionNotRequired);
    return result == ERROR_SUCCESS || result == ERROR_NO_MORE_ITEMS;
}

bool WindowsBluetoothSystem::remove(const std::wstring& deviceId) const
{
    BLUETOOTH_ADDRESS address{};
    if (!parseAddress(deviceId, address))
        return false;
    return BluetoothRemoveDevice(&address) == ERROR_SUCCESS;
}
}
