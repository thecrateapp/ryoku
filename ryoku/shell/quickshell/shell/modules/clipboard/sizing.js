// A clipboard size the layout leaves out, or sets to the stock value, is the
// look's own. The Hub's Desktop page saves its whole document, stock clipboard
// sizes included, so under the crate look a stock value reads as "untouched" and
// takes the crate size; a value the user really changed wins in either look.
function sized(value, stock, crate, crateLook) {
    if (value === undefined || value === null || value === "")
        return crateLook ? crate : stock;
    const n = Number(value);
    if (!isFinite(n))
        return crateLook ? crate : stock;
    return crateLook && n === stock ? crate : n;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { sized };
