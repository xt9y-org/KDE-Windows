#include "Backend.hpp"

#include <QBuffer>
#include <QClipboard>
#include <QCoreApplication>
#include <QDate>
#include <QDateTime>
#include <QGuiApplication>
#include <QImage>
#include <QMetaObject>
#include <QTime>
#include <QUrl>
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
constexpr int kMaxNotificationHistory = 50;
constexpr int kNotificationTimeoutMs = 8000;
constexpr int kSystemStatusIntervalMs = 2000;
constexpr int kDesktopRefreshIntervalMs = 3000;
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

    shortcutSystem_.start([this](ShortcutAction action) {
        QMetaObject::invokeMethod(this,
                                  [this, action] {
                                      switch (action) {
                                      case ShortcutAction::Runner:
                                          emit runnerRequested();
                                          break;
                                      case ShortcutAction::Clipboard:
                                          emit clipboardRequested();
                                          break;
                                      case ShortcutAction::WindowNext:
                                          cycleWindowSwitcher(false);
                                          break;
                                      case ShortcutAction::WindowPrevious:
                                          cycleWindowSwitcher(true);
                                          break;
                                      case ShortcutAction::WindowCommit:
                                          commitWindowSwitcher();
                                          break;
                                      case ShortcutAction::Overview:
                                          if (windowSwitcherVisible_) {
                                              windowSwitcherVisible_ = false;
                                              windowSwitcherSelection_ = kNoWindowSelection;
                                              emit windowSwitcherChanged();
                                          }
                                          emit overviewRequested();
                                          break;
                                      case ShortcutAction::None:
                                          break;
                                      }
                                  },
                                  Qt::QueuedConnection);
    });

    reloadApplications();
    reloadDesktop();
    refreshWindows();
    refreshSystemStatus();

    windowSystem_.start([this] {
        QMetaObject::invokeMethod(this, [this] { refreshWindows(); }, Qt::QueuedConnection);
    });

    clockTimer_.setInterval(1000);
    connect(&clockTimer_, &QTimer::timeout, this, &Backend::clockChanged);
    clockTimer_.start();

    statusTimer_.setInterval(kSystemStatusIntervalMs);
    connect(&statusTimer_, &QTimer::timeout, this, &Backend::refreshSystemStatus);
    statusTimer_.start();

    desktopTimer_.setInterval(kDesktopRefreshIntervalMs);
    connect(&desktopTimer_, &QTimer::timeout, this, &Backend::reloadDesktop);
    desktopTimer_.start();

    if (QClipboard* clipboard = QGuiApplication::clipboard()) {
        connect(clipboard, &QClipboard::dataChanged, this, &Backend::captureClipboard);
        captureClipboard();
    }
}

Backend::~Backend()
{
    shortcutSystem_.stop();
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

QVariantList Backend::desktopItems() const
{
    QVariantList result;
    result.reserve(static_cast<qsizetype>(desktopModel_.entries().size()));
    for (const auto& entry : desktopModel_.entries())
        result.push_back(desktopMap(entry));
    return result;
}

QString Backend::wallpaperUrl() const
{
    if (wallpaperPath_.empty())
        return {};
    return QUrl::fromLocalFile(QString::fromStdWString(wallpaperPath_)).toString();
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

QStringList Backend::clipboardEntries() const
{
    QStringList result;
    result.reserve(static_cast<qsizetype>(clipboardModel_.entries().size()));
    for (const auto& text : clipboardModel_.entries())
        result.push_back(QString::fromStdWString(text));
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

int Backend::windowSwitcherIndex() const
{
    return windowSwitcherSelection_ == kNoWindowSelection
        ? -1
        : static_cast<int>(windowSwitcherSelection_);
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

bool Backend::runCommand(const QString& command)
{
    const QString trimmed = command.trimmed();
    if (trimmed.isEmpty())
        return false;

    std::wstring mutableCommand = trimmed.toStdWString();
    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process{};
    if (CreateProcessW(nullptr,
                       mutableCommand.data(),
                       nullptr,
                       nullptr,
                       FALSE,
                       0,
                       nullptr,
                       nullptr,
                       &startup,
                       &process)) {
        CloseHandle(process.hThread);
        CloseHandle(process.hProcess);
        return true;
    }

    const std::wstring target = trimmed.toStdWString();
    const HINSTANCE result = ShellExecuteW(nullptr, L"open", target.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    return reinterpret_cast<INT_PTR>(result) > 32;
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

void Backend::launchDesktopItem(const QString& id)
{
    const auto* entry = desktopModel_.find(id.toStdWString());
    if (entry)
        desktopSystem_.launch(*entry);
}

void Backend::reloadDesktop()
{
    DesktopModel nextModel;
    nextModel.replace(desktopSystem_.scan());
    const std::wstring nextWallpaper = desktopSystem_.wallpaper();

    if (nextModel.entries() == desktopModel_.entries() && nextWallpaper == wallpaperPath_)
        return;

    desktopModel_ = std::move(nextModel);
    wallpaperPath_ = nextWallpaper;
    emit desktopChanged();
}

bool Backend::setWallpaper(const QString& path)
{
    QString localPath = path;
    const QUrl url(path);
    if (url.isLocalFile())
        localPath = url.toLocalFile();
    if (!desktopSystem_.setWallpaper(localPath.toStdWString()))
        return false;
    reloadDesktop();
    return true;
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

void Backend::removeNotificationHistory(qulonglong id)
{
    bool historyChanged = false;
    for (qsizetype index = 0; index < notificationHistory_.size(); ++index) {
        const QVariantMap notification = notificationHistory_.at(index).toMap();
        if (notification.value(QStringLiteral("id")).toULongLong() == id) {
            notificationHistory_.removeAt(index);
            historyChanged = true;
            break;
        }
    }
    if (historyChanged)
        emit notificationHistoryChanged();

    for (qsizetype index = 0; index < notifications_.size(); ++index) {
        const QVariantMap notification = notifications_.at(index).toMap();
        if (notification.value(QStringLiteral("id")).toULongLong() == id) {
            notifications_.removeAt(index);
            emit notificationsChanged();
            break;
        }
    }
}

void Backend::clearNotificationHistory()
{
    if (notificationHistory_.isEmpty())
        return;
    notificationHistory_.clear();
    emit notificationHistoryChanged();
}

void Backend::activateClipboardEntry(int index)
{
    const auto& entries = clipboardModel_.entries();
    if (index < 0 || static_cast<std::size_t>(index) >= entries.size())
        return;
    if (QClipboard* clipboard = QGuiApplication::clipboard())
        clipboard->setText(QString::fromStdWString(entries[static_cast<std::size_t>(index)]));
}

void Backend::removeClipboardEntry(int index)
{
    if (index < 0)
        return;
    if (clipboardModel_.remove(static_cast<std::size_t>(index)))
        emit clipboardChanged();
}

void Backend::clearClipboardHistory()
{
    if (clipboardModel_.entries().empty())
        return;
    clipboardModel_.clear();
    emit clipboardChanged();
}

void Backend::setVolume(int volume)
{
    audioSystem_.setVolume(volume);
    refreshSystemStatus();
}

void Backend::toggleMute()
{
    audioSystem_.toggleMuted();
    refreshSystemStatus();
}

void Backend::suspend()
{
    powerSystem_.suspend();
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

    if (windowSwitcherVisible_ && windowSwitcherSelection_ >= windowModel_.windows().size()) {
        windowSwitcherVisible_ = false;
        windowSwitcherSelection_ = kNoWindowSelection;
        emit windowSwitcherChanged();
    }

    emit windowsChanged();
}

void Backend::refreshSystemStatus()
{
    const AudioState audio = audioSystem_.state();
    const PowerState power = powerSystem_.state();
    const NetworkState network = networkSystem_.state();

    const bool changed =
        audio.available != audioState_.available ||
        audio.volume != audioState_.volume ||
        audio.muted != audioState_.muted ||
        power.batteryAvailable != powerState_.batteryAvailable ||
        power.batteryPercent != powerState_.batteryPercent ||
        power.charging != powerState_.charging ||
        power.onAc != powerState_.onAc ||
        power.secondsRemaining != powerState_.secondsRemaining ||
        network.connected != networkState_.connected ||
        network.wifi != networkState_.wifi ||
        network.name != networkState_.name ||
        network.signalQuality != networkState_.signalQuality;

    audioState_ = audio;
    powerState_ = power;
    networkState_ = network;
    if (changed)
        emit systemStatusChanged();
}

void Backend::captureClipboard()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    if (!clipboard)
        return;
    const QString text = clipboard->text(QClipboard::Clipboard);
    if (clipboardModel_.push(text.toStdWString()))
        emit clipboardChanged();
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

    notificationHistory_.prepend(map);
    while (notificationHistory_.size() > kMaxNotificationHistory)
        notificationHistory_.removeLast();
    emit notificationHistoryChanged();

    QTimer::singleShot(kNotificationTimeoutMs, this, [this, id] { dismissNotification(id); });
}

void Backend::cycleWindowSwitcher(bool reverse)
{
    const auto& windows = windowModel_.windows();
    if (windows.empty()) {
        windowSwitcherVisible_ = false;
        windowSwitcherSelection_ = kNoWindowSelection;
        emit windowSwitcherChanged();
        return;
    }

    std::size_t current = windowSwitcherSelection_;
    if (!windowSwitcherVisible_) {
        current = kNoWindowSelection;
        for (std::size_t i = 0; i < windows.size(); ++i) {
            if (windows[i].active) {
                current = i;
                break;
            }
        }
    }

    windowSwitcherSelection_ = cycleWindowSelection(windows.size(), current, reverse);
    windowSwitcherVisible_ = windowSwitcherSelection_ != kNoWindowSelection;
    emit windowSwitcherChanged();
}

void Backend::commitWindowSwitcher()
{
    if (!windowSwitcherVisible_)
        return;

    WindowId selected = 0;
    const auto& windows = windowModel_.windows();
    if (windowSwitcherSelection_ < windows.size())
        selected = windows[windowSwitcherSelection_].id;

    windowSwitcherVisible_ = false;
    windowSwitcherSelection_ = kNoWindowSelection;
    emit windowSwitcherChanged();

    if (selected)
        windowSystem_.activate(selected);
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

QVariantMap Backend::desktopMap(const DesktopEntry& entry)
{
    QVariantMap map;
    map.insert(QStringLiteral("id"), QString::fromStdWString(entry.id));
    map.insert(QStringLiteral("name"), QString::fromStdWString(entry.name));
    map.insert(QStringLiteral("path"), QString::fromStdWString(entry.path));
    map.insert(QStringLiteral("directory"), entry.directory);
    map.insert(QStringLiteral("icon"), shellIconImage(entry.path));
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

QString Backend::shellIconImage(const std::wstring& path)
{
    SHFILEINFOW info{};
    if (!SHGetFileInfoW(path.c_str(), 0, &info, sizeof(info), SHGFI_ICON | SHGFI_LARGEICON) || !info.hIcon)
        return {};
    const QString image = trayIconImage(reinterpret_cast<std::uintptr_t>(info.hIcon));
    DestroyIcon(info.hIcon);
    return image;
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
