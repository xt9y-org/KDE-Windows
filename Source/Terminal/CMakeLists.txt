qt_add_executable(konsole
    main.cpp
    ConPtySession.cpp
    ConPtySession.hpp
)

target_include_directories(konsole PRIVATE .)

qt_add_qml_module(konsole
    URI org.kde.konsole.windows
    VERSION 1.0
    QML_FILES
        qml/Terminal.qml
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
