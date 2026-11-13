import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate tray overflow with a stand-in panel: the count
// rides the title, each hidden app is a list row, an app that needs attention
// takes the pick and says so, open, pin and menu reach the panel with their
// own app, an app without a menu cannot open one, and close closes.
ShellRoot {
    QtObject {
        id: panel
        property var hiddenItems: [
            { service: "discord", name: "Discord", description: "", attention: false, icon: "", hasMenu: true, itemIsMenu: false },
            { service: "steam", name: "Steam", description: "Downloading", attention: true, icon: "", hasMenu: false, itemIsMenu: false }
        ]
        readonly property int attentionCount: 1
        property string calls: ""
        property bool closed: false
        function activateItem(e, anchor) { calls += "open:" + e.service + " " }
        function pinItem(e) { calls += "pin:" + e.service + " " }
        function openMenu(e, anchor) { calls += "menu:" + e.service + " " }
        function close() { closed = true }
    }

    Item {
        width: 296
        height: 400
        CrateTrayAppsBody { id: body; width: 296; panel: panel }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        if (item.contentItem) return find(item.contentItem, name);
        return null;
    }

    Timer {
        interval: 120
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            if (find(body, "trayAppsTitle").title.indexOf("2") < 0)
                throw new Error("The hidden count rides the title");
            const discord = find(body, "trayApp-discord"), steam = find(body, "trayApp-steam");
            if (!discord || !steam)
                throw new Error("Every hidden app is a row");
            if (!steam.on || discord.on || steam.sub.indexOf("Downloading") < 0)
                throw new Error("An app that needs attention takes the pick and says why");
            find(discord, "trayOpen").clicked();
            find(discord, "trayPin").clicked();
            find(discord, "trayMenu").clicked();
            if (panel.calls !== "open:discord pin:discord menu:discord ")
                throw new Error("Open, pin and menu act on their own app: " + panel.calls);
            if (find(steam, "trayMenu").enabled)
                throw new Error("An app without a menu cannot open one");
            find(body, "closeTrayApps").clicked();
            if (!panel.closed)
                throw new Error("Close closes");
            console.log("TRAY-APPS-PROBE-PASS");
            Qt.quit();
        }
    }
}
