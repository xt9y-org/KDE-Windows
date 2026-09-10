#include "Backend.hpp"
#include "FavoritesBridge.hpp"
#include "PanelBridge.hpp"
#include "ShellIconProvider.hpp"

#include <QColor>
#include <QCoreApplication>
#include <QDir>
#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <objbase.h>

namespace
{
QPalette breezeLightPalette()
{
    QPalette palette;
    palette.setColor(QPalette::Window, QColor(QStringLiteral("#eff0f1")));
    palette.setColor(QPalette::WindowText, QColor(QStringLiteral("#232629")));
    palette.setColor(QPalette::Base, QColor(QStringLiteral("#fcfcfc")));
    palette.setColor(QPalette::AlternateBase, QColor(QStringLiteral("#f5f6f7")));
    palette.setColor(QPalette::ToolTipBase, QColor(QStringLiteral("#eff0f1")));
    palette.setColor(QPalette::ToolTipText, QColor(QStringLiteral("#232629")));
    palette.setColor(QPalette::Text, QColor(QStringLiteral("#232629")));
    palette.setColor(QPalette::Button, QColor(QStringLiteral("#f2f3f4")));
    palette.setColor(QPalette::ButtonText, QColor(QStringLiteral("#232629")));
    palette.setColor(QPalette::BrightText, QColor(QStringLiteral("#ffffff")));
    palette.setColor(QPalette::Highlight, QColor(QStringLiteral("#3daee9")));
    palette.setColor(QPalette::HighlightedText, QColor(QStringLiteral("#ffffff")));
    palette.setColor(QPalette::PlaceholderText, QColor(QStringLiteral("#7f8c8d")));
    palette.setColor(QPalette::Disabled, QPalette::Text, QColor(QStringLiteral("#7f8c8d")));
    palette.setColor(QPalette::Disabled, QPalette::ButtonText, QColor(QStringLiteral("#7f8c8d")));
    return palette;
}
}

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
        app.setPalette(breezeLightPalette());

        QFont plasmaFont(QStringLiteral("Noto Sans"));
        plasmaFont.setPointSize(10);
        app.setFont(plasmaFont);

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
        kde_windows::FavoritesBridge favorites;
        kde_windows::PanelBridge panelBridge;
        QQmlApplicationEngine engine;
        engine.addImportPath(qmlRoot);
        engine.addImageProvider(QStringLiteral("shell"), new ShellIconProvider);
        engine.rootContext()->setContextProperty(QStringLiteral("PlasmaBackend"), &backend);
        engine.rootContext()->setContextProperty(QStringLiteral("Favorites"), &favorites);
        engine.rootContext()->setContextProperty(QStringLiteral("PanelBridge"), &panelBridge);

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
