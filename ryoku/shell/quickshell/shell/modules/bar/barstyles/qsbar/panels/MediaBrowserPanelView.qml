import QtQuick
import Quickshell.Widgets
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Tanzaku filmstrip browser for screenshots and videos: the drawing MediaBrowserPanel.qml hosts,
// in an Item of its own so a probe and a scene load it offscreen (a layer
// window needs a compositor). `picker` is that window: its state, geometry
// and actions. Under crate the chrome comes from the kit and Tokens; the
// layout itself (its strips, cards or slices) stays as it is.
Item {
    id: view
    required property var picker
    required property var root

    readonly property bool crate: Tokens.controlsCrate

    function focusStage() { stage.forceActiveFocus() }

    // ── scrim: the one glass under crate (the compositor frosts the desktop) ──
    Rectangle {
        objectName: "pickerScrim"
        anchors.fill: parent
        color: view.crate ? Tokens.glass : picker.scrim
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

    // ── empty/loading - also catches Esc to close when the stage isn't focused ──
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
        color: view.crate ? Tokens.inkSecondary : root.ink
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }

    // ── header ──
    Text {
        objectName: "pickerHead"
        visible: picker.ready && !view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        opacity: picker.reveal
        text: picker.isVideos ? I18n.tr("VIDEOS") : I18n.tr("SCREENSHOTS")
        color: root.sectionInk
        font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 12; font.letterSpacing: 3; font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
    }
    Kit.TrackLabel {
        objectName: "pickerHeadKit"
        visible: picker.ready && view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        opacity: picker.reveal
        tone: "accent"
        text: picker.isVideos ? I18n.tr("VIDEOS") : I18n.tr("SCREENSHOTS")
    }

    // ── the stage (filmstrip) ──
    Item {
        id: stage
        visible: picker.ready && picker.filtered.length > 0
        focus: picker.ready && picker.filtered.length > 0
        opacity: picker.reveal
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 + (1 - picker.reveal) * 14
        width: parent.width
        height: picker.focusedH

        readonly property real cx:     width / 2
        readonly property real fLeft:  cx - picker.focusedW / 2
        readonly property real fRight: cx + picker.focusedW / 2

        function xForRel(r) {
            if (r === 0) return fLeft
            var x
            if (r < 0) {
                x = fLeft
                for (var k = -1; k >= r; k--) x = x - picker.gap - picker.stripWidthFor(-k)
                return x
            }
            x = fRight + picker.gap
            for (var j = 1; j < r; j++) x = x + picker.stripWidthFor(j) + picker.gap
            return x
        }

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
                id: item
                required property int index
                readonly property var  entry:   picker.filtered[index] || null
                readonly property int  relIdx:  index - picker.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool near:    Math.abs(relIdx) <= picker.maxVisible
                // every visible tile gets a thumbnail (videos + screenshots);
                // the background pre-warm fills the rest so fast scrubbing keeps up
                readonly property bool wantThumb: picker.ready && near && entry

                width:  picker.stripWidthFor(Math.abs(relIdx))
                height: picker.focusedH
                y: 0
                x: stage.xForRel(relIdx)
                z: focused ? 100 : 50 - Math.abs(relIdx)
                visible: near
                opacity: near ? 1 : 0

                Behavior on x       { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on width   { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                // ── lazy cached thumbnail (480px jpg) - videos via ffmpegthumbnailer,
                // screenshots via magick; full-size sources are never decoded live ──
                readonly property string thumbPath: {
                    if (!entry) return ""
                    var fp = entry.thumbnailPath || ""
                    if (!fp && !picker.isVideos) fp = entry.filePath
                    if (picker.isVideos && fp === entry.filePath) return ""
                    return fp ? "file://" + fp : ""
                }

                // hairline frame; the photo is clipped to the rounded INNER shape
                // (ClippingRectangle = AA shader mask) so corners round to match the
                // frame. radius 5 = concentric (8 - 3px inset). Under crate it is the
                // kit's frame: popover at Tokens.radius in a hairline, the focused
                // strip in the 1 px pick edge.
                Rectangle {
                    id: frame
                    objectName: "pickerFrame-" + item.index
                    anchors.fill: parent
                    radius: view.crate ? Tokens.radius : 8
                    color: view.crate ? Tokens.popover : picker.frameBg
                    border.width: 1
                    border.color: item.focused ? (view.crate ? Tokens.pickEdge : root.seal)
                                               : (view.crate ? Tokens.line : root.sep)
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: view.crate ? Tokens.radius - 3 : 5
                        color: "transparent"

                        // image / poster - clipped to the rounded shape above
                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            // always the cached 480px thumb (never the full source);
                            // current-visibility bound → bounded memory
                            readonly property string wantedSource: (picker.ready && item.near && item.entry && item.thumbPath) ? item.thumbPath : ""
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
                            sourceSize.width:  picker.focusedW
                            sourceSize.height: picker.focusedH
                        }
                        // paper-wash dim; the preview peek lighter
                        Rectangle {
                            anchors.fill: parent
                            color: view.crate ? Tokens.paper : root.paper
                            opacity: item.focused ? 0 : (Math.abs(item.relIdx) === 1 ? 0.28 : 0.5)
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.focused ? picker.openSelected() : (picker.selFilt = index)
                }
            }
        }
    }

    // ── brush-stroke + label + hint ──
    Column {
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        opacity: picker.reveal
        anchors.top: stage.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: stage.horizontalCenter
        spacing: 12

        // the seal brush stroke (Ryoku marginalia: the crate caption has none)
        Rectangle {
            objectName: "pickerStroke"
            anchors.horizontalCenter: parent.horizontalCenter
            width: picker.focusedW * 0.42
            height: 3; radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.5;  color: root.seal }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }

        Text {
            objectName: "pickerTitle"
            anchors.horizontalCenter: parent.horizontalCenter
            width: picker.focusedW + 160
            text: (picker.isVideos ? I18n.tr("Videos · ") : I18n.tr("Screenshots · ")) + picker.currentLabel
            color: root.ink
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fValue : 22; font.weight: Font.DemiBold
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

        // delete confirmation prompt (replaces the hint while armed)
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
            color: picker.uiDim
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // the same caption on the kit under crate
    CratePickerCaption {
        visible: picker.ready && picker.filtered.length > 0 && view.crate
        opacity: picker.reveal
        anchors.top: stage.bottom
        anchors.topMargin: Tokens.s4
        anchors.horizontalCenter: stage.horizontalCenter
        width: picker.focusedW + 160
        title: (picker.isVideos ? I18n.tr("Videos · ") : I18n.tr("Screenshots · ")) + picker.currentLabel
        filterText: picker.confirmDelete ? "" : picker.filterText
        confirm: picker.confirmDelete
                 ? I18n.tr("Delete this %1?   Del again to confirm   ·   Esc cancel").arg(picker.isVideos ? I18n.tr("video") : I18n.tr("screenshot"))
                 : ""
        hint: I18n.tr("← →  scroll navigate     Enter open     Del delete     Ctrl+C copy     Esc")
    }
}
