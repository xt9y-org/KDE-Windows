$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path build | Out-Null

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
if ($cl) {
    & $cl.Source /nologo /std:c++20 /EHsc /I Source Tests\ShellConfig.cpp /Fe:build\ShellConfigTests.exe
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    $gpp = Get-Command g++.exe -ErrorAction SilentlyContinue
    if (-not $gpp) { throw 'No supported compiler found for tests.' }
    & $gpp.Source -std=c++20 -I Source Tests\ShellConfig.cpp -o build\ShellConfigTests.exe
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

& .\build\ShellConfigTests.exe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
