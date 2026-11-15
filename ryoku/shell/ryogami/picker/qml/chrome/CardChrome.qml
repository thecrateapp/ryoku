import QtQuick
import Ryoku.Ui.Singletons

// Anchored to the CardField's live currentRect, so it follows the selection as the scene moves.
Item {
    id: chrome

    required property PickerState state
    readonly property CardField field: state.field

    readonly property rect cardRect: chrome.field ? chrome.field.currentRect : Qt.rect(0, 0, 0, 0)
    // Half the card's skew and edge tilt: the same inner box and shear card.frag draws.
    readonly property point shear: chrome.field ? chrome.field.currentShear : Qt.point(0, 0)
    readonly property real sx: chrome.shear.x * 0.5
    readonly property real ty: chrome.shear.y * 0.5
    readonly property real innerW: Math.max(chrome.cardRect.width - 2 * Math.abs(chrome.sx), 2)
    readonly property real innerH: Math.max(chrome.cardRect.height - 2 * Math.abs(chrome.ty), 2)
    readonly property int row: chrome.field ? chrome.field.currentIndex : -1
    // view.get() is a call QML cannot track, so any model change re-runs the lookup.
    property int _rev: 0
    Connections {
        target: chrome.state.view
        function onModelReset() { chrome._rev++ }
        function onDataChanged() { chrome._rev++ }
        function onLayoutChanged() { chrome._rev++ }
        function onCountChanged() { chrome._rev++ }
        function onCollectionChanged() { chrome._rev++ }
    }
    readonly property var entry: {
        chrome._rev
        var v = chrome.state.view
        if (!v || chrome.row < 0 || chrome.row >= v.count || chrome.cardRect.width <= 0)
            return ({})
        return v.get(chrome.row)
    }
    readonly property int badges: chrome.entry.badges !== undefined ? chrome.entry.badges : 0

    visible: !!(chrome.field && chrome.field.flippedIndex < 0
        && chrome.cardRect.width > 4 && chrome.cardRect.height > 4
        && (chrome.entry.name || chrome.entry.key))

    CardLabel {
        x: chrome.cardRect.x + (chrome.cardRect.width - chrome.innerW) * 0.5
        y: chrome.cardRect.y + (chrome.cardRect.height - chrome.innerH) * 0.5
        width: chrome.innerW
        height: chrome.innerH
        sx: chrome.sx
        ty: chrome.ty
        type: chrome.entry.type || ""
        name: chrome.entry.name || chrome.entry.key || ""
        badges: chrome.badges
        showName: chrome.state.collection !== "workshop"
    }
}
