#pragma once

#include "Core/ApplicationModel.hpp"
#include "Core/WindowModel.hpp"
#include "Platform/Windows/WindowsApplications.hpp"
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
    Q_PROPERTY(QString clockText READ clockText NOTIFY clockChanged)
    Q_PROPERTY(QString dateText READ dateText NOTIFY clockChanged)

public:
    explicit Backend(QObject* parent = nullptr);
    ~Backend() override;

    [[nodiscard]] QVariantList windows() const;
    [[nodiscard]] QVariantList applications() const;
    [[nodiscard]] QString clockText() const;
    [[nodiscard]] QString dateText() const;

    Q_INVOKABLE QVariantList searchApplications(const QString& query) const;
    Q_INVOKABLE void activateWindow(qulonglong id);
    Q_INVOKABLE void minimizeWindow(qulonglong id);
    Q_INVOKABLE void toggleMaximizeWindow(qulonglong id);
    Q_INVOKABLE void closeWindow(qulonglong id);
    Q_INVOKABLE void launchApplication(const QString& id);
    Q_INVOKABLE void reloadApplications();
    Q_INVOKABLE void registerDesktop(QObject* object);
    Q_INVOKABLE void registerPanel(QObject* object);
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void logOut();
    Q_INVOKABLE void restart();
    Q_INVOKABLE void shutDown();

signals:
    void windowsChanged();
    void applicationsChanged();
    void clockChanged();

private:
    void refreshWindows();
    static QVariantMap windowMap(const WindowSnapshot& window);
    static QVariantMap applicationMap(const ApplicationEntry& application);
    static bool enableShutdownPrivilege();
    static void exitWindows(unsigned flags);
    void reservePanel(QWindow* window);

    WindowModel windowModel_;
    ApplicationModel applicationModel_;
    WindowsWindowSystem windowSystem_;
    WindowsApplications applications_;
    QTimer clockTimer_;
    QWindow* desktop_ = nullptr;
    QWindow* panel_ = nullptr;
    bool appBarRegistered_ = false;
};
}
