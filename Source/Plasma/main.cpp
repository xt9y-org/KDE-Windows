#include "Backend.hpp"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char** argv)
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
    return app.exec();
}
