#include "PanelBridge.hpp"

#include <QCoreApplication>
#include <QWindow>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>

#include <algorithm>

namespace kde_windows
{
PanelBridge::PanelBridge(QObject* parent)
    : QObject(parent)
{
    callbackMessage_ = RegisterWindowMessageW(L"KDEWindowsAppBarMessage");
    if (QCoreApplication::instance())
        QCoreApplication::instance()->installNativeEventFilter(this);
}

PanelBridge::~PanelBridge()
{
    if (QCoreApplication::instance())
        QCoreApplication::instance()->removeNativeEventFilter(this);
    unregisterPanel();
}

void PanelBridge::registerPanel(QObject* object)
{
    QWindow* window = qobject_cast<QWindow*>(object);
    if (!window)
        return;

    if (window_ != window)
        unregisterPanel();
    window_ = window;

    const HWND hwnd = reinterpret_cast<HWND>(window_->winId());
    if (!hwnd)
        return;

    if (!registered_) {
        APPBARDATA data{};
        data.cbSize = sizeof(data);
        data.hWnd = hwnd;
        data.uCallbackMessage = callbackMessage_;
        registered_ = SHAppBarMessage(ABM_NEW, &data) != 0;
    }

    if (!registered_)
        return;

    connect(window_, &QWindow::xChanged, this, &PanelBridge::updatePosition, Qt::UniqueConnection);
    connect(window_, &QWindow::yChanged, this, &PanelBridge::updatePosition, Qt::UniqueConnection);
    connect(window_, &QWindow::widthChanged, this, &PanelBridge::updatePosition, Qt::UniqueConnection);
    connect(window_, &QWindow::heightChanged, this, &PanelBridge::updatePosition, Qt::UniqueConnection);
    updatePosition();
}

bool PanelBridge::nativeEventFilter(const QByteArray&, void* message, qintptr*)
{
    if (!message || !window_)
        return false;

    const auto* nativeMessage = static_cast<const MSG*>(message);
    const HWND panel = reinterpret_cast<HWND>(window_->winId());
    if (!panel || nativeMessage->hwnd != panel)
        return false;

    if (nativeMessage->message == callbackMessage_) {
        if (nativeMessage->wParam == ABN_POSCHANGED || nativeMessage->wParam == ABN_STATECHANGE)
            updatePosition();
    } else if (nativeMessage->message == WM_DISPLAYCHANGE || nativeMessage->message == WM_SETTINGCHANGE) {
        updatePosition();
    }
    return false;
}

void PanelBridge::updatePosition()
{
    if (!registered_ || !window_)
        return;

    const HWND hwnd = reinterpret_cast<HWND>(window_->winId());
    if (!hwnd)
        return;

    RECT windowRect{};
    GetWindowRect(hwnd, &windowRect);
    const LONG requestedHeight = std::max<LONG>(1, windowRect.bottom - windowRect.top);

    const HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoW(monitor, &info))
        return;

    APPBARDATA data{};
    data.cbSize = sizeof(data);
    data.hWnd = hwnd;
    data.uEdge = ABE_BOTTOM;
    data.rc = info.rcMonitor;
    data.rc.top = data.rc.bottom - requestedHeight;

    SHAppBarMessage(ABM_QUERYPOS, &data);
    data.rc.top = data.rc.bottom - requestedHeight;
    SHAppBarMessage(ABM_SETPOS, &data);

    SetWindowPos(hwnd,
                 HWND_TOPMOST,
                 data.rc.left,
                 data.rc.top,
                 data.rc.right - data.rc.left,
                 data.rc.bottom - data.rc.top,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
}

void PanelBridge::unregisterPanel()
{
    if (registered_ && window_) {
        APPBARDATA data{};
        data.cbSize = sizeof(data);
        data.hWnd = reinterpret_cast<HWND>(window_->winId());
        SHAppBarMessage(ABM_REMOVE, &data);
    }
    registered_ = false;
    window_ = nullptr;
}
}
