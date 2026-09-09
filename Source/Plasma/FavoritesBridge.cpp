#include "FavoritesBridge.hpp"

#include <QSettings>
#include <QStringList>
#include <QVariantMap>

namespace kde_windows
{
namespace
{
const QStringList kDefaultFavorites{
    QStringLiteral("org.kde.dolphin"),
    QStringLiteral("org.kde.konsole"),
};
}

FavoritesBridge::FavoritesBridge(QObject* parent)
    : QObject(parent)
{
    reload();
}

QVariantList FavoritesBridge::applications() const
{
    QVariantList result;
    const QStringList ids = favoriteIds();
    result.reserve(ids.size());
    for (const QString& id : ids) {
        const ApplicationEntry* application = applications_.find(id.toStdWString());
        if (application)
            result.push_back(mapApplication(*application));
    }
    return result;
}

bool FavoritesBridge::isFavorite(const QString& id) const
{
    return favoriteIds().contains(id, Qt::CaseInsensitive);
}

void FavoritesBridge::setFavorite(const QString& id, bool favorite)
{
    if (id.isEmpty())
        return;

    QStringList ids = favoriteIds();
    qsizetype existing = -1;
    for (qsizetype index = 0; index < ids.size(); ++index) {
        if (ids.at(index).compare(id, Qt::CaseInsensitive) == 0) {
            existing = index;
            break;
        }
    }

    if (favorite) {
        if (existing < 0)
            ids.push_back(id);
    } else if (existing >= 0) {
        ids.removeAt(existing);
    } else {
        return;
    }

    writeFavoriteIds(ids);
    emit changed();
}

void FavoritesBridge::launch(const QString& id)
{
    const ApplicationEntry* application = applications_.find(id.toStdWString());
    if (application)
        windowsApplications_.launch(*application);
}

void FavoritesBridge::reload()
{
    applications_.replace(windowsApplications_.scan());
    emit changed();
}

QStringList FavoritesBridge::favoriteIds() const
{
    QSettings settings(QStringLiteral("KDE"), QStringLiteral("KDE-Windows"));
    const QVariant stored = settings.value(QStringLiteral("Panel/Favorites"));
    if (!stored.isValid())
        return kDefaultFavorites;
    return stored.toStringList();
}

void FavoritesBridge::writeFavoriteIds(const QStringList& ids)
{
    QSettings settings(QStringLiteral("KDE"), QStringLiteral("KDE-Windows"));
    settings.setValue(QStringLiteral("Panel/Favorites"), ids);
    settings.sync();
}

QVariantMap FavoritesBridge::mapApplication(const ApplicationEntry& application)
{
    QVariantMap map;
    map.insert(QStringLiteral("id"), QString::fromStdWString(application.id));
    map.insert(QStringLiteral("name"), QString::fromStdWString(application.name));
    map.insert(QStringLiteral("executable"), QString::fromStdWString(application.executable));
    map.insert(QStringLiteral("iconPath"), QString::fromStdWString(application.iconPath));
    return map;
}
}
