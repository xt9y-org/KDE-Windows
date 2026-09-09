#pragma once

namespace kde_windows
{
enum class ShortcutAction
{
    None,
    Runner,
    Clipboard,
    WindowNext,
    WindowPrevious,
    WindowCommit,
    Overview,
};

inline constexpr int kRunnerHotkeyId = 1;
inline constexpr int kClipboardHotkeyId = 2;

constexpr ShortcutAction shortcutActionForId(int id)
{
    return id == kRunnerHotkeyId ? ShortcutAction::Runner
         : id == kClipboardHotkeyId ? ShortcutAction::Clipboard
                                    : ShortcutAction::None;
}
}
