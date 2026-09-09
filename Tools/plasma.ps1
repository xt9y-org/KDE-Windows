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

function Copy-DirectoryContents {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path $Source)) { return }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Recurse -Force (Join-Path $Source '*') $Destination
}

function Find-CraftRuntimeExecutable {
    param([string]$CraftRoot, [string]$Name)

    $binRoot = Join-Path $CraftRoot 'bin'
    $direct = Join-Path $binRoot $Name
    if (Test-Path -LiteralPath $direct -PathType Leaf) {
        return (Resolve-Path -LiteralPath $direct).Path
    }
    if (-not (Test-Path -LiteralPath $binRoot -PathType Container)) {
        return $null
    }

    $candidate = Get-ChildItem -LiteralPath $binRoot -Filter $Name -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    return $null
}

function Copy-CraftRuntimeDirectory {
    param([string]$Executable, [string]$Destination)

    $sourceDirectory = Split-Path -Parent $Executable
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Get-ChildItem -LiteralPath $sourceDirectory -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -ieq '.exe' -or $_.Extension -ieq '.dll' } |
        ForEach-Object { Copy-Item -Force $_.FullName $Destination }
}

function Remove-CraftEnvironmentConflicts {
    foreach ($name in @('MAKEFLAGS', 'MFLAGS', 'MAKE', 'NMAKEFLAGS')) {
        Remove-Item "Env:$name" -ErrorAction SilentlyContinue
    }

    if (-not $env:PATH) { return }

    $cleanPath = foreach ($pathEntry in ($env:PATH -split ';')) {
        $trimmed = $pathEntry.Trim().Trim('"')
        if (-not $trimmed) { continue }

        $conflictingCompiler = $false
        try {
            $conflictingCompiler =
                (Test-Path -LiteralPath (Join-Path $trimmed 'gcc.exe')) -or
                (Test-Path -LiteralPath (Join-Path $trimmed 'g++.exe')) -or
                (Test-Path -LiteralPath (Join-Path $trimmed 'cpp.exe'))
        }
        catch {
            $conflictingCompiler = $false
        }

        if ($conflictingCompiler) {
            Write-Host "Temporarily excluding conflicting compiler path from Craft: $trimmed"
            continue
        }

        $pathEntry
    }

    $env:PATH = $cleanPath -join ';'
}

function Import-CraftEnvironment {
    Remove-CraftEnvironmentConflicts

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        # craftenv.ps1 intentionally removes the inherited environment. Some empty
        # variables reported by the Env provider can disappear before Remove-Item
        # reaches them; Craft expects those to remain non-terminating errors.
        $ErrorActionPreference = 'Continue'
        . $craftEnv
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }

    # craftenv.ps1 changes location to KDEROOT. The rest of this script uses repo-relative paths.
    Set-Location $root

    if (-not (Get-Command craft -ErrorAction SilentlyContinue)) {
        throw 'KDE Craft environment activation did not define the craft command.'
    }
    if (-not $env:CraftRoot) {
        throw 'KDE Craft environment activation did not set CraftRoot.'
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

Import-CraftEnvironment

Invoke-CraftPackage 'libs/qt/qtbase'
Invoke-CraftPackage 'libs/qt/qtdeclarative'
Invoke-CraftPackage 'libs/qt/qtsvg'
Invoke-CraftPackage 'kde/frameworks/tier1/breeze-icons'
Invoke-CraftPackage 'kde/frameworks/tier3/qqc2-desktop-style'
Invoke-CraftPackage 'kde/plasma/breeze'
Invoke-CraftPackage 'kde/applications/dolphin'

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
$konsoleExe = Join-Path $plasmaRoot 'bin\konsole.exe'
if (-not (Test-Path $plasmaExe)) {
    throw "Plasma shell build did not produce $plasmaExe"
}
if (-not (Test-Path $konsoleExe)) {
    throw "Konsole frontend build did not produce $konsoleExe"
}

$deploy = Get-Command windeployqt.exe -ErrorAction SilentlyContinue
if (-not $deploy) { $deploy = Get-Command windeployqt -ErrorAction SilentlyContinue }
if (-not $deploy) { throw 'windeployqt was not provided by the Craft Qt runtime.' }

& $deploy.Source --release --qmldir (Join-Path $root 'Source\Plasma\qml') $plasmaExe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $deploy.Source --release --qmldir (Join-Path $root 'Source\Terminal\qml') $konsoleExe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$craftRoot = if ($env:CraftRoot) { $env:CraftRoot } else { $craftPrefix }
$craftBin = Join-Path $craftRoot 'bin'
Copy-DirectoryContents (Join-Path $craftRoot 'qml') (Join-Path $plasmaRoot 'qml')
Copy-DirectoryContents (Join-Path $craftRoot 'plugins') (Join-Path $plasmaRoot 'plugins')
Copy-DirectoryContents (Join-Path $craftRoot 'bin\data') (Join-Path $plasmaRoot 'bin\data')
Copy-DirectoryContents (Join-Path $craftRoot 'share') (Join-Path $plasmaRoot 'share')
Copy-DirectoryContents (Join-Path $craftRoot 'libexec') (Join-Path $plasmaRoot 'libexec')

Get-ChildItem $craftBin -Filter '*.dll' -File -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item -Force $_.FullName (Join-Path $plasmaRoot 'bin') }
Get-ChildItem $craftBin -Filter '*.exe' -File -ErrorAction SilentlyContinue |
    ForEach-Object {
        $destination = Join-Path $plasmaRoot 'bin' $_.Name
        if (-not (Test-Path $destination)) { Copy-Item -Force $_.FullName $destination }
    }

$dolphinSource = Find-CraftRuntimeExecutable -CraftRoot $craftRoot -Name 'dolphin.exe'
if (-not $dolphinSource) {
    Write-Host "Craft runtime root: $craftRoot"
    Write-Host 'Craft install database entries for Dolphin:'
    & craft -q --ci-mode --print-files kde/applications/dolphin | Out-Host
    throw "Dolphin is registered as installed by Craft, but dolphin.exe was not found below $craftBin."
}

Copy-CraftRuntimeDirectory -Executable $dolphinSource -Destination (Join-Path $plasmaRoot 'bin')
Copy-Item -Force $dolphinSource (Join-Path $plasmaRoot 'bin\dolphin.exe')

if (-not (Test-Path (Join-Path $plasmaRoot 'bin\dolphin.exe'))) {
    throw 'Dolphin was not staged into the Plasma runtime.'
}
if (-not (Test-Path $konsoleExe)) {
    throw 'Konsole frontend was overwritten or removed during runtime staging.'
}

Write-Host "Plasma Windows runtime: $plasmaExe"
Write-Host "Konsole Windows frontend: $konsoleExe"
Write-Host "Dolphin Windows runtime: $(Join-Path $plasmaRoot 'bin\dolphin.exe')"
