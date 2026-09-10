$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator privileges are required. Run: sudo make uninstall'
}

$installRoot = Join-Path $env:ProgramFiles 'KDE-Windows'
$machineWinlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'
$runOnce = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'

$previousShell = 'explorer.exe'
$previousAutoRestart = 1
$installedUserSid = $null
$previousUserPolicyShellExists = $false
$previousUserPolicyShell = ''
$previousUserWinlogonShellExists = $false
$previousUserWinlogonShell = ''

if (Test-Path $state) {
    $saved = Get-ItemProperty -Path $state
    if ($saved.PreviousShell) { $previousShell = [string]$saved.PreviousShell }
    if ($null -ne $saved.PreviousAutoRestartShell) { $previousAutoRestart = [int]$saved.PreviousAutoRestartShell }
    if ($saved.InstalledUserSid) { $installedUserSid = [string]$saved.InstalledUserSid }
    if ($null -ne $saved.PreviousUserPolicyShellExists) {
        $previousUserPolicyShellExists = [bool][int]$saved.PreviousUserPolicyShellExists
    }
    if ($null -ne $saved.PreviousUserPolicyShell) {
        $previousUserPolicyShell = [string]$saved.PreviousUserPolicyShell
    }
    if ($null -ne $saved.PreviousUserWinlogonShellExists) {
        $previousUserWinlogonShellExists = [bool][int]$saved.PreviousUserWinlogonShellExists
    }
    if ($null -ne $saved.PreviousUserWinlogonShell) {
        $previousUserWinlogonShell = [string]$saved.PreviousUserWinlogonShell
    }
}

if ([string]::IsNullOrWhiteSpace($previousShell)) {
    $previousShell = 'explorer.exe'
}

$userRoot = if ($installedUserSid) { 'Registry::HKEY_USERS\' + $installedUserSid } else { $null }
$userPolicy = if ($userRoot) { $userRoot + '\Software\Microsoft\Windows\CurrentVersion\Policies\System' } else { $null }
$userWinlogon = if ($userRoot) { $userRoot + '\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' } else { $null }

function Restore-ShellValue([string]$path, [bool]$existed, [string]$value) {
    if (-not $path) { return }
    if ($existed) {
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -Path $path -Name Shell -PropertyType String -Value $value -Force | Out-Null
    }
    elseif (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name Shell -ErrorAction SilentlyContinue
    }
}

function Test-ShellValueRestored([string]$path, [bool]$existed, [string]$value) {
    if (-not $path) { return $true }
    if ($existed) {
        try {
            return [string](Get-ItemProperty -Path $path -Name Shell -ErrorAction Stop).Shell -eq $value
        }
        catch {
            return $false
        }
    }

    try {
        Get-ItemProperty -Path $path -Name Shell -ErrorAction Stop | Out-Null
        return $false
    }
    catch {
        return $true
    }
}

# Restoration is the critical operation. Do not delete state/runtime until every
# shell-selection path is restored to its pre-install value.
Set-ItemProperty -Path $machineWinlogon -Name Shell -Value $previousShell
Set-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -Type DWord -Value $previousAutoRestart
Restore-ShellValue $userPolicy $previousUserPolicyShellExists $previousUserPolicyShell
Restore-ShellValue $userWinlogon $previousUserWinlogonShellExists $previousUserWinlogonShell

$restoredShell = [string](Get-ItemProperty -Path $machineWinlogon -Name Shell -ErrorAction Stop).Shell
$restoredAutoRestart = [int](Get-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -ErrorAction Stop).AutoRestartShell
if ($restoredShell -ne $previousShell -or $restoredAutoRestart -ne $previousAutoRestart) {
    throw 'Windows shell restoration verification failed; KDE-Windows files were left untouched.'
}
if (-not (Test-ShellValueRestored $userPolicy $previousUserPolicyShellExists $previousUserPolicyShell)) {
    throw 'User shell policy restoration verification failed; KDE-Windows files were left untouched.'
}
if (-not (Test-ShellValueRestored $userWinlogon $previousUserWinlogonShellExists $previousUserWinlogonShell)) {
    throw 'User Winlogon shell restoration verification failed; KDE-Windows files were left untouched.'
}

if (Test-Path $state) {
    Remove-Item -Recurse -Force $state
}

if (Test-Path $runOnce) {
    Remove-ItemProperty -Path $runOnce -Name KDEWindowsCleanup -ErrorAction SilentlyContinue
}

if (Test-Path $installRoot) {
    try {
        Remove-Item -Recurse -Force $installRoot -ErrorAction Stop
    }
    catch {
        New-Item -Path $runOnce -Force | Out-Null
        $cleanup = 'cmd.exe /d /c timeout /t 3 /nobreak >nul & rd /s /q "' + $installRoot + '"'
        New-ItemProperty -Path $runOnce -Name KDEWindowsCleanup -PropertyType String -Value $cleanup -Force | Out-Null
    }
}

Write-Host 'KDE-Windows uninstalled. Machine and per-user shell settings were restored.'
Write-Host 'Restart Windows to return to the previous shell.'
