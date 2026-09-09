#include "ConPtySession.hpp"

#include <QByteArray>
#include <QMetaObject>

#include <algorithm>
#include <array>
#include <cstddef>
#include <string>
#include <vector>

namespace kde_windows
{
namespace
{
constexpr qsizetype kMaxTerminalChars = 200000;
}

ConPtySession::ConPtySession(QObject* parent)
    : QObject(parent)
{
    start();
}

ConPtySession::~ConPtySession()
{
    stop();
}

bool ConPtySession::start()
{
    if (running_)
        return true;

    stop();
    stopping_.store(false);

    HANDLE inputRead = nullptr;
    HANDLE outputWrite = nullptr;
    SECURITY_ATTRIBUTES attributes{};
    attributes.nLength = sizeof(attributes);
    attributes.bInheritHandle = TRUE;

    if (!CreatePipe(&inputRead, &inputWrite_, &attributes, 0) ||
        !CreatePipe(&outputRead_, &outputWrite, &attributes, 0)) {
        if (inputRead) CloseHandle(inputRead);
        if (inputWrite_) CloseHandle(inputWrite_);
        if (outputRead_) CloseHandle(outputRead_);
        if (outputWrite) CloseHandle(outputWrite);
        inputWrite_ = nullptr;
        outputRead_ = nullptr;
        return false;
    }

    SetHandleInformation(inputWrite_, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(outputRead_, HANDLE_FLAG_INHERIT, 0);

    const COORD size{120, 40};
    const HRESULT consoleResult = CreatePseudoConsole(size, inputRead, outputWrite, 0, &pseudoConsole_);
    CloseHandle(inputRead);
    CloseHandle(outputWrite);
    if (FAILED(consoleResult)) {
        CloseHandle(inputWrite_);
        CloseHandle(outputRead_);
        inputWrite_ = nullptr;
        outputRead_ = nullptr;
        pseudoConsole_ = nullptr;
        return false;
    }

    SIZE_T attributeBytes = 0;
    InitializeProcThreadAttributeList(nullptr, 1, 0, &attributeBytes);
    if (attributeBytes == 0) {
        stop();
        return false;
    }

    std::vector<std::byte> attributeStorage(attributeBytes);
    STARTUPINFOEXW startup{};
    startup.StartupInfo.cb = sizeof(startup);
    startup.lpAttributeList = reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(attributeStorage.data());

    bool attributeListInitialized = false;
    if (!InitializeProcThreadAttributeList(startup.lpAttributeList, 1, 0, &attributeBytes)) {
        stop();
        return false;
    }
    attributeListInitialized = true;

    if (!UpdateProcThreadAttribute(startup.lpAttributeList,
                                   0,
                                   PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE,
                                   pseudoConsole_,
                                   sizeof(HPCON),
                                   nullptr,
                                   nullptr)) {
        if (attributeListInitialized)
            DeleteProcThreadAttributeList(startup.lpAttributeList);
        stop();
        return false;
    }

    std::wstring command = L"powershell.exe -NoLogo";
    PROCESS_INFORMATION processInfo{};
    const BOOL created = CreateProcessW(nullptr,
                                        command.data(),
                                        nullptr,
                                        nullptr,
                                        FALSE,
                                        EXTENDED_STARTUPINFO_PRESENT,
                                        nullptr,
                                        nullptr,
                                        &startup.StartupInfo,
                                        &processInfo);
    DeleteProcThreadAttributeList(startup.lpAttributeList);

    if (!created) {
        stop();
        return false;
    }

    CloseHandle(processInfo.hThread);
    process_ = processInfo.hProcess;
    running_ = true;
    emit runningChanged();

    reader_ = std::thread([this] { readerLoop(); });
    return true;
}

void ConPtySession::sendLine(const QString& line)
{
    sendText(line + QStringLiteral("\r\n"));
}

void ConPtySession::sendText(const QString& text)
{
    if (!running_ || !inputWrite_)
        return;

    const QByteArray bytes = text.toUtf8();
    DWORD written = 0;
    WriteFile(inputWrite_, bytes.constData(), static_cast<DWORD>(bytes.size()), &written, nullptr);
}

void ConPtySession::clear()
{
    if (output_.isEmpty())
        return;
    output_.clear();
    emit outputChanged();
}

void ConPtySession::stop()
{
    stopping_.store(true);

    if (inputWrite_) {
        CloseHandle(inputWrite_);
        inputWrite_ = nullptr;
    }

    if (pseudoConsole_) {
        ClosePseudoConsole(pseudoConsole_);
        pseudoConsole_ = nullptr;
    }

    if (process_) {
        if (WaitForSingleObject(process_, 500) == WAIT_TIMEOUT)
            TerminateProcess(process_, 0);
        CloseHandle(process_);
        process_ = nullptr;
    }

    if (outputRead_) {
        CancelIoEx(outputRead_, nullptr);
        CloseHandle(outputRead_);
        outputRead_ = nullptr;
    }

    if (reader_.joinable())
        reader_.join();

    if (running_) {
        running_ = false;
        emit runningChanged();
    }
}

void ConPtySession::readerLoop()
{
    std::array<char, 4096> buffer{};
    while (!stopping_.load()) {
        DWORD read = 0;
        if (!ReadFile(outputRead_, buffer.data(), static_cast<DWORD>(buffer.size()), &read, nullptr) || read == 0)
            break;
        appendOutput(QByteArray(buffer.data(), static_cast<qsizetype>(read)));
    }

    if (!stopping_.load()) {
        QMetaObject::invokeMethod(this, [this] {
            if (running_) {
                running_ = false;
                emit runningChanged();
            }
        }, Qt::QueuedConnection);
    }
}

void ConPtySession::appendOutput(const QByteArray& bytes)
{
    const QString text = sanitizeTerminalText(bytes);
    if (text.isEmpty())
        return;

    QMetaObject::invokeMethod(this, [this, text] {
        output_ += text;
        if (output_.size() > kMaxTerminalChars)
            output_.remove(0, output_.size() - kMaxTerminalChars);
        emit outputChanged();
    }, Qt::QueuedConnection);
}

QString ConPtySession::sanitizeTerminalText(const QByteArray& bytes)
{
    QByteArray plain;
    plain.reserve(bytes.size());

    for (qsizetype i = 0; i < bytes.size();) {
        const unsigned char c = static_cast<unsigned char>(bytes.at(i));
        if (c == 0x1b) {
            if (i + 1 < bytes.size() && bytes.at(i + 1) == '[') {
                i += 2;
                while (i < bytes.size()) {
                    const unsigned char end = static_cast<unsigned char>(bytes.at(i++));
                    if (end >= 0x40 && end <= 0x7e)
                        break;
                }
                continue;
            }
            if (i + 1 < bytes.size() && bytes.at(i + 1) == ']') {
                i += 2;
                while (i < bytes.size()) {
                    if (bytes.at(i) == '\a') {
                        ++i;
                        break;
                    }
                    if (static_cast<unsigned char>(bytes.at(i)) == 0x1b &&
                        i + 1 < bytes.size() && bytes.at(i + 1) == '\\') {
                        i += 2;
                        break;
                    }
                    ++i;
                }
                continue;
            }
            i += std::min<qsizetype>(2, bytes.size() - i);
            continue;
        }
        plain.append(bytes.at(i++));
    }

    QString text = QString::fromUtf8(plain);
    QString normalized;
    normalized.reserve(text.size());
    for (const QChar c : text) {
        if (c == QLatin1Char('\b')) {
            if (!normalized.isEmpty())
                normalized.chop(1);
        } else if (c != QChar::Null) {
            normalized.append(c);
        }
    }
    return normalized;
}
}
