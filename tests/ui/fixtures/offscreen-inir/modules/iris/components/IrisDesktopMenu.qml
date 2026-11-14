pragma ComponentBehavior: Bound

import QtQuick

// Offscreen stand-in for iRiS's desktop menu, for probes and scenes: the real
// one opens in a popup window of its own, which cannot load under the offscreen
// platform. It keeps the API its hosts call and never opens.
Loader {
    id: root
    property var model: []
    property var shown: []
    property Item anchorItem: parent
    property string opensToward: ""
    function requestOpen(): void {}
    function close(): void {}
    active: false
}
