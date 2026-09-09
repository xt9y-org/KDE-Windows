$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Get-Content (Join-Path $root 'Tools\plasma.ps1') -Raw

if (-not $script.Contains('function Find-CraftRuntimeExecutable')) {
    throw 'plasma.ps1 must resolve Craft runtime executables instead of assuming they live directly in CraftRoot\bin.'
}

if (-not $script.Contains("Get-ChildItem -LiteralPath $binRoot -Filter $Name -File -Recurse")) {
    throw 'Craft runtime executable lookup must search recursively below CraftRoot\bin.'
}

if (-not $script.Contains("--print-files")) {
    throw 'Dolphin staging failure must report Craft install-database files for diagnostics.'
}

if (-not $script.Contains('Copy-CraftRuntimeDirectory')) {
    throw 'Dolphin staging must copy sibling runtime binaries when its executable lives in a nested Craft bin directory.'
}
