$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Get-Content (Join-Path $root 'Tools\plasma.ps1') -Raw

if (-not $script.Contains('function Find-CraftRuntimeExecutable')) {
    throw 'plasma.ps1 must resolve Craft runtime executables instead of assuming they live directly in the Craft source tree.'
}

if (-not $script.Contains('$craftRuntimeRoot = if ($env:KDEROOT) { $env:KDEROOT } else { $craftPrefix }')) {
    throw 'plasma.ps1 must stage from KDEROOT/the bootstrap prefix, not env:CraftRoot (which points at the Craft source directory).'
}

if ($script.Contains('$craftRoot = if ($env:CraftRoot) { $env:CraftRoot } else { $craftPrefix }')) {
    throw 'plasma.ps1 must not use env:CraftRoot as the runtime prefix.'
}

if (-not $script.Contains('Get-ChildItem -LiteralPath $binRoot -Filter $Name -File -Recurse')) {
    throw 'Craft runtime executable lookup must search recursively below the runtime prefix bin directory.'
}

if (-not $script.Contains('--print-files')) {
    throw 'Dolphin staging failure must report Craft install-database files for diagnostics.'
}

if (-not $script.Contains('Copy-CraftRuntimeDirectory')) {
    throw 'Dolphin staging must copy sibling runtime binaries when its executable lives in a nested Craft bin directory.'
}

if (-not $script.Contains("`$plasmaBin = Join-Path `$plasmaRoot 'bin'")) {
    throw 'plasma.ps1 must precompute the Plasma bin directory for Windows PowerShell 5.1 compatibility.'
}

if ($script.Contains("Join-Path `$plasmaRoot 'bin' `$_.Name")) {
    throw 'plasma.ps1 must not pass a third positional path component to Join-Path on Windows PowerShell 5.1.'
}
