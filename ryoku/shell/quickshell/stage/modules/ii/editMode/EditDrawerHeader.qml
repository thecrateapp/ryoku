import QtQuick
import QtQuick.Layouts
import stage
import stage.services
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui
import Ryoku.Ui.Singletons

/**
 * The catalogue panel's header: the way back (or the section's mark when there
 * is nowhere to go back to), the "Stage editor" eyebrow and the page title.
 *
 * Under crate the way back is the kit's IconButton, the mark a Solar Glyph, the
 * eyebrow the kit's TrackLabel, and the lead bar and the rule beside the
 * eyebrow (Ryoku marginalia) do not show. Its own Item, so a probe can load it
 * without the panel's services.
 */
RowLayout {
    id: header

    property bool canGoBack: false
    property string symbol: ""
    property string title: ""
    signal backRequested()

    readonly property bool crate: Tokens.controlsCrate

    spacing: Appearance.sizes.space3

    // The section mark becomes a back action on sub-pages and
    // provider pages with an explicit return destination.
    // Under crate: the kit's IconButton going back, the
    // section's Solar glyph when there is nowhere to go.
    Item {
        objectName: "editDrawerKitBack"
        visible: header.crate
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Appearance.sizes.controlHeight
        implicitHeight: Appearance.sizes.controlHeight

        IconButton {
            objectName: "editDrawerBackButton"
            anchors.centerIn: parent
            visible: header.canGoBack
            width: parent.width
            height: parent.height
            glyph: "arrow_back"
            onClicked: header.backRequested()
        }
        Glyph {
            anchors.centerIn: parent
            visible: !header.canGoBack
            name: header.symbol
            color: Tokens.inkSecondary
        }
    }

    Rectangle {
        visible: !header.crate
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Appearance.sizes.controlHeight
        implicitHeight: Appearance.sizes.controlHeight
        radius: Appearance.rounding.small
        color: !header.canGoBack ? "transparent"
            : backMouse.containsPress
                ? Appearance.colors.colLayer1Active
                : backMouse.containsMouse
                    ? Appearance.colors.colLayer1Hover
                    : "transparent"
        border.width: 1
        border.color: header.canGoBack
            ? Appearance.colors.colOutlineVariant : "transparent"

        Behavior on color {
            enabled: !Appearance.reducedMotion
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: header.canGoBack ? "arrow_back" : header.symbol
            iconSize: 18
            color: Appearance.colors.colOnSurface
        }

        MouseArea {
            id: backMouse
            anchors.fill: parent
            enabled: header.canGoBack
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.backRequested()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 1

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Appearance.sizes.space2

            Rectangle {
                objectName: "editDrawerLeadBar"
                visible: !header.crate
                implicitWidth: 2
                implicitHeight: 10
                radius: 1
                color: Appearance.colors.colOnSurfaceVariant
            }
            TrackLabel {
                objectName: "editDrawerEyebrow"
                visible: header.crate
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: Translation.tr("Stage editor")
            }
            StyledText {
                visible: !header.crate
                text: Translation.tr("Stage editor").toUpperCase()
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.Medium
                font.letterSpacing: Appearance.font.trackLabel
                color: Appearance.colors.colSubtext
            }
            Rectangle {
                objectName: "editDrawerRule"
                visible: !header.crate
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: header.title
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnSurface
            elide: Text.ElideRight
        }
    }
}
