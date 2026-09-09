$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path build\tests | Out-Null

$tests = @('ShellConfig', 'ShellPolicy', 'WindowModel', 'ApplicationModel', 'PanelLayout')

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
$clangCl = Get-Command clang-cl.exe -ErrorAction SilentlyContinue
$gpp = Get-Command g++.exe -ErrorAction SilentlyContinue

foreach ($test in $tests) {
    $source = "Tests\$test.cpp"
    $output = "build\tests\$test.exe"

    if ($cl) {
        & $cl.Source /nologo /std:c++20 /EHsc /W4 /I Source $source "/Fe:$output"
    } elseif ($clangCl) {
        & $clangCl.Source /nologo /std:c++20 /EHsc /W4 /I Source $source "/Fe:$output"
    } elseif ($gpp) {
        & $gpp.Source -std=c++20 -Wall -Wextra -pedantic -I Source $source -o $output
    } else {
        throw 'No supported compiler found for tests.'
    }

    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & ".\$output"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
