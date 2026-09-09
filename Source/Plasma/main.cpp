#include "Backend.hpp"
#include "ShellIconProvider.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QIcon>
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

        const QDir binDir(QCoreApplication::applicationDirPath());
        const QString runtimeRoot = QDir::cleanPath(binDir.absoluteFilePath(QStringLiteral("..")));
        const QString qmlRoot = QDir(runtimeRoot).absoluteFilePath(QStringLiteral("qml"));
        const QString dataRoot = binDir.absoluteFilePath(QStringLiteral("data"));

        qputenv("QML2_IMPORT_PATH", qmlRoot.toUtf8());
        qputenv("QML_IMPORT_PATH", qmlRoot.toUtf8());
        QIcon::setThemeSearchPaths({QDir(dataRoot).absoluteFilePath(QStringLiteral("icons"))});
        QIcon::setThemeName(QStringLiteral("breeze"));

        QQuickStyle::setFallbackStyle(QStringLiteral("Fusion"));
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));

        kde_windows::Backend backend;
        QQmlApplicationEngine engine;
        engine.addImportPath(qmlRoot);
        engine.addImageProvider(QStringLiteral("shell"), new ShellIconProvider);
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
