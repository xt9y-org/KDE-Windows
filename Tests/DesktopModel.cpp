#include "Core/DesktopModel.hpp"

#include <cassert>
#include <vector>

int main()
{
    using namespace kde_windows;

    DesktopModel model;
    model.replace({
        {L"a", L"file.txt", L"C:\\Users\\x\\Desktop\\file.txt", false},
        {L"b", L"Folder", L"C:\\Users\\x\\Desktop\\Folder", true},
        {L"c", L"Duplicate", L"c:\\users\\x\\desktop\\FILE.TXT", false},
        {L"d", L"Alpha", L"C:\\Users\\x\\Desktop\\Alpha.txt", false},
    });

    const auto& entries = model.entries();
    assert(entries.size() == 3);
    assert(entries[0].directory);
    assert(entries[0].name == L"Folder");
    assert(entries[1].name == L"Alpha");
    assert(entries[2].name == L"file.txt");
    assert(model.find(L"a") != nullptr);
    assert(model.find(L"missing") == nullptr);
    return 0;
}
