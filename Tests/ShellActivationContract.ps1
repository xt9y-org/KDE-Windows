$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$install = Get-Content (Join-Path $root 'Tools\install.ps1') -Raw
$uninstall = Get-Content (Join-Path $root 'Tools\uninstall.ps1') -Raw

$policyFragment = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
$userWinlogonFragment = 'Software\Microsoft\Windows NT\CurrentVersion\Winlogon'

if (-not $install.Contains('Registry::HKEY_USERS\')) {
    throw 'Installer must configure shell activation for the concrete signed-in user SID under HKEY_USERS.'
}
if (-not $install.Contains($policyFragment)) {
    throw 'Installer must configure the Windows Custom User Interface policy path.'
}
if (-not $install.Contains($userWinlogonFragment)) {
    throw 'Installer must also cover an existing per-user Winlogon Shell override.'
}
foreach ($name in @(
    'InstalledUserSid',
    'PreviousUserPolicyShellExists', 'PreviousUserPolicyShell',
    'PreviousUserWinlogonShellExists', 'PreviousUserWinlogonShell'
)) {
    if (-not $install.Contains($name)) {
        throw "Installer must persist $name for transactional uninstall/upgrade behavior."
    }
    if (-not $uninstall.Contains($name)) {
        throw "Uninstaller must consume $name to restore the previous shell configuration."
    }
}
if (-not $install.Contains("New-ItemProperty -Path `$userPolicy -Name Shell")) {
    throw 'Installer must write the installed shell to the per-user Custom User Interface policy.'
}
if (-not $install.Contains("New-ItemProperty -Path `$userWinlogon -Name Shell")) {
    throw 'Installer must write the installed shell to the per-user Winlogon override.'
}
if (-not $install.Contains('Shell activation verification failed')) {
    throw 'Installer must verify every shell activation registry value before reporting success.'
}
if (-not $uninstall.Contains('Remove-ItemProperty') -or -not $uninstall.Contains('-Name Shell')) {
    throw 'Uninstaller must remove shell values that did not exist before installation.'
}
if (-not $uninstall.Contains('User shell policy restoration verification failed')) {
    throw 'Uninstaller must verify per-user policy restoration before deleting state/runtime.'
}
if (-not $uninstall.Contains('User Winlogon shell restoration verification failed')) {
    throw 'Uninstaller must verify per-user Winlogon restoration before deleting state/runtime.'
}
