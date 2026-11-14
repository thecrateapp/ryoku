import QtQuick
import QtQuick.Shapes
import "ImagePickerModel.js" as Model
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Hearthstone card-hand browser for screenshots and videos: the drawing MediaBrowserHearthstone.qml hosts,
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
        onClicked: root.mediaBrowserVisible = false
        onWheel: function(wheel) {
            if (!picker.ready) return
            picker.moveSel(wheel.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // ── empty/loading - also catches Esc to close when the hand isn't focused ──
    Item {
        anchors.fill: parent
        focus: picker.visible && !(picker.ready && picker.filtered.length > 0)
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (picker.filterText) picker.filterText = ""
                else root.mediaBrowserVisible = false
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
    // ── loading / empty ──
    Text {
        visible: root.mediaBrowserVisible && picker.active && picker.ready && picker.filtered.length === 0
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No matches: %1").arg(picker.filterText) + I18n.tr("\n\nBackspace to edit, or Esc to clear")
        color: view.crate ? Tokens.inkSecondary : root.ink
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }
    Text {
        visible: root.mediaBrowserVisible && picker.active && !picker.ready
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: picker.layoutSettled && !picker.loaded
              ? (picker.isVideos ? I18n.tr("No recordings in ~/Videos/Recordings") : I18n.tr("No screenshots in ~/Pictures/Screenshots")) + I18n.tr("\n\nEsc or click to close")
              : I18n.tr("Loading…")
        color: view.crate ? Tokens.inkSecondary : picker.textLight
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }

    // ── header + position (top) ──
    Text {
        objectName: "pickerHead"
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 40
        opacity: picker.reveal
        text: (picker.isVideos ? I18n.tr("VIDEOS") : I18n.tr("SCREENSHOTS")) + "      " + (picker.selFilt + 1) + " / " + picker.filtered.length
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
        Kit.TrackLabel { tone: "accent"; text: picker.isVideos ? I18n.tr("VIDEOS") : I18n.tr("SCREENSHOTS") }
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
                if (picker.confirmDelete) picker.confirmDelete = false
                else if (picker.filterText) picker.filterText = ""
                else root.mediaBrowserVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Delete) {
                if (picker.confirmDelete) picker.deleteFocused()
                else picker.confirmDelete = true
                event.accepted = true
            } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
                picker.copyFocused(); event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                picker.openSelected(); event.accepted = true
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

                // lazy cached thumbnail (video poster or screenshot thumb)
                readonly property string thumbPath: {
                    if (!entry) return ""
                    var fp = entry.thumbnailPath || ""
                    if (!fp && !picker.isVideos) fp = entry.filePath
                    if (picker.isVideos && fp === entry.filePath) return ""
                    return fp ? "file://" + fp : ""
                }

                width: picker.cardW; height: picker.cardH
                visible: nearby
                transformOrigin: Item.Bottom

                x: (hand.width  - picker.cardW) / 2 + relIdx * picker.stepX * picker.dealT
                y: (hand.height - picker.cardH)     - (focused ? picker.focusLift * picker.dealT : 0)
                rotation: relIdx * picker.spreadDeg * picker.dealT
                scale: focused ? 1 + (picker.focusScale - 1) * picker.dealT : 1
                z: focused ? 1000 : 500 - Math.min(Math.abs(relIdx), 40)
                opacity: picker.dealT

                Behavior on x        { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on y        { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on scale    { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                // photo/poster (raster) - edges hidden behind the passepartout
                Item {
                    anchors.fill: parent
                    anchors.margins: 6
                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        readonly property string wantedSource: (picker.ready && card.nearby && card.entry && card.thumbPath) ? card.thumbPath : ""
                        source: wantedSource
                        onWantedSourceChanged: source = wantedSource
                        Connections {
                            target: view.picker
                            function onThumbEpochChanged() {
                                if (thumbImage.wantedSource && (thumbImage.status === Image.Error || thumbImage.status === Image.Null)) {
                                    var s = thumbImage.wantedSource
                                    thumbImage.source = ""
                                    thumbImage.source = s
                                }
                            }
                        }
                        fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false; smooth: true
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
                        font.pixelSize: view.crate ? Tokens.fBody : 12
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
                // passepartout - crisp rounded outer + inner hole over the photo
                Shape {
                    id: frameShape
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    readonly property real w:  picker.cardW
                    readonly property real h:  picker.cardH
                    readonly property real ro: card.outerRadius
                    readonly property real m:  8
                    readonly property real ri: card.innerRadius
                    ShapePath {
                        fillRule: ShapePath.OddEvenFill
                        fillColor: card.matColor
                        strokeColor: "transparent"
                        strokeWidth: 0
                        startX: frameShape.ro; startY: 0
                        PathLine { x: frameShape.w - frameShape.ro; y: 0 }
                        PathArc  { x: frameShape.w; y: frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.w; y: frameShape.h - frameShape.ro }
                        PathArc  { x: frameShape.w - frameShape.ro; y: frameShape.h; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: frameShape.ro; y: frameShape.h }
                        PathArc  { x: 0; y: frameShape.h - frameShape.ro; radiusX: frameShape.ro; radiusY: frameShape.ro }
                        PathLine { x: 0; y: frameShape.ro }
                        PathArc  { x: frameShape.ro; y: 0; radiusX: frameShape.ro; radiusY: frameShape.ro }
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

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: card.focused ? picker.openSelected() : (picker.selFilt = index)
                }
            }
        }
    }

    // ── label + delete-confirm + hint (bottom) ──
    Column {
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        opacity: picker.reveal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        spacing: 8

        Text {
            objectName: "pickerTitle"
            anchors.horizontalCenter: parent.horizontalCenter
            width: 820
            text: (picker.isVideos ? I18n.tr("Videos · ") : I18n.tr("Screenshots · ")) + picker.currentLabel
            color: picker.textLight
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fValue : 24; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            objectName: "pickerFilter"
            visible: picker.filterText.length > 0 && !picker.confirmDelete
            anchors.horizontalCenter: parent.horizontalCenter
            text: picker.filterText
            color: root.seal; opacity: 0.95
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fBody : 14
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            objectName: "pickerConfirm"
            visible: picker.confirmDelete
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.tr("Delete this %1?   Del again to confirm   ·   Esc cancel").arg(picker.isVideos ? I18n.tr("video") : I18n.tr("screenshot"))
            color: root.seal
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11; font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            objectName: "pickerHint"
            visible: !picker.confirmDelete
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.tr("← →  scroll navigate     Enter open     Del delete     Ctrl+C copy     Esc")
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
        title: (picker.isVideos ? I18n.tr("Videos · ") : I18n.tr("Screenshots · ")) + picker.currentLabel
        filterText: picker.confirmDelete ? "" : picker.filterText
        confirm: picker.confirmDelete
                 ? I18n.tr("Delete this %1?   Del again to confirm   ·   Esc cancel").arg(picker.isVideos ? I18n.tr("video") : I18n.tr("screenshot"))
                 : ""
        hint: I18n.tr("← →  scroll navigate     Enter open     Del delete     Ctrl+C copy     Esc")
    }
}
