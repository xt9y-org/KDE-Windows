#pragma once

#include "Core/ApplicationModel.hpp"
#include "Core/WindowModel.hpp"
#include "Platform/Windows/WindowsApplications.hpp"
#include "Platform/Windows/WindowsTraySystem.hpp"
#include "Platform/Windows/WindowsWindowSystem.hpp"

#include <QObject>
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
    Q_PROPERTY(QVariantList trayIcons READ trayIcons NOTIFY trayIconsChanged)
    Q_PROPERTY(QVariantList notifications READ notifications NOTIFY notificationsChanged)
    Q_PROPERTY(QString clockText READ clockText NOTIFY clockChanged)
    Q_PROPERTY(QString dateText READ dateText NOTIFY clockChanged)

public:
    explicit Backend(QObject* parent = nullptr);
    ~Backend() override;

    [[nodiscard]] QVariantList windows() const;
    [[nodiscard]] QVariantList applications() const;
    [[nodiscard]] QVariantList trayIcons() const;
    [[nodiscard]] QVariantList notifications() const { return notifications_; }
    [[nodiscard]] QString clockText() const;
    [[nodiscard]] QString dateText() const;

    Q_INVOKABLE QVariantList searchApplications(const QString& query) const;
    Q_INVOKABLE void activateWindow(qulonglong id);
    Q_INVOKABLE void minimizeWindow(qulonglong id);
    Q_INVOKABLE void toggleMaximizeWindow(qulonglong id);
    Q_INVOKABLE void closeWindow(qulonglong id);
    Q_INVOKABLE void launchApplication(const QString& id);
    Q_INVOKABLE void reloadApplications();
    Q_INVOKABLE void invokeTrayIcon(const QString& key, bool contextMenu = false);
    Q_INVOKABLE void dismissNotification(qulonglong id);
    Q_INVOKABLE void registerDesktop(QObject* object);
    Q_INVOKABLE void registerPanel(QObject* object);
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void logOut();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void shutDown();

signals:
    void windowsChanged();
    void applicationsChanged();
    void trayIconsChanged();
    void notificationsChanged();
    void clockChanged();

private:
    void refreshWindows();
    void addNotification(const TrayNotification& notification);
    static QVariantMap windowMap(const WindowSnapshot& window);
    static QVariantMap applicationMap(const ApplicationEntry& application);
    static QVariantMap trayIconMap(const TrayIconSnapshot& icon);
    static QString trayIconImage(std::uintptr_t iconHandle);
    static bool enableShutdownPrivilege();
    static void exitWindows(unsigned flags);
    void reservePanel(QWindow* window);
    void restoreWorkArea();

    WindowModel windowModel_;
    ApplicationModel applicationModel_;
    WindowsWindowSystem windowSystem_;
    WindowsApplications applications_;
    WindowsTraySystem traySystem_;
    QTimer clockTimer_;
    QVariantList notifications_;
    qulonglong nextNotificationId_ = 1;
    QWindow* desktop_ = nullptr;
    QWindow* panel_ = nullptr;
    RECT originalWorkArea_{};
    bool workAreaChanged_ = false;
};
}
