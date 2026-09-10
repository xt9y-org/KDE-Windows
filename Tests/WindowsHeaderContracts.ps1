$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$trayHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsTraySystem.hpp') -Raw
$shortcutHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsShortcutSystem.hpp') -Raw
$iconSource = Get-Content (Join-Path $root 'Source\Plasma\ShellIconProvider.cpp') -Raw
$buildScript = Get-Content (Join-Path $root 'Tools\build.ps1') -Raw
$plasmaScript = Get-Content (Join-Path $root 'Tools\plasma.ps1') -Raw
$cmake = Get-Content (Join-Path $root 'Source\Plasma\CMakeLists.txt') -Raw

if (-not $trayHeader.Contains('#include <shellapi.h>')) {
    throw 'WindowsTraySystem.hpp must include shellapi.h because it exposes NOTIFYICONDATAW in its interface.'
}

foreach ($source in @(
    @{ Name = 'WindowsTraySystem.hpp'; Content = $trayHeader },
    @{ Name = 'WindowsShortcutSystem.hpp'; Content = $shortcutHeader },
    @{ Name = 'ShellIconProvider.cpp'; Content = $iconSource }
)) {
    if (-not $source.Content.Contains('#ifndef WIN32_LEAN_AND_MEAN')) {
        throw "$($source.Name) must guard WIN32_LEAN_AND_MEAN before defining it."
    }
    if (-not $source.Content.Contains('#ifndef NOMINMAX')) {
        throw "$($source.Name) must guard NOMINMAX before defining it."
    }
}

if (-not $cmake.Contains('add_executable(KDEWindowsShell')) {
    throw 'The fallback Windows shell must be built by CMake with the Plasma host build.'
}
if (-not $cmake.Contains('../Shell.cpp')) {
    throw 'The CMake fallback shell target must include Source/Shell.cpp.'
}
if (-not $cmake.Contains('target_compile_definitions(KDEWindowsShell PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)')) {
    throw 'The fallback shell CMake target must define the Windows compile contract.'
}
if (-not $cmake.Contains('advapi32')) {
    throw 'The fallback shell must link Advapi32 for token/privilege APIs.'
}
if (-not $cmake.Contains('RUNTIME_OUTPUT_DIRECTORY "${KDE_WINDOWS_SHELL_ROOT}"')) {
    throw 'The fallback shell CMake target must emit directly into the installer build root.'
}
if (-not $plasmaScript.Contains('"-DKDE_WINDOWS_SHELL_ROOT=$buildRoot"')) {
    throw 'plasma.ps1 must pass the fallback shell output root into CMake.'
}
if (-not $plasmaScript.Contains('KDEWindowsShell.exe')) {
    throw 'plasma.ps1 must validate the CMake-built fallback shell output.'
}

foreach ($forbidden in @('cl.exe', 'clang-cl.exe', 'g++.exe', 'link.exe', '/Fo', '/Fe', '/OUT:')) {
    if ($buildScript.Contains($forbidden)) {
        throw "Tools/build.ps1 must not maintain a second manual compiler/linker path: found $forbidden"
    }
}
if (-not $buildScript.Contains("Tools\plasma.ps1")) {
    throw 'Tools/build.ps1 must delegate the Windows build to the unified CMake/Plasma build.'
}
