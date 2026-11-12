pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"
import "lib/rows.js" as Rows

// A level row, crate-mark's volume and brightness line: an icon that toggles mute,
// a tracked caption, an interactive Beam, the value (click it to type an exact
// percent) and a chevron that opens a drawer, on the columns in lib/rows.js.
// The value is controlled: the row emits adjusted() and the owner sets `value`.
// The icon is an SVG path (`iconPath`, a 24-unit Solar-style line icon) or a font
// glyph (`glyph` in `glyphFont`).
Item {
    id: row

    property real s: 1
    // a group of rows sets this to the widest caption so the beams line up
    property real labelWidth: 0
    readonly property real labelImplicitWidth: caption.implicitWidth
    property string label: ""
    property string iconPath: ""
    property string glyph: ""
    property string glyphFont: "Material Symbols Rounded"
    property real value: 0
    property real from: 0
    property bool available: true
    property bool muted: false
    property bool muteEnabled: false
    property bool expandable: true
    property bool expanded: false

    signal adjusted(real value)
    signal muteRequested()
    signal expandedRequested(bool expanded)

    readonly property bool hasIcon: row.iconPath.length > 0 || row.glyph.length > 0
    readonly property var cols: Rows.levelColumns(row.width, { s: row.s, labelWidth: row.labelWidth, icon: row.hasIcon, chevron: row.expandable })
    readonly property int percent: Math.round(row.clamp(row.value) * 100)
    readonly property bool editing: input.visible

    function clamp(v) {
        return Math.max(row.from, Math.min(1, v));
    }

    function beginEditing() {
        if (!row.available)
            return;
        input.text = String(row.percent);
        input.visible = true;
        input.forceActiveFocus();
        input.selectAll();
    }

    function finishEditing() {
        if (!input.visible)
            return;
        const parsed = Number(input.text);
        input.visible = false;
        if (input.text.length > 0 && !isNaN(parsed))
            row.adjusted(row.clamp(parsed / 100));
    }

    implicitWidth: 360 * row.s
    implicitHeight: Rows.ROW.level * row.s
    opacity: row.available ? 1 : 0.58

    IconButton {
        visible: row.hasIcon
        x: row.cols.icon.x + row.cols.icon.w / 2 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 28 * row.s
        height: width
        iconSize: 18 * row.s
        path: row.iconPath
        glyph: row.glyph
        glyphFont: row.glyphFont
        alert: row.muted
        enabled: row.available && row.muteEnabled
        opacity: 1
        Accessible.name: row.muted ? I18n.tr("Unmute %1").arg(row.label) : I18n.tr("Mute %1").arg(row.label)
        onClicked: row.muteRequested()
    }

    TrackLabel {
        id: caption
        x: row.cols.label.x
        width: row.cols.label.w
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        font.pixelSize: Tokens.fMicro * row.s
        font.letterSpacing: Tokens.trackLabel * row.s
    }

    Beam {
        id: beam
        x: row.cols.beam.x
        width: row.cols.beam.w
        height: 24 * row.s
        anchors.verticalCenter: parent.verticalCenter
        from: row.from
        to: 1
        stepSize: 0.01
        value: row.clamp(row.value)
        interactive: row.available
        opacity: row.muted || !row.available ? 0.4 : 1
        Accessible.name: row.label
        onMoved: v => row.adjusted(row.clamp(v))

        WheelHandler {
            enabled: row.available
            onWheel: event => {
                row.adjusted(row.clamp(row.value + (event.angleDelta.y >= 0 ? 0.02 : -0.02)));
                event.accepted = true;
            }
        }
    }

    Rectangle {
        id: valueBox
        x: row.cols.value.x - 4 * row.s
        width: row.cols.value.w + 4 * row.s
        height: 24 * row.s
        anchors.verticalCenter: parent.verticalCenter
        radius: 6 * row.s
        color: input.visible ? Tokens.tint10 : valueHover.hovered && row.available ? Tokens.tint5 : "transparent"

        Text {
            anchors.fill: parent
            anchors.rightMargin: 0
            visible: !input.visible
            text: !row.available ? "—" : row.muted ? I18n.tr("Muted") : row.percent + "%"
            textFormat: Text.PlainText
            color: row.muted || !row.available ? Tokens.inkFaint2 : Tokens.ink
            font.family: Tokens.mono
            font.pixelSize: 12 * row.s
            font.features: { "tnum": 1 }
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideLeft
        }

        TextInput {
            id: input
            visible: false
            anchors.fill: parent
            color: Tokens.ink
            selectionColor: Tokens.mark
            selectedTextColor: Tokens.paper
            font.family: Tokens.mono
            font.pixelSize: 12 * row.s
            horizontalAlignment: TextInput.AlignRight
            verticalAlignment: TextInput.AlignVCenter
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: Math.round(row.from * 100); top: 100 }
            onAccepted: row.finishEditing()
            onActiveFocusChanged: if (!activeFocus) row.finishEditing()
            Keys.onEscapePressed: visible = false
        }

        HoverHandler { id: valueHover; enabled: row.available; cursorShape: Qt.IBeamCursor }
        TapHandler { enabled: row.available && !input.visible; onTapped: row.beginEditing() }
    }

    IconButton {
        visible: row.expandable
        x: row.cols.chevron.x
        anchors.verticalCenter: parent.verticalCenter
        width: row.cols.chevron.w
        height: width
        iconSize: 16 * row.s
        glyph: "expand_more"
        glyphFont: "Material Symbols Rounded"
        on: row.expanded
        rotation: row.expanded ? 180 : 0
        Behavior on rotation {
            enabled: !Tokens.reduceMotion
            NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease }
        }
        Accessible.name: row.expanded ? I18n.tr("Collapse %1").arg(row.label) : I18n.tr("Expand %1").arg(row.label)
        onClicked: row.expandedRequested(!row.expanded)
    }
}
