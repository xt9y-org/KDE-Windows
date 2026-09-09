#include "Backend.hpp"

#include <QVariantList>
#include <QVariantMap>

namespace kde_windows
{
QVariantList Backend::displayModes(const QString& displayId) const
{
    const auto modes = displaySystem_.modes(displayId.toStdWString());
    QVariantList result;
    result.reserve(static_cast<qsizetype>(modes.size()));
    for (const auto& mode : modes) {
        QVariantMap item;
        item.insert(QStringLiteral("width"), mode.width);
        item.insert(QStringLiteral("height"), mode.height);
        item.insert(QStringLiteral("refreshRate"), mode.refreshRate);
        item.insert(QStringLiteral("bitsPerPixel"), mode.bitsPerPixel);
        item.insert(QStringLiteral("label"), QStringLiteral("%1×%2 @ %3 Hz").arg(mode.width).arg(mode.height).arg(mode.refreshRate));
        result.push_back(item);
    }
    return result;
}

QVariantMap Backend::currentDisplayMode(const QString& displayId) const
{
    QVariantMap result;
    const DisplaySnapshot* display = displayModel_.find(displayId.toStdWString());
    if (!display)
        return result;

    result.insert(QStringLiteral("width"), display->width);
    result.insert(QStringLiteral("height"), display->height);
    result.insert(QStringLiteral("refreshRate"), display->refreshRate);
    result.insert(QStringLiteral("label"), QStringLiteral("%1×%2 @ %3 Hz").arg(display->width).arg(display->height).arg(display->refreshRate));
    return result;
}

QVariantMap Backend::displayBrightness(const QString& displayId) const
{
    QVariantMap result;
    const DisplaySnapshot* display = displayModel_.find(displayId.toStdWString());
    if (!display) {
        result.insert(QStringLiteral("available"), false);
        result.insert(QStringLiteral("percent"), -1);
        return result;
    }

    result.insert(QStringLiteral("available"), display->brightnessAvailable);
    result.insert(QStringLiteral("percent"), display->brightnessPercent);
    return result;
}

bool Backend::setDisplayMode(const QString& displayId, int width, int height, int refreshRate)
{
    if (!displaySystem_.setMode(displayId.toStdWString(), width, height, refreshRate))
        return false;
    reloadDisplays();
    return true;
}

bool Backend::setPrimaryDisplay(const QString& displayId)
{
    if (!displaySystem_.setPrimary(displayId.toStdWString()))
        return false;
    reloadDisplays();
    return true;
}

bool Backend::setDisplayBrightness(const QString& displayId, int percent)
{
    if (!displaySystem_.setBrightness(displayId.toStdWString(), percent))
        return false;
    reloadDisplays();
    return true;
}

QVariantMap Backend::wifiState() const
{
    const NetworkState current = networkSystem_.state();
    const auto networks = networkSystem_.networks();
    QVariantList items;
    items.reserve(static_cast<qsizetype>(networks.size()));

    for (const auto& network : networks) {
        QVariantMap item;
        item.insert(QStringLiteral("id"), QString::fromStdWString(network.id));
        item.insert(QStringLiteral("name"), QString::fromStdWString(network.name));
        item.insert(QStringLiteral("profileName"), QString::fromStdWString(network.profileName));
        item.insert(QStringLiteral("signal"), network.signalQuality);
        item.insert(QStringLiteral("connected"), network.connected);
        item.insert(QStringLiteral("known"), network.known);
        item.insert(QStringLiteral("secure"), network.secure);
        items.push_back(item);
    }

    QVariantMap result;
    result.insert(QStringLiteral("enabled"), networkSystem_.radioEnabled());
    result.insert(QStringLiteral("connected"), current.connected);
    result.insert(QStringLiteral("name"), QString::fromStdWString(current.name));
    result.insert(QStringLiteral("networks"), items);
    return result;
}

bool Backend::setWifiEnabled(bool enabled)
{
    const bool changed = networkSystem_.setRadioEnabled(enabled);
    if (changed)
        refreshSystemStatus();
    return changed;
}

bool Backend::connectWifi(const QString& networkId)
{
    const bool requested = networkSystem_.connectKnown(networkId.toStdWString());
    if (requested)
        refreshSystemStatus();
    return requested;
}

bool Backend::connectWifiPassword(const QString& networkId, const QString& password)
{
    const bool requested = networkSystem_.connectWithPassword(networkId.toStdWString(), password.toStdWString());
    if (requested)
        refreshSystemStatus();
    return requested;
}

bool Backend::disconnectWifi()
{
    const bool disconnected = networkSystem_.disconnect();
    if (disconnected)
        refreshSystemStatus();
    return disconnected;
}

QVariantMap Backend::bluetoothState() const
{
    const BluetoothState state = bluetoothSystem_.state();
    QVariantList devices;
    devices.reserve(static_cast<qsizetype>(state.devices.size()));

    for (const auto& device : state.devices) {
        QVariantMap item;
        item.insert(QStringLiteral("id"), QString::fromStdWString(device.id));
        item.insert(QStringLiteral("name"), QString::fromStdWString(device.name));
        item.insert(QStringLiteral("connected"), device.connected);
        item.insert(QStringLiteral("paired"), device.paired);
        item.insert(QStringLiteral("remembered"), device.remembered);
        devices.push_back(item);
    }

    QVariantMap result;
    result.insert(QStringLiteral("available"), state.available);
    result.insert(QStringLiteral("discoverable"), state.discoverable);
    result.insert(QStringLiteral("radioName"), QString::fromStdWString(state.radioName));
    result.insert(QStringLiteral("devices"), devices);
    return result;
}

bool Backend::setBluetoothDiscoverable(bool enabled)
{
    const bool changed = bluetoothSystem_.setDiscoverable(enabled);
    if (changed)
        emit systemStatusChanged();
    return changed;
}

bool Backend::pairBluetooth(const QString& deviceId)
{
    const bool paired = bluetoothSystem_.pair(deviceId.toStdWString());
    if (paired)
        emit systemStatusChanged();
    return paired;
}

bool Backend::removeBluetooth(const QString& deviceId)
{
    const bool removed = bluetoothSystem_.remove(deviceId.toStdWString());
    if (removed)
        emit systemStatusChanged();
    return removed;
}

void Backend::virtualDesktopLeft()
{
    virtualDesktopSystem_.perform(VirtualDesktopAction::Left);
}

void Backend::virtualDesktopRight()
{
    virtualDesktopSystem_.perform(VirtualDesktopAction::Right);
}

void Backend::virtualDesktopCreate()
{
    virtualDesktopSystem_.perform(VirtualDesktopAction::Create);
}

void Backend::virtualDesktopClose()
{
    virtualDesktopSystem_.perform(VirtualDesktopAction::Close);
}
}
