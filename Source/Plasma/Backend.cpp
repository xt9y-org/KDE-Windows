#include "Backend.hpp"

#include <QCoreApplication>
#include <QDate>
#include <QMetaObject>
#include <QTime>
#include <QWindow>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <dwmapi.h>
#include <shellapi.h>

namespace kde_windows
{
namespace
{
constexpr UINT kAppBarMessage = WM_APP + 0x70;
constexpr int kDwmWindowCornerPreference = 33;
constexpr int kDwmSystemBackdropType = 38;
constexpr DWORD kRoundCorners = 2;
constexpr DWORD kTransientBackdrop = 3;
}

Backend::Backend(QObject* parent)
    : QObject(parent)
{
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
    windowSystem_.stop();
    if (appBarRegistered_ && panel_) {
        APPBARDATA data{};
        data.cbSize = sizeof(data);
        data.hWnd = reinterpret_cast<HWND>(panel_->winId());
        SHAppBarMessage(ABM_REMOVE, &data);
    }
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
    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    APPBARDATA data{};
    data.cbSize = sizeof(data);
    data.hWnd = hwnd;
    data.uCallbackMessage = kAppBarMessage;

    if (!appBarRegistered_)
        appBarRegistered_ = SHAppBarMessage(ABM_NEW, &data) != 0;

    data.uEdge = ABE_BOTTOM;
    data.rc.left = window->x();
    data.rc.top = window->y();
    data.rc.right = window->x() + window->width();
    data.rc.bottom = window->y() + window->height();
    SHAppBarMessage(ABM_QUERYPOS, &data);
    data.rc.top = data.rc.bottom - window->height();
    SHAppBarMessage(ABM_SETPOS, &data);

    window->setPosition(data.rc.left, data.rc.top);
    window->resize(data.rc.right - data.rc.left, data.rc.bottom - data.rc.top);
}
}
