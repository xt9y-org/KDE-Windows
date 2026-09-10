$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$cmake = Get-Content (Join-Path $root 'Source\Plasma\CMakeLists.txt') -Raw
$panel = Get-Content (Join-Path $root 'Source\Plasma\qml\Panel.qml') -Raw
$launcher = Get-Content (Join-Path $root 'Source\Plasma\qml\Launcher.qml') -Raw
$settings = Get-Content (Join-Path $root 'Source\Plasma\qml\Settings.qml') -Raw
$switcher = Get-Content (Join-Path $root 'Source\Plasma\qml\WindowSwitcher.qml') -Raw
$notifications = Get-Content (Join-Path $root 'Source\Plasma\qml\NotificationCenter.qml') -Raw
$themePath = Join-Path $root 'Source\Plasma\qml\PlasmaTheme.qml'

if (-not (Test-Path $themePath)) {
    throw 'PlasmaTheme.qml must provide one Breeze visual contract for the shell.'
}
$theme = Get-Content $themePath -Raw
foreach ($token in @('#eff0f1', '#232629', '#3daee9', 'panelMargin', 'panelHeight', 'popupRadius')) {
    if (-not $theme.Contains($token)) {
        throw "PlasmaTheme.qml is missing Breeze token: $token"
    }
}
foreach ($component in @('PlasmaTheme.qml', 'PlasmaSurface.qml', 'PlasmaIconButton.qml', 'PlasmaListDelegate.qml')) {
    if (-not $cmake.Contains("qml/$component")) {
        throw "CMake QML module must register $component"
    }
}
if (-not $cmake.Contains('QT_QML_SINGLETON_TYPE')) {
    throw 'PlasmaTheme.qml must be registered as a QML singleton.'
}

if (-not $panel.Contains('PlasmaTheme.panelMargin')) {
    throw 'Panel must use the Plasma floating-panel screen margin.'
}
if (-not $panel.Contains('PlasmaTheme.panelHeight')) {
    throw 'Panel must use the shared Plasma panel height.'
}
if (-not $panel.Contains('image://shell/window/')) {
    throw 'Task manager must render application icons.'
}
if (-not $panel.Contains('ToolTip.text: modelData.title')) {
    throw 'Icon-only task buttons must expose the window title as a tooltip.'
}

foreach ($section in @('Favorites', 'Applications', 'Computer')) {
    if (-not $launcher.Contains($section)) {
        throw "Kickoff must contain the $section section."
    }
}
if (-not $launcher.Contains('currentSection')) {
    throw 'Kickoff must have a section-based Plasma navigation model.'
}
if (-not $launcher.Contains('PlasmaSurface')) {
    throw 'Kickoff must use the shared Plasma popup surface.'
}

if (-not $settings.Contains('Qt.FramelessWindowHint')) {
    throw 'System Settings must use custom Breeze window chrome instead of the native Windows title bar.'
}
if (-not $settings.Contains('Search')) {
    throw 'System Settings must expose the Plasma-style navigation search field.'
}
if (-not $switcher.Contains('GridView')) {
    throw 'Alt+Tab must use Plasma 6 Thumbnail Grid layout.'
}
if (-not $notifications.Contains('PlasmaSurface')) {
    throw 'Notification center must use the shared Plasma surface.'
}

foreach ($legacy in @('#e6262a2e', '#f223272b', '#30363c', '#4b5964')) {
    foreach ($file in @($panel, $launcher, $settings, $switcher, $notifications)) {
        if ($file.Contains($legacy)) {
            throw "Legacy prototype color $legacy must not remain in primary Plasma surfaces."
        }
    }
}
