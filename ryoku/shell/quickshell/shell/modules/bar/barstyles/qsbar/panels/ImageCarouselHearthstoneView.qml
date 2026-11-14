import QtQuick
import QtQuick.Shapes
import "ImagePickerModel.js" as Model
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Hearthstone card-hand picker for theme and wallpaper: the drawing ImageCarouselHearthstone.qml hosts,
// in an Item of its own so a probe and a scene load it offscreen (a layer
// window needs a compositor). `picker` is that window: its state, geometry
// and actions. Under crate the chrome comes from the kit and Tokens; the
// layout itself (its strips, cards or slices) stays as it is.
Item {
    id: view
    required property var picker
    required property var root

    readonly property bool crate: Tokens.controlsCrate

    function focusStage() { hand.forceActiveFocus() }

    // ── felt scrim: the one glass under crate (the compositor frosts the desktop) ──
    Rectangle {
        objectName: "pickerScrim"
        anchors.fill: parent
        color: view.crate ? Tokens.glass : picker.feltColor
        opacity: picker.reveal
    }
    MouseArea {
        anchors.fill: parent
        enabled: picker.visible
        onClicked: root.imagePickerVisible = false
        onWheel: function(wheel) {
            if (!picker.ready) return
            picker.moveSel(wheel.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // ── loading ──
    Item {
        anchors.fill: parent
        focus: picker.visible && !(picker.ready && picker.filtered.length > 0)
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (picker.filterText) picker.filterText = ""
                else root.imagePickerVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                if (picker.filterText.length > 0) picker.filterText = picker.filterText.slice(0, -1)
                event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                       && event.text.charCodeAt(0) !== 127
                       && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                if (event.text !== " " || (picker.filterText.length > 0 && !picker.filterText.endsWith(" "))) picker.filterText += event.text;
                event.accepted = true
            }
        }
    }
    Text {
        visible: root.imagePickerVisible && picker.active && picker.ready && picker.filtered.length === 0
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No matches: %1").arg(picker.filterText) + I18n.tr("\n\nBackspace to edit, or Esc to clear")
        color: view.crate ? Tokens.inkSecondary : root.ink
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }
    Text {
        visible: root.imagePickerVisible && picker.active && !picker.ready
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: picker.scanDone
              ? (picker.isThemeMode ? I18n.tr("No themes found") : I18n.tr("No wallpapers found")) + I18n.tr("\n\nEsc or click to close")
              : I18n.tr("Loading…")
        color: view.crate ? Tokens.inkSecondary : picker.textLight
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }

    // ── position indicator (top) ──
    Text {
        objectName: "pickerHead"
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 40
        opacity: picker.reveal
        text: (picker.isThemeMode ? I18n.tr("THEME") : I18n.tr("WALLPAPER")) + "      " + (picker.selFilt + 1) + " / " + picker.filtered.length
        color: picker.textDim
        font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 12; font.letterSpacing: 2
    }
    // under crate: the accent head and the subtle count, kit labels
    Row {
        objectName: "pickerHeadKit"
        visible: picker.ready && picker.filtered.length > 0 && view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 40
        opacity: picker.reveal
        spacing: Tokens.s5
        Kit.TrackLabel { tone: "accent"; text: picker.isThemeMode ? I18n.tr("THEME") : I18n.tr("WALLPAPER") }
        Kit.TrackLabel {
            font.features: { "tnum": 1 }
            text: (picker.selFilt + 1) + " / " + picker.filtered.length
        }
    }

    // ── the hand ──
    Item {
        id: hand
        visible: picker.ready && picker.filtered.length > 0
        focus: picker.ready && picker.filtered.length > 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -16
        width: parent.width
        height: picker.cardH + picker.focusLift + 40

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (picker.filterText) picker.filterText = ""
                else root.imagePickerVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                picker.applySelected(); event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                if (picker.filterText.length > 0) picker.filterText = picker.filterText.slice(0, -1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab
                       || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                picker.moveSel(-1); event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                picker.moveSel(1); event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                       && event.text.charCodeAt(0) !== 127
                       && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                if (event.text !== " " || (picker.filterText.length > 0 && !picker.filterText.endsWith(" "))) picker.filterText += event.text; event.accepted = true
            }
        }

        Repeater {
            model: picker.filtered.length

            delegate: Item {
                id: card
                required property int index
                objectName: "pickerCard-" + index
                // the passepartout: under crate popover at Tokens.radius in a
                // hairline, the focused card in the 1 px pick edge
                readonly property color matColor: view.crate ? Tokens.popover : picker.frameDark
                readonly property real outerRadius: view.crate ? Tokens.radius : 18
                readonly property real innerRadius: view.crate ? Math.max(0, Tokens.radius - 2) : 10
                readonly property color edgeColor: view.crate ? (focused ? Tokens.pickEdge : Tokens.line)
                                                              : (focused ? root.seal : "transparent")
                readonly property real edgeWidth: view.crate ? Tokens.border : (focused ? 2 : 0)
                readonly property var  entry:   picker.filtered[index] || null
                readonly property int  relIdx:  index - picker.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool nearby:  Math.abs(relIdx) <= picker.maxVisible
                readonly property real dim: focused ? 0.0 : Math.min(0.62, 0.30 + Math.abs(relIdx) * 0.05)

                // Cached thumbnails are resolved by the scan/warm worker, so
                // visible delegates don't start shell processes or briefly
                // switch from an empty source to a generated path.
                readonly property string thumbPath: entry ? entry.thumb : ""

                width: picker.cardW; height: picker.cardH
                visible: nearby
                transformOrigin: Item.Bottom

                x: (hand.width  - picker.cardW) / 2 + relIdx * picker.stepX * picker.dealT
                y: (hand.height - picker.cardH)     - (focused ? picker.focusLift * picker.dealT : 0)
                rotation: relIdx * picker.spreadDeg * picker.dealT
                scale: focused ? 1 + (picker.focusScale - 1) * picker.dealT : 1
                z: focused ? 1000 : 500 - Math.min(Math.abs(relIdx), 40)
                opacity: picker.dealT

                Behavior on x        { enabled: picker.dealSettled; NumberAnimation { duration: picker.cardMotionDuration; easing.type: Easing.OutCubic } }
                Behavior on y        { enabled: picker.dealSettled; NumberAnimation { duration: picker.cardMotionDuration; easing.type: Easing.OutCubic } }
                Behavior on rotation { enabled: picker.dealSettled; NumberAnimation { duration: picker.cardMotionDuration; easing.type: Easing.OutCubic } }
                Behavior on scale    { enabled: picker.dealSettled; NumberAnimation { duration: picker.cardMotionDuration; easing.type: Easing.OutCubic } }

                // photo (raster) - its edges are hidden behind the passepartout's
                // crisp Shape inner edge, so no rotated raster edge ever shows
                Item {
                    anchors.fill: parent
                    anchors.margins: 6
                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        readonly property string wantedSource: (picker.ready && card.nearby && card.thumbPath) ? card.thumbPath : ""
                        source: wantedSource
                        onWantedSourceChanged: source = wantedSource
                        Connections {
                            target: view.picker
                            function onThumbEpochChanged() {
                                if (thumbImage.wantedSource === picker.readyThumbUrl
                                        && thumbImage.status !== Image.Ready) {
                                    var s = thumbImage.wantedSource
                                    thumbImage.source = ""
                                    thumbImage.source = s
                                }
                            }
                        }
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; smooth: true
                        sourceSize.width:  picker.cardW * 2
                        sourceSize.height: picker.cardH * 2
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 70
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: view.crate ? Qt.rgba(Tokens.popover.r, Tokens.popover.g, Tokens.popover.b, 0.86) : Qt.rgba(0, 0, 0, 0.72) }
                        }
                    }
                    Text {
                        objectName: "pickerCardName"
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
                        text: card.entry ? I18n.tr(card.entry.label) : ""
                        color: view.crate ? Tokens.ink : picker.textLight
                        font.family: view.crate ? Tokens.ui : root.mono
                        font.pixelSize: view.crate ? Tokens.fBody : 13
                        font.weight: view.crate ? Font.Medium : Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    }
                    Rectangle {
                        objectName: "pickerCardDim"
                        anchors.fill: parent; color: view.crate ? Tokens.paper : "black"
                        opacity: card.dim
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                }
                // passepartout - rounded outer + rounded inner hole (OddEven), drawn
                // OVER the photo; only its CurveRenderer edges are visible → crisp
                // rounded card AND crisp rounded photo cut-out, even when rotated
                Shape {
                    id: frameShape
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    readonly property real w:  picker.cardW
                    readonly property real h:  picker.cardH
                    readonly property real ro: card.outerRadius   // outer radius
                    readonly property real m:  8                  // mat width
                    readonly property real ri: card.innerRadius   // inner (photo) radius
                    ShapePath {
                        fillRule: ShapePath.OddEvenFill
                        fillColor: card.matColor
                        strokeColor: "transparent"
                        strokeWidth: 0
                        // outer rounded rect
                        startX: frameShape.ro; startY: 0
                        PathLine { x: frameShape.w - frameShape.ro; y: 0 }
                        PathArc  { x: frameShape.w; y: frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.w; y: frameShape.h - frameShape.ro }
                        PathArc  { x: frameShape.w - frameShape.ro; y: frameShape.h; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.ro; y: frameShape.h }
                        PathArc  { x: 0; y: frameShape.h - frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: 0; y: frameShape.ro }
                        PathArc  { x: frameShape.ro; y: 0; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        // inner rounded hole (photo cut-out)
                        PathMove { x: frameShape.m + frameShape.ri; y: frameShape.m }
                        PathLine { x: frameShape.w - frameShape.m - frameShape.ri; y: frameShape.m }
                        PathArc  { x: frameShape.w - frameShape.m; y: frameShape.m + frameShape.ri; radiusX: frameShape.ri; radiusY: frameShape.ri }
                        PathLine { x: frameShape.w - frameShape.m; y: frameShape.h - frameShape.m - frameShape.ri }
                        PathArc  { x: frameShape.w - frameShape.m - frameShape.ri; y: frameShape.h - frameShape.m; radiusX: frameShape.ri; radiusY: frameShape.ri }
                        PathLine { x: frameShape.m + frameShape.ri; y: frameShape.h - frameShape.m }
                        PathArc  { x: frameShape.m; y: frameShape.h - frameShape.m - frameShape.ri; radiusX: frameShape.ri; radiusY: frameShape.ri }
                        PathLine { x: frameShape.m; y: frameShape.m + frameShape.ri }
                        PathArc  { x: frameShape.m + frameShape.ri; y: frameShape.m; radiusX: frameShape.ri; radiusY: frameShape.ri }
                    }
                    // focus accent - OUTER outline only (one border, not two)
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: card.edgeColor
                        strokeWidth: card.edgeWidth
                        Behavior on strokeColor { ColorAnimation { duration: 160 } }
                        startX: frameShape.ro; startY: 0
                        PathLine { x: frameShape.w - frameShape.ro; y: 0 }
                        PathArc  { x: frameShape.w; y: frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.w; y: frameShape.h - frameShape.ro }
                        PathArc  { x: frameShape.w - frameShape.ro; y: frameShape.h; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.ro; y: frameShape.h }
                        PathArc  { x: 0; y: frameShape.h - frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: 0; y: frameShape.ro }
                        PathArc  { x: frameShape.ro; y: 0; radiusX: frameShape.ro; radiusY: frameShape.ro }
                    }
                }
                // "current" marker; under crate the kit's picked mark (PickCard's
                // dot in its halo)
                Item {
                    objectName: "pickerDot-" + card.index
                    visible: card.entry && card.entry.current === true
                    width: view.crate ? 12 : 9; height: width
                    x: view.crate ? 12 : 14; y: x; z: 5
                    Rectangle {
                        objectName: "pickerDotHalo"
                        visible: view.crate
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: view.crate ? 6 : 9; height: width; radius: width / 2
                        color: view.crate ? Tokens.mark : root.seal
                        border.color: Qt.rgba(0, 0, 0, 0.35); border.width: view.crate ? 0 : 1
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: card.focused ? picker.applySelected() : (picker.selFilt = index)
                }
            }
        }
    }

    // ── label + palette + meta + hint (bottom) ──
    Column {
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        opacity: picker.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        spacing: 8

        Text {
            objectName: "pickerTitle"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 820; text: picker.currentLabel
            color: picker.textLight
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fValue : 26; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        // palette swatch (lazy, theme mode)
        Row {
            visible: picker.isThemeMode && picker.selMeta && picker.selMeta.palette.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Repeater {
                model: (picker.selMeta && picker.selMeta.palette.length > 0)
                       ? picker.selMeta.palette.split(",") : []
                delegate: Rectangle {
                    required property var modelData
                    width: 13; height: 13; radius: 6.5
                    color: modelData
                    border.color: Qt.rgba(1, 1, 1, 0.18); border.width: 1
                }
            }
        }

        // current badge · author
        Row {
            visible: (picker.sel && picker.sel.current)
                     || (picker.isThemeMode && picker.selMeta && picker.selMeta.author.length > 0)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            Text {
                objectName: "pickerCurrent"
                visible: picker.sel && picker.sel.current
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("● current")
                color: root.seal
                font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
            }
            Text {
                objectName: "pickerAuthor"
                visible: picker.isThemeMode && picker.selMeta && picker.selMeta.author.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("by %1  ↗").arg(picker.selMeta ? picker.selMeta.author : "")
                color: authorMa.containsMouse ? root.seal : picker.textDim
                font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: authorMa
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.openRepo()
                }
            }
        }

        Text {
            objectName: "pickerFilter"
            visible: picker.filterText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: picker.filterText
            color: root.seal; opacity: 0.95
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fBody : 14
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            objectName: "pickerHint"
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.tr("← →  scroll navigate     Enter apply     Esc cancel     type to filter")
            color: picker.textDim
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // the same caption on the kit under crate
    CratePickerCaption {
        visible: picker.ready && picker.filtered.length > 0 && view.crate
        opacity: picker.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        width: 820
        title: picker.currentLabel
        swatches: picker.isThemeMode && picker.selMeta && picker.selMeta.palette.length > 0
                  ? picker.selMeta.palette.split(",") : []
        current: !!(picker.sel && picker.sel.current)
        author: picker.isThemeMode && picker.selMeta ? picker.selMeta.author : ""
        filterText: picker.filterText
        hint: I18n.tr("← →  scroll navigate     Enter apply     Esc cancel     type to filter")
        onOpenAuthor: picker.openRepo()
    }
}
