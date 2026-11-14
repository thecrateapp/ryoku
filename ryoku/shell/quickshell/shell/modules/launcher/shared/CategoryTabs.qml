import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "Singletons"
import "providers/actions/catalog.js" as Catalog

// Action-mode tab bar (shown when the query starts with "/"): All | System |
// Appearance | Tools | Media | Settings, the active tab underlined in vermilion,
// with a faint command-hint row for the package verbs. Tab/Shift+Tab cycle the
// active category; the actions provider reads it to narrow its list.
// Under crate the bar is the kit's Tabs (the live tab underlined in the mark)
// and the hint row a tracked mono caption.
Item {
    id: root

    property real s: 1
    property int activeIndex: 0
    readonly property var categories: Catalog.CATEGORIES
    readonly property string activeCategory: categories[activeIndex]
    readonly property bool crate: Tokens.controlsCrate

    implicitHeight: (crate ? kitTabs.height : tabRow.height) + hints.height + 10 * s

    function cycle(delta) {
        var n = categories.length;
        root.activeIndex = (root.activeIndex + delta + n) % n;
    }

    Tabs {
        id: kitTabs
        objectName: "categoryKitTabs"
        visible: root.crate
        anchors.top: parent.top
        anchors.left: parent.left
        options: root.categories
        current: root.activeCategory
        onChose: label => root.activeIndex = Math.max(0, root.categories.indexOf(label))
    }

    Row {
        id: tabRow
        objectName: "categoryTabs"
        visible: !root.crate
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: Metrics.gapTab * root.s
        height: 26 * root.s

        Repeater {
            model: root.categories.length
            delegate: Item {
                required property int index
                readonly property bool sel: index === root.activeIndex
                width: label.width
                height: tabRow.height

                Text {
                    id: label
                    anchors.top: parent.top
                    text: I18n.tr(root.categories[index])
                    color: parent.sel ? Theme.bright : Theme.faint
                    font.family: Theme.font
                    font.pixelSize: Metrics.fontSubtitle * root.s
                    font.weight: parent.sel ? Font.DemiBold : Font.Normal
                }

                Rectangle {
                    anchors.top: label.bottom
                    anchors.topMargin: 4 * root.s
                    anchors.horizontalCenter: label.horizontalCenter
                    width: label.width
                    height: 2 * root.s
                    radius: Theme.radius
                    color: Theme.verm
                    visible: parent.sel
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeIndex = index
                }
            }
        }
    }

    Text {
        id: hints
        anchors.top: root.crate ? kitTabs.bottom : tabRow.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        text: "/file   /folder   /image   /video       >install <pkg>   >search <pkg>"
        color: root.crate ? Tokens.inkSubtle : Theme.faint
        font.family: Theme.mono
        font.pixelSize: root.crate ? Tokens.fMicro : Metrics.fontEyebrow * root.s
    }
}
