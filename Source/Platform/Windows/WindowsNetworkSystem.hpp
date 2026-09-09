#pragma once

#include "Core/SystemState.hpp"

namespace kde_windows
{
class WindowsNetworkSystem final
{
public:
    [[nodiscard]] NetworkState state() const;
};
}
