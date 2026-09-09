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

function Resolve-MSVCLinker {
    param([string]$Compiler)

    $compilerDir = Split-Path -Parent $Compiler
    $compilerName = [System.IO.Path]::GetFileName($Compiler)
    $preferred = if ($compilerName -ieq 'clang-cl.exe') { @('lld-link.exe', 'link.exe') } else { @('link.exe', 'lld-link.exe') }

    foreach ($name in $preferred) {
        $sibling = Join-Path $compilerDir $name
        if (Test-Path $sibling) { return $sibling }
    }
    foreach ($name in $preferred) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }

    throw "No linker found for $Compiler."
}

function Invoke-MSVC {
    param([string]$Compiler)

    $objects = @()
    foreach ($source in $sources) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($source)
        $object = Join-Path $objectDir ($base + '.obj')
        $compileResponse = Join-Path $objectDir ($base + '.compile.rsp')
        $compileOptions = @(
            '/nologo',
            '/std:c++20',
            '/O2',
            '/EHsc',
            '/DUNICODE',
            '/D_UNICODE',
            '/DNOMINMAX',
            '/I',
            '"Source"',
            '/c',
            '"' + $source + '"',
            '/Fo"' + $object + '"'
        )
        Set-Content -LiteralPath $compileResponse -Encoding ASCII -Value $compileOptions
        $compileResponseArg = '@' + $compileResponse
        & $Compiler $compileResponseArg
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $objects += $object
    }

    $linker = Resolve-MSVCLinker $Compiler
    $linkResponse = Join-Path $objectDir 'link.rsp'
    $linkOptions = @(
        '/nologo',
        '/SUBSYSTEM:WINDOWS',
        '/OUT:"' + $output + '"'
    ) + ($objects | ForEach-Object { '"' + $_ + '"' }) + $msvcLibraries
    Set-Content -LiteralPath $linkResponse -Encoding ASCII -Value $linkOptions
    $linkResponseArg = '@' + $linkResponse
    & $linker $linkResponseArg
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
        $objects = @()
        $compileCommands = @()

        foreach ($source in $sources) {
            $object = Join-Path $objectDir ([System.IO.Path]::GetFileNameWithoutExtension($source) + '.obj')
            $objects += $object
            $compileCommands += 'cl.exe /nologo /std:c++20 /O2 /EHsc /DUNICODE /D_UNICODE /DNOMINMAX /I Source /c "' + $source + '" /Fo"' + $object + '"'
        }

        $quotedObjects = ($objects | ForEach-Object { '"' + $_ + '"' }) -join ' '
        $libraries = $msvcLibraries -join ' '
        $linkCommand = 'link.exe /nologo /SUBSYSTEM:WINDOWS /OUT:"' + $output + '" ' + $quotedObjects + ' ' + $libraries
        $command = '"' + $devcmd + '" -no_logo -arch=' + $arch + ' -host_arch=' + $arch +
                   ' && ' + (($compileCommands + $linkCommand) -join ' && ')

        & cmd.exe /d /s /c $command
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
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
