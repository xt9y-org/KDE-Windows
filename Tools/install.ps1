$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator privileges are required. Run: sudo make install'
}

$root = Split-Path -Parent $PSScriptRoot
$built = Join-Path $root 'build\KDEWindowsShell.exe'
if (-not (Test-Path $built)) {
    throw 'Build is missing. Run: make'
}

$plasmaBuild = Join-Path $root 'build\Plasma'
$plasmaExe = Join-Path $plasmaBuild 'bin\plasmashell.exe'
if (-not (Test-Path $plasmaExe)) {
    throw 'Plasma runtime is missing. Run: make'
}

$installRoot = Join-Path $env:ProgramFiles 'KDE-Windows'
$installed = Join-Path $installRoot 'KDEWindowsShell.exe'
$plasmaInstall = Join-Path $installRoot 'Plasma'
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'

New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
Copy-Item -Force $built $installed

if (Test-Path $plasmaInstall) {
    Remove-Item -Recurse -Force $plasmaInstall
}
New-Item -ItemType Directory -Force -Path $plasmaInstall | Out-Null
Copy-Item -Recurse -Force (Join-Path $plasmaBuild '*') $plasmaInstall

$current = (Get-ItemProperty -Path $winlogon -Name Shell -ErrorAction SilentlyContinue).Shell
if (-not $current) { $current = 'explorer.exe' }
$currentAutoRestart = (Get-ItemProperty -Path $winlogon -Name AutoRestartShell -ErrorAction SilentlyContinue).AutoRestartShell
if ($null -eq $currentAutoRestart) { $currentAutoRestart = 1 }

if (-not (Test-Path $state)) {
    New-Item -Path $state -Force | Out-Null
    New-ItemProperty -Path $state -Name PreviousShell -PropertyType String -Value $current -Force | Out-Null
    New-ItemProperty -Path $state -Name PreviousAutoRestartShell -PropertyType DWord -Value ([int]$currentAutoRestart) -Force | Out-Null
}

$command = '"' + $installed + '"'
Set-ItemProperty -Path $winlogon -Name Shell -Value $command
Set-ItemProperty -Path $winlogon -Name AutoRestartShell -Type DWord -Value 1

Write-Host 'KDE-Windows installed. Restart Windows to apply it.'
