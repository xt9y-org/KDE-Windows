$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$buildRoot = Join-Path $root 'build'
$craftPrefix = Join-Path $buildRoot 'CraftRoot'
$craftEnv = Join-Path $craftPrefix 'craft\craftenv.ps1'
$plasmaBuild = Join-Path $buildRoot 'plasma-host'
$plasmaRoot = Join-Path $buildRoot 'Plasma'
$bootstrap = Join-Path $buildRoot 'CraftBootstrap.py'

New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $plasmaRoot | Out-Null

function Find-Python {
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($python) { return $python.Source }

    $py = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($py) { return $py.Source }

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) { throw 'Python 3 is required and winget is unavailable to install it automatically.' }

    Write-Host 'Installing Python for the private KDE build environment...'
    & $winget.Source install --id Python.Python.3.13 --exact --scope user --silent `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw 'Automatic Python installation failed.' }

    $candidate = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs\Python') -Filter python.exe -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    throw 'Python was installed but python.exe could not be located.'
}

function Ensure-MSVC {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($installation) { return }
    }

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) { throw 'MSVC Build Tools are required and winget is unavailable to install them automatically.' }

    Write-Host 'Installing Visual Studio C++ Build Tools for KDE/Qt...'
    & $winget.Source install --id Microsoft.VisualStudio.2022.BuildTools --exact --silent `
        --accept-package-agreements --accept-source-agreements `
        --override '--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
    if ($LASTEXITCODE -ne 0) { throw 'Automatic Visual Studio Build Tools installation failed.' }
}

function Invoke-CraftPackage {
    param([string]$Package)

    Write-Host "  -> Craft $Package"
    & craft --use-cache $Package
    if ($LASTEXITCODE -ne 0) {
        & craft $Package
        if ($LASTEXITCODE -ne 0) { throw "Craft failed for $Package" }
    }
}

if (-not (Test-Path $craftEnv)) {
    Ensure-MSVC
    $python = Find-Python
    Write-Host 'Bootstrapping private KDE Craft runtime...'
    Invoke-WebRequest -UseBasicParsing `
        'https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py' `
        -OutFile $bootstrap

    & $python $bootstrap --prefix $craftPrefix --use-defaults
    if ($LASTEXITCODE -ne 0) { throw 'KDE Craft bootstrap failed.' }
}

. $craftEnv

Invoke-CraftPackage 'libs/qt/qtbase'
Invoke-CraftPackage 'libs/qt/qtdeclarative'
Invoke-CraftPackage 'libs/qt/qtsvg'

$cmake = Get-Command cmake.exe -ErrorAction SilentlyContinue
if (-not $cmake) { $cmake = Get-Command cmake -ErrorAction SilentlyContinue }
if (-not $cmake) { throw 'CMake was not provided by the Craft environment.' }

$ninja = Get-Command ninja.exe -ErrorAction SilentlyContinue
if (-not $ninja) { $ninja = Get-Command ninja -ErrorAction SilentlyContinue }
if (-not $ninja) {
    Invoke-CraftPackage 'dev-utils/ninja'
    $ninja = Get-Command ninja.exe -ErrorAction SilentlyContinue
    if (-not $ninja) { throw 'Ninja was not provided by the Craft environment.' }
}

& $cmake.Source -S Source\Plasma -B $plasmaBuild -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    "-DKDE_WINDOWS_PLASMA_ROOT=$plasmaRoot"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $cmake.Source --build $plasmaBuild --config Release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$plasmaExe = Join-Path $plasmaRoot 'bin\plasmashell.exe'
if (-not (Test-Path $plasmaExe)) {
    throw "Plasma shell build did not produce $plasmaExe"
}

$deploy = Get-Command windeployqt.exe -ErrorAction SilentlyContinue
if (-not $deploy) { $deploy = Get-Command windeployqt -ErrorAction SilentlyContinue }
if (-not $deploy) { throw 'windeployqt was not provided by the Craft Qt runtime.' }

& $deploy.Source --release --qmldir (Join-Path $root 'Source\Plasma\qml') $plasmaExe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Plasma Windows runtime: $plasmaExe"
