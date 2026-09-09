cmake_minimum_required(VERSION 3.21)
project(KDEWindowsPlasma VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

set(KDE_WINDOWS_PLASMA_ROOT "${CMAKE_BINARY_DIR}/Plasma" CACHE PATH "Plasma runtime output root")

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(plasmashell
    main.cpp
    Backend.cpp
    BackendSystem.cpp
    Backend.hpp
    PanelBridge.cpp
    PanelBridge.hpp
    ShellIconProvider.cpp
    ShellIconProvider.hpp
    ../Platform/Windows/WindowsWindowSystem.cpp
    ../Platform/Windows/WindowsWindowSystem.hpp
    ../Platform/Windows/WindowsApplications.cpp
    ../Platform/Windows/WindowsApplications.hpp
    ../Platform/Windows/WindowsDesktopSystem.cpp
    ../Platform/Windows/WindowsDesktopSystem.hpp
    ../Platform/Windows/WindowsDisplaySystem.cpp
    ../Platform/Windows/WindowsDisplaySystem.hpp
    ../Platform/Windows/WindowsTraySystem.cpp
    ../Platform/Windows/WindowsTraySystem.hpp
    ../Platform/Windows/WindowsAudioSystem.cpp
    ../Platform/Windows/WindowsAudioSystem.hpp
    ../Platform/Windows/WindowsPowerSystem.cpp
    ../Platform/Windows/WindowsPowerSystem.hpp
    ../Platform/Windows/WindowsNetworkSystem.cpp
    ../Platform/Windows/WindowsNetworkSystem.hpp
    ../Platform/Windows/WindowsBluetoothSystem.cpp
    ../Platform/Windows/WindowsBluetoothSystem.hpp
    ../Platform/Windows/WindowsVirtualDesktopSystem.cpp
    ../Platform/Windows/WindowsVirtualDesktopSystem.hpp
    ../Platform/Windows/WindowsShortcutSystem.cpp
    ../Platform/Windows/WindowsShortcutSystem.hpp
)

target_include_directories(plasmashell PRIVATE ..)

qt_add_qml_module(plasmashell
    URI org.kde.plasma.windows
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Desktop.qml
        qml/Panel.qml
        qml/Launcher.qml
        qml/Notifications.qml
        qml/NotificationCenter.qml
        qml/StatusArea.qml
        qml/Runner.qml
        qml/Clipboard.qml
        qml/WindowSwitcher.qml
        qml/Overview.qml
        qml/Settings.qml
        qml/AppearanceSettings.qml
        qml/DisplaySettings.qml
        qml/NetworkSettings.qml
        qml/BluetoothSettings.qml
        qml/SoundSettings.qml
        qml/PowerSettings.qml
        qml/VirtualDesktopSettings.qml
)

target_compile_definitions(plasmashell PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)

target_link_libraries(plasmashell PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    user32
    gdi32
    shell32
    dwmapi
    ole32
    propsys
    uuid
    PowrProf
    wlanapi
    Bthprops
    Dxva2
)

set_target_properties(plasmashell PROPERTIES
    WIN32_EXECUTABLE TRUE
    RUNTIME_OUTPUT_DIRECTORY "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${KDE_WINDOWS_PLASMA_ROOT}/bin"
)

qt_add_executable(konsole
    ../Terminal/main.cpp
    ../Terminal/ConPtySession.cpp
    ../Terminal/ConPtySession.hpp
)

target_include_directories(konsole PRIVATE ../Terminal)

qt_add_qml_module(konsole
    URI org.kde.konsole.windows
    VERSION 1.0
    QML_FILES
        ../Terminal/qml/Terminal.qml
)

target_compile_definitions(konsole PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_link_libraries(konsole PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    user32
)

set_target_properties(konsole PROPERTIES
    WIN32_EXECUTABLE TRUE
    RUNTIME_OUTPUT_DIRECTORY "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${KDE_WINDOWS_PLASMA_ROOT}/bin"
)
