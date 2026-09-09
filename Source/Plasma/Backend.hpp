#pragma once

#include "Core/ApplicationModel.hpp"
#include "Core/AudioState.hpp"
#include "Core/ClipboardModel.hpp"
#include "Core/DesktopModel.hpp"
#include "Core/SystemState.hpp"
#include "Core/WindowModel.hpp"
#include "Core/WindowSwitcher.hpp"
#include "Platform/Windows/WindowsApplications.hpp"
#include "Platform/Windows/WindowsAudioSystem.hpp"
#include "Platform/Windows/WindowsDesktopSystem.hpp"
#include "Platform/Windows/WindowsNetworkSystem.hpp"
#include "Platform/Windows/WindowsPowerSystem.hpp"
#include "Platform/Windows/WindowsShortcutSystem.hpp"
#include "Platform/Windows/WindowsTraySystem.hpp"
#include "Platform/Windows/WindowsWindowSystem.hpp"

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

class QWindow;

namespace kde_windows
{
class Backend final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QVariantList applications READ applications NOTIFY applicationsChanged)
    Q_PROPERTY(QVariantList desktopItems READ desktopItems NOTIFY desktopChanged)
    Q_PROPERTY(QString wallpaperUrl READ wallpaperUrl NOTIFY desktopChanged)
    Q_PROPERTY(QVariantList trayIcons READ trayIcons NOTIFY trayIconsChanged)
    Q_PROPERTY(QVariantList notifications READ notifications NOTIFY notificationsChanged)
    Q_PROPERTY(QStringList clipboardEntries READ clipboardEntries NOTIFY clipboardChanged)
    Q_PROPERTY(QString clockText READ clockText NOTIFY clockChanged)
    Q_PROPERTY(QString dateText READ dateText NOTIFY clockChanged)
    Q_PROPERTY(bool audioAvailable READ audioAvailable NOTIFY systemStatusChanged)
    Q_PROPERTY(int volume READ volume NOTIFY systemStatusChanged)
    Q_PROPERTY(bool muted READ muted NOTIFY systemStatusChanged)
    Q_PROPERTY(bool batteryAvailable READ batteryAvailable NOTIFY systemStatusChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY systemStatusChanged)
    Q_PROPERTY(bool charging READ charging NOTIFY systemStatusChanged)
    Q_PROPERTY(bool onAc READ onAc NOTIFY systemStatusChanged)
    Q_PROPERTY(bool networkConnected READ networkConnected NOTIFY systemStatusChanged)
    Q_PROPERTY(bool wifi READ wifi NOTIFY systemStatusChanged)
    Q_PROPERTY(QString networkName READ networkName NOTIFY systemStatusChanged)
    Q_PROPERTY(int networkSignal READ networkSignal NOTIFY systemStatusChanged)
    Q_PROPERTY(bool windowSwitcherVisible READ windowSwitcherVisible NOTIFY windowSwitcherChanged)
    Q_PROPERTY(int windowSwitcherIndex READ windowSwitcherIndex NOTIFY windowSwitcherChanged)

public:
    explicit Backend(QObject* parent = nullptr);
    ~Backend() override;

    [[nodiscard]] QVariantList windows() const;
    [[nodiscard]] QVariantList applications() const;
    [[nodiscard]] QVariantList desktopItems() const;
    [[nodiscard]] QString wallpaperUrl() const;
    [[nodiscard]] QVariantList trayIcons() const;
    [[nodiscard]] QVariantList notifications() const { return notifications_; }
    [[nodiscard]] QStringList clipboardEntries() const;
    [[nodiscard]] QString clockText() const;
    [[nodiscard]] QString dateText() const;
    [[nodiscard]] bool audioAvailable() const { return audioState_.available; }
    [[nodiscard]] int volume() const { return audioState_.volume; }
    [[nodiscard]] bool muted() const { return audioState_.muted; }
    [[nodiscard]] bool batteryAvailable() const { return powerState_.batteryAvailable; }
    [[nodiscard]] int batteryPercent() const { return powerState_.batteryPercent; }
    [[nodiscard]] bool charging() const { return powerState_.charging; }
    [[nodiscard]] bool onAc() const { return powerState_.onAc; }
    [[nodiscard]] bool networkConnected() const { return networkState_.connected; }
    [[nodiscard]] bool wifi() const { return networkState_.wifi; }
    [[nodiscard]] QString networkName() const { return QString::fromStdWString(networkState_.name); }
    [[nodiscard]] int networkSignal() const { return networkState_.signalQuality; }
    [[nodiscard]] bool windowSwitcherVisible() const { return windowSwitcherVisible_; }
    [[nodiscard]] int windowSwitcherIndex() const;

    Q_INVOKABLE QVariantList searchApplications(const QString& query) const;
    Q_INVOKABLE bool runCommand(const QString& command);
    Q_INVOKABLE void activateWindow(qulonglong id);
    Q_INVOKABLE void minimizeWindow(qulonglong id);
    Q_INVOKABLE void toggleMaximizeWindow(qulonglong id);
    Q_INVOKABLE void closeWindow(qulonglong id);
    Q_INVOKABLE void launchApplication(const QString& id);
    Q_INVOKABLE void reloadApplications();
    Q_INVOKABLE void launchDesktopItem(const QString& id);
    Q_INVOKABLE void reloadDesktop();
    Q_INVOKABLE bool setWallpaper(const QString& path);
    Q_INVOKABLE void invokeTrayIcon(const QString& key, bool contextMenu = false);
    Q_INVOKABLE void dismissNotification(qulonglong id);
    Q_INVOKABLE void activateClipboardEntry(int index);
    Q_INVOKABLE void removeClipboardEntry(int index);
    Q_INVOKABLE void clearClipboardHistory();
    Q_INVOKABLE void setVolume(int volume);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void registerDesktop(QObject* object);
    Q_INVOKABLE void registerPanel(QObject* object);
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void logOut();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void shutDown();

signals:
    void windowsChanged();
    void applicationsChanged();
    void desktopChanged();
    void trayIconsChanged();
    void notificationsChanged();
    void clipboardChanged();
    void systemStatusChanged();
    void clockChanged();
    void runnerRequested();
    void clipboardRequested();
    void overviewRequested();
    void windowSwitcherChanged();

private:
    void refreshWindows();
    void refreshSystemStatus();
    void captureClipboard();
    void addNotification(const TrayNotification& notification);
    void cycleWindowSwitcher(bool reverse);
    void commitWindowSwitcher();
    static QVariantMap windowMap(const WindowSnapshot& window);
    static QVariantMap applicationMap(const ApplicationEntry& application);
    static QVariantMap desktopMap(const DesktopEntry& entry);
    static QVariantMap trayIconMap(const TrayIconSnapshot& icon);
    static QString trayIconImage(std::uintptr_t iconHandle);
    static QString shellIconImage(const std::wstring& path);
    static bool enableShutdownPrivilege();
    static void exitWindows(unsigned flags);
    void reservePanel(QWindow* window);
    void restoreWorkArea();

    WindowModel windowModel_;
    ApplicationModel applicationModel_;
    DesktopModel desktopModel_;
    ClipboardModel clipboardModel_;
    WindowsWindowSystem windowSystem_;
    WindowsApplications applications_;
    WindowsDesktopSystem desktopSystem_;
    WindowsTraySystem traySystem_;
    WindowsAudioSystem audioSystem_;
    WindowsPowerSystem powerSystem_;
    WindowsNetworkSystem networkSystem_;
    WindowsShortcutSystem shortcutSystem_;
    AudioState audioState_;
    PowerState powerState_;
    NetworkState networkState_;
    QTimer clockTimer_;
    QTimer statusTimer_;
    QTimer desktopTimer_;
    QVariantList notifications_;
    std::wstring wallpaperPath_;
    qulonglong nextNotificationId_ = 1;
    std::size_t windowSwitcherSelection_ = kNoWindowSelection;
    bool windowSwitcherVisible_ = false;
    QWindow* desktop_ = nullptr;
    QWindow* panel_ = nullptr;
    RECT originalWorkArea_{};
    bool workAreaChanged_ = false;
};
}
