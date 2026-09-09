$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path build | Out-Null

& (Join-Path $PSScriptRoot 'plasma.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$sources = @(
    'Source\Shell.cpp',
    'Source\Platform\Windows\WindowsWindowSystem.cpp',
    'Source\Platform\Windows\WindowsApplications.cpp'
)
$output = 'build\KDEWindowsShell.exe'
$objectDir = 'build\shell-obj'
$msvcLibraries = @('user32.lib', 'gdi32.lib', 'shell32.lib', 'dwmapi.lib', 'ole32.lib', 'propsys.lib', 'uuid.lib')
New-Item -ItemType Directory -Force -Path $objectDir | Out-Null

function Resolve-MSVCLinkerName {
    param([string]$Compiler)

    $compilerDir = Split-Path -Parent $Compiler
    $compilerName = [System.IO.Path]::GetFileName($Compiler)
    $preferred = if ($compilerName -ieq 'clang-cl.exe') { @('lld-link.exe', 'link.exe') } else { @('link.exe', 'lld-link.exe') }

    foreach ($name in $preferred) {
        if (Test-Path (Join-Path $compilerDir $name)) { return $name }
    }
    foreach ($name in $preferred) {
        if (Get-Command $name -ErrorAction SilentlyContinue) { return $name }
    }

    throw "No linker found for $Compiler."
}

function Invoke-MSVC {
    param([string]$Compiler)

    $compilerName = [System.IO.Path]::GetFileName($Compiler)
    $linkerName = Resolve-MSVCLinkerName $Compiler
    $objects = @()

    Write-Host 'MSVC shell build: cmd.exe compile/link'

    foreach ($source in $sources) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($source)
        $object = Join-Path $objectDir ($base + '.obj')
        $compileCommand = $compilerName +
            ' /nologo /std:c++20 /O2 /EHsc /DUNICODE /D_UNICODE /DNOMINMAX /ISource /c ' +
            $source + ' /Fo' + $object

        & cmd.exe /d /s /c $compileCommand
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (-not (Test-Path $object)) { throw "Compiler did not produce $object." }
        $objects += $object
    }

    $linkCommand = $linkerName +
        ' /nologo /SUBSYSTEM:WINDOWS /OUT:' + $output + ' ' +
        ($objects -join ' ') + ' ' + ($msvcLibraries -join ' ')

    & cmd.exe /d /s /c $linkCommand
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not (Test-Path $output)) { throw "Linker did not produce $output." }
}

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
if ($cl) {
    Invoke-MSVC $cl.Source
    exit 0
}

$clangCl = Get-Command clang-cl.exe -ErrorAction SilentlyContinue
if ($clangCl) {
    Invoke-MSVC $clangCl.Source
    exit 0
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vs) {
        $devcmd = Join-Path $vs 'Common7\Tools\VsDevCmd.bat'
        $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
        $objects = @()
        $compileCommands = @()

        foreach ($source in $sources) {
            $object = Join-Path $objectDir ([System.IO.Path]::GetFileNameWithoutExtension($source) + '.obj')
            $objects += $object
            $compileCommands += 'cl.exe /nologo /std:c++20 /O2 /EHsc /DUNICODE /D_UNICODE /DNOMINMAX /ISource /c ' + $source + ' /Fo' + $object
        }

        $linkCommand = 'link.exe /nologo /SUBSYSTEM:WINDOWS /OUT:' + $output + ' ' + ($objects -join ' ') + ' ' + ($msvcLibraries -join ' ')
        $command = '"' + $devcmd + '" -no_logo -arch=' + $arch + ' -host_arch=' + $arch +
                   ' && echo MSVC shell build: cmd.exe compile/link && ' + (($compileCommands + $linkCommand) -join ' && ')

        & cmd.exe /d /s /c $command
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (-not (Test-Path $output)) { throw "Linker did not produce $output." }
        exit 0
    }
}

$gpp = Get-Command g++.exe -ErrorAction SilentlyContinue
if ($gpp) {
    & $gpp.Source -std=c++20 -O2 -municode -mwindows -DUNICODE -D_UNICODE -DNOMINMAX -I Source @sources `
        -o $output -luser32 -lgdi32 -lshell32 -ldwmapi -lole32 -lpropsys -luuid
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    exit 0
}

throw 'No supported C++ compiler found. Install MSVC Build Tools, clang-cl, or MinGW g++.'
