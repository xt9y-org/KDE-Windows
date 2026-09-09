#include "WindowsTraySystem.hpp"

#include <algorithm>
#include <cstddef>
#include <cstring>

#include <objbase.h>
#include <shellapi.h>

namespace kde_windows
{
namespace
{
constexpr wchar_t kShellTrayClass[] = L"Shell_TrayWnd";
constexpr ULONG_PTR kTrayCopyData = 2;
constexpr DWORD kTrayNotifySignature = 0x34753423;

struct TrayNotifyHeader
{
    DWORD signature;
    DWORD message;
};
}

WindowsTraySystem::~WindowsTraySystem()
{
    stop();
}

bool WindowsTraySystem::start(ChangeCallback changed, NotificationCallback notification)
{
    if (window_)
        return true;

    if (FindWindowW(kShellTrayClass, nullptr))
        return false;

    changed_ = std::move(changed);
    notification_ = std::move(notification);

    const HINSTANCE instance = GetModuleHandleW(nullptr);
    WNDCLASSEXW windowClass{};
    windowClass.cbSize = sizeof(windowClass);
    windowClass.hInstance = instance;
    windowClass.lpfnWndProc = &WindowsTraySystem::windowProc;
    windowClass.lpszClassName = kShellTrayClass;
    windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);

    classAtom_ = RegisterClassExW(&windowClass);
    if (!classAtom_) {
        changed_ = {};
        notification_ = {};
        return false;
    }

    window_ = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
                              kShellTrayClass,
                              L"KDE Windows Shell Tray",
                              WS_POPUP,
                              -32000, -32000, 1, 1,
                              nullptr, nullptr, instance, this);
    if (!window_) {
        UnregisterClassW(kShellTrayClass, instance);
        classAtom_ = 0;
        changed_ = {};
        notification_ = {};
        return false;
    }

    broadcastTaskbarCreated();
    return true;
}

void WindowsTraySystem::stop()
{
    if (window_) {
        DestroyWindow(window_);
        window_ = nullptr;
    }

    for (const auto& icon : model_.icons()) {
        if (icon.iconHandle)
            DestroyIcon(reinterpret_cast<HICON>(icon.iconHandle));
    }
    model_ = TrayModel{};

    if (classAtom_) {
        UnregisterClassW(kShellTrayClass, GetModuleHandleW(nullptr));
        classAtom_ = 0;
    }

    changed_ = {};
    notification_ = {};
}

void WindowsTraySystem::invoke(const std::wstring& key, bool contextMenu)
{
    const auto* icon = model_.find(key);
    if (!icon || !icon->ownerWindow || !icon->callbackMessage)
        return;

    const HWND owner = reinterpret_cast<HWND>(icon->ownerWindow);
    if (!IsWindow(owner))
        return;

    POINT cursor{};
    GetCursorPos(&cursor);

    if (contextMenu)
        SetForegroundWindow(owner);

    if (icon->version >= NOTIFYICON_VERSION_4) {
        const UINT event = contextMenu ? WM_CONTEXTMENU : NIN_SELECT;
        const WPARAM coordinates = MAKEWPARAM(static_cast<SHORT>(cursor.x), static_cast<SHORT>(cursor.y));
        const LPARAM eventAndId = MAKELPARAM(event, static_cast<WORD>(icon->id));
        SendNotifyMessageW(owner, icon->callbackMessage, coordinates, eventAndId);
        return;
    }

    const UINT down = contextMenu ? WM_RBUTTONDOWN : WM_LBUTTONDOWN;
    const UINT up = contextMenu ? WM_RBUTTONUP : WM_LBUTTONUP;
    SendNotifyMessageW(owner, icon->callbackMessage, icon->id, down);
    SendNotifyMessageW(owner, icon->callbackMessage, icon->id, up);
}

LRESULT CALLBACK WindowsTraySystem::windowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam)
{
    WindowsTraySystem* self = reinterpret_cast<WindowsTraySystem*>(GetWindowLongPtrW(window, GWLP_USERDATA));

    if (message == WM_NCCREATE) {
        const auto* create = reinterpret_cast<const CREATESTRUCTW*>(lparam);
        self = static_cast<WindowsTraySystem*>(create->lpCreateParams);
        SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    }

    if (self && message == WM_COPYDATA)
        return self->handleCopyData(wparam, lparam);

    return DefWindowProcW(window, message, wparam, lparam);
}

LRESULT WindowsTraySystem::handleCopyData(WPARAM, LPARAM lparam)
{
    const auto* copy = reinterpret_cast<const COPYDATASTRUCT*>(lparam);
    if (!copy || copy->dwData != kTrayCopyData || !copy->lpData || copy->cbData < sizeof(TrayNotifyHeader))
        return FALSE;

    TrayNotifyHeader header{};
    std::memcpy(&header, copy->lpData, sizeof(header));
    if (header.signature != kTrayNotifySignature)
        return FALSE;

    const std::size_t payloadSize = copy->cbData - sizeof(header);
    if (payloadSize < sizeof(DWORD))
        return FALSE;

    NOTIFYICONDATAW data{};
    std::memcpy(&data,
                static_cast<const std::byte*>(copy->lpData) + sizeof(header),
                std::min<std::size_t>(payloadSize, sizeof(data)));

    if (data.cbSize < NOTIFYICONDATAW_V1_SIZE)
        return FALSE;

    return handleNotifyIcon(header.message, data) ? TRUE : FALSE;
}

bool WindowsTraySystem::handleNotifyIcon(DWORD message, const NOTIFYICONDATAW& data)
{
    const std::wstring key = keyFor(data);
    if (key.empty())
        return false;

    switch (message) {
    case NIM_ADD: {
        if (model_.find(key)) {
            removeOwnedIcon(key);
            model_.remove(key);
        }

        TrayIconSnapshot icon;
        icon.key = key;
        icon.ownerWindow = reinterpret_cast<std::uintptr_t>(data.hWnd);
        icon.id = data.uID;
        if (data.uFlags & NIF_MESSAGE)
            icon.callbackMessage = data.uCallbackMessage;
        if ((data.uFlags & NIF_ICON) && data.hIcon) {
            const HICON copy = CopyIcon(data.hIcon);
            icon.iconHandle = reinterpret_cast<std::uintptr_t>(copy);
        }
        if (data.uFlags & NIF_TIP)
            icon.tooltip = data.szTip;
        if ((data.uFlags & NIF_STATE) && (data.dwStateMask & NIS_HIDDEN))
            icon.hidden = (data.dwState & NIS_HIDDEN) != 0;

        const bool added = model_.add(icon);
        if (!added && icon.iconHandle)
            DestroyIcon(reinterpret_cast<HICON>(icon.iconHandle));
        if (added) {
            notifyBalloon(data);
            notifyChanged();
        }
        return added;
    }

    case NIM_MODIFY: {
        const auto* current = model_.find(key);
        if (!current)
            return false;

        const std::uintptr_t previousIcon = current->iconHandle;
        TrayIconUpdate update;
        update.key = key;
        if (data.uFlags & NIF_MESSAGE)
            update.callbackMessage = data.uCallbackMessage;
        if ((data.uFlags & NIF_ICON) && data.hIcon) {
            const HICON copy = CopyIcon(data.hIcon);
            if (copy)
                update.iconHandle = reinterpret_cast<std::uintptr_t>(copy);
        }
        if (data.uFlags & NIF_TIP)
            update.tooltip = std::wstring(data.szTip);
        if ((data.uFlags & NIF_STATE) && (data.dwStateMask & NIS_HIDDEN))
            update.hidden = (data.dwState & NIS_HIDDEN) != 0;

        const bool modified = model_.modify(update);
        if (!modified) {
            if (update.iconHandle)
                DestroyIcon(reinterpret_cast<HICON>(*update.iconHandle));
            return false;
        }
        if (update.iconHandle && previousIcon)
            DestroyIcon(reinterpret_cast<HICON>(previousIcon));

        notifyBalloon(data);
        notifyChanged();
        return true;
    }

    case NIM_DELETE:
        removeOwnedIcon(key);
        if (model_.remove(key)) {
            notifyChanged();
            return true;
        }
        return false;

    case NIM_SETVERSION:
        return model_.setVersion(key, data.uVersion);

    case NIM_SETFOCUS:
        return model_.find(key) != nullptr;

    default:
        return false;
    }
}

std::wstring WindowsTraySystem::keyFor(const NOTIFYICONDATAW& data)
{
    if (hasGuid(data.guidItem)) {
        wchar_t guid[64]{};
        if (StringFromGUID2(data.guidItem, guid, static_cast<int>(std::size(guid))) > 0)
            return std::wstring(L"guid:") + guid;
    }

    if (!data.hWnd)
        return {};

    return L"window:" + std::to_wstring(reinterpret_cast<std::uintptr_t>(data.hWnd)) +
           L":" + std::to_wstring(data.uID);
}

bool WindowsTraySystem::hasGuid(const GUID& guid)
{
    static constexpr GUID zero{};
    return std::memcmp(&guid, &zero, sizeof(GUID)) != 0;
}

void WindowsTraySystem::replaceOwnedIcon(const std::wstring& key, HICON icon)
{
    const auto* current = model_.find(key);
    if (current && current->iconHandle && current->iconHandle != reinterpret_cast<std::uintptr_t>(icon))
        DestroyIcon(reinterpret_cast<HICON>(current->iconHandle));
}

void WindowsTraySystem::removeOwnedIcon(const std::wstring& key)
{
    const auto* current = model_.find(key);
    if (current && current->iconHandle)
        DestroyIcon(reinterpret_cast<HICON>(current->iconHandle));
}

void WindowsTraySystem::notifyChanged()
{
    if (changed_)
        changed_();
}

void WindowsTraySystem::notifyBalloon(const NOTIFYICONDATAW& data)
{
    if (!(data.uFlags & NIF_INFO) || !data.szInfo[0] || !notification_)
        return;

    TrayNotification notification;
    notification.title = data.szInfoTitle;
    notification.body = data.szInfo;
    notification.source = (data.uFlags & NIF_TIP) && data.szTip[0] ? data.szTip : L"Application";
    notification_(notification);
}

void WindowsTraySystem::broadcastTaskbarCreated() const
{
    const UINT message = RegisterWindowMessageW(L"TaskbarCreated");
    if (!message)
        return;

    DWORD_PTR ignored = 0;
    SendMessageTimeoutW(HWND_BROADCAST,
                        message,
                        0,
                        0,
                        SMTO_ABORTIFHUNG | SMTO_NORMAL,
                        1000,
                        &ignored);
}
}
