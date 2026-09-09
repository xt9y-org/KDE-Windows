#include "Core/WindowModel.hpp"

#include <cassert>
#include <string>
#include <vector>

using kde_windows::WindowId;
using kde_windows::WindowModel;
using kde_windows::WindowSnapshot;

static WindowSnapshot window(WindowId id, unsigned long pid, const wchar_t* title)
{
    WindowSnapshot value;
    value.id = id;
    value.processId = pid;
    value.title = title;
    value.visible = true;
    return value;
}

int main()
{
    WindowModel model;

    auto a = window(1, 10, L"Editor");
    auto b = window(2, 20, L"Browser");
    auto hidden = window(3, 30, L"Hidden");
    hidden.visible = false;
    auto tool = window(4, 40, L"Tool");
    tool.toolWindow = true;
    auto cloaked = window(5, 50, L"Cloaked");
    cloaked.cloaked = true;

    model.replace({a, b, hidden, tool, cloaked}, 999);
    assert(model.windows().size() == 2);
    assert(model.windows()[0].id == 1);
    assert(model.windows()[1].id == 2);

    auto b2 = b;
    b2.title = L"Browser - New";
    b2.active = true;
    auto c = window(6, 60, L"Terminal");
    model.replace({b2, c}, 999);

    assert(model.windows().size() == 2);
    assert(model.windows()[0].id == 2);
    assert(model.windows()[0].title == L"Browser - New");
    assert(model.windows()[0].active);
    assert(model.windows()[1].id == 6);
    assert(model.find(2) != nullptr);
    assert(model.find(1) == nullptr);
    assert(model.active() != nullptr && model.active()->id == 2);

    auto own = window(7, 999, L"Shell");
    model.replace({own}, 999);
    assert(model.windows().empty());

    auto untitled = window(8, 80, L"");
    model.replace({untitled}, 999);
    assert(model.windows().empty());

    return 0;
}
