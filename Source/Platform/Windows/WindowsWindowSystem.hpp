#pragma once

#include "Core/WindowModel.hpp"

#include <functional>
#include <memory>
#include <vector>

namespace kde_windows
{
class WindowsWindowSystem
{
public:
    using ChangeCallback = std::function<void()>;

    WindowsWindowSystem();
    ~WindowsWindowSystem();

    WindowsWindowSystem(const WindowsWindowSystem&) = delete;
    WindowsWindowSystem& operator=(const WindowsWindowSystem&) = delete;

    [[nodiscard]] std::vector<WindowSnapshot> snapshot() const;
    [[nodiscard]] bool activate(WindowId id) const;
    [[nodiscard]] bool minimize(WindowId id) const;
    [[nodiscard]] bool toggleMaximize(WindowId id) const;
    [[nodiscard]] bool close(WindowId id) const;

    bool start(ChangeCallback callback);
    void stop();

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};
}
