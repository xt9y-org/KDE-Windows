#include "WindowsAudioSystem.hpp"

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <endpointvolume.h>
#include <mmdeviceapi.h>

namespace kde_windows
{
namespace
{
bool defaultEndpointVolume(IAudioEndpointVolume** endpoint)
{
    if (!endpoint)
        return false;
    *endpoint = nullptr;

    IMMDeviceEnumerator* enumerator = nullptr;
    IMMDevice* device = nullptr;

    HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator),
                                      nullptr,
                                      CLSCTX_ALL,
                                      IID_PPV_ARGS(&enumerator));
    if (FAILED(result))
        return false;

    result = enumerator->GetDefaultAudioEndpoint(eRender, eMultimedia, &device);
    enumerator->Release();
    if (FAILED(result) || !device)
        return false;

    result = device->Activate(__uuidof(IAudioEndpointVolume),
                              CLSCTX_ALL,
                              nullptr,
                              reinterpret_cast<void**>(endpoint));
    device->Release();
    return SUCCEEDED(result) && *endpoint;
}
}

AudioState WindowsAudioSystem::state() const
{
    AudioState result;
    IAudioEndpointVolume* endpoint = nullptr;
    if (!defaultEndpointVolume(&endpoint))
        return result;

    float scalar = 0.0f;
    BOOL muted = FALSE;
    const HRESULT volumeResult = endpoint->GetMasterVolumeLevelScalar(&scalar);
    const HRESULT muteResult = endpoint->GetMute(&muted);
    endpoint->Release();

    if (FAILED(volumeResult) || FAILED(muteResult))
        return result;

    result.available = true;
    result.volume = clampVolume(static_cast<int>(scalar * 100.0f + 0.5f));
    result.muted = muted != FALSE;
    return result;
}

bool WindowsAudioSystem::setVolume(int volume) const
{
    IAudioEndpointVolume* endpoint = nullptr;
    if (!defaultEndpointVolume(&endpoint))
        return false;

    const float scalar = static_cast<float>(clampVolume(volume)) / 100.0f;
    const HRESULT result = endpoint->SetMasterVolumeLevelScalar(scalar, nullptr);
    endpoint->Release();
    return SUCCEEDED(result);
}

bool WindowsAudioSystem::setMuted(bool muted) const
{
    IAudioEndpointVolume* endpoint = nullptr;
    if (!defaultEndpointVolume(&endpoint))
        return false;

    const HRESULT result = endpoint->SetMute(muted ? TRUE : FALSE, nullptr);
    endpoint->Release();
    return SUCCEEDED(result);
}

bool WindowsAudioSystem::toggleMuted() const
{
    const AudioState current = state();
    return current.available && setMuted(!current.muted);
}
}
