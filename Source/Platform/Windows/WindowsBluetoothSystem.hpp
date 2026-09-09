#pragma once

#include "Core/BluetoothState.hpp"

#include <string>

namespace kde_windows
{
class WindowsBluetoothSystem final
{
public:
    [[nodiscard]] BluetoothState state() const;
    [[nodiscard]] BluetoothState scan() const;
    [[nodiscard]] bool setDiscoverable(bool enabled) const;
    [[nodiscard]] bool pair(const std::wstring& deviceId) const;
    [[nodiscard]] bool remove(const std::wstring& deviceId) const;
};
}
