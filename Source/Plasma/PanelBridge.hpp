#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>

class QWindow;

namespace kde_windows
{
class PanelBridge final : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT

public:
    explicit PanelBridge(QObject* parent = nullptr);
    ~PanelBridge() override;

    Q_INVOKABLE void registerPanel(QObject* object);
    bool nativeEventFilter(const QByteArray& eventType, void* message, qintptr* result) override;

private:
    void updatePosition();
    void unregisterPanel();

    QWindow* window_ = nullptr;
    unsigned callbackMessage_ = 0;
    bool registered_ = false;
};
}
