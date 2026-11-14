pragma ComponentBehavior: Bound

import QtQuick

// Offscreen stand-in for inir's LiveLayer, for probes and scenes: the real one
// moves its content into a layer surface of its own once the host is still,
// and a layer window cannot load under the offscreen platform. This draws the
// content in place, which is what the real one does whenever it is not
// detached.
Item {
    id: root
    property Component content: null
    property bool live: false
    property bool allowed: true
    property int pad: 0
    property int settleMs: 220
    readonly property bool detached: false

    Loader {
        id: home
        anchors.fill: parent
        sourceComponent: root.content
    }
    Binding { target: home.item; property: "drawing"; value: true; when: home.item !== null }
}
