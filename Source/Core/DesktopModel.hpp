#pragma once

#include <algorithm>
#include <cwctype>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

namespace kde_windows
{
struct DesktopEntry
{
    std::wstring id;
    std::wstring name;
    std::wstring path;
    bool directory = false;

    bool operator==(const DesktopEntry&) const = default;
};

class DesktopModel final
{
public:
    void replace(std::vector<DesktopEntry> entries)
    {
        std::vector<DesktopEntry> normalized;
        normalized.reserve(entries.size());
        std::unordered_set<std::wstring> seen;

        for (auto& entry : entries) {
            if (entry.path.empty())
                continue;
            const std::wstring key = lower(entry.path);
            if (!seen.insert(key).second)
                continue;
            if (entry.id.empty())
                entry.id = entry.path;
            if (entry.name.empty())
                entry.name = entry.path;
            normalized.push_back(std::move(entry));
        }

        std::stable_sort(normalized.begin(), normalized.end(), [](const DesktopEntry& a, const DesktopEntry& b) {
            if (a.directory != b.directory)
                return a.directory > b.directory;
            return lower(a.name) < lower(b.name);
        });
        entries_ = std::move(normalized);
    }

    [[nodiscard]] const std::vector<DesktopEntry>& entries() const { return entries_; }

    [[nodiscard]] const DesktopEntry* find(const std::wstring& id) const
    {
        const auto it = std::find_if(entries_.begin(), entries_.end(), [&](const DesktopEntry& entry) {
            return entry.id == id;
        });
        return it == entries_.end() ? nullptr : &*it;
    }

private:
    static std::wstring lower(std::wstring value)
    {
        std::transform(value.begin(), value.end(), value.begin(), [](wchar_t c) {
            return static_cast<wchar_t>(std::towlower(c));
        });
        return value;
    }

    std::vector<DesktopEntry> entries_;
};
}
