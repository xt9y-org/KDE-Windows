$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$trayHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsTraySystem.hpp') -Raw
$shortcutHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsShortcutSystem.hpp') -Raw
$iconSource = Get-Content (Join-Path $root 'Source\Plasma\ShellIconProvider.cpp') -Raw
$buildScript = Get-Content (Join-Path $root 'Tools\build.ps1') -Raw

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

if (-not $buildScript.Contains('/DNOMINMAX')) {
    throw 'The standalone Windows shell MSVC/clang-cl build must define NOMINMAX before windows.h is parsed.'
}
if (-not $buildScript.Contains('-DNOMINMAX')) {
    throw 'The standalone Windows shell MinGW build must define NOMINMAX before windows.h is parsed.'
}
if ($buildScript.Contains('/Fe')) {
    throw 'The standalone MSVC shell build must not use cl.exe /Fe; compile and link must be separate to avoid Windows PowerShell 5.1 argument corruption.'
}
if (-not $buildScript.Contains("'/c'")) {
    throw 'The standalone MSVC shell build must compile sources with /c.'
}
if (-not $buildScript.Contains('link.exe')) {
    throw 'The standalone MSVC shell build must invoke link.exe explicitly.'
}
if (-not $buildScript.Contains("'/OUT:' + `$output")) {
    throw 'The standalone MSVC link step must set the executable path with link.exe /OUT:.'
}
