#pragma once

// SystemGraph's plot geometry, free of Qt so tests/systemgraph-layout.sh can
// check it. A negative inset keeps the stock automatic margin on every side; an
// inset of zero or more is the crate-mark plot: flush left, so the oldest samples
// run off the edge, and inset at the top, the bottom and the right, so a series
// at 0 % or at its newest sample is never cut by the item's edge.

#include <algorithm>
#include <array>

namespace systemgraph {

struct PlotArea {
    float left = 0.0f;
    float top = 0.0f;
    float width = 0.0f;
    float height = 0.0f;
};

inline PlotArea plotArea(float width, float height, float inset, float autoMargin) {
    if (inset < 0.0f)
        return {autoMargin, autoMargin, std::max(0.0f, width - autoMargin * 2.0f),
                std::max(0.0f, height - autoMargin * 2.0f)};
    return {0.0f, inset, std::max(0.0f, width - inset), std::max(0.0f, height - inset * 2.0f)};
}

inline float baseline(const PlotArea& area) {
    return area.top + area.height;
}

// the "rules" grid: hairlines at the top, the middle and the bottom of the plot
inline std::array<float, 3> ruleYs(const PlotArea& area) {
    return {area.top, area.top + area.height * 0.5f, baseline(area)};
}

// a line's solid core half-width and where its antialiased edge fades out: the
// core is half the width (never under half a pixel), the feather is the fade
struct LineBands {
    float inner = 0.5f;
    float outer = 0.5f;
};

inline LineBands lineBands(float width, float feather) {
    const float inner = std::max(0.5f, width * 0.5f);
    return {inner, inner + std::max(0.0f, feather)};
}

} // namespace systemgraph
