$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$script = Get-Content (Join-Path $root 'Tools\plasma.ps1') -Raw

if (-not $script.Contains('Remove-Item "Env:$name" -ErrorAction SilentlyContinue')) {
    throw 'plasma.ps1 must remove inherited make variables safely before Craft activation.'
}

if (-not $script.Contains('$ErrorActionPreference = ''Continue''')) {
    throw 'plasma.ps1 must isolate Craft activation from the caller Stop preference.'
}

if (-not $script.Contains('Set-Location $root')) {
    throw 'plasma.ps1 must restore the repository working directory after Craft activation.'
}

if (-not $script.Contains('g++.exe')) {
    throw 'plasma.ps1 must filter conflicting MinGW compiler directories before Craft activation.'
}
