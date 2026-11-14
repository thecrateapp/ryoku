import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "ImagePickerModel.js" as Model
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Carousel (skewed slices) picker for theme and wallpaper: the drawing ImageCarouselCarousel.qml hosts,
// in an Item of its own so a probe and a scene load it offscreen (a layer
// window needs a compositor). `picker` is that window: its state, geometry
// and actions. Under crate the chrome comes from the kit and Tokens; the
// layout itself (its strips, cards or slices) stays as it is.
Item {
    id: view
    required property var picker
    required property var root

    readonly property bool crate: Tokens.controlsCrate

    function focusStage() { carousel.forceActiveFocus() }

    // the wash over the slices that are not picked
    readonly property color dimInk: view.crate ? Tokens.paper : picker.dimColor

    // NO scrim - the carousel floats over the live desktop (no extra background).
    MouseArea {
        anchors.fill: parent
        enabled: picker.visible
        onClicked: root.imagePickerVisible = false
        onWheel: function(wheel) {
            if (!picker.ready) return
            picker.selectAdjacent(wheel.angleDelta.y < 0 ? 1 : -1)
        }
    }

    // ── empty/loading - also catches Esc to close when the carousel isn't focused ──
    Item {
        anchors.fill: parent
        focus: picker.visible && !(picker.ready && picker.imageArray.length > 0)
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
    // under crate the messages sit on the one glass: the carousel has no scrim
    Rectangle {
        objectName: "pickerMessagePlate"
        readonly property Item shown: noMatch.visible ? noMatch : loading
        visible: view.crate && (noMatch.visible || loading.visible)
        anchors.centerIn: parent
        width: shown.implicitWidth + 2 * Tokens.s5
        height: shown.implicitHeight + 2 * Tokens.s4
        radius: Tokens.radius
        color: Tokens.glass
        border.width: Tokens.border
        border.color: Tokens.line
    }
    Text {
        id: noMatch
        visible: root.imagePickerVisible && picker.active && picker.ready && Model.matchCount(picker.imageArray, picker.filterText) === 0
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No matches: %1").arg(picker.filterText) + I18n.tr("\n\nBackspace to edit, or Esc to clear")
        color: view.crate ? Tokens.inkSecondary : root.ink
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 16
        font.letterSpacing: view.crate ? 0 : 1
    }
    Text {
        id: loading
        visible: root.imagePickerVisible && picker.active && !picker.ready
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: picker.scanDone
              ? (picker.isThemeMode ? I18n.tr("No themes found") : I18n.tr("No wallpapers found")) + I18n.tr("\n\nEsc or click to close")
              : I18n.tr("Loading…")
        color: view.crate ? Tokens.inkSecondary : root.ink
        style: view.crate ? Text.Normal : Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.6)
        font.family: view.crate ? Tokens.ui : root.mono
        font.pixelSize: view.crate ? Tokens.fRow : 18
    }

    // ── Carousel ──
    Item {
        id: carousel
        visible: picker.ready && picker.imageArray.length > 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: picker.expandedW + 13 * (picker.sliceW + picker.sliceGap)
        height: picker.expandedH
        focus: picker.ready && picker.imageArray.length > 0

        readonly property real itemStep: picker.sliceW + picker.sliceGap
        readonly property real previewX: (width - picker.expandedW) / 2

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (picker.filterText) picker.filterText = ""
                else root.imagePickerVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                picker.applySelected(); event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                if (picker.filterText.length > 0) { picker.filterText = picker.filterText.slice(0, -1); event.accepted = true }
            } else if (event.key === Qt.Key_Left || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
                picker.selectAdjacent(-1); event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                picker.selectAdjacent(1); event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127
                       && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                if (event.text !== " " || (picker.filterText.length > 0 && !picker.filterText.endsWith(" "))) picker.filterText += event.text; event.accepted = true
            }
        }

        Repeater {
            model: picker.imageArray.length

            delegate: Item {
                id: slice
                required property int index

                readonly property var  imgData:    picker.imageArray[index]
                readonly property bool matched:    picker.itemMatches(index)
                readonly property int  relIdx:     picker.filteredPos(index) - picker.selectedFiltPos()
                readonly property bool selected:   matched && index === picker.selectedIndex
                readonly property bool nearby:     matched && Math.abs(relIdx) <= 14
                objectName: "pickerSlice-" + index
                // the slice's edge: under crate a hairline, the picked slice in the
                // 1 px pick edge (the skewed shape is the layout's own)
                readonly property color edgeColor: view.crate ? (selected ? Tokens.pickEdge : Tokens.line)
                                                              : (selected ? picker.selBorder : picker.unselBorder)
                readonly property real edgeWidth: view.crate ? Tokens.border : (selected ? 3 : 1)

                // shared 512px thumbnail cache. The scan/warm worker owns path
                // resolution so delegates don't spawn per-item shell processes.
                readonly property string thumbPath: picker.thumbUrlFor(imgData)

                visible: nearby
                x: selected ? carousel.previewX
                             : (relIdx < 0 ? carousel.previewX + relIdx * carousel.itemStep
                                           : carousel.previewX + picker.expandedW + picker.sliceGap + (relIdx - 1) * carousel.itemStep)
                y: selected ? 0 : (picker.expandedH - picker.sliceH) / 2
                width:  selected ? picker.expandedW : picker.sliceW
                height: selected ? picker.expandedH : picker.sliceH
                z: selected ? 100 : 50 - Math.min(Math.abs(relIdx), 40)

                Behavior on x     { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on y     { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                readonly property real skAbs:    Math.abs(picker.skew)
                readonly property real topLeft:  picker.skew >= 0 ? skAbs : 0
                readonly property real topRight: picker.skew >= 0 ? width : width - skAbs
                readonly property real botRight: picker.skew >= 0 ? width - skAbs : width
                readonly property real botLeft:  picker.skew >= 0 ? 0 : skAbs

                Loader {
                    anchors.fill: parent
                    active: picker.ready && slice.nearby
                    sourceComponent: sliceVisualComponent
                }

                Component {
                    id: sliceVisualComponent

                    Item {
                        anchors.fill: parent

                        Item {
                            id: maskShape; anchors.fill: parent
                            visible: false; layer.enabled: true
                            Shape {
                                anchors.fill: parent; antialiasing: true
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    fillColor: "white"; strokeColor: "transparent"
                                    startX: slice.topLeft; startY: 0
                                    PathLine { x: slice.topRight; y: 0 }
                                    PathLine { x: slice.botRight; y: slice.height }
                                    PathLine { x: slice.botLeft;  y: slice.height }
                                    PathLine { x: slice.topLeft;  y: 0 }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent; layer.enabled: true; layer.smooth: true
                            layer.effect: MultiEffect {
                                maskEnabled: true; maskSource: maskShape
                                maskThresholdMin: 0.3; maskSpreadAtMin: 0.3
                            }
                            Image {
                                id: thumbImage
                                anchors.fill: parent
                                readonly property string wantedSource: (picker.ready && slice.nearby && slice.thumbPath) ? slice.thumbPath : ""
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
                                retainWhileLoading: true
                                fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; smooth: true
                                sourceSize.width:  slice.selected ? picker.expandedW : picker.sliceW
                                sourceSize.height: slice.selected ? picker.expandedH : picker.sliceH
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(view.dimInk.r, view.dimInk.g, view.dimInk.b, slice.selected ? 0 : 0.42)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        Shape {
                            anchors.fill: parent; antialiasing: true
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: slice.edgeColor
                                strokeWidth: slice.edgeWidth
                                Behavior on strokeColor { ColorAnimation { duration: 150 } }
                                startX: slice.topLeft; startY: 0
                                PathLine { x: slice.topRight; y: 0 }
                                PathLine { x: slice.botRight; y: slice.height }
                                PathLine { x: slice.botLeft;  y: slice.height }
                                PathLine { x: slice.topLeft;  y: 0 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: slice.selected ? picker.applySelected() : (picker.selectedIndex = index)
                        }
                    }
                }
            }
        }
    }

    // ── Label + hint (contrast-stable over any wallpaper) ──
    Column {
        visible: picker.ready && !view.crate
        z: 500
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: carousel.bottom; anchors.topMargin: 18
        width: root.evenW(Math.min(picker.expandedW + 96, Math.max(320, parent.width - 48)))
        spacing: 5

        Text {
            objectName: "pickerTitle"
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: picker.currentLabel()
            color: picker.footerText
            renderType: Text.NativeRendering
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fValue : 30; font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            objectName: "pickerFilter"
            visible: picker.filterText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: picker.filterText
            color: picker.footerText; opacity: 0.95
            renderType: Text.NativeRendering
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fRow : 15
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }

        Text {
            objectName: "pickerHint"
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            text: I18n.tr("← → navigate   Enter apply   Esc cancel   type to filter")
            color: picker.footerDim
            renderType: Text.NativeRendering
            font.family: root.mono; font.pixelSize: view.crate ? Tokens.fMicro : 11
            horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
        }
    }

    // under crate the caption is on the one glass, a plate under the carousel
    Rectangle {
        objectName: "pickerFooterPlate"
        visible: picker.ready && view.crate
        z: 500
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: carousel.bottom; anchors.topMargin: 18
        width: kitCaption.width + 2 * Tokens.s4
        height: kitCaption.implicitHeight + 2 * Tokens.s4
        radius: Tokens.radius
        color: Tokens.glass
        border.width: Tokens.border
        border.color: Tokens.line

        CratePickerCaption {
            id: kitCaption
            anchors.centerIn: parent
            width: root.evenW(Math.min(picker.expandedW, Math.max(320, view.width - 80)))
            title: picker.currentLabel()
            filterText: picker.filterText
            hint: I18n.tr("← → navigate   Enter apply   Esc cancel   type to filter")
        }
    }
}
