pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import shell.services

Item {
    id: root

    required property real s
    required property bool active
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce

    implicitHeight: body.implicitHeight

    // crate-mark: the longest stream or microphone name, in the rows' mono 12
    FontMetrics {
        id: nameMetrics
        font.family: Tokens.mono
        font.pixelSize: 12 * root.s
    }
    readonly property real streamNameWidth: {
        if (!root.active || !Tokens.controlsCrate)
            return 0;
        const titles = Audio.streams.filter(Audio.alive).map(n => Audio.streamName(n))
            .concat(Audio.captureStreams.filter(Audio.alive).map(n => Audio.streamName(n)));
        if (Audio.source && Audio.source.audio)
            titles.push(Audio.nodeLabel(Audio.source));
        let widest = 0;
        for (const title of titles)
            widest = Math.max(widest, nameMetrics.advanceWidth(title));
        return Math.ceil(widest);
    }

    Column {
        id: body
        width: parent.width
        spacing: Tokens.s3 * root.s

        Rectangle {
            width: parent.width
            height: Tokens.border
            color: Tokens.lineSoft
        }

        Column {
            width: parent.width
            spacing: Tokens.s2 * root.s

            Text {
                text: I18n.tr("OUTPUT")
                color: Tokens.controlsCrate ? Tokens.inkSubtle : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: (Tokens.controlsCrate ? Tokens.fMicro : Tokens.fTiny) * root.s
                font.letterSpacing: Tokens.trackLabel * root.s
            }

            // crate-mark: the devices as the kit's pick rows, the default one picked
            Column {
                visible: Tokens.controlsCrate
                width: parent.width
                spacing: 6 * root.s

                Repeater {
                    model: root.active && Tokens.controlsCrate ? Audio.outputs.filter(Audio.alive) : []
                    delegate: Kit.PickRow {
                        required property var modelData
                        width: parent ? parent.width : 0
                        title: Audio.nodeLabel(modelData)
                        sub: Audio.isBluez(modelData) ? I18n.tr("Bluetooth") : ""
                        glyph: Audio.nodeIcon(modelData)
                        glyphFont: "Material Symbols Rounded"
                        picked: !!(Audio.sink && modelData && Audio.sink.name === modelData.name)
                        Accessible.name: picked ? I18n.tr("%1 is the default output").arg(title)
                            : I18n.tr("Use %1 as the default output").arg(title)
                        onClicked: if (!picked) Audio.setOutput(modelData)
                    }
                }
            }

            Flow {
                id: outputChips
                visible: !Tokens.controlsCrate
                width: parent.width
                height: childrenRect.height
                spacing: Tokens.s2 * root.s

                Repeater {
                    model: root.active ? Audio.outputs.filter(Audio.alive) : []
                    delegate: QQC.AbstractButton {
                        id: outputChip
                        required property var modelData
                        readonly property bool selected: !!(Audio.sink && modelData && Audio.sink.name === modelData.name)
                        readonly property string deviceLabel: Audio.nodeLabel(modelData)
                        hoverEnabled: true
                        implicitWidth: chipRow.implicitWidth + Tokens.s3 * root.s * 2
                        implicitHeight: Tokens.ctlH * root.s
                        Accessible.name: selected ? I18n.tr("%1 is the default output").arg(deviceLabel)
                            : I18n.tr("Use %1 as the default output").arg(deviceLabel)
                        onClicked: if (!selected) Audio.setOutput(modelData)
                        background: Rectangle {
                            radius: Tokens.radius * root.s
                            color: outputChip.selected ? Tokens.bone : outputChip.down ? Tokens.tint16 : outputChip.hovered ? Tokens.tint10 : Tokens.tint5
                            border.width: Tokens.border
                            border.color: outputChip.selected ? Tokens.bone : outputChip.visualFocus ? Tokens.bone : Tokens.lineSoft
                            Behavior on color {
                                enabled: root.motionAllowed
                                ColorAnimation { duration: Tokens.snap }
                            }
                        }
                        contentItem: Row {
                            id: chipRow
                            spacing: Tokens.s1 * root.s
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Audio.nodeIcon(outputChip.modelData)
                                color: outputChip.selected ? Tokens.inkOnBone : Tokens.inkDim
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Tokens.fSmall * root.s
                                Accessible.ignored: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: outputChip.deviceLabel
                                color: outputChip.selected ? Tokens.inkOnBone : Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.Medium
                            }
                        }
                        scale: down ? 0.97 : 1
                        Behavior on scale {
                            enabled: root.motionAllowed
                            NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }

                Text {
                    visible: root.active && Audio.outputs.length === 0
                    text: I18n.tr("No audio output")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                }
            }
        }

        Column {
            width: parent.width
            spacing: Tokens.s2 * root.s

            Text {
                text: I18n.tr("PLAYING")
                color: Tokens.controlsCrate ? Tokens.inkSubtle : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: (Tokens.controlsCrate ? Tokens.fMicro : Tokens.fTiny) * root.s
                font.letterSpacing: Tokens.trackLabel * root.s
            }

            ListView {
                id: playList
                width: parent.width
                height: contentHeight
                interactive: false
                clip: false
                spacing: Tokens.s1 * root.s
                model: root.active ? Audio.streams.filter(Audio.alive) : []
                delegate: MixerRow {
                    required property var modelData
                    width: playList.width
                    s: root.s
                    nameWidth: root.streamNameWidth
                    node: modelData
                }
                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                        NumberAnimation { property: "y"; from: Tokens.s2 * root.s; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                        NumberAnimation { property: "y"; to: -Tokens.s2 * root.s; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                }
            }

            Text {
                visible: root.active && Audio.streams.length === 0
                text: I18n.tr("No audio playing")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
            }
        }

        Column {
            width: parent.width
            spacing: Tokens.s2 * root.s
            visible: root.active && Audio.captureStreams.length > 0

            Text {
                text: I18n.tr("RECORDING")
                color: Tokens.controlsCrate ? Tokens.inkSubtle : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: (Tokens.controlsCrate ? Tokens.fMicro : Tokens.fTiny) * root.s
                font.letterSpacing: Tokens.trackLabel * root.s
            }

            ListView {
                id: captureList
                width: parent.width
                height: contentHeight
                interactive: false
                clip: false
                spacing: Tokens.s1 * root.s
                model: root.active ? Audio.captureStreams.filter(Audio.alive) : []
                delegate: MixerRow {
                    required property var modelData
                    width: captureList.width
                    s: root.s
                    nameWidth: root.streamNameWidth
                    node: modelData
                    capture: true
                }
                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                        NumberAnimation { property: "y"; from: Tokens.s2 * root.s; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                        NumberAnimation { property: "y"; to: -Tokens.s2 * root.s; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                }
            }
        }

        Column {
            width: parent.width
            spacing: Tokens.s2 * root.s
            visible: Audio.inputs.length > 0 || !!(Audio.source && Audio.source.audio)

            Text {
                text: I18n.tr("MICROPHONE")
                color: Tokens.controlsCrate ? Tokens.inkSubtle : Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: (Tokens.controlsCrate ? Tokens.fMicro : Tokens.fTiny) * root.s
                font.letterSpacing: Tokens.trackLabel * root.s
            }

            // crate-mark: the devices as the kit's pick rows, the default one picked
            Column {
                visible: Tokens.controlsCrate
                width: parent.width
                spacing: 6 * root.s

                Repeater {
                    model: root.active && Tokens.controlsCrate ? Audio.inputs.filter(Audio.alive) : []
                    delegate: Kit.PickRow {
                        required property var modelData
                        width: parent ? parent.width : 0
                        title: Audio.nodeLabel(modelData)
                        sub: Audio.isBluez(modelData) ? I18n.tr("Bluetooth") : ""
                        glyph: Audio.nodeIcon(modelData)
                        glyphFont: "Material Symbols Rounded"
                        picked: !!(Audio.source && modelData && Audio.source.name === modelData.name)
                        Accessible.name: picked ? I18n.tr("%1 is the default microphone").arg(title)
                            : I18n.tr("Use %1 as the default microphone").arg(title)
                        onClicked: if (!picked) Audio.setInput(modelData)
                    }
                }
            }

            Flow {
                id: inputChips
                visible: !Tokens.controlsCrate
                width: parent.width
                height: childrenRect.height
                spacing: Tokens.s2 * root.s

                Repeater {
                    model: root.active ? Audio.inputs.filter(Audio.alive) : []
                    delegate: QQC.AbstractButton {
                        id: inputChip
                        required property var modelData
                        readonly property bool selected: !!(Audio.source && modelData && Audio.source.name === modelData.name)
                        readonly property string deviceLabel: Audio.nodeLabel(modelData)
                        hoverEnabled: true
                        implicitWidth: inputChipRow.implicitWidth + Tokens.s3 * root.s * 2
                        implicitHeight: Tokens.ctlH * root.s
                        Accessible.name: selected ? I18n.tr("%1 is the default microphone").arg(deviceLabel)
                            : I18n.tr("Use %1 as the default microphone").arg(deviceLabel)
                        onClicked: if (!selected) Audio.setInput(modelData)
                        background: Rectangle {
                            radius: Tokens.radius * root.s
                            color: inputChip.selected ? Tokens.bone : inputChip.down ? Tokens.tint16 : inputChip.hovered ? Tokens.tint10 : Tokens.tint5
                            border.width: Tokens.border
                            border.color: inputChip.selected ? Tokens.bone : inputChip.visualFocus ? Tokens.bone : Tokens.lineSoft
                            Behavior on color {
                                enabled: root.motionAllowed
                                ColorAnimation { duration: Tokens.snap }
                            }
                        }
                        contentItem: Row {
                            id: inputChipRow
                            spacing: Tokens.s1 * root.s
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Audio.nodeIcon(inputChip.modelData)
                                color: inputChip.selected ? Tokens.inkOnBone : Tokens.inkDim
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Tokens.fSmall * root.s
                                Accessible.ignored: true
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: inputChip.deviceLabel
                                color: inputChip.selected ? Tokens.inkOnBone : Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.Medium
                            }
                        }
                        scale: down ? 0.97 : 1
                        Behavior on scale {
                            enabled: root.motionAllowed
                            NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            MixerRow {
                width: parent.width
                visible: !!(Audio.source && Audio.source.audio)
                s: root.s
                nameWidth: root.streamNameWidth
                node: Audio.source
                device: true
                capture: true
            }
        }
    }
}