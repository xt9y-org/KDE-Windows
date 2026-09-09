$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$trayHeader = Get-Content (Join-Path $root 'Source\Platform\Windows\WindowsTraySystem.hpp') -Raw

if (-not $trayHeader.Contains('#include <shellapi.h>')) {
    throw 'WindowsTraySystem.hpp must include shellapi.h because it exposes NOTIFYICONDATAW in its interface.'
}

if (-not $trayHeader.Contains('#ifndef WIN32_LEAN_AND_MEAN')) {
    throw 'WindowsTraySystem.hpp must guard WIN32_LEAN_AND_MEAN before defining it.'
}

if (-not $trayHeader.Contains('#ifndef NOMINMAX')) {
    throw 'WindowsTraySystem.hpp must guard NOMINMAX before defining it.'
}
