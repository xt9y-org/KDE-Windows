#pragma once

#include <QQuickImageProvider>

class ShellIconProvider final : public QQuickImageProvider
{
public:
    ShellIconProvider();
    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

private:
    static QImage iconImage(qulonglong windowId, int size);
    static QImage pathImage(const QString& path, int size);
};
