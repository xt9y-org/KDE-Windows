#include "Backend.hpp"

#include <QBuffer>
#include <QCoreApplication>
#include <QDate>
#include <QDateTime>
#include <QImage>
#include <QMetaObject>
#include <QTime>
#include <QWindow>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <dwmapi.h>
#include <shellapi.h>

#include <algorithm>
#include <cstring>

namespace kde_windows
{
namespace
{
constexpr int kDwmWindowCornerPreference = 33;
constexpr int kDwmSystemBackdropType = 38;
constexpr DWORD kRoundCorners = 2;
constexpr DWORD kTransientBackdrop = 3;
constexpr int kTrayIconSize = 32;
constexpr int kMaxNotifications = 6;
constexpr int kNotificationTimeoutMs = 8000;
}

Backend::Backend(QObject* parent)
    : QObject(parent)
{
    traySystem_.start(
        [this] {
            QMetaObject::invokeMethod(this, [this] { emit trayIconsChanged(); }, Qt::QueuedConnection);
        },
        [this](const TrayNotification& notification) {
            QMetaObject::invokeMethod(this,
                                      [this, notification] { addNotification(notification); },
                                      Qt::QueuedConnection);
        });

    reloadApplications();
    refreshWindows();

    windowSystem_.start([this] {
        QMetaObject::invokeMethod(this, [this] { refreshWindows(); }, Qt::QueuedConnection);
    });

    clockTimer_.setInterval(1000);
    connect(&clockTimer_, &QTimer::timeout, this, &Backend::clockChanged);
    clockTimer_.start();
}

Backend::~Backend()
{
    traySystem_.stop();
    windowSystem_.stop();
    restoreWorkArea();
}

QVariantList Backend::windows() const
{
    QVariantList result;
    result.reserve(static_cast<qsizetype>(windowModel_.windows().size()));
    for (const auto& window : windowModel_.windows())
        result.push_back(windowMap(window));
    return result;
}

QVariantList Backend::applications() const
{
    QVariantList result;
    result.reserve(static_cast<qsizetype>(applicationModel_.applications().size()));
    for (const auto& application : applicationModel_.applications())
        result.push_back(applicationMap(application));
    return result;
}

QVariantList Backend::trayIcons() const
{
    QVariantList result;
    for (const auto& icon : traySystem_.icons()) {
        if (!icon.hidden)
            result.push_back(trayIconMap(icon));
    }
    return result;
}

QString Backend::clockText() const
{
    return QTime::currentTime().toString(QStringLiteral("HH:mm"));
}

QString Backend::dateText() const
{
    return QDate::currentDate().toString(QStringLiteral("ddd, d MMM"));
}

QVariantList Backend::searchApplications(const QString& query) const
{
    QVariantList result;
    const auto matches = applicationModel_.search(query.toStdWString());
    result.reserve(static_cast<qsizetype>(matches.size()));
    for (const auto* application : matches)
        result.push_back(applicationMap(*application));
    return result;
}

void Backend::activateWindow(qulonglong id)
{
    windowSystem_.activate(static_cast<WindowId>(id));
}

void Backend::minimizeWindow(qulonglong id)
{
    windowSystem_.minimize(static_cast<WindowId>(id));
}

void Backend::toggleMaximizeWindow(qulonglong id)
{
    windowSystem_.toggleMaximize(static_cast<WindowId>(id));
}

void Backend::closeWindow(qulonglong id)
{
    windowSystem_.close(static_cast<WindowId>(id));
}

void Backend::launchApplication(const QString& id)
{
    const auto* application = applicationModel_.find(id.toStdWString());
    if (application)
        applications_.launch(*application);
}

void Backend::reloadApplications()
{
    applicationModel_.replace(applications_.scan());
    emit applicationsChanged();
}

void Backend::invokeTrayIcon(const QString& key, bool contextMenu)
{
    traySystem_.invoke(key.toStdWString(), contextMenu);
}

void Backend::dismissNotification(qulonglong id)
{
    for (qsizetype index = 0; index < notifications_.size(); ++index) {
        const QVariantMap notification = notifications_.at(index).toMap();
        if (notification.value(QStringLiteral("id")).toULongLong() == id) {
            notifications_.removeAt(index);
            emit notificationsChanged();
            return;
        }
    }
}

void Backend::registerDesktop(QObject* object)
{
    desktop_ = qobject_cast<QWindow*>(object);
    if (!desktop_)
        return;

    const HWND hwnd = reinterpret_cast<HWND>(desktop_->winId());
    SetWindowPos(hwnd, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
}

void Backend::registerPanel(QObject* object)
{
    panel_ = qobject_cast<QWindow*>(object);
    if (!panel_)
        return;

    reservePanel(panel_);

    const HWND hwnd = reinterpret_cast<HWND>(panel_->winId());
    DwmSetWindowAttribute(hwnd, kDwmWindowCornerPreference, &kRoundCorners, sizeof(kRoundCorners));
    DwmSetWindowAttribute(hwnd, kDwmSystemBackdropType, &kTransientBackdrop, sizeof(kTransientBackdrop));
}

void Backend::lockSession()
{
    LockWorkStation();
}

void Backend::logOut()
{
    exitWindows(EWX_LOGOFF);
}

void Backend::restart()
{
    exitWindows(EWX_REBOOT);
}

void Backend::shutDown()
{
    exitWindows(EWX_POWEROFF);
}

void Backend::refreshWindows()
{
    windowModel_.replace(windowSystem_.snapshot(), GetCurrentProcessId());
    emit windowsChanged();
}

void Backend::addNotification(const TrayNotification& notification)
{
    const qulonglong id = nextNotificationId_++;

    QVariantMap map;
    map.insert(QStringLiteral("id"), QVariant::fromValue<qulonglong>(id));
    map.insert(QStringLiteral("title"), QString::fromStdWString(notification.title));
    map.insert(QStringLiteral("body"), QString::fromStdWString(notification.body));
    map.insert(QStringLiteral("source"), QString::fromStdWString(notification.source));
    map.insert(QStringLiteral("timestamp"), QDateTime::currentDateTime().toString(QStringLiteral("HH:mm")));

    notifications_.prepend(map);
    while (notifications_.size() > kMaxNotifications)
        notifications_.removeLast();
    emit notificationsChanged();

    QTimer::singleShot(kNotificationTimeoutMs, this, [this, id] { dismissNotification(id); });
}

QVariantMap Backend::windowMap(const WindowSnapshot& window)
{
    QVariantMap map;
    map.insert(QStringLiteral("id"), QVariant::fromValue<qulonglong>(window.id));
    map.insert(QStringLiteral("title"), QString::fromStdWString(window.title));
    map.insert(QStringLiteral("executable"), QString::fromStdWString(window.executable));
    map.insert(QStringLiteral("appId"), QString::fromStdWString(window.appId));
    map.insert(QStringLiteral("active"), window.active);
    map.insert(QStringLiteral("minimized"), window.minimized);
    map.insert(QStringLiteral("maximized"), window.maximized);
    return map;
}

QVariantMap Backend::applicationMap(const ApplicationEntry& application)
{
    QVariantMap map;
    map.insert(QStringLiteral("id"), QString::fromStdWString(application.id));
    map.insert(QStringLiteral("name"), QString::fromStdWString(application.name));
    map.insert(QStringLiteral("executable"), QString::fromStdWString(application.executable));
    map.insert(QStringLiteral("iconPath"), QString::fromStdWString(application.iconPath));
    map.insert(QStringLiteral("packaged"), application.packaged);
    return map;
}

QVariantMap Backend::trayIconMap(const TrayIconSnapshot& icon)
{
    QVariantMap map;
    map.insert(QStringLiteral("key"), QString::fromStdWString(icon.key));
    map.insert(QStringLiteral("tooltip"), QString::fromStdWString(icon.tooltip));
    map.insert(QStringLiteral("icon"), trayIconImage(icon.iconHandle));
    map.insert(QStringLiteral("id"), icon.id);
    return map;
}

QString Backend::trayIconImage(std::uintptr_t iconHandle)
{
    if (!iconHandle)
        return {};

    const HICON icon = reinterpret_cast<HICON>(iconHandle);
    HDC screen = GetDC(nullptr);
    if (!screen)
        return {};

    BITMAPINFO bitmapInfo{};
    bitmapInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bitmapInfo.bmiHeader.biWidth = kTrayIconSize;
    bitmapInfo.bmiHeader.biHeight = -kTrayIconSize;
    bitmapInfo.bmiHeader.biPlanes = 1;
    bitmapInfo.bmiHeader.biBitCount = 32;
    bitmapInfo.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    HBITMAP bitmap = CreateDIBSection(screen, &bitmapInfo, DIB_RGB_COLORS, &bits, nullptr, 0);
    HDC memory = bitmap ? CreateCompatibleDC(screen) : nullptr;
    if (!bitmap || !memory || !bits) {
        if (memory)
            DeleteDC(memory);
        if (bitmap)
            DeleteObject(bitmap);
        ReleaseDC(nullptr, screen);
        return {};
    }

    std::memset(bits, 0, kTrayIconSize * kTrayIconSize * 4);
    const HGDIOBJ previous = SelectObject(memory, bitmap);
    DrawIconEx(memory, 0, 0, icon, kTrayIconSize, kTrayIconSize, 0, nullptr, DI_NORMAL);

    const QImage view(static_cast<const uchar*>(bits),
                      kTrayIconSize,
                      kTrayIconSize,
                      kTrayIconSize * 4,
                      QImage::Format_ARGB32_Premultiplied);
    const QImage image = view.copy();

    SelectObject(memory, previous);
    DeleteDC(memory);
    DeleteObject(bitmap);
    ReleaseDC(nullptr, screen);

    QByteArray bytes;
    QBuffer buffer(&bytes);
    if (!buffer.open(QIODevice::WriteOnly) || !image.save(&buffer, "PNG"))
        return {};

    return QStringLiteral("data:image/png;base64,") + QString::fromLatin1(bytes.toBase64());
}

bool Backend::enableShutdownPrivilege()
{
    HANDLE token = nullptr;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &token))
        return false;

    LUID luid{};
    if (!LookupPrivilegeValueW(nullptr, SE_SHUTDOWN_NAME, &luid)) {
        CloseHandle(token);
        return false;
    }

    TOKEN_PRIVILEGES privileges{};
    privileges.PrivilegeCount = 1;
    privileges.Privileges[0].Luid = luid;
    privileges.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    SetLastError(ERROR_SUCCESS);
    AdjustTokenPrivileges(token, FALSE, &privileges, 0, nullptr, nullptr);
    const bool ok = GetLastError() == ERROR_SUCCESS;
    CloseHandle(token);
    return ok;
}

void Backend::exitWindows(unsigned flags)
{
    if ((flags & (EWX_REBOOT | EWX_POWEROFF | EWX_SHUTDOWN)) != 0 && !enableShutdownPrivilege())
        return;
    ExitWindowsEx(flags, SHTDN_REASON_MAJOR_OTHER | SHTDN_REASON_MINOR_OTHER);
}

void Backend::reservePanel(QWindow* window)
{
    if (!window)
        return;

    if (!workAreaChanged_) {
        if (!SystemParametersInfoW(SPI_GETWORKAREA, 0, &originalWorkArea_, 0))
            return;
        workAreaChanged_ = true;
    }

    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    const HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoW(monitor, &info) || !(info.dwFlags & MONITORINFOF_PRIMARY))
        return;

    RECT work = info.rcMonitor;
    work.bottom = std::max(work.top, info.rcMonitor.bottom - window->height());
    SystemParametersInfoW(SPI_SETWORKAREA, 0, &work, SPIF_SENDCHANGE);
}

void Backend::restoreWorkArea()
{
    if (!workAreaChanged_)
        return;
    SystemParametersInfoW(SPI_SETWORKAREA, 0, &originalWorkArea_, SPIF_SENDCHANGE);
    workAreaChanged_ = false;
}
}
