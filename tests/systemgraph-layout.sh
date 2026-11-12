#!/usr/bin/env bash
# SystemGraph's plot geometry (ryoku/shell/plugin/systemgraphlayout.hpp): the
# stock automatic margin, the crate inset (flush left, inset top, bottom and
# right), and the three rules at the top, middle and bottom of the plot.
set -euo pipefail
ROOT=${RYOKU_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
work=$(mktemp -d)
trap 'rm -r -- "$work"' EXIT
cat > "$work/t.cpp" <<'CPP'
#include "systemgraphlayout.hpp"
#include <cassert>
#include <cmath>
#include <cstdio>
static bool near(float a, float b) { return std::fabs(a - b) < 1e-4f; }
int main() {
    using namespace systemgraph;
    // stock: the automatic margin on every side
    PlotArea a = plotArea(200.f, 80.f, -1.f, 3.f);
    assert(near(a.left, 3.f) && near(a.top, 3.f) && near(a.width, 194.f) && near(a.height, 74.f));
    // crate: flush left so the trace runs off the edge, inset elsewhere
    PlotArea b = plotArea(200.f, 84.f, 6.f, 3.f);
    assert(near(b.left, 0.f) && near(b.top, 6.f) && near(b.width, 194.f) && near(b.height, 72.f));
    assert(near(b.left + b.width, 194.f));
    assert(near(baseline(b), 78.f));
    auto r = ruleYs(b);
    assert(near(r[0], 6.f) && near(r[1], 42.f) && near(r[2], 78.f));
    // never negative on a tiny item
    PlotArea c = plotArea(4.f, 4.f, 6.f, 3.f);
    assert(c.width >= 0.f && c.height >= 0.f);
    // a line's solid core and antialiased edge: the stock 1.25 px feather, and the
    // crate 0.5 px one that keeps a 1 px line reading as 1 px
    LineBands stock = lineBands(1.f, 1.25f);
    assert(near(stock.inner, 0.5f) && near(stock.outer, 1.75f));
    LineBands crisp = lineBands(1.f, 0.5f);
    assert(near(crisp.inner, 0.5f) && near(crisp.outer, 1.0f));
    LineBands wide = lineBands(2.f, 1.25f);
    assert(near(wide.inner, 1.0f) && near(wide.outer, 2.25f));
    assert(near(lineBands(0.2f, -3.f).inner, 0.5f) && near(lineBands(0.2f, -3.f).outer, 0.5f));
    std::puts("systemgraph-layout: ok");
    return 0;
}
CPP
c++ -std=c++20 -I"$ROOT/ryoku/shell/plugin" "$work/t.cpp" -o "$work/t"
"$work/t"
