#pragma once

#include <algorithm>
#include <cstddef>
#include <string>
#include <vector>

namespace kde_windows
{
class ClipboardModel
{
public:
    explicit ClipboardModel(std::size_t limit = 20)
        : limit_(limit)
    {
    }

    bool push(const std::wstring& text)
    {
        if (text.empty() || limit_ == 0)
            return false;

        const auto it = std::find(entries_.begin(), entries_.end(), text);
        if (it != entries_.end() && it == entries_.begin())
            return false;
        if (it != entries_.end())
            entries_.erase(it);

        entries_.insert(entries_.begin(), text);
        if (entries_.size() > limit_)
            entries_.resize(limit_);
        return true;
    }

    bool remove(std::size_t index)
    {
        if (index >= entries_.size())
            return false;
        entries_.erase(entries_.begin() + static_cast<std::ptrdiff_t>(index));
        return true;
    }

    void clear()
    {
        entries_.clear();
    }

    [[nodiscard]] const std::vector<std::wstring>& entries() const
    {
        return entries_;
    }

private:
    std::size_t limit_;
    std::vector<std::wstring> entries_;
};
}
