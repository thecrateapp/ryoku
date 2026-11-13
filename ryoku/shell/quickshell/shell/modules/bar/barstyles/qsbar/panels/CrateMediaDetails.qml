pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar media panel under the crate look (the user's pick: the turning
// record and the equalizer as a curve). The record turns while playing, with
// the spectrum as hairline marks around it; the track reads out beside it with
// its output; the position is a kit Beam; the transport is kit IconButtons;
// the ten bands are a curve with a draggable node per band, then the preset
// chips. It reads and drives only the panel (see media-details-probe for the
// whole surface).
Column {
    id: details
    required property var panel
    readonly property bool active: details.panel.active
    signal closeRequested()
    spacing: Tokens.s4

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Now playing")
        closeObjectName: "closeMedia"
        onCloseRequested: details.closeRequested()
        Kit.TrackLabel {
            visible: details.active && details.panel.playerName !== ""
            text: I18n.tr("via %1").arg(details.panel.playerName)
        }
    }

    Row {
        width: parent.width
        height: record.height
        spacing: Tokens.s4

        Item {
            id: record
            objectName: "mediaRecord"
            readonly property bool spinning: details.panel.visible && details.panel.playing && !Tokens.reduceMotion
            readonly property real discSize: 104
            readonly property real room: (width - discSize) / 2
            width: 136
            height: 136

            // the spectrum as hairline marks around the record
            Repeater {
                model: details.panel.bands
                Item {
                    required property int index
                    readonly property real level: {
                        const lv = details.panel.levels;
                        return lv && lv[index] !== undefined ? lv[index] : 0;
                    }
                    x: record.width / 2
                    y: record.height / 2
                    rotation: index * 360 / Math.max(1, details.panel.bands)
                    Rectangle {
                        x: -width / 2
                        y: -record.discSize / 2 - 3 - height
                        width: 2
                        height: Math.max(2, parent.level * (record.room - 5))
                        radius: 1
                        antialiasing: true
                        color: Tokens.mark
                        opacity: details.panel.playing ? 0.35 + parent.level * 0.65 : 0.25
                        Behavior on height { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Item {
                id: disc
                anchors.centerIn: parent
                width: record.discSize
                height: record.discSize
                NumberAnimation on rotation {
                    id: spin
                    from: 0
                    to: 360
                    duration: 24000
                    loops: Animation.Infinite
                    running: details.panel.visible && !Tokens.reduceMotion
                    // Qt refuses pause() on a stopped animation, so the paused
                    // state only exists while it runs
                    paused: spin.running && !record.spinning
                }
                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: artMask
                    }
                    Rectangle { anchors.fill: parent; color: Tokens.paperLift }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: details.panel.artSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }
                }
                // grooves
                Repeater {
                    model: [0.84, 0.66, 0.48]
                    Rectangle {
                        required property real modelData
                        anchors.centerIn: parent
                        width: disc.width * modelData
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.28)
                        antialiasing: true
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: details.panel.playing ? Tokens.markHover : Tokens.line
                    antialiasing: true
                    Behavior on border.color { ColorAnimation { duration: 400 } }
                }
                // spindle
                Rectangle {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: Tokens.paper
                    border.width: 1
                    border.color: Tokens.markHover
                    antialiasing: true
                }
            }
        }

        Column {
            width: parent.width - record.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.s1

            Text {
                objectName: "mediaTitle"
                width: parent.width
                text: details.active ? (details.panel.trackTitle || I18n.tr("Unknown")) : I18n.tr("No song playing")
                color: Tokens.ink
                font.family: Tokens.mono
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                objectName: "mediaArtist"
                width: parent.width
                text: details.active ? (details.panel.trackArtist || I18n.tr("Unknown artist")) : I18n.tr("no active player")
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Kit.TrackLabel {
                width: parent.width
                visible: details.active && text !== ""
                text: details.panel.trackAlbum || ""
            }
            Item { width: 1; height: Tokens.s2 }
            Row {
                width: parent.width
                spacing: Tokens.s2
                Kit.Glyph {
                    id: outGlyph
                    anchors.verticalCenter: parent.verticalCenter
                    name: details.panel.outputHeadphones ? "headphones" : "speaker"
                    size: 16
                    color: Tokens.inkSecondary
                }
                Text {
                    objectName: "mediaOutput"
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - outGlyph.width - parent.spacing
                    text: details.panel.outputLabel || ""
                    color: Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0
        Kit.Beam {
            id: seek
            objectName: "mediaSeek"
            width: parent.width
            visible: details.active
            from: 0
            to: 1
            value: details.panel.curLen > 0 ? Math.min(1, details.panel.shownPos / details.panel.curLen) : 0
            interactive: details.panel.canSeek && details.panel.curLen > 0
            Accessible.name: I18n.tr("Position")
            onCommitted: v => details.panel.seekTo(v)
        }
        Item {
            width: parent.width
            height: elapsed.implicitHeight
            visible: details.active
            Text {
                id: elapsed
                anchors.left: parent.left
                text: details.panel.fmtTime(details.panel.shownPos)
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
            Text {
                anchors.right: parent.right
                text: details.panel.fmtTime(details.panel.curLen)
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: 11
                font.features: { "tnum": 1 }
            }
        }
    }

    Row {
        objectName: "mediaTransport"
        anchors.horizontalCenter: parent.horizontalCenter
        visible: details.active
        spacing: Tokens.s2
        Kit.IconButton {
            objectName: "mediaPrevious"
            anchors.verticalCenter: parent.verticalCenter
            glyph: "skip_previous"
            enabled: details.panel.canPrevious
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Previous")
            onClicked: details.panel.previous()
        }
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "transparent"
            border.width: 1
            border.color: Tokens.markHover
            Kit.IconButton {
                objectName: "mediaPlay"
                anchors.centerIn: parent
                glyph: details.panel.playing ? "pause" : "play"
                on: true
                enabled: details.panel.canTogglePlaying
                Accessible.role: Accessible.Button
                Accessible.name: details.panel.playing ? I18n.tr("Pause") : I18n.tr("Play")
                onClicked: details.panel.togglePlaying()
            }
        }
        Kit.IconButton {
            objectName: "mediaNext"
            anchors.verticalCenter: parent.verticalCenter
            glyph: "skip_next"
            enabled: details.panel.canNext
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Next")
            onClicked: details.panel.next()
        }
    }

    Kit.Divider { width: parent.width; quiet: true }

    Item {
        width: parent.width
        height: eqSwitch.height
        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Equalizer")
            tone: "accent"
        }
        Text {
            anchors.right: eqSwitch.left
            anchors.rightMargin: Tokens.s3
            anchors.verticalCenter: parent.verticalCenter
            text: details.panel.eqPresetLabel(details.panel.eqPreset)
            color: Tokens.inkMuted
            font.family: Tokens.mono
            font.pixelSize: 12
        }
        Kit.Sw {
            id: eqSwitch
            objectName: "eqSwitch"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            on: details.panel.eqOn
            Accessible.name: I18n.tr("Equalizer")
            onToggled: v => details.panel.setEqOn(v)
        }
    }

    // the ten bands as a curve: a node per band on a hairline grid with the
    // 0 dB line, a smooth path through them and a fading area under it
    Item {
        id: curve
        width: parent.width
        height: 128
        opacity: details.panel.eqOn ? 1 : 0.45
        readonly property int pad: 16
        readonly property int count: (details.panel.eqGains || []).length
        readonly property real span: Math.max(1, details.panel.eqRange)
        function xAt(i) { return 22 + i * (width - 44) / Math.max(1, count - 1) }
        function yAt(db) { return pad + (height - 2 * pad) * (1 - (db + span) / (2 * span)) }
        function dbAt(y) {
            const t = 1 - Math.max(0, Math.min(1, (y - pad) / (height - 2 * pad)));
            return Math.round(t * 2 * span - span);
        }
        readonly property var points: {
            const g = details.panel.eqGains || [];
            const out = [];
            for (let i = 0; i < g.length; i++) out.push([curve.xAt(i), curve.yAt(g[i])]);
            return out;
        }
        // Catmull-Rom through the nodes as cubic Béziers
        readonly property string path: {
            const p = curve.points;
            if (p.length < 2) return "";
            let d = "M " + p[0][0] + " " + p[0][1];
            for (let k = 0; k < p.length - 1; k++) {
                const p0 = p[Math.max(0, k - 1)], p1 = p[k], p2 = p[k + 1], p3 = p[Math.min(p.length - 1, k + 2)];
                d += " C " + (p1[0] + (p2[0] - p0[0]) / 6) + " " + (p1[1] + (p2[1] - p0[1]) / 6)
                    + " " + (p2[0] - (p3[0] - p1[0]) / 6) + " " + (p2[1] - (p3[1] - p1[1]) / 6)
                    + " " + p2[0] + " " + p2[1];
            }
            return d;
        }

        Repeater {
            model: [0, 0.5, 1]
            Rectangle {
                required property real modelData
                x: 0
                y: Math.round(curve.pad + (curve.height - 2 * curve.pad) * modelData)
                width: curve.width
                height: 1
                color: modelData === 0.5 ? Tokens.line : Tokens.lineSoft
            }
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: curve.height
                    GradientStop { position: 0; color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.24) }
                    GradientStop { position: 1; color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0) }
                }
                PathSvg {
                    path: curve.points.length > 1
                        ? curve.path + " L " + curve.points[curve.points.length - 1][0] + " " + curve.height
                            + " L " + curve.points[0][0] + " " + curve.height + " Z"
                        : ""
                }
            }
            ShapePath {
                strokeWidth: 1.25
                strokeColor: Tokens.beamTail
                fillColor: "transparent"
                PathSvg { path: curve.path }
            }
        }

        Repeater {
            model: curve.count
            Item {
                id: node
                required property int index
                objectName: "eqNode-" + index
                // while the finger is down the node owns its value, so the
                // service's answer (and its debounced echo) cannot yank it back
                property bool dragging: false
                property int dragDb: 0
                readonly property int db: dragging ? dragDb : (details.panel.eqGains[index] || 0)
                function nudge(delta) {
                    details.panel.setEqBand(index, Math.max(-curve.span, Math.min(curve.span, node.db + delta)));
                }
                width: 22
                height: 22
                x: curve.xAt(index) - width / 2
                y: curve.yAt(node.db) - height / 2
                activeFocusOnTab: true
                Accessible.role: Accessible.Slider
                Accessible.name: details.panel.eqBandLabels[index] + " Hz"
                Keys.onUpPressed: node.nudge(1)
                Keys.onDownPressed: node.nudge(-1)

                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, node.dragging || drag.containsMouse || node.activeFocus ? 0.30 : 0.18)
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Tokens.thumb
                }
                Timer {
                    id: livePush
                    interval: 110
                    onTriggered: details.panel.setEqBand(node.index, node.dragDb)
                }
                MouseArea {
                    id: drag
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeVerCursor
                    preventStealing: true
                    onPressed: m => {
                        node.dragDb = curve.dbAt(node.mapToItem(curve, m.x, m.y).y);
                        node.dragging = true;
                        livePush.restart();
                    }
                    onPositionChanged: m => {
                        if (!node.dragging) return;
                        const next = curve.dbAt(node.mapToItem(curve, m.x, m.y).y);
                        if (next === node.dragDb) return;
                        node.dragDb = next;
                        if (!livePush.running) livePush.restart();
                    }
                    onReleased: {
                        livePush.stop();
                        details.panel.setEqBand(node.index, node.dragDb);
                        node.dragging = false;
                    }
                    onCanceled: {
                        livePush.stop();
                        node.dragging = false;
                    }
                    onWheel: w => node.nudge(w.angleDelta.y > 0 ? 1 : -1)
                }
            }
        }
    }

    // each frequency sits under its node
    Item {
        width: parent.width
        height: Tokens.s4
        Repeater {
            model: details.panel.eqBandLabels || []
            Text {
                required property string modelData
                required property int index
                width: 36
                x: curve.xAt(index) - width / 2
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Tokens.inkSubtle
                font.family: Tokens.mono
                font.pixelSize: 10
                font.features: { "tnum": 1 }
            }
        }
    }

    Kit.Chips {
        objectName: "eqPresets"
        width: parent.width
        options: details.panel.eqPresets || []
        current: details.panel.eqPreset
        labels: {
            const out = {};
            for (const p of (details.panel.eqPresets || [])) out[p] = details.panel.eqPresetLabel(p);
            return out;
        }
        onChose: key => details.panel.applyEqPreset(key)
    }
}
