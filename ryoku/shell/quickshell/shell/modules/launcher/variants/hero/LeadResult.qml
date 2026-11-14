import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "../../shared/Singletons"

Rectangle {
    id: root

    property real s: 1
    property var entry: null
    property string errorText: ""
    property int windowCount: 0
    property bool windowFocusActive: false
    property var outgoingSnapshot: null
    property var currentSnapshot: null
    property string displayedKey: ""
    property bool complete: false

    signal activated()

    readonly property var primaryAction: entry ? entry.primaryAction : null
    readonly property var secondaryActions: entry && entry.secondaryActions
        ? entry.secondaryActions : []
    readonly property bool executable: primaryAction !== null && !entry.disabled
    readonly property string accessibleName: {
        if (!entry)
            return "";
        var title = String(entry.title || "");
        var detail = metadataFor(entry);
        return detail.length ? title + ", " + detail : title;
    }

    // Under crate the lead is the picked row of the kit: the pick wash in the
    // 1 px pickEdge at Tokens.radius, its ink the pick ink, its captions the
    // tracked mono label. Stock keeps the bone plate in a 2 px bright edge.
    readonly property bool crate: Tokens.controlsCrate
    readonly property color ink: crate ? Tokens.pickInk : Theme.onLead
    readonly property color inkDim: crate ? Tokens.pickInkDim : Theme.onLeadDim

    implicitHeight: 82 * s
    color: crate ? Tokens.pickFill : Theme.leadContainer
    opacity: entry && entry.disabled ? 0.56 : 1
    radius: crate ? Tokens.radius : 0

    border.width: crate ? Tokens.border : Math.max(1, 2 * s)
    border.color: crate ? Tokens.pickEdge : Theme.bright

    Accessible.role: Accessible.ListItem
    Accessible.name: accessibleName
    Accessible.description: primaryAction
        ? I18n.tr("Primary action: %1").arg(String(primaryAction.name || I18n.tr("Open")))
        : I18n.tr("Informational result")
    Accessible.ignored: entry === null
    Accessible.focusable: false
    Accessible.selectable: entry !== null
    Accessible.selected: entry !== null
    Accessible.defaultButton: executable
    Accessible.onPressAction: if (root.executable) root.activated()

    Behavior on color {
        ColorAnimation { duration: Motion.selection; easing.type: Easing.OutCubic }
    }

    function entryKey(source) {
        return source ? String(source.resultKey || "") : "";
    }

    function metadataFor(source) {
        if (!source)
            return "";
        var provider = I18n.tr(String(source.type || source.providerId || "")).toUpperCase();
        var detail = String(source.subtitle || "");
        return provider.length && detail.length ? provider + "  /  " + detail
            : (provider.length ? provider : detail);
    }

    function snapshot(source) {
        if (!source)
            return null;
        var secondaries = [];
        var rawSecondaries = source.secondaryActions || [];
        for (var index = 0; index < rawSecondaries.length; index++) {
            secondaries.push({
                id: String(rawSecondaries[index].id || ""),
                name: String(rawSecondaries[index].name || "")
            });
        }
        return {
            resultKey: entryKey(source),
            providerId: String(source.providerId || ""),
            type: String(source.type || ""),
            title: String(source.title || ""),
            subtitle: String(source.subtitle || ""),
            icon: String(source.icon || ""),
            preview: String(source.preview || ""),
            disabled: source.disabled === true,
            primaryAction: source.primaryAction ? {
                id: String(source.primaryAction.id || ""),
                name: String(source.primaryAction.name || I18n.tr("Open"))
            } : null,
            secondaryActions: secondaries
        };
    }

    function adoptEntry() {
        var next = snapshot(entry);
        var nextKey = entryKey(entry);
        if (!complete) {
            currentSnapshot = next;
            displayedKey = nextKey;
            return;
        }
        if (nextKey === displayedKey) {
            currentSnapshot = next;
            return;
        }

        leadSwap.stop();
        outgoingSnapshot = currentSnapshot;
        currentSnapshot = next;
        displayedKey = nextKey;
        outgoingContent.opacity = outgoingSnapshot ? 1 : 0;
        incomingContent.opacity = outgoingSnapshot && currentSnapshot
            && Motion.selection > 0 ? 0 : 1;
        if (outgoingSnapshot && currentSnapshot && Motion.selection > 0)
            leadSwap.restart();
        else
            outgoingSnapshot = null;
    }

    onEntryChanged: adoptEntry()
    Component.onCompleted: {
        complete = true;
        adoptEntry();
    }

    component LeadContent: Item {
        property var visualEntry: null
        property real scaleFactor: 1
        property string visualError: ""
        readonly property string visualKey: visualEntry
            ? String(visualEntry.resultKey || "") : ""
        readonly property var visualPrimary: visualEntry
            ? visualEntry.primaryAction : null
        readonly property var visualSecondaries: visualEntry
            && visualEntry.secondaryActions ? visualEntry.secondaryActions : []
        readonly property bool visualExecutable: visualPrimary !== null
            && visualEntry && !visualEntry.disabled
        readonly property bool visualHasIcon: visualEntry
            && String(visualEntry.icon || "").length > 0
        readonly property bool visualHasPreview: visualEntry
            && String(visualEntry.preview || "").length > 0
        readonly property bool visualIsWeb: visualEntry
            && String(visualEntry.providerId || "") === "web"

        Rectangle {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 15 * parent.scaleFactor
            anchors.verticalCenter: parent.verticalCenter
            width: parent.visualHasPreview || parent.visualHasIcon
                || parent.visualIsWeb ? 38 * parent.scaleFactor : 0
            height: width
            color: root.crate ? (parent.visualIsWeb ? Tokens.mark : "transparent")
                : parent.visualIsWeb ? Theme.onLead : Theme.drawerRaised
            radius: root.crate ? Tokens.radius : 0
            border.width: parent.visualHasPreview ? Math.max(1, parent.scaleFactor) : 0
            border.color: root.crate ? Tokens.line : Theme.onLeadDim
            clip: true

            Image {
                anchors.fill: parent
                sourceSize.width: Math.round(76 * icon.parent.scaleFactor)
                sourceSize.height: Math.round(76 * icon.parent.scaleFactor)
                fillMode: icon.parent.visualHasPreview ? Image.PreserveAspectCrop
                    : Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: icon.parent.visualHasPreview || icon.parent.visualHasIcon
                source: !icon.parent.visualEntry ? ""
                    : (icon.parent.visualHasPreview
                        ? icon.parent.visualEntry.preview
                        : icon.parent.visualEntry.icon)
            }

            Text {
                anchors.centerIn: parent
                visible: icon.parent.visualIsWeb
                text: "?"
                color: root.crate ? Tokens.paper : Theme.leadContainer
                font.family: root.crate ? Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Tokens.fValue : 24 * icon.parent.scaleFactor
                font.weight: Font.DemiBold
            }
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: parent.visualHasPreview || parent.visualHasIcon
                || parent.visualIsWeb
                ? 13 * parent.scaleFactor : 15 * parent.scaleFactor
            anchors.right: command.left
            anchors.rightMargin: 14 * parent.scaleFactor
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * parent.scaleFactor

            Text {
                objectName: "leadTitle"
                width: parent.width
                text: parent.parent.visualEntry
                    ? String(parent.parent.visualEntry.title || "") : ""
                color: root.ink
                font.family: root.crate ? Tokens.ui : Theme.font
                font.pixelSize: root.crate ? Tokens.fRow : 16 * parent.parent.scaleFactor
                font.weight: root.crate ? Font.Medium : Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: parent.parent.visualError.length
                    ? parent.parent.visualError
                    : root.metadataFor(parent.parent.visualEntry)
                color: parent.parent.visualError.length
                    ? (root.crate ? Tokens.alert : root.ink) : root.inkDim
                font.family: root.crate ? Tokens.ui : Theme.mono
                font.pixelSize: root.crate ? Tokens.fSmall : 9 * parent.parent.scaleFactor
                font.letterSpacing: root.crate ? 0 : 0.35 * parent.parent.scaleFactor
                elide: Text.ElideMiddle
                visible: text.length > 0
            }
        }

        Column {
            id: command
            anchors.right: parent.right
            anchors.rightMargin: 15 * parent.scaleFactor
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3 * parent.scaleFactor

            Text {
                anchors.right: parent.right
                text: parent.parent.visualPrimary
                    ? (root.windowCount > 0 ? I18n.tr("OPEN NEW")
                        : String(parent.parent.visualPrimary.name || I18n.tr("OPEN"))
                            .toUpperCase())
                    : I18n.tr("INFO")
                color: root.ink
                font.family: root.crate ? Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Tokens.fMicro : 9 * parent.parent.scaleFactor
                font.weight: root.crate ? Font.Normal : Font.DemiBold
                font.letterSpacing: root.crate ? Tokens.trackLabel : 0.8 * parent.parent.scaleFactor
            }

            Text {
                anchors.right: parent.right
                text: !parent.parent.visualExecutable ? I18n.tr("NO ACTION")
                    : (root.windowCount > 0
                        ? (root.windowFocusActive
                            ? I18n.tr("WINDOW FOCUS  ·  ENTER")
                            : I18n.tr("ENTER NEW  ·  TAB WINDOWS"))
                        : I18n.tr("\u23ce  ENTER"))
                color: root.crate ? Tokens.inkSubtle : root.inkDim
                font.family: root.crate ? Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Tokens.fMicro : 8 * parent.parent.scaleFactor
                font.letterSpacing: root.crate ? Tokens.trackLabel : 0.5 * parent.parent.scaleFactor
            }

            Text {
                anchors.right: parent.right
                visible: parent.parent.visualSecondaries.length > 0
                text: I18n.tr("+%1 MORE  \u00b7  CTRL+K")
                    .arg(parent.parent.visualSecondaries.length)
                color: root.crate ? Tokens.inkSubtle : root.ink
                font.family: root.crate ? Tokens.mono : Theme.mono
                font.pixelSize: root.crate ? Tokens.fMicro : 8 * parent.parent.scaleFactor
                font.weight: root.crate ? Font.Normal : Font.DemiBold
                font.letterSpacing: root.crate ? Tokens.trackLabel : 0
            }
        }
    }

    LeadContent {
        id: outgoingContent
        objectName: "lead-outgoing"
        anchors.fill: parent
        visualEntry: root.outgoingSnapshot
        scaleFactor: root.s
        visualError: root.errorText
        opacity: 0
        visible: opacity > 0
    }

    LeadContent {
        id: incomingContent
        objectName: "lead-incoming"
        anchors.fill: parent
        visualEntry: root.currentSnapshot
        scaleFactor: root.s
        visualError: root.errorText
        opacity: 1
    }

    ParallelAnimation {
        id: leadSwap

        NumberAnimation {
            target: outgoingContent
            property: "opacity"
            from: 1
            to: 0
            duration: Motion.selection
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: incomingContent
            property: "opacity"
            from: 0
            to: 1
            duration: Motion.selection
            easing.type: Easing.OutCubic
        }
        onFinished: root.outgoingSnapshot = null
    }

    HoverHandler {
        cursorShape: root.executable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.executable
        onTapped: root.activated()
    }
}
