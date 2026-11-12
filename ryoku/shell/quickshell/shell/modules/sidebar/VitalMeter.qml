pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import shell.services

Item {
    id: root

    required property real s
    required property string label
    required property string valueText
    property string tooltipText: ""
    property bool showProgress: false
    property real progressValue: 0
    property real progressMaximum: 100
    property int settle: Tokens.flap
    property color accent: Tokens.inkDim
    property Component meterContent: null
    // crate-mark: a list of meters shares one caption width (see Kit.MeterRow)
    property real labelWidth: 0
    readonly property real labelImplicitWidth: crateRow.labelImplicitWidth

    implicitHeight: (Tokens.s5 + Tokens.s1) * s
    clip: true

    readonly property real progressRatio: showProgress && isFinite(progressValue) && progressMaximum > 0
                                                 ? Math.max(0, Math.min(1, progressValue / progressMaximum))
                                                 : 0

    // crate-mark: the kit's meter row (caption, read-only Beam, mono value)
    Kit.MeterRow {
        id: crateRow
        visible: Tokens.controlsCrate
        anchors.fill: parent
        s: root.s
        labelWidth: root.labelWidth
        label: root.label
        valueText: root.valueText
        fraction: root.progressRatio
        showMeter: root.showProgress
        meter: root.meterContent
    }

    Item {
        id: stock
        visible: !Tokens.controlsCrate
        anchors.fill: parent

        Text {
            id: heading
            anchors.left: parent.left
            anchors.top: parent.top
            width: Math.min(implicitWidth, Math.max(0, parent.width - Tokens.s7 * root.s))
            text: root.label.toUpperCase()
            textFormat: Text.PlainText
            color: Tokens.inkMuted
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro * root.s
            font.letterSpacing: Tokens.trackLabel * root.s
            elide: Text.ElideRight
        }

        Text {
            anchors.left: heading.right
            anchors.leftMargin: Tokens.s2 * root.s
            anchors.right: parent.right
            anchors.top: parent.top
            text: root.valueText
            textFormat: Text.PlainText
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall * root.s
            font.weight: Font.DemiBold
            elide: Text.ElideLeft
            horizontalAlignment: Text.AlignRight
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.meterContent ? Tokens.s3 * root.s : Tokens.border * 3 * root.s
            clip: true

            Rectangle {
                visible: root.showProgress && root.meterContent === null
                anchors.fill: parent
                radius: Math.min(height / 2, Tokens.radius * root.s)
                color: Tokens.inkFaint

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root.progressRatio
                    radius: parent.radius
                    color: root.accent

                    Behavior on width {
                        enabled: !Tokens.reduceMotion && !Motion.reduce
                        NumberAnimation { duration: root.settle; easing.type: Easing.Linear }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: root.visible && stock.visible && root.meterContent !== null
                sourceComponent: root.meterContent
            }
        }
    }

    HoverHandler {
        id: meterHover
    }

    CornerTip { s: root.s; visible: meterHover.hovered && root.tooltipText.length > 0; text: root.tooltipText }
}
