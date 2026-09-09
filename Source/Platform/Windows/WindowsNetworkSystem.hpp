#pragma once

#include "Core/NetworkModel.hpp"
#include "Core/SystemState.hpp"

#include <string>
#include <vector>

namespace kde_windows
{
class WindowsNetworkSystem final
{
public:
    [[nodiscard]] NetworkState state() const;
    [[nodiscard]] std::vector<WifiNetworkSnapshot> networks() const;
    [[nodiscard]] bool radioEnabled() const;
    [[nodiscard]] bool setRadioEnabled(bool enabled) const;
    [[nodiscard]] bool connectKnown(const std::wstring& networkId) const;
    [[nodiscard]] bool connectWithPassword(const std::wstring& networkId, const std::wstring& password) const;
    [[nodiscard]] bool disconnect() const;
};
}
