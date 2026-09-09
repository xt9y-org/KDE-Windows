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
    throw 'The standalone MSVC shell build must not use cl.exe /Fe; compile and link must be separate.'
}
if (-not $buildScript.Contains('/c')) {
    throw 'The standalone MSVC shell build must compile sources with /c.'
}
if (-not $buildScript.Contains('link.exe')) {
    throw 'The standalone MSVC shell build must invoke link.exe explicitly.'
}
if ($buildScript.Contains('.compile.rsp') -or $buildScript.Contains('link.rsp')) {
    throw 'Do not route MSVC shell options through generated response files; use cmd.exe native parsing.'
}
if ($buildScript.Contains('& $Compiler') -or $buildScript.Contains('& $linker')) {
    throw 'Do not invoke cl.exe/link.exe directly through Windows PowerShell 5.1 argument reconstruction.'
}
if (-not $buildScript.Contains('& cmd.exe /d /s /c $compileCommand')) {
    throw 'MSVC source compilation must be executed through cmd.exe as one native command line.'
}
if (-not $buildScript.Contains('& cmd.exe /d /s /c $linkCommand')) {
    throw 'MSVC linking must be executed through cmd.exe as one native command line.'
}
if (-not $buildScript.Contains("Write-Host 'MSVC shell build: cmd.exe compile/link'")) {
    throw 'The shell build must print its MSVC execution path so stale local scripts are immediately visible.'
}
