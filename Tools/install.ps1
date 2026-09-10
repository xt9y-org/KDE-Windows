$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Administrator privileges are required. Run: sudo make install'
}

$root = Split-Path -Parent $PSScriptRoot
$built = Join-Path $root 'build\KDEWindowsShell.exe'
$plasmaBuild = Join-Path $root 'build\Plasma'
$requiredRuntime = @(
    (Join-Path $plasmaBuild 'bin\plasmashell.exe'),
    (Join-Path $plasmaBuild 'bin\dolphin.exe'),
    (Join-Path $plasmaBuild 'bin\konsole.exe')
)

if (-not (Test-Path $built)) {
    throw 'Build is missing. Run: make'
}
foreach ($required in $requiredRuntime) {
    if (-not (Test-Path $required)) {
        throw "Runtime is incomplete: $required. Run: make"
    }
}

$installRoot = Join-Path $env:ProgramFiles 'KDE-Windows'
$machineWinlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'
$userSid = $identity.User.Value
$userRoot = 'Registry::HKEY_USERS\' + $userSid
$userPolicy = $userRoot + '\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$userWinlogon = $userRoot + '\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'

$currentShell = (Get-ItemProperty -Path $machineWinlogon -Name Shell -ErrorAction SilentlyContinue).Shell
if (-not $currentShell) { $currentShell = 'explorer.exe' }
$currentAutoRestart = (Get-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -ErrorAction SilentlyContinue).AutoRestartShell
if ($null -eq $currentAutoRestart) { $currentAutoRestart = 1 }

function Get-ShellValue([string]$path) {
    if (-not (Test-Path $path)) {
        return @{ Exists = $false; Value = '' }
    }
    try {
        $value = [string](Get-ItemProperty -Path $path -Name Shell -ErrorAction Stop).Shell
        return @{ Exists = $true; Value = $value }
    }
    catch {
        return @{ Exists = $false; Value = '' }
    }
}

function Restore-ShellValue([string]$path, [bool]$existed, [string]$value) {
    if ($existed) {
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -Path $path -Name Shell -PropertyType String -Value $value -Force | Out-Null
    }
    elseif (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name Shell -ErrorAction SilentlyContinue
    }
}

$policyBefore = Get-ShellValue $userPolicy
$userWinlogonBefore = Get-ShellValue $userWinlogon

$hashInput = (Get-FileHash -Algorithm SHA256 $built).Hash + (Get-FileHash -Algorithm SHA256 (Join-Path $plasmaBuild 'bin\plasmashell.exe')).Hash
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $versionBytes = [Text.Encoding]::UTF8.GetBytes($hashInput)
    $versionHash = ([BitConverter]::ToString($sha.ComputeHash($versionBytes))).Replace('-', '').Substring(0, 12).ToLowerInvariant()
}
finally {
    $sha.Dispose()
}

$versionRoot = Join-Path $installRoot $versionHash
$installedShell = Join-Path $versionRoot 'KDEWindowsShell.exe'
$stageRoot = Join-Path $installRoot ('.stage-' + $versionHash + '-' + $PID)
$newState = -not (Test-Path $state)
$existingState = if ($newState) { $null } else { Get-ItemProperty -Path $state }
$stateProperties = if ($existingState) { @($existingState.PSObject.Properties.Name) } else { @() }

if (($stateProperties -contains 'InstalledUserSid') -and [string]$existingState.InstalledUserSid -ne $userSid) {
    throw "KDE-Windows is already installed for a different user SID: $($existingState.InstalledUserSid)"
}

$needsPolicySnapshot = $newState -or -not ($stateProperties -contains 'PreviousUserPolicyShellExists')
$needsUserWinlogonSnapshot = $newState -or -not ($stateProperties -contains 'PreviousUserWinlogonShellExists')
$addedUserState = $false

function Test-Runtime([string]$base) {
    return (Test-Path (Join-Path $base 'KDEWindowsShell.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\plasmashell.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\dolphin.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\konsole.exe'))
}

try {
    New-Item -ItemType Directory -Force -Path $installRoot | Out-Null

    if (-not (Test-Runtime $versionRoot)) {
        if (Test-Path $stageRoot) {
            Remove-Item -Recurse -Force $stageRoot
        }
        New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
        Copy-Item -Force $built (Join-Path $stageRoot 'KDEWindowsShell.exe')
        New-Item -ItemType Directory -Force -Path (Join-Path $stageRoot 'Plasma') | Out-Null
        Copy-Item -Recurse -Force (Join-Path $plasmaBuild '*') (Join-Path $stageRoot 'Plasma')

        if (-not (Test-Runtime $stageRoot)) {
            throw 'Staged KDE-Windows runtime failed validation.'
        }

        if (Test-Path $versionRoot) {
            Remove-Item -Recurse -Force $versionRoot
        }
        Move-Item -Path $stageRoot -Destination $versionRoot
    }

    if (-not (Test-Runtime $versionRoot)) {
        throw 'Installed KDE-Windows runtime failed validation.'
    }

    if ($newState) {
        New-Item -Path $state -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousShell -PropertyType String -Value $currentShell -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousAutoRestartShell -PropertyType DWord -Value ([int]$currentAutoRestart) -Force | Out-Null
    }

    if (-not ($stateProperties -contains 'InstalledUserSid')) {
        New-Item -Path $state -Force | Out-Null
        New-ItemProperty -Path $state -Name InstalledUserSid -PropertyType String -Value $userSid -Force | Out-Null
        $addedUserState = $true
    }
    if ($needsPolicySnapshot) {
        New-ItemProperty -Path $state -Name PreviousUserPolicyShellExists -PropertyType DWord -Value ([int][bool]$policyBefore.Exists) -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousUserPolicyShell -PropertyType String -Value ([string]$policyBefore.Value) -Force | Out-Null
        $addedUserState = $true
    }
    if ($needsUserWinlogonSnapshot) {
        New-ItemProperty -Path $state -Name PreviousUserWinlogonShellExists -PropertyType DWord -Value ([int][bool]$userWinlogonBefore.Exists) -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousUserWinlogonShell -PropertyType String -Value ([string]$userWinlogonBefore.Value) -Force | Out-Null
        $addedUserState = $true
    }

    New-ItemProperty -Path $state -Name CurrentVersionRoot -PropertyType String -Value $versionRoot -Force | Out-Null

    $command = '"' + $installedShell + '"'

    # Set all shell resolution paths that can select Explorer for this user.
    # The per-user Custom User Interface policy is the Windows 11 policy path;
    # per-user Winlogon covers an existing legacy override; machine Winlogon
    # remains the compatibility fallback.
    Set-ItemProperty -Path $machineWinlogon -Name Shell -Value $command
    Set-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -Type DWord -Value 1

    New-Item -Path $userPolicy -Force | Out-Null
    New-ItemProperty -Path $userPolicy -Name Shell -PropertyType String -Value $command -Force | Out-Null

    New-Item -Path $userWinlogon -Force | Out-Null
    New-ItemProperty -Path $userWinlogon -Name Shell -PropertyType String -Value $command -Force | Out-Null

    $verifiedMachineShell = [string](Get-ItemProperty -Path $machineWinlogon -Name Shell -ErrorAction Stop).Shell
    $verifiedAutoRestart = [int](Get-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -ErrorAction Stop).AutoRestartShell
    $verifiedPolicyShell = [string](Get-ItemProperty -Path $userPolicy -Name Shell -ErrorAction Stop).Shell
    $verifiedUserWinlogonShell = [string](Get-ItemProperty -Path $userWinlogon -Name Shell -ErrorAction Stop).Shell
    if ($verifiedMachineShell -ne $command -or
        $verifiedAutoRestart -ne 1 -or
        $verifiedPolicyShell -ne $command -or
        $verifiedUserWinlogonShell -ne $command) {
        throw "Shell activation verification failed. Machine='$verifiedMachineShell' Policy='$verifiedPolicyShell' UserWinlogon='$verifiedUserWinlogonShell'"
    }

    Get-ChildItem $installRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -ne $versionRoot -and $_.Name -notlike '.stage-*' } |
        ForEach-Object {
            try { Remove-Item -Recurse -Force $_.FullName -ErrorAction Stop } catch { }
        }
}
catch {
    try {
        Set-ItemProperty -Path $machineWinlogon -Name Shell -Value $currentShell
        Set-ItemProperty -Path $machineWinlogon -Name AutoRestartShell -Type DWord -Value ([int]$currentAutoRestart)
    } catch { }
    try { Restore-ShellValue $userPolicy ([bool]$policyBefore.Exists) ([string]$policyBefore.Value) } catch { }
    try { Restore-ShellValue $userWinlogon ([bool]$userWinlogonBefore.Exists) ([string]$userWinlogonBefore.Value) } catch { }

    if ($newState -and (Test-Path $state)) {
        try { Remove-Item -Recurse -Force $state } catch { }
    }
    elseif ($addedUserState -and (Test-Path $state)) {
        foreach ($name in @(
            'InstalledUserSid',
            'PreviousUserPolicyShellExists', 'PreviousUserPolicyShell',
            'PreviousUserWinlogonShellExists', 'PreviousUserWinlogonShell'
        )) {
            if (-not ($stateProperties -contains $name)) {
                try { Remove-ItemProperty -Path $state -Name $name -ErrorAction SilentlyContinue } catch { }
            }
        }
    }
    if (Test-Path $stageRoot) {
        try { Remove-Item -Recurse -Force $stageRoot } catch { }
    }
    throw
}
finally {
    if (Test-Path $stageRoot) {
        try { Remove-Item -Recurse -Force $stageRoot } catch { }
    }
}

Write-Host "KDE-Windows installed: $versionRoot"
Write-Host "Shell activation verified for user SID: $userSid"
Write-Host 'Restart Windows to apply it.'
