#include "sliceslayout.h"

#include <QVariant>

#include <cmath>
#include <cstdio>
#include <vector>

// The frame the picker's look sets: the stock look draws the current slice with a
// 3 px edge and the layout's rounded corners, crate with a 1 px edge and the
// shared corner on a card the layout rounds, never on one it leaves square.
namespace {

class TestParams final : public ParamSource
{
public:
    bool square = false;
    QVariant value(const QString &key) const override
    {
        if (square && key.endsWith(QLatin1String("roundCorners")))
            return false;
        return {};
    }
    bool smallScreen() const override { return false; }
};

const CardVisual *cardOf(const std::vector<CardVisual> &cards, int row)
{
    for (const CardVisual &card : cards)
        if (card.row == row && card.texture != CardVisual::TextureNone)
            return &card;
    return nullptr;
}

std::vector<CardVisual> settle(const LayoutContext &ctx)
{
    SlicesLayout layout;
    layout.configure(ctx, false);
    layout.reset(ctx);
    std::vector<CardVisual> cards;
    for (int frame = 0; frame < 120; ++frame) {
        layout.tick(ctx, 1.0 / 60.0);
        cards.clear();
        layout.build(ctx, cards);
    }
    return cards;
}

bool near(float a, float b) { return std::abs(a - b) < 1e-3f; }

int fail(const char *what)
{
    std::fprintf(stderr, "slicesframe: %s\n", what);
    return 1;
}

} // namespace

int main()
{
    TestParams params;
    MotionProfile motion;
    LayoutContext ctx;
    ctx.viewport = QSizeF(1920, 1080);
    ctx.params = &params;
    ctx.motion = &motion;
    ctx.count = 9;
    ctx.current = 4;
    ctx.entrance = 1.0;

    std::vector<CardVisual> cards = settle(ctx);
    const CardVisual *current = cardOf(cards, 4);
    const CardVisual *other = cardOf(cards, 3);
    if (!current || !other)
        return fail("stock: the current card or its neighbour is missing");
    if (!near(current->inst.params[1], 3.0f) || !near(other->inst.params[1], 1.0f))
        return fail("stock: the current card lost its 3 px edge");
    if (current->inst.radii[0] <= 6.0f)
        return fail("stock: the slices lost their own rounded corners");

    ctx.frame.currentEdge = 1.0f;
    ctx.frame.cornerRadius = 6.0f;
    cards = settle(ctx);
    current = cardOf(cards, 4);
    other = cardOf(cards, 3);
    if (!current || !other)
        return fail("crate: the current card or its neighbour is missing");
    if (!near(current->inst.params[1], 1.0f) || !near(other->inst.params[1], 1.0f))
        return fail("crate: the current card's edge is not 1 px");
    for (int i = 0; i < 4; ++i)
        if (!near(current->inst.radii[i], 6.0f) || !near(other->inst.radii[i], 6.0f))
            return fail("crate: a rounded slice did not take the shared 6 px corner");
    if (!near(current->inst.params[0], other->inst.params[0]) || std::abs(current->inst.params[0]) < 1.0f)
        return fail("crate: the slices lost their skew");

    params.square = true;
    cards = settle(ctx);
    current = cardOf(cards, 4);
    if (!current)
        return fail("square: the current card is missing");
    for (int i = 0; i < 4; ++i)
        if (!near(current->inst.radii[i], 0.0f))
            return fail("square: crate rounded a slice the settings keep square");
    return 0;
}
