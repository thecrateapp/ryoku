pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Blobs
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property var monitor
    required property bool active
    required property real s
    property var channels: ["cpu"]
    property var colors: [Tokens.sun]
    property bool fill: true
    property bool showGrid: false
    property bool detailPoints: false
    property real lineWidth: Tokens.border * s
    // crate-mark graph: crisp 1 px lines inset 6 px, three faint rules, only the first
    // channel filled, and a dot in a halo at each line's head
    property bool crate: Tokens.controlsCrate

    clip: true

    SystemGraph {
        anchors.fill: parent
        source: root.monitor
        active: root.active
        animated: !Tokens.reduceMotion && !Motion.reduce
        channels: root.channels
        colors: root.colors
        fill: root.fill
        showGrid: root.crate || root.showGrid
        detailPoints: root.detailPoints
        gridColor: root.crate ? Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, 0.06) : Tokens.lineSoft
        lineWidth: root.crate ? 1 : root.lineWidth
        lineFeather: root.crate ? 0.5 : 1.25
        inset: root.crate ? 6 * root.s : -1
        gridStyle: root.crate ? "rules" : "cells"
        fillChannels: root.crate && root.channels.length > 0 ? [root.channels[0]] : []
        heads: root.crate
        haloColor: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22)
    }
}
