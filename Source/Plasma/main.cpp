#include "Backend.hpp"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <objbase.h>

int main(int argc, char** argv)
{
    const HRESULT comResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    const bool uninitializeCom = SUCCEEDED(comResult);

    int result = EXIT_FAILURE;
    {
        QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
        QGuiApplication app(argc, argv);
        app.setApplicationName(QStringLiteral("plasmashell"));
        app.setOrganizationName(QStringLiteral("KDE"));
        QQuickStyle::setStyle(QStringLiteral("Basic"));

        kde_windows::Backend backend;
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty(QStringLiteral("PlasmaBackend"), &backend);

        QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
            QCoreApplication::exit(EXIT_FAILURE);
        }, Qt::QueuedConnection);

        engine.loadFromModule(QStringLiteral("org.kde.plasma.windows"), QStringLiteral("Main"));
        result = app.exec();
    }

    if (uninitializeCom)
        CoUninitialize();
    return result;
}
