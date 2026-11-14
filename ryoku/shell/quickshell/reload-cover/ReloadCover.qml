pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Ryoku.Ui.Singletons

PanelWindow {
    id: cover

    required property var targetScreen
    required property string phase
    required property string mode
    required property bool startClose
    required property var reloadCover
    signal mapped()

    screen: targetScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "ryoku-reload-cover"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}

    property real diagonal: Math.sqrt(width * width + height * height)
    property real iris: diagonal
    property bool mappedReported: false
    // the curtain: Ryoku's black, or the theme's paper under controls "crate"
    readonly property color coverFill: Tokens.controlsCrate ? Tokens.paper : "black"
    readonly property real mediaOpacity: {
        if (cover.phase === "closing") return Math.max(0, 1 - cover.iris / (cover.diagonal * 0.38));
        if (cover.phase === "hold" || cover.phase === "failed") return 1;
        if (cover.phase === "opening") return Math.max(0, 1 - cover.iris / (cover.diagonal * 0.38));
        return 0;
    }


    function reportMapped(): void {
        if (!mappedReported && backingWindowVisible && width > 0 && height > 0) {
            mappedReported = true;
            mapped();
        }
    }

    function closeIris(): void {
        iris = diagonal;
        closeAnim.restart();
    }
    function openIris(): void {
        iris = 0;
        openAnim.restart();
    }

    Component.onCompleted: reportMapped()
    onBackingWindowVisibleChanged: reportMapped()
    onWidthChanged: reportMapped()
    onHeightChanged: reportMapped()
    onStartCloseChanged: if (startClose) closeIris()
    onPhaseChanged: if (phase === "opening") openIris()

    NumberAnimation {
        id: closeAnim
        target: cover
        property: "iris"
        from: cover.diagonal
        to: 0
        duration: 520
        easing.type: Easing.InOutCubic
    }
    NumberAnimation {
        id: openAnim
        target: cover
        property: "iris"
        from: 0
        to: cover.diagonal
        duration: 520
        easing.type: Easing.InOutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: cover.coverFill
        visible: cover.phase === "hold" || cover.phase === "failed"
    }
    Item {
        anchors.fill: parent
        visible: cover.phase === "closing" || cover.phase === "opening"

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: cover.coverFill
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                PathRectangle { x: 0; y: 0; width: cover.width; height: cover.height }
                PathSvg {
                    path: {
                        const r = Math.max(0.001, cover.iris);
                        const x = cover.width / 2 - r;
                        const y = cover.height / 2;
                        return "M " + x + " " + y
                            + " A " + r + " " + r + " 0 1 0 " + (x + r * 2) + " " + y
                            + " A " + r + " " + r + " 0 1 0 " + x + " " + y + " Z";
                    }
                }
            }
        }
    }

    ReloadMedia {
        id: media
        anchors.fill: parent
        descriptor: cover.reloadCover
        active: cover.backingWindowVisible
        forceDefault: cover.phase === "failed"
        themeMark: Tokens.controlsCrate ? Tokens.coverMark : ""
        markEffects: Tokens.controlsCrate
        markMotion: !Tokens.reduceMotion
        markGlow: Tokens.sunHi
        opacity: cover.mediaOpacity
        scale: opacity < 1 ? 0.94 + opacity * 0.06 : 1
    }
    CoverStatus {
        anchors.fill: parent
        mode: cover.mode
        phase: cover.phase
        logoHeight: media.defaultLogoHeight
        showingDefault: media.showingDefault
        mediaOpacity: cover.mediaOpacity
    }
}
