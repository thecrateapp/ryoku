import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate tray menu with a stand-in menu: the app title
// heads it, each dbusmenu entry is a row and each separator a hairline, a
// checked entry carries the pick mark, a submenu row discloses instead of
// activating, a leaf row activates its id, a disabled row does nothing, and
// close closes.
ShellRoot {
    QtObject {
        id: menu
        property string title: "Discord"
        property string icon: ""
        property var expandedIds: ({})
        property var activated: []
        property bool closed: false
        property var rows: [
            { node: { id: 1, label: "_Open", enabled: true }, depth: 0, sep: false, hasKids: false },
            { node: { id: 2, label: "Mute", enabled: true, toggleType: "checkmark", toggleState: 1 }, depth: 0, sep: false, hasKids: false },
            { node: { id: 3, type: "separator" }, depth: 0, sep: true, hasKids: false },
            { node: { id: 4, label: "Status", enabled: true }, depth: 0, sep: false, hasKids: true },
            { node: { id: 5, label: "Updates", enabled: false }, depth: 0, sep: false, hasKids: false }
        ]
        function isExpanded(id) { return !!expandedIds[id] }
        function toggleExpand(id) { const e = Object.assign({}, expandedIds); e[id] = !e[id]; expandedIds = e }
        function activate(id) { activated = activated.concat([id]) }
        function cleanLabel(s) { return String(s || "").replace(/_([^_])/g, "$1") }
        function iconPath(name) { return "" }
        function close() { closed = true }
    }

    Item {
        width: 240
        height: 400
        CrateTrayMenuBody { id: body; width: 240; panel: menu }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }

    Timer {
        interval: 120
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            if (find(body, "trayTitle").text !== "Discord")
                throw new Error("The app title heads the menu");
            const open = find(body, "trayRow-1"), mute = find(body, "trayRow-2");
            if (!open || !mute || !find(body, "trayRow-4") || !find(body, "traySep-3"))
                throw new Error("Every entry is a row and every separator a hairline");
            if (find(open, "trayLabel").text !== "Open")
                throw new Error("Mnemonic underscores are dropped");
            if (!find(mute, "trayCheck").visible || find(open, "trayCheck").visible)
                throw new Error("Only a checked entry carries the pick mark");
            find(body, "trayRow-4").act();
            if (!menu.isExpanded(4) || menu.activated.length !== 0)
                throw new Error("A submenu row discloses instead of activating");
            open.act();
            find(body, "trayRow-5").act();
            if (menu.activated.length !== 1 || menu.activated[0] !== 1)
                throw new Error("A leaf activates its id and a disabled row does nothing: " + menu.activated);
            find(body, "closeTrayMenu").clicked();
            if (!menu.closed)
                throw new Error("Close closes");
            console.log("TRAY-MENU-PROBE-PASS");
            Qt.quit();
        }
    }
}
