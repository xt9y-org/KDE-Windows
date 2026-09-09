#include "Core/TrayModel.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    TrayModel model;
    TrayIconSnapshot icon;
    icon.key = L"window:10:7";
    icon.ownerWindow = 10;
    icon.id = 7;
    icon.tooltip = L"Network";
    icon.callbackMessage = 0x500;
    icon.iconHandle = 42;

    assert(model.add(icon));
    assert(model.icons().size() == 1);
    assert(!model.add(icon));

    TrayIconUpdate update;
    update.key = icon.key;
    update.tooltip = L"Connected";
    update.hidden = true;
    assert(model.modify(update));
    assert(model.icons()[0].tooltip == L"Connected");
    assert(model.icons()[0].hidden);
    assert(model.icons()[0].iconHandle == 42);

    assert(model.setVersion(icon.key, 4));
    assert(model.icons()[0].version == 4);

    assert(model.remove(icon.key));
    assert(model.icons().empty());
    assert(!model.remove(icon.key));
    return 0;
}
