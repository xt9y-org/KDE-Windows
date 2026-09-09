#include "Core/PanelLayout.hpp"

#include <cassert>

using kde_windows::panelLayout;

int main()
{
    const auto three = panelLayout(1280, 44, 3);
    assert(three.launcher.x == 6 && three.launcher.width == 44);
    assert(three.clock.x == 1186 && three.clock.width == 84);
    assert(three.tasks.size() == 3);
    assert(three.tasks[0].x == 58);
    assert(three.tasks[0].width == 180);
    assert(three.tasks[1].x == 242);
    assert(three.tasks[2].x == 426);
    assert(three.tasks[2].x + three.tasks[2].width < three.clock.x);

    const auto many = panelLayout(800, 44, 10);
    assert(many.tasks.size() == 10);
    for (std::size_t i = 1; i < many.tasks.size(); ++i)
        assert(many.tasks[i - 1].x + many.tasks[i - 1].width <= many.tasks[i].x);
    assert(many.tasks.back().x + many.tasks.back().width <= many.clock.x - 8);

    const auto tiny = panelLayout(150, 44, 5);
    assert(tiny.tasks.empty());
    return 0;
}
