#pragma once

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace kde_windows
{
struct TrayIconSnapshot
{
    std::wstring key;
    std::uintptr_t ownerWindow = 0;
    std::uint32_t id = 0;
    std::uint32_t callbackMessage = 0;
    std::uintptr_t iconHandle = 0;
    std::wstring tooltip;
    std::uint32_t version = 0;
    bool hidden = false;
};

struct TrayIconUpdate
{
    std::wstring key;
    std::optional<std::uint32_t> callbackMessage;
    std::optional<std::uintptr_t> iconHandle;
    std::optional<std::wstring> tooltip;
    std::optional<bool> hidden;
};

class TrayModel
{
public:
    bool add(const TrayIconSnapshot& icon)
    {
        if (icon.key.empty() || find(icon.key))
            return false;
        icons_.push_back(icon);
        return true;
    }

    bool modify(const TrayIconUpdate& update)
    {
        auto* icon = findMutable(update.key);
        if (!icon)
            return false;
        if (update.callbackMessage)
            icon->callbackMessage = *update.callbackMessage;
        if (update.iconHandle)
            icon->iconHandle = *update.iconHandle;
        if (update.tooltip)
            icon->tooltip = *update.tooltip;
        if (update.hidden)
            icon->hidden = *update.hidden;
        return true;
    }

    bool remove(const std::wstring& key)
    {
        const auto it = std::find_if(icons_.begin(), icons_.end(), [&](const auto& icon) { return icon.key == key; });
        if (it == icons_.end())
            return false;
        icons_.erase(it);
        return true;
    }

    bool setVersion(const std::wstring& key, std::uint32_t version)
    {
        auto* icon = findMutable(key);
        if (!icon)
            return false;
        icon->version = version;
        return true;
    }

    [[nodiscard]] const TrayIconSnapshot* find(const std::wstring& key) const
    {
        const auto it = std::find_if(icons_.begin(), icons_.end(), [&](const auto& icon) { return icon.key == key; });
        return it == icons_.end() ? nullptr : &*it;
    }

    [[nodiscard]] const std::vector<TrayIconSnapshot>& icons() const { return icons_; }

private:
    TrayIconSnapshot* findMutable(const std::wstring& key)
    {
        const auto it = std::find_if(icons_.begin(), icons_.end(), [&](const auto& icon) { return icon.key == key; });
        return it == icons_.end() ? nullptr : &*it;
    }

    std::vector<TrayIconSnapshot> icons_;
};
}
