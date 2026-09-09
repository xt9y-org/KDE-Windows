#include "WindowsDesktopSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>

#include <cwchar>
#include <filesystem>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
namespace
{
std::wstring knownFolder(REFKNOWNFOLDERID id)
{
    PWSTR path = nullptr;
    if (FAILED(SHGetKnownFolderPath(id, KF_FLAG_DEFAULT, nullptr, &path)) || !path)
        return {};
    std::wstring result(path);
    CoTaskMemFree(path);
    return result;
}

std::filesystem::path executableDirectory()
{
    std::wstring path(32768, L'\0');
    const DWORD length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
    if (!length)
        return {};
    path.resize(length);
    return std::filesystem::path(path).parent_path();
}

bool openInDolphin(const std::wstring& path)
{
    const auto dolphin = executableDirectory() / L"dolphin.exe";
    if (!std::filesystem::exists(dolphin))
        return false;

    const std::wstring arguments = L"\"" + path + L"\"";
    const HINSTANCE result = ShellExecuteW(nullptr,
                                           L"open",
                                           dolphin.c_str(),
                                           arguments.c_str(),
                                           dolphin.parent_path().c_str(),
                                           SW_SHOWNORMAL);
    return reinterpret_cast<INT_PTR>(result) > 32;
}

void appendFolder(std::vector<DesktopEntry>& entries, const std::wstring& folder)
{
    if (folder.empty())
        return;

    std::error_code error;
    for (const auto& item : std::filesystem::directory_iterator(folder, error)) {
        if (error)
            break;

        const std::wstring path = item.path().wstring();
        const DWORD attributes = GetFileAttributesW(path.c_str());
        if (attributes == INVALID_FILE_ATTRIBUTES || (attributes & (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM)))
            continue;

        DesktopEntry entry;
        entry.id = path;
        entry.path = path;
        entry.directory = item.is_directory(error);
        if (error)
            error.clear();

        if (!entry.directory && item.path().extension() == L".lnk")
            entry.name = item.path().stem().wstring();
        else
            entry.name = item.path().filename().wstring();
        entries.push_back(std::move(entry));
    }
}
}

std::vector<DesktopEntry> WindowsDesktopSystem::scan() const
{
    std::vector<DesktopEntry> entries;
    appendFolder(entries, knownFolder(FOLDERID_Desktop));
    appendFolder(entries, knownFolder(FOLDERID_PublicDesktop));
    return entries;
}

bool WindowsDesktopSystem::launch(const DesktopEntry& entry) const
{
    if (entry.path.empty())
        return false;

    if (entry.directory && openInDolphin(entry.path))
        return true;

    const HINSTANCE result = ShellExecuteW(nullptr, L"open", entry.path.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    return reinterpret_cast<INT_PTR>(result) > 32;
}

bool WindowsDesktopSystem::openDesktop() const
{
    const std::wstring desktop = knownFolder(FOLDERID_Desktop);
    if (desktop.empty())
        return false;
    if (openInDolphin(desktop))
        return true;
    const HINSTANCE result = ShellExecuteW(nullptr, L"open", desktop.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
    return reinterpret_cast<INT_PTR>(result) > 32;
}

bool WindowsDesktopSystem::createFolder() const
{
    const std::wstring desktop = knownFolder(FOLDERID_Desktop);
    if (desktop.empty())
        return false;

    std::filesystem::path candidate = std::filesystem::path(desktop) / L"New Folder";
    std::error_code error;
    for (unsigned index = 2; std::filesystem::exists(candidate, error); ++index) {
        if (error)
            return false;
        candidate = std::filesystem::path(desktop) / (L"New Folder (" + std::to_wstring(index) + L")");
    }

    return std::filesystem::create_directory(candidate, error) && !error;
}

std::wstring WindowsDesktopSystem::wallpaper() const
{
    std::wstring path(32768, L'\0');
    if (!SystemParametersInfoW(SPI_GETDESKWALLPAPER,
                               static_cast<UINT>(path.size()),
                               path.data(),
                               0))
        return {};
    path.resize(std::wcslen(path.c_str()));
    return path;
}

bool WindowsDesktopSystem::setWallpaper(const std::wstring& path) const
{
    if (path.empty() || !std::filesystem::exists(path))
        return false;
    return SystemParametersInfoW(SPI_SETDESKWALLPAPER,
                                 0,
                                 const_cast<wchar_t*>(path.c_str()),
                                 SPIF_UPDATEINIFILE | SPIF_SENDCHANGE) != FALSE;
}
}
