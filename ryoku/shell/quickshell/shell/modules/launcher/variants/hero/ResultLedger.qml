import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons as Ui
import "../../shared/Singletons"

GridView {
    id: root

    property real s: 1
    property var results: []
    property string selectedResultKey: ""

    signal resultSelected(string resultKey, int rank)

    // Under crate a row is the kit's list row: the picked one takes the pick
    // wash in the 1 px pickEdge at Tokens.radius, and the ledger's rank
    // numerals and grid rules (Ryoku marginalia) do not show.
    readonly property bool crate: Ui.Tokens.controlsCrate

    readonly property var rows: {
        var output = [];
        var source = root.results || [];
        for (var index = 0; index < source.length; index++) {
            var entry = source[index];
            if (entry)
                output.push({ entry: entry, rank: index + 1 });
        }
        return output;
    }
    readonly property int ledgerRowCount: Math.ceil(rows.length / 2)
    readonly property real desiredHeight: 4 * 44 * s

    model: rows.length
    cellWidth: width / 2
    cellHeight: 44 * s
    clip: true
    reuseItems: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 2600

    function revealRank(rank) {
        if (rows.length === 0)
            return;
        var filtered = rows.length - 1;
        for (var index = 0; index < rows.length; index++) {
            if (rows[index].rank - 1 >= rank) {
                filtered = index;
                break;
            }
        }
        positionViewAtIndex(Math.max(0, filtered), GridView.Contain);
    }

    delegate: Item {
        id: cell

        required property int index
        readonly property var rowData: root.rows[index]
        readonly property var entry: rowData ? rowData.entry : null
        readonly property bool hasIcon: entry && String(entry.icon || "").length > 0
        readonly property bool hasPreview: entry
            && String(entry.preview || "").length > 0
        readonly property bool isWeb: entry && String(entry.providerId || "") === "web"
        readonly property bool picked: entry !== null
            && entry.resultKey === root.selectedResultKey

        objectName: "result-" + (entry ? String(entry.resultKey || "") : "")
        width: root.cellWidth
        height: root.cellHeight

        Accessible.role: Accessible.ListItem
        Accessible.name: entry ? String(entry.title || "") : ""
        Accessible.description: entry
            ? Ui.I18n.tr("Rank %1, %2").arg(String(rowData.rank))
                .arg(String(entry.type || entry.providerId || ""))
            : ""
        Accessible.ignored: entry === null
        Accessible.focusable: false
        Accessible.selectable: entry !== null
        Accessible.selected: entry !== null
            && entry.resultKey === root.selectedResultKey
        Accessible.onPressAction: cell.selectResult()

        function selectResult() {
            if (entry)
                root.resultSelected(entry.resultKey, rowData.rank - 1);
        }

        Entrance {
            anchors.fill: parent
            index: cell.index
        Rectangle {
            objectName: cell.picked ? "resultPick" : ""
            anchors.fill: parent
            anchors.margins: root.crate ? 2 * root.s : 0
            radius: root.crate ? Ui.Tokens.radius : 0
            color: cell.picked
                ? (root.crate ? Ui.Tokens.pickFill : Theme.pickRow) : "transparent"
            border.width: cell.picked ? 1 : 0
            border.color: root.crate ? Ui.Tokens.pickEdge : Theme.pickEdge
        }

        Rectangle {
            objectName: cell.index === 0 ? "resultRule" : ""
            visible: !root.crate
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.hair
        }

        Rectangle {
            visible: !root.crate
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: cell.index % 2 === 0 ? 1 : 0
            color: Theme.hair
        }

        Text {
            id: rank
            objectName: cell.index === 0 ? "resultRank" : ""
            visible: !root.crate
            anchors.left: parent.left
            anchors.leftMargin: 9 * root.s
            anchors.verticalCenter: parent.verticalCenter
            width: root.crate ? 3 * root.s : 24 * root.s
            text: cell.rowData ? String(cell.rowData.rank).padStart(2, "0") : ""
            color: Theme.faint
            font.family: Theme.mono
            font.pixelSize: 8 * root.s
            font.features: ({ "tnum": 1 })
        }

        Rectangle {
            id: icon
            anchors.left: rank.right
            anchors.verticalCenter: parent.verticalCenter
            width: cell.hasPreview || cell.hasIcon || cell.isWeb ? 21 * root.s : 0
            height: width
            radius: root.crate ? Ui.Tokens.radius : 0
            color: root.crate ? (cell.isWeb ? Ui.Tokens.mark : "transparent")
                : cell.isWeb ? Theme.onLead : Theme.drawerRaised
            border.width: cell.hasPreview ? 1 : 0
            border.color: Theme.hair
            clip: true

            Image {
                anchors.fill: parent
                sourceSize.width: Math.round(42 * root.s)
                sourceSize.height: Math.round(42 * root.s)
                fillMode: cell.hasPreview ? Image.PreserveAspectCrop
                    : Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: cell.hasPreview || cell.hasIcon
                source: cell.hasPreview ? cell.entry.preview : cell.entry.icon
            }

            Text {
                anchors.centerIn: parent
                visible: cell.isWeb
                text: "?"
                color: root.crate ? Ui.Tokens.paper : Theme.drawer
                font.family: root.crate ? Ui.Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Ui.Tokens.fBody : 14 * root.s
                font.weight: Font.DemiBold
            }
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: (root.crate ? icon.width > 0 : cell.hasIcon) ? 9 * root.s : 0
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                objectName: cell.index === 0 ? "resultTitle" : ""
                width: parent.width
                text: cell.entry ? String(cell.entry.title || "") : ""
                color: cell.entry && cell.entry.disabled
                    ? (root.crate ? Ui.Tokens.inkFaint : Theme.faint)
                    : root.crate ? (cell.picked ? Ui.Tokens.pickInk : Ui.Tokens.ink) : Theme.cream
                font.family: root.crate ? Ui.Tokens.ui : Theme.font
                font.pixelSize: root.crate ? Ui.Tokens.fBody : 11 * root.s
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: cell.entry
                    ? Ui.I18n.tr(String(cell.entry.type || cell.entry.providerId || "")).toUpperCase()
                    : ""
                objectName: cell.index === 0 ? "resultSub" : ""
                color: root.crate ? Ui.Tokens.inkSubtle : Theme.faint
                font.family: root.crate ? Ui.Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Ui.Tokens.fMicro : 7.5 * root.s
                font.letterSpacing: root.crate ? Ui.Tokens.trackLabel : 0.7 * root.s
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: cell.selectResult()
        }
        }
    }
}
