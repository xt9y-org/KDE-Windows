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
if (-not $buildScript.Contains("'/c'")) {
    throw 'The standalone MSVC shell build must compile sources with /c.'
}
if (-not $buildScript.Contains('link.exe')) {
    throw 'The standalone MSVC shell build must invoke link.exe explicitly.'
}
if (-not $buildScript.Contains('Set-Content -LiteralPath $compileResponse -Encoding ASCII')) {
    throw 'Direct MSVC compilation must use a response file so Windows PowerShell 5.1 cannot split /Fo from its path.'
}
if (-not $buildScript.Contains("`$compileResponseArg = '@' + `$compileResponse")) {
    throw 'Direct MSVC compilation must pass exactly one @response-file argument to cl.exe/clang-cl.exe.'
}
if (-not $buildScript.Contains('Set-Content -LiteralPath $linkResponse -Encoding ASCII')) {
    throw 'Direct MSVC linking must use a response file so Windows PowerShell 5.1 cannot split /OUT: from its path.'
}
if (-not $buildScript.Contains("`$linkResponseArg = '@' + `$linkResponse")) {
    throw 'Direct MSVC linking must pass exactly one @response-file argument to link.exe/lld-link.exe.'
}
if ($buildScript.Contains('& $Compiler @compileArgs')) {
    throw 'Do not pass MSVC compile options as a PowerShell argument array on Windows PowerShell 5.1.'
}
if ($buildScript.Contains('& $linker @linkArgs')) {
    throw 'Do not pass MSVC linker options as a PowerShell argument array on Windows PowerShell 5.1.'
}
if (-not $buildScript.Contains("'/ISource'")) {
    throw 'MSVC response files must keep /I and its include directory in one plain token.'
}
if (-not $buildScript.Contains("'/Fo' + `$object")) {
    throw 'MSVC response files must keep /Fo and its object path in one plain token.'
}
if (-not $buildScript.Contains("'/OUT:' + `$output")) {
    throw 'MSVC linker response files must keep /OUT: and the executable path in one plain token.'
}
if ($buildScript.Contains("'/Fo\"' + `$object")) {
    throw 'Do not write C-style escaped quotes into an MSVC response file; PowerShell treats backslash as a literal character.'
}
if ($buildScript.Contains("'/OUT:\"' + `$output")) {
    throw 'Do not write C-style escaped quotes into an MSVC linker response file.'
}
