pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar AI usage panel under the crate look: a section per provider the
// bar shows, with its weekly share as a figure and a kit Beam, the pace line,
// the last seven days as a hairline bar chart and the other limit windows as
// InfoRows; a provider behind pace turns to the alert. OpenCode's models
// follow. It scrolls inside the card's cap, and it reads only the panel:
// providers, models, and the shared ai* helpers on panel.root.
Flickable {
    id: details
    required property var panel
    readonly property var theme: details.panel.root
    readonly property var providers: details.panel.providers || []
    readonly property var models: details.panel.models || []
    signal closeRequested()

    implicitHeight: content.implicitHeight
    contentWidth: width
    contentHeight: content.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: content
        width: details.width
        spacing: Tokens.s4

        CrateResourceHeader {
            width: parent.width
            title: I18n.tr("AI usage")
            closeObjectName: "closeAiUsage"
            onCloseRequested: details.closeRequested()
            Kit.IconButton {
                id: refresh
                objectName: "aiRefresh"
                width: 32
                height: 32
                glyph: "refresh"
                on: details.theme.aiRefreshing
                Accessible.role: Accessible.Button
                Accessible.name: I18n.tr("Refresh")
                onClicked: details.theme.regenerateAiUsage()
                RotationAnimation on rotation {
                    running: details.theme.aiRefreshing
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                    onRunningChanged: if (!running) refresh.rotation = 0
                }
            }
        }

        Text {
            objectName: "aiEmpty"
            visible: details.providers.length === 0
            width: parent.width
            text: I18n.tr("no AI usage yet — run claude, codex or opencode")
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: details.providers

            Column {
                id: section
                required property var modelData
                required property int index
                readonly property var p: modelData
                readonly property bool behind: details.theme.aiBehindPace(p.pct, p.paceTs)
                readonly property color tone: section.behind ? Tokens.alert : Tokens.ink
                objectName: "ai-" + p.id
                width: content.width
                spacing: Tokens.s2

                Kit.Divider {
                    width: parent.width
                    quiet: true
                    visible: section.index > 0
                }

                Item {
                    width: parent.width
                    height: Math.max(names.implicitHeight, share.implicitHeight)

                    Item {
                        id: mark
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: section.p.markW || 18
                        height: section.p.markH || 18
                        Image {
                            anchors.fill: parent
                            visible: !section.p.tinted && String(section.p.logo) !== ""
                            source: section.p.logo
                            sourceSize: Qt.size(36, 36)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                        Image {
                            id: tintedMark
                            anchors.fill: parent
                            visible: section.p.tinted && String(section.p.logo) !== ""
                            source: section.p.logo
                            sourceSize: Qt.size(36, 36)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            layer.enabled: tintedMark.visible
                            layer.effect: ShaderEffect {
                                property color tintColor: section.tone
                                fragmentShader: Qt.resolvedUrl("../shaders/logo-tint.frag.qsb")
                            }
                        }
                    }
                    Column {
                        id: names
                        anchors.left: mark.right
                        anchors.leftMargin: Tokens.s2
                        anchors.right: share.left
                        anchors.rightMargin: Tokens.s2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            width: parent.width
                            text: section.p.name + (section.p.plan ? "  · " + section.p.plan : "")
                            color: section.tone
                            font.family: Tokens.mono
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            objectName: "aiStatus"
                            width: parent.width
                            text: !section.p.has ? I18n.tr("no data")
                                : [section.p.resetTs > 0
                                        ? I18n.tr("· resets in %1").arg(details.theme.aiFmtReset(section.p.resetTs)).replace(/^·\s*/, "")
                                        : "",
                                    section.p.fresh ? "" : I18n.tr("(stale)")].filter(s => s !== "").join(" ")
                            color: section.behind ? Tokens.alert : Tokens.inkMuted
                            font.family: Tokens.mono
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        id: share
                        objectName: "aiPct"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: section.p.has
                        text: section.p.pct + "%"
                        color: section.tone
                        font.family: Tokens.mono
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        font.features: { "tnum": 1 }
                    }
                }

                Kit.Beam {
                    objectName: "aiMeter"
                    width: parent.width
                    visible: section.p.has
                    interactive: false
                    from: 0
                    to: 1
                    value: Math.max(0, Math.min(100, section.p.pct)) / 100
                    Accessible.name: section.p.name
                }

                Item {
                    width: parent.width
                    height: pace.implicitHeight
                    visible: section.p.has && section.p.paceTs > 0
                    Text {
                        id: pace
                        objectName: "aiPace"
                        anchors.left: parent.left
                        text: details.theme.aiPaceText(section.p.pct, section.p.paceTs)
                        color: section.behind ? Tokens.alert : Tokens.mark
                        font.family: Tokens.mono
                        font.pixelSize: 11
                    }
                    Text {
                        anchors.right: parent.right
                        text: I18n.tr("Expected %1% used").arg(100 - details.theme.aiExpectedPct(section.p.paceTs))
                        color: Tokens.inkSubtle
                        font.family: Tokens.mono
                        font.pixelSize: 11
                    }
                }

                // the last seven days, scaled to the busiest one
                Column {
                    readonly property var days: section.p.recent || []
                    readonly property real peak: Math.max(1, details.theme.aiRecentPeak(days))
                    width: parent.width
                    spacing: Tokens.s1
                    visible: section.p.has && days.length > 0 && details.theme.aiRecentTotal(days) > 0
                    Kit.TrackLabel {
                        width: parent.width
                        text: I18n.tr("LAST 7 DAYS · %1 TOKENS").arg(details.theme.aiTokenCount(details.theme.aiRecentTotal(parent.days)))
                    }
                    Row {
                        id: chart
                        width: parent.width
                        readonly property var days: parent.days
                        readonly property real peak: parent.peak
                        Repeater {
                            model: chart.days
                            Column {
                                id: day
                                required property var modelData
                                required property int index
                                readonly property real tokens: details.theme.aiDayTokens(modelData)
                                width: chart.width / Math.max(1, chart.days.length)
                                spacing: 2
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: day.tokens > 0 ? details.theme.aiTokenCount(day.tokens) : "0"
                                    color: Tokens.inkSubtle
                                    font.family: Tokens.mono
                                    font.pixelSize: 10
                                    font.features: { "tnum": 1 }
                                    elide: Text.ElideRight
                                }
                                Item {
                                    width: parent.width
                                    height: 32
                                    Rectangle {
                                        objectName: "aiBar-" + day.index
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 6
                                        height: day.tokens > 0 ? Math.max(2, parent.height * day.tokens / chart.peak) : 0
                                        radius: 1
                                        color: section.behind ? Tokens.alert : Tokens.mark
                                        opacity: 0.8
                                        Behavior on height { NumberAnimation { duration: 300 } }
                                    }
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 1
                                        color: Tokens.lineSoft
                                    }
                                }
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: details.theme.aiDayLabel(day.modelData.date)
                                    color: Tokens.inkSubtle
                                    font.family: Tokens.mono
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: section.p.extras || []
                    Kit.InfoRow {
                        required property var modelData
                        objectName: "aiWindow-" + modelData.label
                        width: section.width
                        label: I18n.tr(String(modelData.label))
                        valueText: I18n.tr("%1% used").arg(modelData.pct || 0)
                        secondary: modelData.resetTs > 0 ? details.theme.aiFmtReset(modelData.resetTs) : ""
                    }
                }
            }
        }

        Column {
            objectName: "aiModels"
            width: parent.width
            spacing: Tokens.s3
            visible: details.models.length > 0

            Kit.Divider { width: parent.width; quiet: true }
            Item {
                width: parent.width
                height: modelsLabel.implicitHeight
                Kit.TrackLabel {
                    id: modelsLabel
                    anchors.left: parent.left
                    text: I18n.tr("Models")
                    tone: "accent"
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("recent")
                    color: Tokens.inkSubtle
                    font.family: Tokens.mono
                    font.pixelSize: 11
                }
            }
            Repeater {
                model: details.models
                Column {
                    id: modelRow
                    required property var modelData
                    required property int index
                    readonly property var m: modelData
                    function part(key, label) {
                        const v = m[key] || "0";
                        return v === "0" ? "" : label.arg(v);
                    }
                    objectName: "aiModel-" + index
                    width: content.width
                    spacing: Tokens.s1
                    Item {
                        width: parent.width
                        height: modelName.implicitHeight
                        Text {
                            id: modelName
                            anchors.left: parent.left
                            anchors.right: modelTotal.left
                            anchors.rightMargin: Tokens.s2
                            text: modelRow.m.name || ""
                            color: Tokens.ink
                            font.family: Tokens.mono
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            id: modelTotal
                            anchors.right: parent.right
                            text: modelRow.m.totalLabel || ""
                            color: Tokens.mark
                            font.family: Tokens.mono
                            font.pixelSize: 12
                            font.features: { "tnum": 1 }
                        }
                    }
                    Kit.Beam {
                        width: parent.width
                        interactive: false
                        from: 0
                        to: 1
                        value: Math.max(0, Math.min(100, parseInt(modelRow.m.pct) || 0)) / 100
                    }
                    Text {
                        width: parent.width
                        text: [I18n.tr("I %1  O %2").arg(modelRow.m.inputLabel || "0").arg(modelRow.m.outputLabel || "0"),
                               modelRow.part("reasoningLabel", I18n.tr("R %1")),
                               modelRow.part("cacheReadLabel", I18n.tr("CR %1")),
                               modelRow.part("cacheWriteLabel", I18n.tr("CW %1")),
                               modelRow.part("todayLabel", I18n.tr("today %1"))].filter(s => s !== "").join("  ")
                        color: Tokens.inkMuted
                        font.family: Tokens.mono
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
