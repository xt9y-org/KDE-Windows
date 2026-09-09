#pragma once

#include "Core/BluetoothState.hpp"

namespace kde_windows
{
class WindowsBluetoothSystem final
{
public:
    [[nodiscard]] BluetoothState state() const;
    [[nodiscard]] bool setDiscoverable(bool enabled) const;
};
}
