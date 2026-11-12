import QtQuick
import "Singletons"
import Ryoku.Ui.Singletons as Ui

// The rule yields all available width to the section name before collapsing,
// so translated labels stay readable in a narrow docked inspector.
Item {
    id: sec

    readonly property bool ryoSection: true

    property string label: ""
    property string gloss: ""

    width: parent ? parent.width : 0
    implicitHeight: sec.label.length > 0 ? 26 : 13

    // crate-mark: the kit's tracked mono caption over a hairline, no tick
    readonly property bool crate: Ui.Tokens.controlsCrate

    Rectangle {
        id: tick
        visible: sec.label.length > 0 && !sec.crate
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 8
        color: Theme.ink
    }

    TextMetrics {
        id: glossMetrics
        text: Ui.UiPreferences.text(sec.gloss, "")
        font.family: Theme.fontJp
        font.pixelSize: 9
    }

    TextMetrics {
        id: labelMetrics
        text: sec.label.toUpperCase()
        font.family: sec.crate ? Ui.Tokens.mono : Theme.font
        font.pixelSize: sec.crate ? Ui.Tokens.fMicro : 9
        font.weight: sec.crate ? Font.Normal : Font.DemiBold
        font.letterSpacing: sec.crate ? Ui.Tokens.trackLabel : 1.6
    }

    Text {
        id: gl
        visible: Ui.UiPreferences.showJapaneseGloss && sec.gloss.length > 0 && sec.label.length > 0
        x: tick.x + tick.width + 7
        width: visible ? glossMetrics.advanceWidth : 0
        anchors.verticalCenter: parent.verticalCenter
        text: sec.gloss
        color: Theme.faint
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: Theme.fontJp
        font.pixelSize: 9
    }

    Text {
        id: cap
        visible: sec.label.length > 0
        x: gl.visible ? gl.x + gl.width + 7 : sec.crate ? 0 : tick.x + tick.width + 7
        width: visible ? Math.min(labelMetrics.advanceWidth,
            Math.max(0, sec.width - x - 7)) : 0
        anchors.verticalCenter: parent.verticalCenter
        text: sec.label.toUpperCase()
        color: sec.crate ? (Ui.Tokens.labelAccent ? Ui.Tokens.caption : Ui.Tokens.inkSubtle)
            : Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.78)
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: sec.crate ? Ui.Tokens.mono : Theme.font
        font.pixelSize: sec.crate ? Ui.Tokens.fMicro : 9
        font.weight: sec.crate ? Font.Normal : Font.DemiBold
        font.letterSpacing: sec.crate ? Ui.Tokens.trackLabel : 1.6
    }

    Rectangle {
        x: sec.label.length > 0 ? cap.x + cap.width + 7 : 0
        width: Math.max(0, sec.width - x)
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: sec.crate ? Ui.Tokens.line : Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.4)
    }
}
