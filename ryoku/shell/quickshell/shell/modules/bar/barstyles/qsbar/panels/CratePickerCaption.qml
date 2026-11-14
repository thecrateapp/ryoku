import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The caption under a QS Bar picker's focused image under crate, one for every
// pickerStyle (tanzaku, hearthstone, carousel) and both pickers (themes and
// wallpapers, screenshots and videos): the item's name, a theme's swatches, the
// current badge and the theme's author, the typed filter as a read-only kit
// Field, then the key hint or, while a delete is armed, its prompt. The layout
// above it (strips, cards, slices) is the picker's own.
Column {
    id: caption

    property string title: ""
    property var swatches: []
    property bool current: false
    property string author: ""
    property string filterText: ""
    property string hint: ""
    property string confirm: ""
    signal openAuthor()

    spacing: Tokens.s3

    Text {
        objectName: "pickerTitleKit"
        anchors.horizontalCenter: parent.horizontalCenter
        width: caption.width
        text: caption.title
        color: Tokens.ink
        font.family: Tokens.ui
        font.pixelSize: Tokens.fValue
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    // a theme's vivid colours, the kit's colour sample
    Row {
        visible: caption.swatches.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.s1 + 2
        Repeater {
            model: caption.swatches
            delegate: Rectangle {
                required property var modelData
                required property int index
                objectName: "pickerSwatch-" + index
                width: Tokens.s3
                height: Tokens.s3
                radius: Tokens.radius / 3
                color: modelData
                border.width: Tokens.border
                border.color: Tokens.lineStrong
            }
        }
    }

    Row {
        visible: caption.current || caption.author.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.s3

        // the picked mark (PickCard's dot and halo) beside an active label
        Row {
            objectName: "pickerCurrentKit"
            visible: caption.current
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.s2
            Item {
                width: 12
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22) }
                Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: Tokens.mark }
            }
            Kit.TrackLabel {
                anchors.verticalCenter: parent.verticalCenter
                tone: "active"
                text: I18n.tr("Current")
            }
        }
        Kit.Btn {
            objectName: "pickerAuthorKit"
            visible: caption.author.length > 0
            anchors.verticalCenter: parent.verticalCenter
            outline: true
            compact: true
            text: I18n.tr("by %1").arg(caption.author)
            onAct: caption.openAuthor()
        }
    }

    Kit.Field {
        objectName: "pickerFilterKit"
        visible: caption.filterText.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(caption.width, 280)
        // it shows what the picker's keys typed; the picker keeps the keyboard
        enabled: false
        readOnly: true
        glyph: "search"
        text: caption.filterText
    }

    Kit.TrackLabel {
        objectName: "pickerConfirmKit"
        visible: caption.confirm.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        color: Tokens.alert
        text: caption.confirm
    }
    Kit.TrackLabel {
        objectName: "pickerHintKit"
        visible: caption.confirm.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(implicitWidth, caption.width)
        horizontalAlignment: Text.AlignHCenter
        text: caption.hint
    }
}
