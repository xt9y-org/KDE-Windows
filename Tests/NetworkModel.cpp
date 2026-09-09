#include "Core/NetworkModel.hpp"

#include <cassert>

int main()
{
    using namespace kde_windows;

    std::vector<WifiNetworkSnapshot> networks{
        {L"cafe", L"Cafe", L"", 110, false, false, false},
        {L"home", L"Home", L"Home", 55, true, true, true},
        {L"work", L"Work", L"Work", 90, false, true, true},
        {L"home", L"Duplicate", L"", 10, false, false, false},
    };

    normalizeWifiNetworks(networks);
    assert(networks.size() == 3);
    assert(networks[0].id == L"home");
    assert(networks[1].id == L"work");
    assert(networks[2].id == L"cafe");
    assert(networks[2].signalQuality == 100);
    return 0;
}
