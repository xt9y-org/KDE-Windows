#pragma once

#include "Core/ApplicationModel.hpp"

#include <vector>

namespace kde_windows
{
class WindowsApplications
{
public:
    [[nodiscard]] std::vector<ApplicationEntry> scan() const;
    [[nodiscard]] bool launch(const ApplicationEntry& application) const;
};
}
