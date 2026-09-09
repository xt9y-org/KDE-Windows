#include "Backend.hpp"

namespace kde_windows
{
bool Backend::openDesktopFolder()
{
    return desktopSystem_.openDesktop();
}

bool Backend::createDesktopFolder()
{
    if (!desktopSystem_.createFolder())
        return false;
    reloadDesktop();
    return true;
}
}
