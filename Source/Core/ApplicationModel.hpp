#pragma once

#include <algorithm>
#include <cwctype>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

namespace kde_windows
{
struct ApplicationEntry
{
    std::wstring id;
    std::wstring name;
    std::wstring executable;
    std::wstring arguments;
    std::wstring workingDirectory;
    std::wstring iconPath;
    bool packaged = false;
};

class ApplicationModel
{
public:
    void replace(std::vector<ApplicationEntry> entries)
    {
        std::vector<ApplicationEntry> next;
        next.reserve(entries.size());
        std::unordered_set<std::wstring> seen;
        seen.reserve(entries.size());

        for (auto& entry : entries) {
            if (entry.name.empty() || entry.executable.empty())
                continue;
            const auto key = lower(entry.id.empty() ? entry.executable + L"\n" + entry.arguments : entry.id);
            if (!seen.insert(key).second)
                continue;
            next.push_back(std::move(entry));
        }

        std::stable_sort(next.begin(), next.end(), [](const ApplicationEntry& a, const ApplicationEntry& b) {
            return lower(a.name) < lower(b.name);
        });
        applications_ = std::move(next);
    }

    [[nodiscard]] const std::vector<ApplicationEntry>& applications() const noexcept
    {
        return applications_;
    }

    [[nodiscard]] const ApplicationEntry* find(const std::wstring& id) const noexcept
    {
        const auto target = lower(id);
        const auto it = std::find_if(applications_.begin(), applications_.end(), [&](const ApplicationEntry& entry) {
            return lower(entry.id) == target;
        });
        return it == applications_.end() ? nullptr : &*it;
    }

    [[nodiscard]] std::vector<const ApplicationEntry*> search(const std::wstring& query) const
    {
        const auto needle = lower(query);
        std::vector<const ApplicationEntry*> matches;
        for (const auto& entry : applications_) {
            if (needle.empty() || lower(entry.name).find(needle) != std::wstring::npos ||
                lower(entry.id).find(needle) != std::wstring::npos ||
                lower(entry.executable).find(needle) != std::wstring::npos) {
                matches.push_back(&entry);
            }
        }
        return matches;
    }

private:
    [[nodiscard]] static std::wstring lower(std::wstring value)
    {
        std::transform(value.begin(), value.end(), value.begin(), [](wchar_t c) {
            return static_cast<wchar_t>(std::towlower(c));
        });
        return value;
    }

    std::vector<ApplicationEntry> applications_;
};
}
