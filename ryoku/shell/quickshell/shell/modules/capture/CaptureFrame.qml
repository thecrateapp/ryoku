import QtQuick
import shell.services
import Ryoku.Ui.Singletons

// What CaptureOverlay draws over its output: the dim scrim, the clear cutout
// framed by four dim bands, the selection or hover outline and the region's
// "W×H" readout. Pure drawing in output-local px; the overlay owns the input
// and hands the highlighted rect in.
//
// Under controls "crate" the scrim is the theme's scrim role, the edge the 1 px
// pickEdge, and the readout an opaque popover tag with a mono value, kept on
// screen, so it reads over whatever the selection crosses.
Item {
    id: frame

    // "region" | "monitor" | "window": the overlay's selection mode
    property string sel: ""
    // a highlighted rect exists (a region being dragged, a hovered window)
    property bool hasRect: false
    // the pointer is over this output (monitor mode lightens its scrim)
    property bool hovering: false
    property real hlx: 0
    property real hly: 0
    property real hlw: 0
    property real hlh: 0
    property real scrW: width
    property real scrH: height
    // per-monitor UI scale, threaded from the overlay (1 = no-op)
    property real us: 1

    readonly property bool crate: Tokens.controlsCrate
    readonly property color dimC: frame.crate ? Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 0.45) : Qt.rgba(0, 0, 0, 0.45)
    readonly property color liteC: frame.crate ? Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 0.05) : Qt.rgba(0, 0, 0, 0.05)

    // --- scrim ----------------------------------------------------------------
    // Monitor: the whole output dims light while this overlay is hovered, dark
    // otherwise. Region/window before a selection: a plain full-cover scrim.
    Rectangle {
        anchors.fill: parent
        visible: frame.sel === "monitor" || !frame.hasRect
        color: frame.sel === "monitor" ? (frame.hovering ? frame.liteC : frame.dimC) : frame.dimC
    }
    // Region/window with a selection: four dim bands frame the clear cutout.
    Item {
        anchors.fill: parent
        visible: frame.hasRect
        Rectangle { objectName: "captureBand"; color: frame.dimC; x: 0; y: 0; width: frame.scrW; height: Math.max(0, frame.hly) }
        Rectangle { color: frame.dimC; x: 0; y: frame.hly + frame.hlh; width: frame.scrW; height: Math.max(0, frame.scrH - (frame.hly + frame.hlh)) }
        Rectangle { color: frame.dimC; x: 0; y: frame.hly; width: Math.max(0, frame.hlx); height: frame.hlh }
        Rectangle { color: frame.dimC; x: frame.hlx + frame.hlw; y: frame.hly; width: Math.max(0, frame.scrW - (frame.hlx + frame.hlw)); height: frame.hlh }
    }

    // Selection / hover outline: 2px for region, 3px for monitor/window; the
    // 1 px pickEdge under crate.
    Rectangle {
        objectName: "captureOutline"
        readonly property real inset: frame.crate ? 0 : 1.5 * frame.us
        visible: frame.hasRect || (frame.sel === "monitor" && frame.hovering)
        color: "transparent"
        border.width: frame.crate ? Tokens.border * frame.us : (frame.sel === "region" ? 2 : 3) * frame.us
        border.color: frame.crate ? Tokens.pickEdge : Theme.frameLine
        x: frame.sel === "monitor" ? inset : frame.hlx
        y: frame.sel === "monitor" ? inset : frame.hly
        width: frame.sel === "monitor" ? frame.scrW - 2 * inset : frame.hlw
        height: frame.sel === "monitor" ? frame.scrH - 2 * inset : frame.hlh
    }

    // Region dimension readout "W×H" (U+00D7), centred under the selection.
    Text {
        objectName: "captureSize"
        visible: !frame.crate && frame.sel === "region" && frame.hasRect
        text: Math.round(frame.hlw) + "\u00d7" + Math.round(frame.hlh)
        color: Theme.outline
        font.family: Theme.fontPrimary
        font.pixelSize: Theme.fontSm * frame.us
        x: frame.hlx + (frame.hlw - width) / 2
        y: frame.hly + frame.hlh + 20 * frame.us
    }

    // Under crate the readout is a tag: centred under the selection, above it
    // when the selection reaches the bottom edge, and never off the output.
    Rectangle {
        objectName: "captureReadout"
        readonly property real gap: Tokens.s3 * frame.us
        readonly property real below: frame.hly + frame.hlh + gap
        visible: frame.crate && frame.sel === "region" && frame.hasRect
        width: readout.implicitWidth + 2 * Tokens.s2 * frame.us
        height: readout.implicitHeight + Tokens.s2 * frame.us
        x: Math.max(gap, Math.min(frame.scrW - width - gap, frame.hlx + (frame.hlw - width) / 2))
        y: below + height <= frame.scrH - gap ? below : Math.max(gap, frame.hly - height - gap)
        radius: Tokens.radius * frame.us
        color: Tokens.popover
        border.width: Tokens.border * frame.us
        border.color: Tokens.line

        Text {
            id: readout
            objectName: "captureReadoutText"
            anchors.centerIn: parent
            text: Math.round(frame.hlw) + "\u00d7" + Math.round(frame.hlh)
            color: Tokens.ink
            font.family: Tokens.mono
            font.pixelSize: Tokens.fSmall * frame.us
        }
    }
}
