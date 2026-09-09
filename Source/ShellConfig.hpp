#pragma once

#include <string>

namespace kde_windows
{
inline std::wstring plasma_executable(const std::wstring& root)
{
    if (root.empty())
        return L"Plasma\\bin\\plasmashell.exe";

    const wchar_t last = root.back();
    return root + ((last == L'\\' || last == L'/') ? L"" : L"\\") +
           L"Plasma\\bin\\plasmashell.exe";
}

inline std::wstring shell_command(const std::wstring& executable)
{
    return L"\"" + executable + L"\"";
}

inline bool is_our_shell(const std::wstring& command, const std::wstring& executable)
{
    return command == executable || command == shell_command(executable);
}
}
