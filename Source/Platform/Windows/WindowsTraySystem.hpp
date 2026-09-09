#pragma once

#include "Core/TrayModel.hpp"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>

#include <functional>
#include <string>

namespace kde_windows
{
struct TrayNotification
{
    std::wstring title;
    std::wstring body;
    std::wstring source;
};

class WindowsTraySystem final
{
public:
    using ChangeCallback = std::function<void()>;
    using NotificationCallback = std::function<void(const TrayNotification&)>;

    WindowsTraySystem() = default;
    ~WindowsTraySystem();

    WindowsTraySystem(const WindowsTraySystem&) = delete;
    WindowsTraySystem& operator=(const WindowsTraySystem&) = delete;

    bool start(ChangeCallback changed, NotificationCallback notification);
    void stop();

    [[nodiscard]] const std::vector<TrayIconSnapshot>& icons() const { return model_.icons(); }
    [[nodiscard]] const TrayIconSnapshot* find(const std::wstring& key) const { return model_.find(key); }

    void invoke(const std::wstring& key, bool contextMenu);

private:
    static LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam);
    LRESULT handleCopyData(WPARAM wparam, LPARAM lparam);
    bool handleNotifyIcon(DWORD message, const NOTIFYICONDATAW& data);
    static std::wstring keyFor(const NOTIFYICONDATAW& data);
    static bool hasGuid(const GUID& guid);
    void replaceOwnedIcon(const std::wstring& key, HICON icon);
    void removeOwnedIcon(const std::wstring& key);
    void notifyChanged();
    void notifyBalloon(const NOTIFYICONDATAW& data);
    void broadcastTaskbarCreated() const;

    HWND window_ = nullptr;
    ATOM classAtom_ = 0;
    TrayModel model_;
    ChangeCallback changed_;
    NotificationCallback notification_;
};
}
