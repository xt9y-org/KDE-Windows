#pragma once

#include <array>
#include <cstdint>
#include <cwchar>
#include <string>

namespace kde_windows
{
inline bool parseBluetoothAddress(const std::wstring& text, std::uint64_t& value)
{
    unsigned parts[6]{};
    if (std::swscanf(text.c_str(),
                     L"%2x:%2x:%2x:%2x:%2x:%2x",
                     &parts[0], &parts[1], &parts[2],
                     &parts[3], &parts[4], &parts[5]) != 6) {
        return false;
    }

    std::uint64_t result = 0;
    for (const unsigned part : parts) {
        if (part > 0xff)
            return false;
        result = (result << 8) | static_cast<std::uint64_t>(part);
    }
    value = result;
    return true;
}

inline std::wstring formatBluetoothAddress(std::uint64_t value)
{
    wchar_t buffer[32]{};
    std::swprintf(buffer,
                  sizeof(buffer) / sizeof(buffer[0]),
                  L"%02X:%02X:%02X:%02X:%02X:%02X",
                  static_cast<unsigned>((value >> 40) & 0xff),
                  static_cast<unsigned>((value >> 32) & 0xff),
                  static_cast<unsigned>((value >> 24) & 0xff),
                  static_cast<unsigned>((value >> 16) & 0xff),
                  static_cast<unsigned>((value >> 8) & 0xff),
                  static_cast<unsigned>(value & 0xff));
    return buffer;
}
}
