#pragma once

#include "Core/DesktopModel.hpp"

#include <string>
#include <vector>

namespace kde_windows
{
class WindowsDesktopSystem final
{
public:
    [[nodiscard]] std::vector<DesktopEntry> scan() const;
    bool launch(const DesktopEntry& entry) const;
    bool openDesktop() const;
    bool createFolder() const;
    [[nodiscard]] std::wstring wallpaper() const;
    bool setWallpaper(const std::wstring& path) const;
};
}
