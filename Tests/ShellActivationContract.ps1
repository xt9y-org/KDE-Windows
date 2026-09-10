$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$install = Get-Content (Join-Path $root 'Tools\install.ps1') -Raw
$uninstall = Get-Content (Join-Path $root 'Tools\uninstall.ps1') -Raw

$policyFragment = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'

if (-not $install.Contains('Registry::HKEY_USERS\')) {
    throw 'Installer must configure the shell policy for the concrete signed-in user SID under HKEY_USERS.'
}
if (-not $install.Contains($policyFragment)) {
    throw 'Installer must configure the Windows Custom User Interface policy path.'
}
foreach ($name in @('InstalledUserSid', 'PreviousUserPolicyShellExists', 'PreviousUserPolicyShell')) {
    if (-not $install.Contains($name)) {
        throw "Installer must persist $name for transactional uninstall/upgrade behavior."
    }
    if (-not $uninstall.Contains($name)) {
        throw "Uninstaller must consume $name to restore the previous per-user shell policy."
    }
}
if (-not $install.Contains("-Name Shell -Value `$command")) {
    throw 'Installer must write the installed KDE shell command to the per-user Custom User Interface policy.'
}
if (-not $install.Contains('Shell activation verification failed')) {
    throw 'Installer must verify the effective shell registry values before reporting success.'
}
if (-not $uninstall.Contains('Remove-ItemProperty') -or -not $uninstall.Contains('-Name Shell')) {
    throw 'Uninstaller must be able to remove a policy value that did not exist before installation.'
}
if (-not $uninstall.Contains('User shell policy restoration verification failed')) {
    throw 'Uninstaller must verify per-user shell policy restoration before deleting state/runtime.'
}
