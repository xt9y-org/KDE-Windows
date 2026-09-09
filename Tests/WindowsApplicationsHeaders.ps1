$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$source = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsApplications.cpp') -Raw

$wtypes = $source.IndexOf('#include <wtypes.h>')
$propkey = $source.IndexOf('#include <propkey.h>')
if ($wtypes -lt 0 -or $propkey -lt 0 -or $wtypes -gt $propkey) {
    throw 'WindowsApplications.cpp must include wtypes.h before propkey.h so PROPERTYKEY is defined under WIN32_LEAN_AND_MEAN.'
}

if (-not $source.Contains('#ifndef WIN32_LEAN_AND_MEAN')) {
    throw 'WindowsApplications.cpp must guard WIN32_LEAN_AND_MEAN before defining it.'
}
