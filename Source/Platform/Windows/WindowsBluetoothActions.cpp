#include "WindowsBluetoothSystem.hpp"
#include "Core/BluetoothAddress.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <bluetoothapis.h>

namespace kde_windows
{
namespace
{
bool addressFromText(const std::wstring& text, BLUETOOTH_ADDRESS& address)
{
    std::uint64_t value = 0;
    if (!parseBluetoothAddress(text, value))
        return false;
    address.ullLong = static_cast<ULONGLONG>(value);
    return true;
}
}

bool WindowsBluetoothSystem::pair(const std::wstring& deviceId) const
{
    BLUETOOTH_ADDRESS address{};
    if (!addressFromText(deviceId, address))
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
    if (!addressFromText(deviceId, address))
        return false;
    return BluetoothRemoveDevice(&address) == ERROR_SUCCESS;
}
}
