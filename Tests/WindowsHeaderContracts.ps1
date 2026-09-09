$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$trayHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsTraySystem.hpp') -Raw
$shortcutHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsShortcutSystem.hpp') -Raw
$iconSource = Get-Content (Join-Path $root 'Source\Plasma\ShellIconProvider.cpp') -Raw

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
