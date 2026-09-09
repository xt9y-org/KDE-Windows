#include "ShellIconProvider.hpp"

#include <QUrl>

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>

#include <algorithm>
#include <cstring>

namespace
{
QImage renderIcon(HICON icon, int requested)
{
    if (!icon)
        return {};

    const int size = std::clamp(requested, 16, 128);
    HDC screen = GetDC(nullptr);
    if (!screen)
        return {};

    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = size;
    info.bmiHeader.biHeight = -size;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    HBITMAP bitmap = CreateDIBSection(screen, &info, DIB_RGB_COLORS, &bits, nullptr, 0);
    HDC memory = bitmap ? CreateCompatibleDC(screen) : nullptr;
    if (!bitmap || !memory || !bits) {
        if (memory)
            DeleteDC(memory);
        if (bitmap)
            DeleteObject(bitmap);
        ReleaseDC(nullptr, screen);
        return {};
    }

    std::memset(bits, 0, static_cast<std::size_t>(size * size * 4));
    const HGDIOBJ previous = SelectObject(memory, bitmap);
    DrawIconEx(memory, 0, 0, icon, size, size, 0, nullptr, DI_NORMAL);

    const QImage view(static_cast<const uchar*>(bits), size, size, size * 4, QImage::Format_ARGB32_Premultiplied);
    const QImage image = view.copy();

    SelectObject(memory, previous);
    DeleteDC(memory);
    DeleteObject(bitmap);
    ReleaseDC(nullptr, screen);
    return image;
}

HICON windowIcon(HWND window)
{
    if (!window || !IsWindow(window))
        return nullptr;

    DWORD_PTR value = 0;
    if (SendMessageTimeoutW(window, WM_GETICON, ICON_SMALL2, 0, SMTO_ABORTIFHUNG, 80, &value) && value)
        return reinterpret_cast<HICON>(value);
    if (SendMessageTimeoutW(window, WM_GETICON, ICON_SMALL, 0, SMTO_ABORTIFHUNG, 80, &value) && value)
        return reinterpret_cast<HICON>(value);
    if (SendMessageTimeoutW(window, WM_GETICON, ICON_BIG, 0, SMTO_ABORTIFHUNG, 80, &value) && value)
        return reinterpret_cast<HICON>(value);

    HICON icon = reinterpret_cast<HICON>(GetClassLongPtrW(window, GCLP_HICONSM));
    if (!icon)
        icon = reinterpret_cast<HICON>(GetClassLongPtrW(window, GCLP_HICON));
    return icon;
}
}

ShellIconProvider::ShellIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage ShellIconProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    const int requested = requestedSize.isValid() ? std::max(requestedSize.width(), requestedSize.height()) : 32;
    QImage image;

    if (id.startsWith(QStringLiteral("window/"))) {
        bool ok = false;
        const qulonglong windowId = id.mid(7).toULongLong(&ok);
        if (ok)
            image = iconImage(windowId, requested);
    } else if (id.startsWith(QStringLiteral("path/"))) {
        const QString path = QUrl::fromPercentEncoding(id.mid(5).toUtf8());
        image = pathImage(path, requested);
    }

    if (size)
        *size = image.size();
    return image;
}

QImage ShellIconProvider::iconImage(qulonglong windowId, int size)
{
    return renderIcon(windowIcon(reinterpret_cast<HWND>(static_cast<quintptr>(windowId))), size);
}

QImage ShellIconProvider::pathImage(const QString& path, int size)
{
    if (path.isEmpty())
        return {};

    SHFILEINFOW info{};
    const UINT flags = SHGFI_ICON | (size <= 20 ? SHGFI_SMALLICON : SHGFI_LARGEICON);
    if (!SHGetFileInfoW(reinterpret_cast<LPCWSTR>(path.utf16()), 0, &info, sizeof(info), flags) || !info.hIcon)
        return {};

    const QImage image = renderIcon(info.hIcon, size);
    DestroyIcon(info.hIcon);
    return image;
}
