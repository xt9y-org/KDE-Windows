#include "Core/ShortcutAction.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;
    assert(shortcutActionForId(kRunnerHotkeyId) == ShortcutAction::Runner);
    assert(shortcutActionForId(kClipboardHotkeyId) == ShortcutAction::Clipboard);
    assert(shortcutActionForId(999) == ShortcutAction::None);
    return 0;
}
