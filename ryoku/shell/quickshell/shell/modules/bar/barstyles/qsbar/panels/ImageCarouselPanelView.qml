import QtQuick
import Quickshell.Widgets
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Tanzaku filmstrip picker for theme and wallpaper: the drawing ImageCarouselPanel.qml hosts,
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
        onClicked: root.imagePickerVisible = false
        onWheel: function(wheel) {
            if (!picker.ready) return
            picker.moveSel(wheel.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // ── empty/loading state - also catches Esc to close when the stage isn't focused ──
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
        color: view.crate ? Tokens.inkSecondary : root.ink
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }

    // ── header / filter (over the stage) ──
    Text {
        objectName: "pickerHead"
        visible: picker.ready && !view.crate
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        opacity: picker.reveal
        text: picker.isThemeMode ? I18n.tr("THEME") : I18n.tr("WALLPAPER")
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
        text: picker.isThemeMode ? I18n.tr("THEME") : I18n.tr("WALLPAPER")
    }

    // ── position indicator (aligned to the right edge of the focused image) ──
    Text {
        objectName: "pickerCount"
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        anchors.bottom: stage.top
        anchors.bottomMargin: 23
        x: stage.cx + picker.focusedW / 2 - width
        opacity: picker.reveal
        text: (picker.selFilt + 1) + " / " + picker.filtered.length
        color: picker.uiDim
        font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
    }
    Kit.TrackLabel {
        objectName: "pickerCountKit"
        visible: picker.ready && picker.filtered.length > 0 && view.crate
        anchors.bottom: stage.top
        anchors.bottomMargin: 22
        x: stage.cx + picker.focusedW / 2 - width
        opacity: picker.reveal
        font.features: { "tnum": 1 }
        text: (picker.selFilt + 1) + " / " + picker.filtered.length
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

        // left edge x for an item at relIdx r, summing intervening (variable) widths
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
                id: item
                required property int index
                readonly property var  entry:   picker.filtered[index] || null
                readonly property int  relIdx:  index - picker.selFilt
                readonly property bool focused: relIdx === 0
                readonly property bool near:    Math.abs(relIdx) <= picker.maxVisible

                // Cached thumbnails are resolved by the scan/warm worker, so
                // visible delegates don't start shell processes or briefly
                // switch from an empty source to a generated path.
                readonly property string thumbPath: entry ? entry.thumb : ""

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

                // hairline frame; the photo is clipped to the rounded INNER shape
                // (ClippingRectangle = AA shader mask) so its corners round to match
                // the frame instead of poking out square. radius 5 = concentric (8 - 3px).
                // Under crate it is the kit's frame: popover at Tokens.radius in a
                // hairline, the focused strip in the 1 px pick edge.
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

                        // image - clipped to the rounded shape above
                        Image {
                            id: thumbImage
                            anchors.fill: parent
                            // cached 512px thumb (theme + wallpaper); current-visibility
                            // bound so off-screen refs drop → bounded memory
                            readonly property string wantedSource: (picker.ready && item.near && item.thumbPath) ? item.thumbPath : ""
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
                            sourceSize.width:  picker.focusedW
                            sourceSize.height: picker.focusedH
                        }
                        // dim the unfocused strips (paper wash); the preview peek lighter
                        Rectangle {
                            anchors.fill: parent
                            color: view.crate ? Tokens.paper : root.paper
                            opacity: item.focused ? 0 : (Math.abs(item.relIdx) === 1 ? 0.28 : 0.5)
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                }

                // "current" marker - seal dot on the active theme/wallpaper; under
                // crate the kit's picked mark (PickCard's dot in its halo)
                Item {
                    objectName: "pickerDot-" + item.index
                    visible: item.entry && item.entry.current === true
                    width: view.crate ? 12 : 8; height: width
                    x: view.crate ? 6 : 9; y: x; z: 5
                    Rectangle {
                        objectName: "pickerDotHalo"
                        visible: view.crate
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22)
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: view.crate ? 6 : 8; height: width; radius: width / 2
                        color: view.crate ? Tokens.mark : root.seal
                        border.color: Qt.rgba(0, 0, 0, 0.35); border.width: view.crate ? 0 : 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.focused ? picker.applySelected() : (picker.selFilt = index)
                }
            }
        }
    }

    // ── seal brush-stroke + label + hint (under the focused image, centred) ──
    Column {
        visible: picker.ready && picker.filtered.length > 0 && !view.crate
        opacity: picker.reveal
        anchors.top: stage.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: stage.horizontalCenter
        spacing: 12

        // the single confident accent line - tapered like a brush stroke
        // (Ryoku marginalia: the crate caption has none)
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
            width: picker.focusedW + 120
            text: picker.currentLabel
            color: root.ink
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fValue : 22; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        // palette swatch - the focused theme's vivid colours (lazy, theme mode)
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
                    border.color: Qt.rgba(1, 1, 1, 0.15); border.width: 1
                }
            }
        }

        // meta - current badge · author (click → open repo)
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
                color: authorMa.containsMouse ? root.seal : picker.uiDim
                font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: authorMa
                    anchors.fill: parent
                    hoverEnabled: true
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
        width: picker.focusedW + 120
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
