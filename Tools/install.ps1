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
$winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$state = 'HKLM:\SOFTWARE\KDE-Windows'
$userSid = $identity.User.Value
$userPolicy = 'Registry::HKEY_USERS\' + $userSid + '\Software\Microsoft\Windows\CurrentVersion\Policies\System'

$currentShell = (Get-ItemProperty -Path $winlogon -Name Shell -ErrorAction SilentlyContinue).Shell
if (-not $currentShell) { $currentShell = 'explorer.exe' }
$currentAutoRestart = (Get-ItemProperty -Path $winlogon -Name AutoRestartShell -ErrorAction SilentlyContinue).AutoRestartShell
if ($null -eq $currentAutoRestart) { $currentAutoRestart = 1 }

$userPolicyShellExisted = $false
$currentUserPolicyShell = ''
if (Test-Path $userPolicy) {
    try {
        $currentUserPolicyShell = [string](Get-ItemProperty -Path $userPolicy -Name Shell -ErrorAction Stop).Shell
        $userPolicyShellExisted = $true
    }
    catch {
        $userPolicyShellExisted = $false
        $currentUserPolicyShell = ''
    }
}

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

if ($existingState -and $existingState.InstalledUserSid -and [string]$existingState.InstalledUserSid -ne $userSid) {
    throw "KDE-Windows is already installed for a different user SID: $($existingState.InstalledUserSid)"
}

$needsUserPolicySnapshot = $newState -or -not ($existingState -and $existingState.InstalledUserSid)
$addedUserPolicySnapshot = $false

function Test-Runtime([string]$base) {
    return (Test-Path (Join-Path $base 'KDEWindowsShell.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\plasmashell.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\dolphin.exe')) -and
           (Test-Path (Join-Path $base 'Plasma\bin\konsole.exe'))
}

function Restore-UserShellPolicy([bool]$existed, [string]$value) {
    if ($existed) {
        New-Item -Path $userPolicy -Force | Out-Null
        New-ItemProperty -Path $userPolicy -Name Shell -PropertyType String -Value $value -Force | Out-Null
    }
    elseif (Test-Path $userPolicy) {
        Remove-ItemProperty -Path $userPolicy -Name Shell -ErrorAction SilentlyContinue
    }
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

    if ($needsUserPolicySnapshot) {
        New-Item -Path $state -Force | Out-Null
        New-ItemProperty -Path $state -Name InstalledUserSid -PropertyType String -Value $userSid -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousUserPolicyShellExists -PropertyType DWord -Value ([int]$userPolicyShellExisted) -Force | Out-Null
        New-ItemProperty -Path $state -Name PreviousUserPolicyShell -PropertyType String -Value $currentUserPolicyShell -Force | Out-Null
        $addedUserPolicySnapshot = $true
    }

    New-ItemProperty -Path $state -Name CurrentVersionRoot -PropertyType String -Value $versionRoot -Force | Out-Null

    $command = '"' + $installedShell + '"'

    # Machine-level Winlogon is kept as a compatibility fallback. The user-scoped
    # Custom User Interface policy is the authoritative Windows 11 activation path.
    Set-ItemProperty -Path $winlogon -Name Shell -Value $command
    Set-ItemProperty -Path $winlogon -Name AutoRestartShell -Type DWord -Value 1
    New-Item -Path $userPolicy -Force | Out-Null
    New-ItemProperty -Path $userPolicy -Name Shell -PropertyType String -Value $command -Force | Out-Null

    $verifiedMachineShell = [string](Get-ItemProperty -Path $winlogon -Name Shell -ErrorAction Stop).Shell
    $verifiedAutoRestart = [int](Get-ItemProperty -Path $winlogon -Name AutoRestartShell -ErrorAction Stop).AutoRestartShell
    $verifiedUserShell = [string](Get-ItemProperty -Path $userPolicy -Name Shell -ErrorAction Stop).Shell
    if ($verifiedMachineShell -ne $command -or $verifiedAutoRestart -ne 1 -or $verifiedUserShell -ne $command) {
        throw "Shell activation verification failed. Machine='$verifiedMachineShell' User='$verifiedUserShell'"
    }

    Get-ChildItem $installRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -ne $versionRoot -and $_.Name -notlike '.stage-*' } |
        ForEach-Object {
            try { Remove-Item -Recurse -Force $_.FullName -ErrorAction Stop } catch { }
        }
}
catch {
    try {
        Set-ItemProperty -Path $winlogon -Name Shell -Value $currentShell
        Set-ItemProperty -Path $winlogon -Name AutoRestartShell -Type DWord -Value ([int]$currentAutoRestart)
    } catch { }
    try {
        Restore-UserShellPolicy $userPolicyShellExisted $currentUserPolicyShell
    } catch { }
    if ($newState -and (Test-Path $state)) {
        try { Remove-Item -Recurse -Force $state } catch { }
    }
    elseif ($addedUserPolicySnapshot -and (Test-Path $state)) {
        foreach ($name in @('InstalledUserSid', 'PreviousUserPolicyShellExists', 'PreviousUserPolicyShell')) {
            try { Remove-ItemProperty -Path $state -Name $name -ErrorAction SilentlyContinue } catch { }
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
Write-Host "Shell policy activated for user SID: $userSid"
Write-Host 'Restart Windows to apply it.'
