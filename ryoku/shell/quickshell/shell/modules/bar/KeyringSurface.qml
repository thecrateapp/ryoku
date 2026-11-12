pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import shell.services
import "../../components"
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit

// keyring password island, grown from the pill centre. renders the GNOME
// keyring prompt the ryoku-shell daemon receives as the system prompter:
// "unlock the keyring" pw ask, "choose a pw for a new keyring" (with confirm
// field), or a plain confirm. typed secret goes to the daemon (Keyring
// singleton) over the control socket, never as an arg.
//
// state lives in Keyring; this only renders + collects input -- the project's
// view/daemon split.
PillSurface {
    id: root

    mTop: 16
    mLeft: 22
    mRight: 22
    mBottom: 16

    ameForm: "off"

    readonly property bool isPassword: Keyring.promptType === "password"
    readonly property bool isPasswordNew: root.isPassword && Keyring.passwordNew
    property bool mismatch: false

    readonly property string continueText: Keyring.continueLabel !== ""
        ? Keyring.continueLabel
        : (root.isPasswordNew ? I18n.tr("Continue") : (root.isPassword ? I18n.tr("Unlock") : I18n.tr("Continue")))
    readonly property string cancelText: Keyring.cancelLabel !== "" ? Keyring.cancelLabel : I18n.tr("Cancel")
    readonly property string headerText: Keyring.title !== ""
        ? Keyring.title
        : (root.isPasswordNew ? I18n.tr("New keyring password") : (root.isPassword ? I18n.tr("Unlock keyring") : I18n.tr("Confirm")))
    readonly property string warnText: root.mismatch ? I18n.tr("Passwords do not match") : Keyring.warning

    implicitHeight: col.implicitHeight

    function reset() {
        field1.text = "";
        field2.text = "";
        root.mismatch = false;
        choiceBox.checked = Keyring.choiceChosen;
        if (root.isPassword)
            field1.forceActiveFocus();
        else
            root.forceActiveFocus();
    }

    function trySubmit() {
        if (Keyring.busy)
            return;
        if (root.isPasswordNew && field1.text !== field2.text) {
            root.mismatch = true;
            field2.forceActiveFocus();
            return;
        }
        root.mismatch = false;
        Keyring.submit(root.isPassword ? field1.text : "", choiceBox.checked);
    }

    onOpenChanged: if (open) reset()

    Connections {
        target: Keyring
        function onOpened() { root.reset(); }
    }

    // enter/escape for the confirm prompt (no text field to carry them);
    // the pw fields handle enter themselves and let escape bubble.
    Keys.onReturnPressed: root.trySubmit()
    Keys.onEnterPressed: root.trySubmit()
    Keys.onEscapePressed: root.requestClose()

    Column {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 11 * root.s

        Row {
            spacing: 10 * root.s
            width: parent.width

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * root.s
                height: 30 * root.s
                radius: width / 2
                // crate-mark: a plateless Solar lock in the mark
                color: Tokens.controlsCrate ? "transparent" : Qt.alpha(Theme.primary, 0.14)
                border.width: Tokens.controlsCrate ? 0 : 1
                border.color: Qt.alpha(Theme.primary, 0.40)

                Kit.Glyph {
                    visible: Tokens.controlsCrate
                    anchors.centerIn: parent
                    name: "lock"
                    size: 18 * root.s
                    color: Tokens.mark
                }

                GlyphIcon {
                    visible: !Tokens.controlsCrate
                    anchors.centerIn: parent
                    width: 16 * root.s
                    height: 16 * root.s
                    name: "lock-round"
                    color: Theme.primary
                    stroke: 1.8
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 * root.s
                text: root.headerText
                color: Theme.onSurface
                font.family: Theme.fontPrimary
                font.pixelSize: 14 * root.s
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        Text {
            width: parent.width
            visible: Keyring.message !== ""
            text: Keyring.message
            color: Theme.onSurface
            font.family: Theme.fontPrimary
            font.pixelSize: 11.5 * root.s
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }

        Text {
            width: parent.width
            visible: Keyring.description !== ""
            text: Keyring.description
            color: Theme.onSurfaceVariant
            font.family: Theme.fontPrimary
            font.pixelSize: 10.5 * root.s
            wrapMode: Text.WordWrap
        }

        // password (+ optional confirm) fields
        Rectangle {
            id: field1Box
            visible: root.isPassword
            width: parent.width
            height: 36 * root.s
            // crate-mark: the kit Field's frame: radius 6, a hairline, the mark on focus
            radius: Tokens.controlsCrate ? 6 * root.s : Theme.radiusWidget
            color: Tokens.controlsCrate ? "transparent" : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Tokens.controlsCrate ? (field1.activeFocus ? Tokens.mark : Tokens.line)
                : field1.activeFocus ? Theme.frameBorder : Theme.outline
            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

            TextField {
                id: field1
                anchors.fill: parent
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                background: null
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "\u2022"
                color: Theme.onSurface
                font.family: Theme.fontPrimary
                font.pixelSize: 13 * root.s
                placeholderText: root.isPasswordNew ? I18n.tr("New password") : I18n.tr("Password")
                placeholderTextColor: Theme.onSurfaceVariant
                selectByMouse: true
                selectionColor: Theme.primary
                enabled: !Keyring.busy
                onTextChanged: root.mismatch = false
                onAccepted: root.isPasswordNew ? field2.forceActiveFocus() : root.trySubmit()
            }
        }

        Rectangle {
            id: field2Box
            visible: root.isPasswordNew
            width: parent.width
            height: 36 * root.s
            // crate-mark: the kit Field's frame: radius 6, a hairline, the mark on focus
            radius: Tokens.controlsCrate ? 6 * root.s : Theme.radiusWidget
            color: Tokens.controlsCrate ? "transparent" : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Tokens.controlsCrate ? (field2.activeFocus ? Tokens.mark : root.mismatch ? Tokens.alert : Tokens.line)
                : field2.activeFocus ? Theme.frameBorder : (root.mismatch ? Qt.alpha(Theme.primary, 0.6) : Theme.outline)
            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

            TextField {
                id: field2
                anchors.fill: parent
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                background: null
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "\u2022"
                color: Theme.onSurface
                font.family: Theme.fontPrimary
                font.pixelSize: 13 * root.s
                placeholderText: I18n.tr("Confirm password")
                placeholderTextColor: Theme.onSurfaceVariant
                selectByMouse: true
                selectionColor: Theme.primary
                enabled: !Keyring.busy
                onTextChanged: root.mismatch = false
                onAccepted: root.trySubmit()
            }
        }

        // optional "remember / auto-unlock" choice
        Row {
            visible: Keyring.choiceLabel !== ""
            width: parent.width
            spacing: 9 * root.s

            Rectangle {
                id: choiceBox
                property bool checked: false
                anchors.verticalCenter: parent.verticalCenter
                // crate-mark: the kit switch; this item keeps the state and the click
                width: (Tokens.controlsCrate ? 34 : 17) * root.s
                height: (Tokens.controlsCrate ? 18 : 17) * root.s
                radius: Theme.radiusWidget
                color: Tokens.controlsCrate ? "transparent" : checked ? Theme.primary : "transparent"
                border.width: Tokens.controlsCrate ? 0 : 1
                border.color: checked ? Theme.primary : Theme.outline

                Kit.Sw {
                    visible: Tokens.controlsCrate
                    anchors.fill: parent
                    on: choiceBox.checked
                    enabled: false
                }
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Text {
                    anchors.centerIn: parent
                    text: "\u2713"
                    visible: choiceBox.checked && !Tokens.controlsCrate
                    color: Theme.ink(Theme.primary)
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11 * root.s
                    font.weight: Font.Bold
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Keyring.busy
                    onClicked: choiceBox.checked = !choiceBox.checked
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 26 * root.s
                text: Keyring.choiceLabel
                color: Theme.onSurfaceVariant
                font.family: Theme.fontPrimary
                font.pixelSize: 10.5 * root.s
                wrapMode: Text.WordWrap
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Keyring.busy
                    onClicked: choiceBox.checked = !choiceBox.checked
                }
            }
        }

        // warning (wrong password / mismatch)
        Text {
            width: parent.width
            visible: root.warnText !== ""
            text: root.warnText
            color: Theme.vermLit
            font.family: Theme.fontPrimary
            font.pixelSize: 10.5 * root.s
            wrapMode: Text.WordWrap
        }

        // crate-mark: the kit's buttons, Continue filled and Cancel outlined
        Row {
            visible: Tokens.controlsCrate
            width: parent.width
            spacing: 8 * root.s
            layoutDirection: Qt.RightToLeft

            Kit.Btn {
                width: (parent.width - parent.spacing) / 2
                primary: true
                text: Keyring.busy ? I18n.tr("Checking\u2026") : root.continueText
                enabled: !Keyring.busy
                onAct: root.trySubmit()
            }
            Kit.Btn {
                width: (parent.width - parent.spacing) / 2
                outline: true
                text: root.cancelText
                onAct: root.requestClose()
            }
        }

        // buttons
        Row {
            visible: !Tokens.controlsCrate
            width: parent.width
            spacing: 9 * root.s
            layoutDirection: Qt.RightToLeft

            Rectangle {
                id: continueBtn
                width: (parent.width - parent.spacing) / 2
                height: 34 * root.s
                radius: Theme.radiusWidget
                color: continueArea.containsMouse ? Theme.vermLit : Theme.primary
                opacity: Keyring.busy ? 0.6 : 1
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Text {
                    anchors.centerIn: parent
                    text: Keyring.busy ? I18n.tr("Checking\u2026") : root.continueText
                    color: Theme.ink(Theme.primary)
                    font.family: Theme.fontPrimary
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: continueArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !Keyring.busy
                    onClicked: root.trySubmit()
                }
            }

            Rectangle {
                width: (parent.width - parent.spacing) / 2
                height: 34 * root.s
                radius: Theme.radiusWidget
                color: cancelArea.containsMouse ? Theme.frameBg : Theme.surfaceContainerHigh
                border.width: 1
                border.color: Theme.frameLine
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Text {
                    anchors.centerIn: parent
                    text: root.cancelText
                    color: Theme.onSurface
                    font.family: Theme.fontPrimary
                    font.pixelSize: 12 * root.s
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestClose()
                }
            }
        }
    }
}
