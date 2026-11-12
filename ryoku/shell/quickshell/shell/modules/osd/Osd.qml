pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import shell.services
import "../../components"

// The shipped OSD stays presentation-only: an icon, value bar and percentage.
// Its source owns device state and timing so installed designs see the same data.
Item {
    id: root

    property string kind: "volume"
    property real us: 1
    property real value: 0
    property real maxValue: 1
    property bool muted: false
    property string iconName: ""
    readonly property bool over: root.value > 1.005

    // Base logical size is scaled per output without changing compositor scale.
    implicitWidth: (Tokens.controlsCrate ? 288 : 250) * root.us
    implicitHeight: (Tokens.controlsCrate ? 24 : 40) * root.us

    // crate-mark: the mark's glyph, a Beam (the part past 100 % in alert, past
    // the mark) and the value, 12 px apart, as in the approved mock-up
    Row {
        visible: Tokens.controlsCrate
        anchors.fill: parent
        spacing: 12 * root.us

        Kit.Glyph {
            id: crateGlyph
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: 18 * root.us
            color: root.over ? Tokens.alert : root.muted ? Tokens.inkSecondary : Tokens.mark
        }

        Kit.Beam {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - crateGlyph.width - crateValue.width - parent.spacing * 2
            height: 24 * root.us
            interactive: false
            from: 0
            to: 1
            limit: root.maxValue > 1.005 ? root.maxValue : 0
            value: root.value
            opacity: root.muted ? 0.4 : 1
        }

        Text {
            id: crateValue
            anchors.verticalCenter: parent.verticalCenter
            width: 44 * root.us
            horizontalAlignment: Text.AlignRight
            text: root.muted ? I18n.tr("Muted") : Math.round(root.value * 100) + "%"
            color: root.over ? Tokens.alert : root.muted ? Tokens.inkFaint2 : Tokens.ink
            font.family: Tokens.mono
            font.pixelSize: 12 * root.us
            font.features: { "tnum": 1 }
        }
    }

    Item {
        id: stock
        visible: !Tokens.controlsCrate
        anchors.fill: parent

        SymbolIcon {
            id: glyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: root.iconName
            size: 40 * root.us
            color: Theme.onSurface
        }

        Rectangle {
            id: trough
            anchors.left: glyph.right
            anchors.leftMargin: 16 * root.us
            anchors.right: pct.left
            anchors.rightMargin: 16 * root.us
            anchors.verticalCenter: parent.verticalCenter
            height: 6 * root.us
            radius: Theme.radiusWidget * root.us
            color: Theme.surfaceContainerLow

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (Math.min(root.value, 1) / root.maxValue)
                radius: parent.radius
                color: Theme.secondary
                visible: width > 0
            }

            Rectangle {
                x: Math.round(parent.width / root.maxValue)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (Math.max(0, root.value - 1) / root.maxValue)
                radius: parent.radius
                color: Theme.error
                visible: width > 0.5
            }

            Rectangle {
                x: Math.round(parent.width / root.maxValue) - root.us
                anchors.verticalCenter: parent.verticalCenter
                width: 2 * root.us
                height: parent.height + 4 * root.us
                radius: 1 * root.us
                color: Theme.onSurface
                opacity: 0.55
                visible: root.maxValue > 1.005
            }
        }

        Text {
            id: pct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 46 * root.us
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.value * 100) + "%"
            color: root.over ? Theme.error : Theme.onSurface
            font.family: Theme.mono
            font.pixelSize: Theme.fontMd * root.us
        }
    }
}
