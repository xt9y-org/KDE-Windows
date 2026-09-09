#pragma once

#include <QObject>
#include <QString>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <atomic>
#include <thread>

namespace kde_windows
{
class ConPtySession final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit ConPtySession(QObject* parent = nullptr);
    ~ConPtySession() override;

    [[nodiscard]] QString output() const { return output_; }
    [[nodiscard]] bool running() const { return running_; }

    Q_INVOKABLE bool start();
    Q_INVOKABLE void sendLine(const QString& line);
    Q_INVOKABLE void sendText(const QString& text);
    Q_INVOKABLE void clear();

signals:
    void outputChanged();
    void runningChanged();

private:
    void stop();
    void readerLoop();
    void appendOutput(const QByteArray& bytes);
    static QString sanitizeTerminalText(const QByteArray& bytes);

    HPCON pseudoConsole_ = nullptr;
    HANDLE inputWrite_ = nullptr;
    HANDLE outputRead_ = nullptr;
    HANDLE process_ = nullptr;
    std::thread reader_;
    std::atomic_bool stopping_{false};
    QString output_;
    bool running_ = false;
};
}
