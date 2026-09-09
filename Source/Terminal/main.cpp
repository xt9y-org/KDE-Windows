#include "ConPtySession.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char** argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Konsole"));
    app.setOrganizationName(QStringLiteral("KDE"));

    const QDir binDir(QCoreApplication::applicationDirPath());
    const QString runtimeRoot = QDir::cleanPath(binDir.absoluteFilePath(QStringLiteral("..")));
    const QString qmlRoot = QDir(runtimeRoot).absoluteFilePath(QStringLiteral("qml"));
    qputenv("QML2_IMPORT_PATH", qmlRoot.toUtf8());
    qputenv("QML_IMPORT_PATH", qmlRoot.toUtf8());

    QQuickStyle::setFallbackStyle(QStringLiteral("Fusion"));
    QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));

    kde_windows::ConPtySession session;
    QQmlApplicationEngine engine;
    engine.addImportPath(qmlRoot);
    engine.rootContext()->setContextProperty(QStringLiteral("TerminalSession"), &session);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
        QCoreApplication::exit(EXIT_FAILURE);
    }, Qt::QueuedConnection);
    engine.loadFromModule(QStringLiteral("org.kde.konsole.windows"), QStringLiteral("Terminal"));
    return app.exec();
}
