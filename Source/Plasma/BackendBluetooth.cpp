#include "Backend.hpp"

#include <QVariantList>
#include <QVariantMap>

namespace kde_windows
{
QVariantMap Backend::bluetoothScan() const
{
    const BluetoothState state = bluetoothSystem_.scan();
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
}
