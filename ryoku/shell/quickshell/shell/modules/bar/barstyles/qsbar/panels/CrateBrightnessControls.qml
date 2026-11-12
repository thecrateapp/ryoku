import QtQuick
import QtQuick.Templates as T
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Column {
    id: controls

    required property int percent
    signal percentRequested(int percent)
    signal stepRequested(bool up)
    signal closeRequested()

    spacing: Tokens.s2

    Item {
        width: parent.width
        height: 32

        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.right: closeButton.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Brightness")
            tone: "accent"
        }
        Kit.IconButton {
            id: closeButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            glyph: "close"
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Close")
            Accessible.onPressAction: controls.closeRequested()
            onClicked: controls.closeRequested()
        }
    }

    Item {
        width: parent.width
        height: 36

        Kit.Glyph {
            id: sun
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: "brightness_high"
            color: Tokens.inkSecondary
            size: 18
            Accessible.ignored: true
        }
        T.Slider {
            id: level
            objectName: "brightnessSlider"
            anchors.left: sun.right
            anchors.right: readout.left
            anchors.leftMargin: Tokens.s3
            anchors.rightMargin: Tokens.s3
            height: parent.height
            from: 1
            to: 100
            stepSize: 1
            snapMode: T.Slider.SnapAlways
            value: controls.percent
            hoverEnabled: true
            Accessible.name: I18n.tr("Brightness")
            onMoved: controls.percentRequested(Math.round(value))
            background: Kit.Beam {
                from: level.from
                to: level.to
                value: level.value
                interactive: false
                hotHint: level.hovered || level.pressed || level.visualFocus
                Accessible.ignored: true
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
        Text {
            id: readout
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.ceil(percentMetrics.advanceWidth)
            horizontalAlignment: Text.AlignRight
            color: Tokens.ink
            text: controls.percent + "%"
            font.family: Tokens.mono
            font.pixelSize: Tokens.px(13)
            font.features: { "tnum": 1 }
            TextMetrics {
                id: percentMetrics
                font: readout.font
                text: "100%"
            }
        }
    }

    Kit.Divider { width: parent.width; quiet: true }

    Row {
        width: parent.width
        spacing: Tokens.s2
        Kit.Btn {
            width: (parent.width - parent.spacing) / 2
            text: "− 5%"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Decrease brightness")
            Accessible.onPressAction: controls.stepRequested(false)
            onAct: controls.stepRequested(false)
        }
        Kit.Btn {
            width: (parent.width - parent.spacing) / 2
            text: "+ 5%"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Increase brightness")
            Accessible.onPressAction: controls.stepRequested(true)
            onAct: controls.stepRequested(true)
        }
    }
}
