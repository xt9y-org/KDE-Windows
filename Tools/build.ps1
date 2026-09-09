$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path build | Out-Null

$source = 'Source\Shell.cpp'
$output = 'build\KDEWindowsShell.exe'

function Invoke-MSVC {
    param([string]$Compiler)

    & $Compiler /nologo /std:c++20 /O2 /EHsc /DUNICODE /D_UNICODE /I Source `
        $source /Fe:$output /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib shell32.lib
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
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
        $command = '"' + $devcmd + '" -no_logo -arch=' + $arch + ' -host_arch=' + $arch +
                   ' && cl.exe /nologo /std:c++20 /O2 /EHsc /DUNICODE /D_UNICODE /I Source ' +
                   $source + ' /Fe:' + $output + ' /link /SUBSYSTEM:WINDOWS user32.lib gdi32.lib shell32.lib'
        & cmd.exe /d /s /c $command
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        exit 0
    }
}

$gpp = Get-Command g++.exe -ErrorAction SilentlyContinue
if ($gpp) {
    & $gpp.Source -std=c++20 -O2 -municode -mwindows -DUNICODE -D_UNICODE -I Source `
        $source -o $output -luser32 -lgdi32 -lshell32
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    exit 0
}

throw 'No supported C++ compiler found. Install MSVC Build Tools, clang-cl, or MinGW g++.'
