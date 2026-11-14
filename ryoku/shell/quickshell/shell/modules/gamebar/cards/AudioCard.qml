pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import ".."
import "../../../components"
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../look"

// Audio: the same faders and app rows the audio menu uses, so a level set here
// is the level Pipewire holds everywhere. Under crate they are the kit's rows,
// as on Controls: a LevelRow per device (its icon mutes it) and a StreamRow per
// app, each on a Beam.
GameBarCard {
    id: card

    title: I18n.tr("Audio")

    readonly property var sinkAudio: Audio.sink && Audio.sink.audio ? Audio.sink.audio : null
    readonly property var sourceAudio: Audio.source && Audio.source.audio ? Audio.source.audio : null
    readonly property var streams: Audio.streams ? Audio.streams.filter(Audio.alive) : []

    // Peak monitors are audio work, so run them only while the card is on
    // screen. Power Saver rests a card left pinned behind a closed bar; an open
    // bar is being looked at.
    readonly property bool saverIdle: Perf.saver && card.pinned && !GameBarStore.open
    readonly property bool polling: (!card.host || (card.host.live && !card.host.suppressed))
        && !Presence.dark && !card.saverIdle

    Column {
        width: parent.width
        spacing: 8 * card.s

        Kit.LevelRow {
            objectName: "gameBarOutputRow"
            visible: GameBarLook.crate
            width: parent.width
            s: card.s
            label: I18n.tr("Output")
            glyph: card.sinkAudio && card.sinkAudio.muted ? "volume_off" : "volume_up"
            value: Audio.volumeOf(Audio.sink)
            available: !!card.sinkAudio
            muted: card.sinkAudio ? card.sinkAudio.muted : false
            muteEnabled: !!card.sinkAudio
            expandable: false
            onAdjusted: v => { if (card.sinkAudio) Audio.setSinkVolume(v, 1); }
            onMuteRequested: { if (card.sinkAudio) card.sinkAudio.muted = !card.sinkAudio.muted; }
        }

        Kit.LevelRow {
            objectName: "gameBarInputRow"
            visible: GameBarLook.crate
            width: parent.width
            s: card.s
            label: I18n.tr("Mic")
            glyph: card.sourceAudio && card.sourceAudio.muted ? "mic_off" : "mic"
            value: card.sourceAudio ? card.sourceAudio.volume : 0
            available: !!card.sourceAudio
            muted: card.sourceAudio ? card.sourceAudio.muted : false
            muteEnabled: !!card.sourceAudio
            expandable: false
            onAdjusted: v => { if (card.sourceAudio) card.sourceAudio.volume = v; }
            onMuteRequested: { if (card.sourceAudio) card.sourceAudio.muted = !card.sourceAudio.muted; }
        }

        HFader {
            visible: !GameBarLook.crate
            width: parent.width
            s: card.s
            icon: Audio.sink ? Audio.nodeIcon(Audio.sink) : "speaker"
            lit: true
            value: Audio.volumeOf(Audio.sink)
            muted: card.sinkAudio ? card.sinkAudio.muted : false
            valueLabel: card.sinkAudio
                ? (card.sinkAudio.muted ? I18n.tr("off") : Math.round(value * 100) + "%")
                : "n/a"
            peakNode: Audio.sink
            peakEnabled: card.polling && !!Audio.sink && !GameBarLook.crate
            onMoved: v => { if (card.sinkAudio) Audio.setSinkVolume(v, 1); }
            onIconTapped: { if (card.sinkAudio) card.sinkAudio.muted = !card.sinkAudio.muted; }
        }

        HFader {
            visible: !GameBarLook.crate
            width: parent.width
            s: card.s
            icon: "mic"
            lit: !!card.sourceAudio
            value: card.sourceAudio ? card.sourceAudio.volume : 0
            muted: card.sourceAudio ? card.sourceAudio.muted : false
            valueLabel: card.sourceAudio
                ? (card.sourceAudio.muted ? I18n.tr("off") : Math.round(card.sourceAudio.volume * 100) + "%")
                : "n/a"
            peakNode: Audio.source
            peakEnabled: card.polling && !!Audio.source && !GameBarLook.crate
            onMoved: v => { if (card.sourceAudio) card.sourceAudio.volume = v; }
            onIconTapped: { if (card.sourceAudio) card.sourceAudio.muted = !card.sourceAudio.muted; }
        }

        Kit.Divider {
            visible: GameBarLook.crate
            width: parent.width
        }

        Rectangle {
            visible: !GameBarLook.crate
            width: parent.width
            height: 1
            color: GameBarLook.border
        }

        GameBarCaption {
            s: card.s
            text: I18n.tr("Apps")
        }

        ListView {
            id: apps
            width: parent.width
            height: Math.min(contentHeight, 3 * 46 * card.s)
            clip: true
            spacing: 4 * card.s
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            model: card.streams

            delegate: Item {
                id: appRow
                required property var modelData
                readonly property var appAudio: appRow.modelData && appRow.modelData.audio ? appRow.modelData.audio : null
                width: apps.width
                height: GameBarLook.crate ? kitRow.implicitHeight : oldRow.implicitHeight

                Kit.StreamRow {
                    id: kitRow
                    objectName: "gameBarStreamRow"
                    visible: GameBarLook.crate
                    width: parent.width
                    s: card.s
                    name: Audio.streamName(appRow.modelData)
                    value: appRow.appAudio ? appRow.appAudio.volume : 0
                    muted: appRow.appAudio ? appRow.appAudio.muted : false
                    available: appRow.appAudio !== null
                    onAdjusted: v => { if (appRow.appAudio) appRow.appAudio.volume = v; }
                    onMuteRequested: { if (appRow.appAudio) appRow.appAudio.muted = !appRow.appAudio.muted; }
                }

                AudioAppRow {
                    id: oldRow
                    visible: !GameBarLook.crate
                    width: parent.width
                    s: card.s
                    stream: appRow.modelData
                    // the stock row's live VU is audio work; the kit row has none
                    open: card.polling && !GameBarLook.crate
                }
            }
        }

        Text {
            visible: card.streams.length === 0
            width: parent.width
            text: I18n.tr("Nothing playing")
            color: GameBarLook.subtext
            horizontalAlignment: Text.AlignHCenter
            font.family: GameBarLook.face
            font.pixelSize: GameBarLook.small * card.s
        }
    }
}
