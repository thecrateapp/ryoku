import QtQuick
import shell.services
import Ryoku.Ui.Singletons

// What RegionOverlay draws while a region recording runs: four dim bands
// framing the clear box (top / bottom / left / right), screen-local px. The box
// interior carries no pixels, so the dim never lands in the recording. Under
// controls "crate" the dim is the theme's scrim role.
Item {
    id: dim

    property real bx: 0
    property real by: 0
    property real bw: 0
    property real bh: 0
    property real screenW: width
    property real screenH: height

    readonly property color tint: Tokens.controlsCrate ? Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 0.45) : Qt.rgba(0, 0, 0, 0.45)

    Rectangle { objectName: "regionBand"; color: dim.tint; x: 0; y: 0; width: dim.screenW; height: dim.by }
    Rectangle { color: dim.tint; x: 0; y: dim.by + dim.bh; width: dim.screenW; height: dim.screenH - (dim.by + dim.bh) }
    Rectangle { color: dim.tint; x: 0; y: dim.by; width: dim.bx; height: dim.bh }
    Rectangle { color: dim.tint; x: dim.bx + dim.bw; y: dim.by; width: dim.screenW - (dim.bx + dim.bw); height: dim.bh }
}
