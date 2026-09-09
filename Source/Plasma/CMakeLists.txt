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
    Backend.hpp
    ../Platform/Windows/WindowsWindowSystem.cpp
    ../Platform/Windows/WindowsWindowSystem.hpp
    ../Platform/Windows/WindowsApplications.cpp
    ../Platform/Windows/WindowsApplications.hpp
    ../Platform/Windows/WindowsTraySystem.cpp
    ../Platform/Windows/WindowsTraySystem.hpp
    ../Platform/Windows/WindowsAudioSystem.cpp
    ../Platform/Windows/WindowsAudioSystem.hpp
    ../Platform/Windows/WindowsPowerSystem.cpp
    ../Platform/Windows/WindowsPowerSystem.hpp
    ../Platform/Windows/WindowsNetworkSystem.cpp
    ../Platform/Windows/WindowsNetworkSystem.hpp
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
        qml/StatusArea.qml
        qml/Runner.qml
        qml/Clipboard.qml
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
)

set_target_properties(plasmashell PROPERTIES
    WIN32_EXECUTABLE TRUE
    RUNTIME_OUTPUT_DIRECTORY "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${KDE_WINDOWS_PLASMA_ROOT}/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${KDE_WINDOWS_PLASMA_ROOT}/bin"
)
