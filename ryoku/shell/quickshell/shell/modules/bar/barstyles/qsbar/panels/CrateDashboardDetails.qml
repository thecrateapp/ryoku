pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar dashboard under the crate look: the month on the left, the time and
// the weather on the right, split by a hairline instead of the stock frosted
// islands. The hourly forecast is the AI usage panel's 1 px curve over a fading
// area, its head dot on the current hour. It reads and drives only the panel:
//   weekdayLong, dateLong, timeMain, timeSecs, ampm
//   monthTitle, monthOffset, weekdays [7], cells [{day, today}], selectedDay,
//   selectDay(day), shiftMonth(delta), resetMonth()
//   wxReady, wxLoading, temperature, condition, area, symbol (a glyph name),
//   readouts [{label, value}], hourly [{time, temp, symbol}]
Column {
    id: details
    required property var panel
    signal closeRequested()
    spacing: Tokens.s3

    readonly property int calW: 7 * 38

    CrateResourceHeader {
        width: parent.width
        title: details.panel.weekdayLong + " · " + details.panel.dateLong
        closeObjectName: "closeDashboard"
        onCloseRequested: details.closeRequested()
    }

    Row {
        id: body
        width: parent.width
        spacing: Tokens.s4

        // ── the month ─────────────────────────────────────────────────────
        Column {
            id: month
            objectName: "dashboardMonth"
            width: details.calW
            spacing: Tokens.s2

            Item {
                width: parent.width
                height: 32
                Kit.IconButton {
                    objectName: "monthPrev"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    glyph: "alt-arrow-left"
                    Accessible.name: I18n.tr("Previous month")
                    onClicked: details.panel.shiftMonth(-1)
                }
                // the month name; away from today it is live and leads back
                Kit.TrackLabel {
                    id: monthTitle
                    objectName: "monthTitle"
                    anchors.centerIn: parent
                    text: details.panel.monthTitle
                    tone: details.panel.monthOffset !== 0 ? "active" : "accent"
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Tokens.s2
                        enabled: details.panel.monthOffset !== 0
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: details.panel.resetMonth()
                    }
                }
                Kit.IconButton {
                    objectName: "monthNext"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    glyph: "alt-arrow-right"
                    Accessible.name: I18n.tr("Next month")
                    onClicked: details.panel.shiftMonth(1)
                }
            }

            Row {
                width: parent.width
                Repeater {
                    model: details.panel.weekdays
                    Text {
                        required property string modelData
                        width: details.calW / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Tokens.inkSubtle
                        font.family: Tokens.mono
                        font.pixelSize: 10
                        font.letterSpacing: 10 * 0.14
                        font.capitalization: Font.AllUppercase
                    }
                }
            }

            Grid {
                columns: 7
                rowSpacing: Tokens.s1
                Repeater {
                    model: details.panel.cells
                    Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool inMonth: modelData.day !== 0
                        readonly property bool today: modelData.today === true
                        readonly property bool picked: inMonth && !today
                            && details.panel.monthOffset === 0 && details.panel.selectedDay === modelData.day
                        readonly property bool hot: inMonth && dayMouse.containsMouse
                        objectName: inMonth ? "day-" + modelData.day : ""
                        width: details.calW / 7
                        height: 32

                        // today is filled with the mark, a picked day takes its edge
                        Rectangle {
                            anchors.centerIn: parent
                            width: 30; height: 28
                            radius: Tokens.radius
                            color: cell.today ? Tokens.mark : "transparent"
                            border.width: cell.picked || (cell.hot && !cell.today) ? 1 : 0
                            border.color: cell.picked ? Tokens.pickEdge : Tokens.markHover
                        }
                        Text {
                            anchors.centerIn: parent
                            text: cell.inMonth ? cell.modelData.day : ""
                            color: cell.today ? Tokens.paper
                                : cell.index % 7 >= 5 ? Tokens.inkSubtle : Tokens.ink
                            font.family: Tokens.mono
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            enabled: cell.inMonth
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: details.panel.selectDay(cell.modelData.day)
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 1
            height: Math.max(month.height, side.height)
            color: Tokens.lineSoft
        }

        // ── the time and the weather ──────────────────────────────────────
        Column {
            id: side
            width: body.width - details.calW - 1 - body.spacing * 2
            spacing: Tokens.s3

            Row {
                objectName: "dashboardClock"
                spacing: Tokens.s2
                Text {
                    id: clockText
                    objectName: "dashboardTime"
                    text: details.panel.timeMain
                    color: Tokens.ink
                    font.family: Tokens.display
                    font.pixelSize: Math.round(Tokens.fHero * 1.5)
                    font.weight: Tokens.displayWeightSet ? Tokens.displayWeight : Font.Light
                }
                // the seconds (and AM/PM) sit on the clock's baseline
                Text {
                    anchors.baseline: clockText.baseline
                    text: (details.panel.ampm !== "" ? details.panel.ampm + " " : "") + ":" + details.panel.timeSecs
                    color: Tokens.inkSubtle
                    font.family: Tokens.mono
                    font.pixelSize: 12
                }
            }

            Kit.Divider { width: parent.width; quiet: true }

            // now: the condition glyph, the temperature and where
            Row {
                objectName: "dashboardNow"
                spacing: Tokens.s3
                Kit.Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    name: details.panel.wxReady ? details.panel.symbol : "cloud"
                    color: details.panel.wxReady ? Tokens.ink : Tokens.inkSubtle
                    size: 32
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: details.panel.wxReady
                    text: details.panel.temperature
                    color: Tokens.ink
                    font.family: Tokens.display
                    font.pixelSize: Tokens.fHero
                    font.weight: Tokens.displayWeightSet ? Tokens.displayWeight : Font.Light
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        objectName: "dashboardCondition"
                        text: details.panel.wxReady ? details.panel.condition
                            : details.panel.wxLoading ? I18n.tr("Loading…") : I18n.tr("Weather offline")
                        color: Tokens.inkSecondary
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fBody
                    }
                    Kit.TrackLabel {
                        visible: details.panel.wxReady && text !== ""
                        text: details.panel.area
                    }
                }
            }

            // wind, humidity, rain and feels-like as readout rows, two columns
            Grid {
                id: readouts
                objectName: "dashboardReadouts"
                visible: details.panel.wxReady
                width: parent.width
                columns: 2
                columnSpacing: Tokens.s4
                Repeater {
                    model: details.panel.wxReady ? details.panel.readouts : []
                    Kit.InfoRow {
                        required property var modelData
                        width: (readouts.width - readouts.columnSpacing) / 2
                        label: modelData.label
                        valueText: modelData.value
                    }
                }
            }

            Kit.Divider { width: parent.width; quiet: true }

            // the coming hours: a 1 px curve over a fading area, the head on now
            Column {
                id: hours
                objectName: "dashboardHours"
                readonly property var list: details.panel.wxReady ? (details.panel.hourly || []) : []
                readonly property bool drawn: list.length >= 2
                width: parent.width
                spacing: Tokens.s1

                Kit.TrackLabel { text: I18n.tr("Next hours") }

                Text {
                    visible: !hours.drawn
                    text: details.panel.wxLoading ? I18n.tr("Loading…") : I18n.tr("Hourly forecast unavailable")
                    color: Tokens.inkSubtle
                    font.family: Tokens.mono
                    font.pixelSize: 12
                }

                Item {
                    id: curve
                    objectName: "hourCurve"
                    visible: hours.drawn
                    width: parent.width
                    height: 64
                    // the readouts above each point need a line of their own
                    readonly property real topY: 16
                    readonly property real baseY: height - 1
                    readonly property var span: {
                        let lo = Infinity, hi = -Infinity;
                        for (const h of hours.list) { lo = Math.min(lo, h.temp); hi = Math.max(hi, h.temp); }
                        if (hi - lo < 1) { hi += 1; lo -= 1; }
                        return [lo, hi];
                    }
                    function xAt(i) {
                        const n = hours.list.length;
                        return 12 + i * (width - 24) / Math.max(1, n - 1);
                    }
                    readonly property var points: {
                        const out = [];
                        for (let i = 0; i < hours.list.length; i++) {
                            const t = (hours.list[i].temp - span[0]) / (span[1] - span[0]);
                            out.push([xAt(i), baseY - 4 - (baseY - 4 - topY) * t]);
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
                    // the temperature over each hour, the current one in the mark
                    Repeater {
                        model: curve.points.length
                        Text {
                            required property int index
                            x: curve.points[index][0] - width / 2
                            y: curve.points[index][1] - height - 3
                            text: hours.list[index].temp + "°"
                            color: index === 0 ? Tokens.mark : Tokens.inkSecondary
                            font.family: Tokens.mono
                            font.pixelSize: 10
                        }
                    }
                    Rectangle {
                        objectName: "hourHead"
                        readonly property var head: curve.points.length ? curve.points[0] : [0, 0]
                        x: head[0] - 4; y: head[1] - 4; width: 8; height: 8; radius: 4
                        color: Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.22)
                        Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: Tokens.thumb }
                    }
                }

                // the hour and its condition under each point
                Item {
                    visible: hours.drawn
                    width: parent.width
                    height: 32
                    Repeater {
                        model: hours.drawn ? hours.list.length : 0
                        Column {
                            required property int index
                            x: curve.xAt(index) - width / 2
                            width: 40
                            spacing: 2
                            Kit.Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: hours.list[index].symbol
                                color: index === 0 ? Tokens.ink : Tokens.inkSubtle
                                size: 14
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: hours.list[index].time
                                color: index === 0 ? Tokens.mark : Tokens.inkSubtle
                                font.family: Tokens.mono
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }
}
