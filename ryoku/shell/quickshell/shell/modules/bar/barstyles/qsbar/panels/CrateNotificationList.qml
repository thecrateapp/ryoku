pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar notification history under the crate look: the pending count in
// the title, each notification as a hairline card in the popup card's language
// (app caption in the accent, summary, two lines of body, a dismiss button),
// scrolling inside the panel's cap, then Clear all. It reads and drives only
// the panel: pending [{key, appName, summary, body}], unreadCount, listCap,
// openNotification(entry), dismissOne(entry) and dismissAll().
Column {
    id: details
    required property var panel
    readonly property var entries: details.panel.pending || []
    signal closeRequested()
    spacing: Tokens.s3

    CrateResourceHeader {
        objectName: "notifTitle"
        width: parent.width
        title: details.panel.unreadCount > 0
            ? I18n.tr("Notifications · %1").arg(details.panel.unreadCount)
            : I18n.tr("Notifications")
        closeObjectName: "closeNotifications"
        onCloseRequested: details.closeRequested()
    }

    Flickable {
        id: scroll
        objectName: "notifScroll"
        width: parent.width
        height: Math.min(cards.implicitHeight, details.panel.listCap)
        visible: details.entries.length > 0
        contentHeight: cards.implicitHeight
        clip: true
        interactive: cards.implicitHeight > details.panel.listCap
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: cards
            objectName: "notifCards"
            width: scroll.width
            spacing: Tokens.s2

            Repeater {
                model: details.entries

                Rectangle {
                    id: card
                    required property var modelData
                    objectName: "notif-" + modelData.key
                    readonly property bool hot: hover.hovered
                    function activate() { details.panel.openNotification(card.modelData) }

                    width: cards.width
                    height: body.implicitHeight + Tokens.s3 * 2
                    radius: Tokens.radius
                    color: "transparent"
                    border.width: Tokens.border
                    border.color: card.hot ? Tokens.markHover : Tokens.line
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: (modelData.appName || "") + ": " + (modelData.summary || "")
                    Accessible.onPressAction: card.activate()
                    Keys.onReturnPressed: card.activate()
                    Keys.onDeletePressed: details.panel.dismissOne(card.modelData)

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.activate() }

                    Column {
                        id: body
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.s3
                        spacing: Tokens.s1

                        Item {
                            width: parent.width
                            height: Math.max(app.implicitHeight, dismiss.height)
                            Kit.TrackLabel {
                                id: app
                                objectName: "notifApp"
                                anchors.left: parent.left
                                anchors.right: dismiss.left
                                anchors.rightMargin: Tokens.s2
                                anchors.verticalCenter: parent.verticalCenter
                                text: card.modelData.appName || I18n.tr("App")
                                font.capitalization: Font.MixedCase
                                tone: "accent"
                            }
                            Kit.IconButton {
                                id: dismiss
                                objectName: "notifDismiss"
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 24
                                iconSize: 14
                                glyph: "close"
                                Accessible.role: Accessible.Button
                                Accessible.name: I18n.tr("Dismiss")
                                Accessible.onPressAction: details.panel.dismissOne(card.modelData)
                                onClicked: details.panel.dismissOne(card.modelData)
                            }
                        }
                        Text {
                            objectName: "notifSummary"
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.summary || ""
                            color: Tokens.ink
                            font.family: Tokens.mono
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            objectName: "notifBody"
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.body || ""
                            textFormat: Text.PlainText
                            color: Tokens.inkMuted
                            font.family: Tokens.mono
                            font.pixelSize: 12
                            lineHeight: 1.35
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Text {
        objectName: "notifEmpty"
        visible: details.entries.length === 0
        width: parent.width
        text: I18n.tr("No notifications")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
    }

    Kit.Btn {
        objectName: "notifClearAll"
        width: parent.width
        visible: details.entries.length > 0
        text: I18n.tr("Clear all")
        outline: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: text
        Accessible.onPressAction: details.panel.dismissAll()
        onAct: details.panel.dismissAll()
    }
}
