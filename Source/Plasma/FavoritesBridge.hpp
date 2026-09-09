#pragma once

#include "Core/ApplicationModel.hpp"
#include "Platform/Windows/WindowsApplications.hpp"

#include <QObject>
#include <QVariantList>

namespace kde_windows
{
class FavoritesBridge final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList applications READ applications NOTIFY changed)

public:
    explicit FavoritesBridge(QObject* parent = nullptr);

    [[nodiscard]] QVariantList applications() const;
    Q_INVOKABLE bool isFavorite(const QString& id) const;
    Q_INVOKABLE void setFavorite(const QString& id, bool favorite);
    Q_INVOKABLE void launch(const QString& id);
    Q_INVOKABLE void reload();

signals:
    void changed();

private:
    [[nodiscard]] QStringList favoriteIds() const;
    void writeFavoriteIds(const QStringList& ids);
    static QVariantMap mapApplication(const ApplicationEntry& application);

    ApplicationModel applications_;
    WindowsApplications windowsApplications_;
};
}
