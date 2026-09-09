#pragma once

#include <algorithm>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace kde_windows
{
using WindowId = std::uintptr_t;

struct WindowSnapshot
{
    WindowId id = 0;
    unsigned long processId = 0;
    std::wstring title;
    std::wstring executable;
    std::wstring appId;
    bool visible = false;
    bool minimized = false;
    bool maximized = false;
    bool active = false;
    bool toolWindow = false;
    bool cloaked = false;
};

class WindowModel
{
public:
    void replace(std::vector<WindowSnapshot> snapshots, unsigned long shellProcessId)
    {
        snapshots.erase(std::remove_if(snapshots.begin(), snapshots.end(), [shellProcessId](const WindowSnapshot& window) {
            return !shouldShow(window, shellProcessId);
        }), snapshots.end());

        std::unordered_map<WindowId, std::size_t> incomingIndex;
        incomingIndex.reserve(snapshots.size());
        for (std::size_t i = 0; i < snapshots.size(); ++i)
            incomingIndex.emplace(snapshots[i].id, i);

        std::vector<WindowSnapshot> next;
        next.reserve(snapshots.size());
        std::unordered_set<WindowId> consumed;
        consumed.reserve(snapshots.size());

        for (const auto& current : windows_) {
            const auto found = incomingIndex.find(current.id);
            if (found == incomingIndex.end())
                continue;
            next.push_back(std::move(snapshots[found->second]));
            consumed.insert(current.id);
        }

        for (auto& snapshot : snapshots) {
            if (!consumed.contains(snapshot.id))
                next.push_back(std::move(snapshot));
        }

        windows_ = std::move(next);
    }

    [[nodiscard]] const std::vector<WindowSnapshot>& windows() const noexcept
    {
        return windows_;
    }

    [[nodiscard]] const WindowSnapshot* find(WindowId id) const noexcept
    {
        const auto it = std::find_if(windows_.begin(), windows_.end(), [id](const WindowSnapshot& window) {
            return window.id == id;
        });
        return it == windows_.end() ? nullptr : &*it;
    }

    [[nodiscard]] const WindowSnapshot* active() const noexcept
    {
        const auto it = std::find_if(windows_.begin(), windows_.end(), [](const WindowSnapshot& window) {
            return window.active;
        });
        return it == windows_.end() ? nullptr : &*it;
    }

    [[nodiscard]] static bool shouldShow(const WindowSnapshot& window, unsigned long shellProcessId) noexcept
    {
        return window.id != 0 && window.processId != shellProcessId && window.visible && !window.toolWindow &&
               !window.cloaked && !window.title.empty();
    }

private:
    std::vector<WindowSnapshot> windows_;
};
}
