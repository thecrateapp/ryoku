pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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
                readonly property color tone: Tokens.ink
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
                            color: Tokens.inkMuted
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

                // the weekly share, with a hairline tick where use should be today
                // and the share past it in the caution tone
                Item {
                    readonly property real expected: section.p.paceTs > 0
                        ? (100 - details.theme.aiExpectedPct(section.p.paceTs)) / 100 : -1
                    readonly property real used: Math.max(0, Math.min(100, section.p.pct)) / 100
                    width: parent.width
                    height: meter.height
                    visible: section.p.has
                    Kit.Beam {
                        id: meter
                        objectName: "aiMeter"
                        width: parent.width
                        interactive: false
                        from: 0
                        to: 1
                        value: parent.used
                        Accessible.name: section.p.name
                    }
                    Rectangle {
                        objectName: "aiOverPace"
                        visible: section.behind && parent.expected >= 0 && parent.used > parent.expected
                        x: Math.round(meter.width * parent.expected)
                        y: meter.cy
                        width: Math.max(0, Math.round(meter.width * parent.used) - x)
                        height: 1
                        color: Tokens.warn
                    }
                    Rectangle {
                        objectName: "aiPaceMark"
                        visible: parent.expected >= 0
                        x: Math.round(meter.width * parent.expected)
                        y: meter.cy - 4
                        width: 1
                        height: 9
                        color: Tokens.inkSubtle
                    }
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
                        color: section.behind ? Tokens.warn : Tokens.inkMuted
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
                    // a 1 px curve over a fading area, a head dot on today
                    Item {
                        id: curve
                        objectName: "aiCurve"
                        readonly property var days: parent.days
                        readonly property real peak: parent.peak
                        readonly property real baseY: height - 1
                        readonly property var points: {
                            const out = [], n = curve.days.length;
                            for (let i = 0; i < n; i++) {
                                const t = details.theme.aiDayTokens(curve.days[i]);
                                out.push([4 + i * (curve.width - 8) / Math.max(1, n - 1),
                                          curve.baseY - (curve.height - 8) * t / curve.peak]);
                            }
                            return out;
                        }
                        readonly property string path: {
                            const p = curve.points;
                            if (p.length < 2) return "";
                            let d = "M " + p[0][0] + " " + p[0][1];
                            for (let k = 0; k < p.length - 1; k++) {
                                const p0 = p[Math.max(0, k - 1)], p1 = p[k], p2 = p[k + 1], p3 = p[Math.min(p.length - 1, k + 2)];
                                d += " C " + (p1[0] + (p2[0] - p0[0]) / 6) + " " + Math.min(curve.baseY, p1[1] + (p2[1] - p0[1]) / 6)
                                    + " " + (p2[0] - (p3[0] - p1[0]) / 6) + " " + Math.min(curve.baseY, p2[1] - (p3[1] - p1[1]) / 6)
                                    + " " + p2[0] + " " + p2[1];
                            }
                            return d;
                        }
                        width: parent.width
                        height: 40
                        Rectangle { y: curve.baseY; width: curve.width; height: 1; color: Tokens.lineSoft }
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeWidth: 0
                                strokeColor: "transparent"
                                fillGradient: LinearGradient {
                                    x1: 0; y1: 0; x2: 0; y2: curve.height
                                    GradientStop { position: 0; color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.22) }
                                    GradientStop { position: 1; color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0) }
                                }
                                PathSvg {
                                    path: curve.points.length > 1
                                        ? curve.path + " L " + curve.points[curve.points.length - 1][0] + " " + curve.baseY
                                            + " L " + curve.points[0][0] + " " + curve.baseY + " Z" : ""
                                }
                            }
                            ShapePath {
                                strokeWidth: 1
                                strokeColor: Tokens.beamTail
                                fillColor: "transparent"
                                PathSvg { path: curve.path }
                            }
                        }
                        Rectangle {
                            readonly property var head: curve.points.length ? curve.points[curve.points.length - 1] : [0, 0]
                            visible: curve.points.length > 0
                            x: head[0] - 4; y: head[1] - 4; width: 8; height: 8; radius: 4
                            color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.22)
                            Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Tokens.thumb }
                        }
                    }
                    Item {
                        width: parent.width
                        height: Tokens.s4
                        Repeater {
                            model: curve.days
                            Text {
                                required property var modelData
                                required property int index
                                readonly property bool first: index === 0
                                readonly property bool last: index === curve.days.length - 1
                                width: 36
                                // the end days sit inside the panel instead of overhanging it
                                x: first ? 0 : last ? parent.width - width
                                    : (curve.points[index] ? curve.points[index][0] : 0) - width / 2
                                horizontalAlignment: first ? Text.AlignLeft : last ? Text.AlignRight : Text.AlignHCenter
                                text: details.theme.aiDayLabel(modelData.date)
                                color: Tokens.inkSubtle
                                font.family: Tokens.mono
                                font.pixelSize: 10
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
