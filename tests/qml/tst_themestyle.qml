import QtQuick
import QtTest
import "../../ryoku/ui/Singletons/themestyle.js" as ThemeStyle

TestCase {
    name: "ThemeStyle"

    function test_no_style_keeps_the_signature_look() {
        const s = ThemeStyle.readStyle(undefined)
        compare(s.styled, false)
        compare(s.displayWeightSet, false)
        compare(s.displayWeight, 400)
        compare(s.lineAlpha, 0.26)
        compare(s.display, "Fraunces")
        compare(s.navFont, "")
        compare(s.flags.selectFill, true)
        compare(s.flags.accentMarks, false)
    }

    function test_a_style_without_a_weight_does_not_claim_one() {
        const s = ThemeStyle.readStyle({ navCaps: true })
        compare(s.styled, true)
        compare(s.displayWeightSet, false)
        compare(s.flags.navCaps, true)
    }

    function test_a_style_weight_is_clamped_and_marked_set() {
        compare(ThemeStyle.readStyle({ displayWeight: 800 }).displayWeight, 800)
        compare(ThemeStyle.readStyle({ displayWeight: 800 }).displayWeightSet, true)
        compare(ThemeStyle.readStyle({ displayWeight: 2000 }).displayWeight, 900)
        compare(ThemeStyle.readStyle({ displayWeight: 10 }).displayWeight, 100)
        compare(ThemeStyle.readStyle({ displayWeight: "800" }).displayWeightSet, false)
    }

    function test_faces_and_flags_are_read() {
        const s = ThemeStyle.readStyle({ display: "Bricolage Grotesque", navFont: "JetBrainsMono Nerd Font",
                                         lineAlpha: 0.1, selectFill: false, accentMarks: true })
        compare(s.display, "Bricolage Grotesque")
        compare(s.navFont, "JetBrainsMono Nerd Font")
        compare(s.lineAlpha, 0.1)
        compare(s.flags.selectFill, false)
        compare(s.flags.accentMarks, true)
    }

    function test_out_of_range_line_alpha_is_ignored() {
        compare(ThemeStyle.readStyle({ lineAlpha: 0 }).lineAlpha, 0.26)
        compare(ThemeStyle.readStyle({ lineAlpha: 3 }).lineAlpha, 0.26)
    }
}
