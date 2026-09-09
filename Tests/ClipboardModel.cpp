#include "Core/ClipboardModel.hpp"

#include <cassert>

int main()
{
    kde_windows::ClipboardModel model(3);
    assert(!model.push(L""));
    assert(model.push(L"one"));
    assert(model.push(L"two"));
    assert(!model.push(L"two"));
    assert(model.push(L"one"));
    assert(model.entries().size() == 2);
    assert(model.entries()[0] == L"one");
    assert(model.entries()[1] == L"two");
    assert(model.push(L"three"));
    assert(model.push(L"four"));
    assert(model.entries().size() == 3);
    assert(model.entries()[0] == L"four");
    assert(model.entries()[2] == L"one");
    assert(model.remove(1));
    assert(model.entries().size() == 2);
    model.clear();
    assert(model.entries().empty());
    return 0;
}
