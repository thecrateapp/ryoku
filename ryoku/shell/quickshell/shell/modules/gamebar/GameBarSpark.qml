import QtQuick
import QtQuick.Shapes
import Ryoku.Ui.Singletons as Ui
import "look"

// A sparkline: a 2px line filled to half opacity underneath, newest sample
// at the right edge. Values are fractions, so a percentage history fills from
// the floor instead of stretching to its own peak.
// Under crate it is the Controls activity graph's grammar: a hairline grid, a
// 1 px series line over a gradient area, and a dot in a halo at the head.
Item {
    id: root

    property var values: []
    property color color: GameBarLook.accent

    readonly property bool crate: Ui.Tokens.controlsCrate

    readonly property var samples: {
        const source = root.values || [];
        const result = [];
        for (let i = 0; i < source.length; i++)
            result.push(Math.max(0, Math.min(1, Number(source[i]) || 0)));
        return result;
    }

    readonly property var points: {
        const list = root.samples;
        if (list.length === 0)
            return [];
        if (list.length === 1)
            return [Qt.point(0, (1 - list[0]) * height), Qt.point(width, (1 - list[0]) * height)];
        return list.map((v, i) => Qt.point(width * i / (list.length - 1), (1 - v) * height));
    }

    readonly property var areaPoints: points.length > 0
        ? [Qt.point(0, height)].concat(points, [Qt.point(width, height)]) : []

    // the hairline grid: quarters of the range
    Repeater {
        model: root.crate ? 3 : 0

        delegate: Rectangle {
            required property int index
            objectName: "gameBarSparkGrid"
            y: Math.round(root.height * (index + 1) / 4)
            width: root.width
            height: 1
            color: Ui.Tokens.lineSoft
        }
    }

    Shape {
        anchors.fill: parent
        visible: root.points.length > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            startX: 0
            startY: root.height
            strokeColor: "transparent"
            fillColor: root.crate ? "transparent" : Qt.rgba(root.color.r, root.color.g, root.color.b, 0.5)
            fillGradient: root.crate ? area : null
            PathPolyline { path: root.areaPoints }
        }

        ShapePath {
            startX: root.points.length > 0 ? root.points[0].x : 0
            startY: root.points.length > 0 ? root.points[0].y : 0
            strokeColor: root.color
            strokeWidth: root.crate ? 1 : 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.points }
        }
    }

    LinearGradient {
        id: area
        x1: 0
        y1: 0
        x2: 0
        y2: root.height
        GradientStop { position: 0; color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.24) }
        GradientStop { position: 1; color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0) }
    }

    // the head: a dot in its halo at the newest sample
    Item {
        objectName: "gameBarSparkHead"
        visible: root.crate && root.points.length > 0
        readonly property point head: root.points.length > 0 ? root.points[root.points.length - 1] : Qt.point(0, 0)
        x: head.x - 4
        y: head.y - 4
        width: 8
        height: 8

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.28)
        }
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: 2
            color: Ui.Tokens.thumb
        }
    }
}
