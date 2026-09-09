#pragma once

#include <QObject>

class QWindow;

namespace kde_windows
{
class PanelBridge final : public QObject
{
    Q_OBJECT

public:
    explicit PanelBridge(QObject* parent = nullptr);
    ~PanelBridge() override;

    Q_INVOKABLE void registerPanel(QObject* object);

private:
    void updatePosition();
    void unregisterPanel();

    QWindow* window_ = nullptr;
    bool registered_ = false;
};
}
