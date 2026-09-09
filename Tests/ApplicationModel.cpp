#include "Core/ApplicationModel.hpp"

#include <cassert>
#include <string>
#include <vector>

using kde_windows::ApplicationEntry;
using kde_windows::ApplicationModel;

static ApplicationEntry app(const wchar_t* id, const wchar_t* name, const wchar_t* exe)
{
    ApplicationEntry value;
    value.id = id;
    value.name = name;
    value.executable = exe;
    return value;
}

int main()
{
    ApplicationModel model;
    model.replace({
        app(L"org.kde.kate", L"Kate", L"C:\\KDE\\bin\\kate.exe"),
        app(L"ORG.KDE.KATE", L"Kate duplicate", L"C:\\KDE\\bin\\kate.exe"),
        app(L"windows.notepad", L"Notepad", L"C:\\Windows\\notepad.exe"),
        app(L"", L"Broken", L""),
        app(L"terminal", L"Windows Terminal", L"wt.exe"),
    });

    assert(model.applications().size() == 3);
    assert(model.find(L"org.kde.kate") != nullptr);
    assert(model.find(L"ORG.KDE.KATE") != nullptr);

    const auto kate = model.search(L"kat");
    assert(kate.size() == 1);
    assert(kate[0]->name == L"Kate");

    const auto win = model.search(L"windows");
    assert(win.size() == 2);

    const auto all = model.search(L"");
    assert(all.size() == 3);
    assert(all[0]->name == L"Kate");
    assert(all[1]->name == L"Notepad");
    assert(all[2]->name == L"Windows Terminal");
    return 0;
}
