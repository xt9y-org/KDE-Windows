$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$plasma = Get-Content (Join-Path $root 'Source\Plasma\CMakeLists.txt') -Raw
$terminalPath = Join-Path $root 'Source\Terminal\CMakeLists.txt'

if ($plasma.Contains('../Terminal/qml/Terminal.qml')) {
    throw 'Plasma CMake must not register Terminal.qml through a parent-directory path; Qt qmlcache turns it into an invalid Ninja output path.'
}

if (-not (Test-Path $terminalPath)) {
    throw 'Terminal must own its CMake/QML module in Source\Terminal.'
}

$terminal = Get-Content $terminalPath -Raw
if (-not $terminal.Contains('qml/Terminal.qml')) {
    throw 'Terminal CMake must register Terminal.qml relative to its own source directory.'
}

if (-not $plasma.Contains('add_subdirectory')) {
    throw 'Plasma CMake must add the terminal as a separate subdirectory.'
}
