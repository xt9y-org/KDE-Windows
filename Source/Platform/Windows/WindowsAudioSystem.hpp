#pragma once

#include "Core/AudioState.hpp"

namespace kde_windows
{
class WindowsAudioSystem final
{
public:
    [[nodiscard]] AudioState state() const;
    bool setVolume(int volume) const;
    bool setMuted(bool muted) const;
    bool toggleMuted() const;
};
}
