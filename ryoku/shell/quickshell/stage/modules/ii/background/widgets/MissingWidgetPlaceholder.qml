import QtQuick
import stage.services
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

Rectangle {
    id: placeholderRoot

    required property string widgetId
    required property real widgetX
    required property real widgetY

    visible: {
        if (!widgetId.startsWith("ext:")) return false;
        if (!WidgetExtensionManager.ready) return false;
        let extId = widgetId.substring(4);
        return !WidgetExtensionManager.isWidgetInstalled(extId);
    }

    // Under crate the placeholder is a glass card edged in the alert role,
    // its words in the kit's type: the stock warning reds are one ink each.
    readonly property bool crate: Tokens.controlsCrate
    readonly property color warnInk: crate ? Tokens.alert : "#ffaaaa"
    readonly property color iconInk: crate ? Tokens.alert : "#ff8a8a"

    x: widgetX
    y: widgetY
    width: 220
    height: 96
    radius: crate ? Tokens.radius : Appearance.rounding.large
    color: crate ? Tokens.glass
        : missingPlaceholderMouse.containsMouse
        ? Qt.rgba(0.12, 0, 0, 0.72)
        : Qt.rgba(0, 0, 0, 0.55)
    border.color: crate ? (missingPlaceholderMouse.containsMouse ? Tokens.alert : Tokens.line) : Qt.rgba(1, 0.4, 0.4, 0.5)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: missingPlaceholderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.removeWidgetFromDesktop(placeholderRoot.widgetId)
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 4

        Ui.Glyph {
            visible: placeholderRoot.crate
            name: "error"
            color: placeholderRoot.iconInk
            anchors.horizontalCenter: parent.horizontalCenter
        }
        MaterialSymbol {
            visible: !placeholderRoot.crate
            text: "extension_off"
            iconSize: 18
            color: placeholderRoot.iconInk
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: placeholderRoot.widgetId.substring(4) + "\nnot installed"
            color: placeholderRoot.crate ? Tokens.ink : placeholderRoot.warnInk
            font.family: placeholderRoot.crate ? Tokens.ui : Qt.application.font.family
            font.pixelSize: placeholderRoot.crate ? Tokens.fSmall : 10
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Remove hint
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: removeHintRow.implicitWidth + 16
            height: 20
            radius: placeholderRoot.crate ? Tokens.radius : height / 2
            color: placeholderRoot.crate ? Tokens.rowWash : Qt.rgba(1, 0.3, 0.3, 0.3)

            Row {
                id: removeHintRow
                anchors.centerIn: parent
                spacing: 3

                Ui.Glyph {
                    visible: placeholderRoot.crate
                    name: "close"
                    size: 10
                    color: placeholderRoot.warnInk
                    anchors.verticalCenter: parent.verticalCenter
                }
                MaterialSymbol {
                    visible: !placeholderRoot.crate
                    text: "close"
                    iconSize: 10
                    color: placeholderRoot.warnInk
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Click to remove"
                    color: placeholderRoot.warnInk
                    font.family: placeholderRoot.crate ? Tokens.mono : Qt.application.font.family
                    font.pixelSize: placeholderRoot.crate ? Tokens.fMicro : 9
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
