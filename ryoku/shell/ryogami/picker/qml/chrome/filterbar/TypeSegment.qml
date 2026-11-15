import QtQuick
import Ryoku.Ui.Singletons

// What kind of wallpaper to show. The chosen word carries a short bone rule that slides
// to the next choice; the tabs above own the plate, so a filter reads one step quieter.
Item {
    id: seg

    required property LibraryView view
    property var shown: function (key) { return true }

    readonly property var choices: [
        { value: "", label: I18n.tr("All"), key: "filterBar.show.type.all" },
        { value: "static", label: I18n.tr("Stills"), key: "filterBar.show.type.static" },
        { value: "video", label: I18n.tr("Video"), key: "filterBar.show.type.video" },
        { value: "we", label: I18n.tr("Scenes"), key: "filterBar.show.type.we" }
    ]

    property real ruleX: 0
    property real ruleW: 0

    implicitWidth: row.implicitWidth
    implicitHeight: 30 * Theme.scale

    Row {
        id: row
        height: parent.height
        spacing: 2 * Theme.scale

        Repeater {
            model: seg.choices
            delegate: Item {
                id: opt
                required property var modelData
                readonly property bool on: seg.view && seg.view.typeFilter === modelData.value
                readonly property bool hovered: mouse.containsMouse
                visible: seg.shown(modelData.key)
                // Sized for the bold cut, so the row holds still as the choice moves.
                width: visible ? boldCut.advanceWidth + 20 * Theme.scale : 0
                height: row.height

                TextMetrics {
                    id: boldCut
                    font.family: word.font.family
                    font.weight: Theme.crate ? Font.Medium : Font.DemiBold
                    font.pixelSize: word.font.pixelSize
                    font.capitalization: word.font.capitalization
                    font.letterSpacing: word.font.letterSpacing
                    text: opt.modelData.label
                }

                Binding { target: seg; property: "ruleX"; value: opt.x + (opt.width - boldCut.advanceWidth) * 0.5; when: opt.on; restoreMode: Binding.RestoreNone }
                Binding { target: seg; property: "ruleW"; value: boldCut.advanceWidth; when: opt.on; restoreMode: Binding.RestoreNone }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: Theme.crate ? "transparent" : Theme.withAlpha(Theme.surfaceText, opt.hovered && !opt.on ? 0.07 : 0)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                Text {
                    id: word
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1 * Theme.scale
                    objectName: "typeSegmentLabel"
                    text: opt.modelData.label
                    // crate: navigation in the mono's tracked caps, one weight
                    font.family: Theme.crate ? Theme.mono : Theme.sans
                    font.weight: opt.on && !Theme.crate ? Font.DemiBold : Font.Medium
                    font.pixelSize: Theme.crate ? Theme.fontMicro : Theme.fs(12.5)
                    font.capitalization: Theme.crate ? Font.AllUppercase : Font.MixedCase
                    font.letterSpacing: Theme.crate ? Tokens.trackLabel : 0
                    color: Theme.crate ? (opt.on ? Tokens.mark : opt.hovered ? Tokens.hoverInk : Tokens.inkSubtle)
                        : opt.on || opt.hovered ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.58)
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: Theme.fast } }
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (seg.view) seg.view.typeFilter = opt.modelData.value
                }
            }
        }
    }

    Rectangle {
        x: seg.ruleX
        width: seg.ruleW
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3 * Theme.scale
        height: Theme.crate ? 2 : 2 * Theme.scale
        radius: height
        color: Theme.crate ? Tokens.mark : Theme.surfaceText
        Behavior on x { NumberAnimation { duration: Theme.standard; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on width { NumberAnimation { duration: Theme.standard; easing.type: Easing.OutCubic } }
    }
}
