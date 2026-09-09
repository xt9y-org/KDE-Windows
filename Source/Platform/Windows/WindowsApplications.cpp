#include "WindowsApplications.hpp"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <wtypes.h>
#include <propkey.h>
#include <propsys.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl.h>

#include <filesystem>
#include <string>
#include <utility>
#include <vector>

namespace kde_windows
{
namespace
{
std::wstring environment(const wchar_t* name)
{
    const DWORD required = GetEnvironmentVariableW(name, nullptr, 0);
    if (!required)
        return {};
    std::wstring value(required, L'\0');
    const DWORD written = GetEnvironmentVariableW(name, value.data(), required);
    if (!written)
        return {};
    value.resize(written);
    return value;
}

std::filesystem::path executable_directory()
{
    std::wstring path(32768, L'\0');
    const DWORD length = GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
    if (!length)
        return {};
    path.resize(length);
    return std::filesystem::path(path).parent_path();
}

void append_bundled_applications(std::vector<ApplicationEntry>& applications)
{
    const auto bin = executable_directory();
    if (bin.empty())
        return;

    const auto dolphin = bin / L"dolphin.exe";
    if (std::filesystem::exists(dolphin)) {
        ApplicationEntry entry;
        entry.id = L"org.kde.dolphin";
        entry.name = L"Dolphin";
        entry.executable = dolphin.wstring();
        entry.workingDirectory = bin.wstring();
        entry.iconPath = dolphin.wstring();
        applications.push_back(std::move(entry));
    }

    const auto konsole = bin / L"konsole.exe";
    if (std::filesystem::exists(konsole)) {
        ApplicationEntry entry;
        entry.id = L"org.kde.konsole";
        entry.name = L"Konsole";
        entry.executable = konsole.wstring();
        entry.workingDirectory = bin.wstring();
        entry.iconPath = konsole.wstring();
        applications.push_back(std::move(entry));
    }
}

std::wstring property_string(IPropertyStore* store, REFPROPERTYKEY key)
{
    if (!store)
        return {};

    PROPVARIANT value;
    PropVariantInit(&value);
    if (FAILED(store->GetValue(key, &value)))
        return {};

    PWSTR raw = nullptr;
    std::wstring result;
    if (SUCCEEDED(PropVariantToStringAlloc(value, &raw)) && raw) {
        result = raw;
        CoTaskMemFree(raw);
    }
    PropVariantClear(&value);
    return result;
}

ApplicationEntry read_shortcut(const std::filesystem::path& file)
{
    ApplicationEntry entry;
    IShellLinkW* link = nullptr;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&link))))
        return entry;

    IPersistFile* persist = nullptr;
    if (FAILED(link->QueryInterface(IID_PPV_ARGS(&persist)))) {
        link->Release();
        return entry;
    }

    if (FAILED(persist->Load(file.c_str(), STGM_READ))) {
        persist->Release();
        link->Release();
        return entry;
    }

    std::wstring path(32768, L'\0');
    WIN32_FIND_DATAW findData{};
    if (SUCCEEDED(link->GetPath(path.data(), static_cast<int>(path.size()), &findData, SLGP_RAWPATH))) {
        path.resize(std::char_traits<wchar_t>::length(path.c_str()));
        entry.executable = path;
    }

    std::wstring arguments(32768, L'\0');
    if (SUCCEEDED(link->GetArguments(arguments.data(), static_cast<int>(arguments.size())))) {
        arguments.resize(std::char_traits<wchar_t>::length(arguments.c_str()));
        entry.arguments = arguments;
    }

    std::wstring working(32768, L'\0');
    if (SUCCEEDED(link->GetWorkingDirectory(working.data(), static_cast<int>(working.size())))) {
        working.resize(std::char_traits<wchar_t>::length(working.c_str()));
        entry.workingDirectory = working;
    }

    int iconIndex = 0;
    std::wstring icon(32768, L'\0');
    if (SUCCEEDED(link->GetIconLocation(icon.data(), static_cast<int>(icon.size()), &iconIndex))) {
        icon.resize(std::char_traits<wchar_t>::length(icon.c_str()));
        entry.iconPath = icon;
    }

    IPropertyStore* properties = nullptr;
    if (SUCCEEDED(link->QueryInterface(IID_PPV_ARGS(&properties)))) {
        entry.id = property_string(properties, PKEY_AppUserModel_ID);
        properties->Release();
    }

    entry.name = file.stem().wstring();
    if (entry.id.empty())
        entry.id = entry.executable.empty() ? file.wstring() : entry.executable;

    if (entry.executable.empty() && !entry.id.empty()) {
        entry.executable = entry.id;
        entry.packaged = true;
    }

    persist->Release();
    link->Release();
    return entry;
}

void scan_shortcuts(const std::filesystem::path& root, std::vector<ApplicationEntry>& applications)
{
    std::error_code error;
    if (root.empty() || !std::filesystem::exists(root, error))
        return;

    for (std::filesystem::recursive_directory_iterator it(root, std::filesystem::directory_options::skip_permission_denied, error), end;
         it != end; it.increment(error)) {
        if (error) {
            error.clear();
            continue;
        }
        if (!it->is_regular_file(error) || _wcsicmp(it->path().extension().c_str(), L".lnk") != 0)
            continue;
        auto entry = read_shortcut(it->path());
        if (!entry.name.empty() && !entry.executable.empty())
            applications.push_back(std::move(entry));
    }
}

void scan_apps_folder(std::vector<ApplicationEntry>& applications)
{
    PIDLIST_ABSOLUTE folderPidl = nullptr;
    if (FAILED(SHParseDisplayName(L"shell:AppsFolder", nullptr, &folderPidl, 0, nullptr)) || !folderPidl)
        return;

    IShellFolder* desktop = nullptr;
    IShellFolder* folder = nullptr;
    IEnumIDList* enumerator = nullptr;

    if (FAILED(SHGetDesktopFolder(&desktop)) ||
        FAILED(desktop->BindToObject(folderPidl, nullptr, IID_PPV_ARGS(&folder))) ||
        FAILED(folder->EnumObjects(nullptr, SHCONTF_FOLDERS | SHCONTF_NONFOLDERS, &enumerator))) {
        if (enumerator)
            enumerator->Release();
        if (folder)
            folder->Release();
        if (desktop)
            desktop->Release();
        CoTaskMemFree(folderPidl);
        return;
    }

    PITEMID_CHILD child = nullptr;
    while (enumerator->Next(1, &child, nullptr) == S_OK) {
        IShellItem2* item = nullptr;
        if (SUCCEEDED(SHCreateItemWithParent(folderPidl, folder, child, IID_PPV_ARGS(&item)))) {
            PWSTR rawName = nullptr;
            PWSTR rawId = nullptr;
            if (SUCCEEDED(item->GetDisplayName(SIGDN_NORMALDISPLAY, &rawName)) &&
                SUCCEEDED(item->GetString(PKEY_AppUserModel_ID, &rawId)) && rawName && rawId && *rawId) {
                ApplicationEntry entry;
                entry.id = rawId;
                entry.name = rawName;
                entry.executable = rawId;
                entry.packaged = true;
                applications.push_back(std::move(entry));
            }
            if (rawName)
                CoTaskMemFree(rawName);
            if (rawId)
                CoTaskMemFree(rawId);
            item->Release();
        }
        CoTaskMemFree(child);
        child = nullptr;
    }

    enumerator->Release();
    folder->Release();
    desktop->Release();
    CoTaskMemFree(folderPidl);
}
}

std::vector<ApplicationEntry> WindowsApplications::scan() const
{
    std::vector<ApplicationEntry> applications;

    const auto appData = environment(L"APPDATA");
    const auto programData = environment(L"ProgramData");
    if (!appData.empty())
        scan_shortcuts(std::filesystem::path(appData) / L"Microsoft/Windows/Start Menu/Programs", applications);
    if (!programData.empty())
        scan_shortcuts(std::filesystem::path(programData) / L"Microsoft/Windows/Start Menu/Programs", applications);

    scan_apps_folder(applications);
    append_bundled_applications(applications);
    return applications;
}

bool WindowsApplications::launch(const ApplicationEntry& application) const
{
    if (application.packaged) {
        IApplicationActivationManager* manager = nullptr;
        if (FAILED(CoCreateInstance(CLSID_ApplicationActivationManager, nullptr, CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&manager))))
            return false;

        DWORD processId = 0;
        const HRESULT result = manager->ActivateApplication(application.executable.c_str(),
                                                            application.arguments.empty() ? nullptr : application.arguments.c_str(),
                                                            AO_NONE, &processId);
        manager->Release();
        return SUCCEEDED(result);
    }

    SHELLEXECUTEINFOW info{};
    info.cbSize = sizeof(info);
    info.fMask = SEE_MASK_FLAG_NO_UI;
    info.lpVerb = L"open";
    info.lpFile = application.executable.c_str();
    info.lpParameters = application.arguments.empty() ? nullptr : application.arguments.c_str();
    info.lpDirectory = application.workingDirectory.empty() ? nullptr : application.workingDirectory.c_str();
    info.nShow = SW_SHOWNORMAL;
    return ShellExecuteExW(&info) != FALSE;
}
}
