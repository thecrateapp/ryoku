.pragma library

// Reads the active theme's style block (shell.json themeStyle) into the values
// Tokens exposes. Every absent or malformed field keeps the signature look, so
// a theme without a style, or with a partial one, changes only what it names.
function readStyle(st) {
    const s = {
        styled: !!(st && typeof st === "object"),
        lineAlpha: 0.26,
        display: "Fraunces",
        navFont: "",
        displayWeight: 400,
        displayWeightSet: false,
        compact: false,
        flags: { navCaps: false, accentMarks: false, focusAccent: false, labelAccent: false, selectFill: true }
    };
    if (!s.styled)
        return s;
    if (typeof st.lineAlpha === "number" && st.lineAlpha > 0 && st.lineAlpha <= 1)
        s.lineAlpha = st.lineAlpha;
    if (typeof st.display === "string" && st.display.length)
        s.display = st.display;
    if (typeof st.navFont === "string" && st.navFont.length)
        s.navFont = st.navFont;
    if (typeof st.displayWeight === "number") {
        s.displayWeight = Math.max(100, Math.min(900, st.displayWeight));
        s.displayWeightSet = true;
    }
    s.compact = st.density === "compact";
    for (const k in s.flags)
        if (typeof st[k] === "boolean")
            s.flags[k] = st[k];
    return s;
}
