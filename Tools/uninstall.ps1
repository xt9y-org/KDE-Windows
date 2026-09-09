$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator privileges are required. Run: sudo make uninstall'
}

$installRoot = Join-Path $env:ProgramFiles 'KDE-Windows'
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'
$runOnce = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'

$previousShell = 'explorer.exe'
$previousAutoRestart = 1
if (Test-Path $state) {
    $saved = Get-ItemProperty -Path $state
    if ($saved.PreviousShell) { $previousShell = $saved.PreviousShell }
    if ($null -ne $saved.PreviousAutoRestartShell) { $previousAutoRestart = [int]$saved.PreviousAutoRestartShell }
}

Set-ItemProperty -Path $winlogon -Name Shell -Value $previousShell
Set-ItemProperty -Path $winlogon -Name AutoRestartShell -Type DWord -Value $previousAutoRestart

if (Test-Path $state) {
    Remove-Item -Recurse -Force $state
}

if (Test-Path $installRoot) {
    try {
        Remove-Item -Recurse -Force $installRoot -ErrorAction Stop
    }
    catch {
        New-Item -Path $runOnce -Force | Out-Null
        $cleanup = 'cmd.exe /d /c rd /s /q "' + $installRoot + '"'
        New-ItemProperty -Path $runOnce -Name KDEWindowsCleanup -PropertyType String -Value $cleanup -Force | Out-Null
    }
}

Write-Host 'KDE-Windows uninstalled. Restart Windows to return to the previous shell.'
