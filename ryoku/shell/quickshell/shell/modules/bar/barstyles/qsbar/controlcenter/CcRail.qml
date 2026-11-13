import QtQuick
import "../modules"
import "kit/Routes.js" as Routes
import Ryoku.Ui
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import shell.services

// QS Bar Settings' left rail: five first-party routes as one flat group, then,
// parted by a rule and a COMMUNITY eyebrow, the route for every bar widget
// installed from outside Ryoku. The panel is about one thing, the bar, so the
// first group has no headers and stays one click away. Latin names the route,
// kanji seals it. The active route takes a bone plate with a `//` lead, the
// desktop's only emphasis; nothing here is coloured except the 力 seal.
Item {
    id: rail

    property var root
    property var tk
    property string current: ""
    signal chose(string id)

    // Under controls "crate" the rail speaks the crate panels' selection: the live
    // route in the mark with a 1 px pick edge (as a connected network row), no bar,
    // no register texture and no seal; the masthead is a plain tracked caption.
    readonly property bool crate: Tokens.controlsCrate

    // Installed bar plugins that are not Ryoku's own: the Community route's count.
    readonly property int communityCount: {
        var c = (rail.root && rail.root.barCatalog) ? rail.root.barCatalog : []
        var n = 0
        for (var i = 0; i < c.length; i++)
            if (c[i].kind === "plugin" && c[i].official !== true) n++
        return n
    }

    // The plate takes its height from whichever is taller, the rail or the page:
    // the masthead and the routes, each with the gap it actually sits in.
    implicitHeight: rail.tk
        ? masthead.height + nav.implicitHeight + rail.tk.gap * 2 + rail.tk.pad * 2
        : 560

    // one route in the rail; a count on the right when the route carries one.
    component NavItem: Rectangle {
        id: item
        required property var modelData
        property int count: -1
        readonly property bool on: rail.current === item.modelData.id

        width: nav.width - rail.tk.gap * 2
        x: rail.tk.gap
        height: rail.tk.navH
        radius: Tokens.radius
        color: rail.crate ? "transparent"
            : item.on ? (Tokens.selectFill ? Tokens.bone : "transparent")
            : (ma.containsMouse && !Tokens.accentMarks ? Tokens.tint5 : "transparent")
        Behavior on color { ColorAnimation { duration: Tokens.snap } }
        border.width: rail.crate && (item.on || ma.containsMouse) ? 1 : 0
        border.color: item.on ? Tokens.pickEdge : Tokens.markHover

        // a theme that drops the selection fill marks the live route with a bar
        Rectangle {
            visible: item.on && !Tokens.selectFill && !rail.crate
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 2; height: parent.height - Tokens.s4; radius: 1
            color: Tokens.mark
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: rail.tk.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: rail.tk.gap / 2

            // the `//` lead: the desktop's mark of the live surface,
            // printed only on the selected route.
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                visible: item.on && Tokens.selectFill
                text: "//"
                color: Tokens.inkOnBoneDim
                font.family: Tokens.mono
                font.pixelSize: Tokens.fMicro
            }
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr(item.modelData.label)
                color: rail.crate ? (item.on ? Tokens.mark : ma.containsMouse ? Tokens.ink : Tokens.inkSecondary)
                    : item.on ? (Tokens.selectFill ? Tokens.inkOnBone : Tokens.ink)
                    : (ma.containsMouse && Tokens.accentMarks ? Tokens.hoverInk : Tokens.inkDim)
                font.family: Tokens.navCaps ? Tokens.navFont : Tokens.ui
                font.pixelSize: Tokens.navCaps ? Tokens.fMicro : Tokens.fBody
                font.capitalization: Tokens.navCaps ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: Tokens.trackNav
                font.weight: item.on && !rail.crate ? Font.DemiBold : Font.Normal
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: rail.tk.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: rail.tk.gap / 2
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                visible: item.count >= 0
                text: String(item.count)
                color: item.on && Tokens.selectFill ? Tokens.inkOnBoneDim : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny
            }
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                text: UiPreferences.text(item.modelData.gloss || "", "")
                color: item.on && Tokens.selectFill ? Tokens.inkOnBoneDim : Tokens.inkFaint
                font.family: Tokens.jp
                font.pixelSize: Tokens.fTiny
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rail.chose(item.modelData.id)
        }
    }

    // the register sheet rides behind the rail only, exactly as the Hub's does:
    // the chrome carries the print texture, the content plate stays clean paper.
    Reg { anchors.fill: parent; visible: !rail.crate }

    // ── masthead ─────────────────────────────────────────────────────────────
    Item {
        id: masthead
        anchors { top: parent.top; left: parent.left; right: parent.right }
        // crate: one header line high, centred on the body's crate head line
        height: rail.crate ? rail.tk.pad * 2 + 32 : rail.tk.headH

        Kit.TrackLabel {
            visible: rail.crate
            anchors.left: parent.left
            anchors.leftMargin: rail.tk.pad
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Settings")
        }
        Row {
            visible: !rail.crate
            anchors.left: parent.left
            anchors.leftMargin: rail.tk.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: rail.tk.gap / 2

            UiText {
                anchors.verticalCenter: parent.verticalCenter
                text: UiPreferences.brandMark("\u529b")
                color: Tokens.sun
                font.family: Tokens.jp
                font.pixelSize: Tokens.fBody
            }
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                text: "RYOKU"
                color: Tokens.ink
                font.family: Tokens.mono
                font.pixelSize: Tokens.fMicro
                font.letterSpacing: Tokens.trackMark
                font.weight: Font.DemiBold
            }
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("QS BAR SETTINGS")
                color: Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny
                font.letterSpacing: Tokens.trackLabel
            }
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Tokens.lineSoft
        }
    }

    // ── the five first-party routes, one flat group ──────────────────────────
    Column {
        id: nav
        anchors {
            top: masthead.bottom; topMargin: rail.tk.gap
            left: parent.left; right: parent.right
        }
        spacing: 4

        Repeater {
            model: Routes.inSection("bar")
            delegate: NavItem {}
        }

        // ── the part: a rule and the COMMUNITY eyebrow, then its route ──
        Item {
            width: nav.width
            height: rail.tk.gap * 2 + partLabel.implicitHeight
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: rail.tk.gap - 2 }
                anchors.leftMargin: rail.tk.gap * 2
                anchors.rightMargin: rail.tk.gap * 2
                height: 1
                color: Tokens.lineSoft
            }
            UiText {
                id: partLabel
                anchors.left: parent.left
                anchors.leftMargin: rail.tk.gap * 2
                anchors.bottom: parent.bottom
                text: I18n.tr("COMMUNITY")
                color: Tokens.labelAccent ? Tokens.caption : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: Tokens.fMicro
                font.letterSpacing: rail.crate ? Tokens.trackLabel : Tokens.trackMark
                font.weight: rail.crate ? Font.Normal : Font.DemiBold
            }
        }
        Repeater {
            model: Routes.inSection("community")
            delegate: NavItem { count: rail.communityCount }
        }
    }

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 1
        color: Tokens.lineSoft
    }
}
