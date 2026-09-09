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

$installRoot = Join-Path $env:ProgramFiles 'KDE-Windows'
$installed = Join-Path $installRoot 'KDEWindowsShell.exe'
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'

New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
Copy-Item -Force $built $installed

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

$plasmaBuild = Join-Path $root 'build\Plasma'
if (Test-Path $plasmaBuild) {
    Copy-Item -Recurse -Force $plasmaBuild (Join-Path $installRoot 'Plasma')
}

Write-Host 'KDE-Windows installed. Restart Windows to apply it.'
