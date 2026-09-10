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
$installedUserSid = $null
$previousUserPolicyShellExists = $false
$previousUserPolicyShell = ''

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
}

if ([string]::IsNullOrWhiteSpace($previousShell)) {
    $previousShell = 'explorer.exe'
}

$userPolicy = if ($installedUserSid) {
    'Registry::HKEY_USERS\' + $installedUserSid + '\Software\Microsoft\Windows\CurrentVersion\Policies\System'
} else {
    $null
}

# Restoration is the critical operation. Do not delete state/runtime until both
# the machine shell and the per-user Custom User Interface policy are restored.
Set-ItemProperty -Path $winlogon -Name Shell -Value $previousShell
Set-ItemProperty -Path $winlogon -Name AutoRestartShell -Type DWord -Value $previousAutoRestart

if ($userPolicy) {
    if ($previousUserPolicyShellExists) {
        New-Item -Path $userPolicy -Force | Out-Null
        New-ItemProperty -Path $userPolicy -Name Shell -PropertyType String -Value $previousUserPolicyShell -Force | Out-Null
    }
    elseif (Test-Path $userPolicy) {
        Remove-ItemProperty -Path $userPolicy -Name Shell -ErrorAction SilentlyContinue
    }
}

$restoredShell = [string](Get-ItemProperty -Path $winlogon -Name Shell -ErrorAction Stop).Shell
$restoredAutoRestart = [int](Get-ItemProperty -Path $winlogon -Name AutoRestartShell -ErrorAction Stop).AutoRestartShell
if ($restoredShell -ne $previousShell -or $restoredAutoRestart -ne $previousAutoRestart) {
    throw 'Windows shell restoration verification failed; KDE-Windows files were left untouched.'
}

if ($userPolicy) {
    if ($previousUserPolicyShellExists) {
        $restoredUserShell = [string](Get-ItemProperty -Path $userPolicy -Name Shell -ErrorAction Stop).Shell
        if ($restoredUserShell -ne $previousUserPolicyShell) {
            throw 'User shell policy restoration verification failed; KDE-Windows files were left untouched.'
        }
    }
    else {
        $userShellStillExists = $false
        try {
            Get-ItemProperty -Path $userPolicy -Name Shell -ErrorAction Stop | Out-Null
            $userShellStillExists = $true
        }
        catch {
            $userShellStillExists = $false
        }
        if ($userShellStillExists) {
            throw 'User shell policy restoration verification failed; KDE-Windows files were left untouched.'
        }
    }
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
