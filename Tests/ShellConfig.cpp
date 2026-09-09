#include "../Source/ShellConfig.hpp"

#include <cassert>
#include <string>

int main()
{
    using namespace kde_windows;

    assert(plasma_executable(L"C:\\Program Files\\KDE-Windows") ==
           L"C:\\Program Files\\KDE-Windows\\Plasma\\bin\\plasmashell.exe");
    assert(shell_command(L"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe") ==
           L"\"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe\"");
    assert(is_our_shell(L"\"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe\"",
                        L"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe"));
    assert(is_our_shell(L"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe",
                        L"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe"));
    assert(!is_our_shell(L"explorer.exe",
                         L"C:\\Program Files\\KDE-Windows\\KDEWindowsShell.exe"));
}
