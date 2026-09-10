$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$plasmaScript = Join-Path $root 'Tools\plasma.ps1'
& $plasmaScript
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$required = @(
    (Join-Path $root 'build\KDEWindowsShell.exe'),
    (Join-Path $root 'build\Plasma\bin\plasmashell.exe'),
    (Join-Path $root 'build\Plasma\bin\konsole.exe'),
    (Join-Path $root 'build\Plasma\bin\dolphin.exe')
)

foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Build completed without required runtime: $path"
    }
}

Write-Host 'KDE-Windows build complete.'
