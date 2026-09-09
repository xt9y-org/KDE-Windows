#pragma once

#include <algorithm>
#include <cstddef>
#include <vector>

namespace kde_windows
{
struct Rect
{
    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
};

struct PanelLayout
{
    Rect launcher;
    Rect clock;
    std::vector<Rect> tasks;
};

inline PanelLayout panelLayout(int width, int height, std::size_t taskCount)
{
    PanelLayout layout;
    layout.launcher = {6, 5, 44, std::max(0, height - 10)};
    layout.clock = {std::max(0, width - 94), 5, 84, std::max(0, height - 10)};

    constexpr int taskStart = 58;
    constexpr int taskGap = 4;
    constexpr int maxTaskWidth = 180;
    constexpr int minimumTaskWidth = 36;
    const int taskEnd = layout.clock.x - 8;
    const int available = taskEnd - taskStart;

    if (taskCount == 0 || available < minimumTaskWidth)
        return layout;

    const int totalGap = taskGap * static_cast<int>(taskCount > 0 ? taskCount - 1 : 0);
    const int slot = (available - totalGap) / static_cast<int>(taskCount);
    const int taskWidth = std::min(maxTaskWidth, slot);
    if (taskWidth < minimumTaskWidth)
        return layout;

    layout.tasks.reserve(taskCount);
    int x = taskStart;
    for (std::size_t i = 0; i < taskCount; ++i) {
        layout.tasks.push_back({x, 5, taskWidth, std::max(0, height - 10)});
        x += taskWidth + taskGap;
    }
    return layout;
}
}
