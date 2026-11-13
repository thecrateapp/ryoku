import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate notification list with a stand-in panel: the count
// rides the title, each pending notification is a card with its app, summary
// and body, a card opens or dismisses its own entry, Clear all clears, a long
// history scrolls inside the panel's cap, and an empty list says so.
ShellRoot {
    QtObject {
        id: panel
        property var pending: [
            { key: "n:1", appName: "Crate", summary: "Download complete", body: "Pronto is now available offline." },
            { key: "n:2", appName: "Firefox", summary: "Upload finished", body: "" }
        ]
        readonly property int unreadCount: pending.length
        property int listCap: 420
        property var opened: null
        property var dismissedEntry: null
        property bool cleared: false
        function openNotification(e) { opened = e }
        function dismissOne(e) { dismissedEntry = e }
        function dismissAll() { cleared = true; pending = [] }
    }

    Item {
        width: 288
        height: 700
        CrateNotificationList {
            id: details
            width: 288
            panel: panel
            property bool closed: false
            onCloseRequested: closed = true
        }
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
        interval: 100
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            const title = find(details, "notifTitle");
            if (!title || title.title.indexOf("2") < 0)
                throw new Error("The pending count must ride the title, got " + (title ? title.title : "none"));
            const first = find(details, "notif-n:1");
            const second = find(details, "notif-n:2");
            if (!first || !second)
                throw new Error("Every pending notification needs a card");
            if (find(first, "notifApp").text !== "Crate" || find(first, "notifSummary").text !== "Download complete")
                throw new Error("A card shows its app and summary");
            if (!find(first, "notifBody").visible || find(second, "notifBody").visible)
                throw new Error("The body shows only when there is one");
            first.activate();
            if (!panel.opened || panel.opened.key !== "n:1")
                throw new Error("A card opens its own notification");
            find(second, "notifDismiss").clicked();
            if (!panel.dismissedEntry || panel.dismissedEntry.key !== "n:2")
                throw new Error("Dismiss acts on its own card");
            const clear = find(details, "notifClearAll");
            if (!clear || !clear.visible)
                throw new Error("Clear all shows while notifications are pending");
            const many = [];
            for (let i = 0; i < 30; i++)
                many.push({ key: "m:" + i, appName: "App", summary: "Item " + i, body: "Body" });
            panel.pending = many;
            panel.listCap = 200;
            find(details, "notifCards").forceLayout();
            const list = find(details, "notifScroll");
            if (!list || list.height > 200.5 || !list.interactive)
                throw new Error("A long history scrolls within the cap, height " + (list ? list.height : "none"));
            clear.act();
            if (!panel.cleared)
                throw new Error("Clear all must clear");
            if (!find(details, "notifEmpty").visible || clear.visible)
                throw new Error("An empty list says so and hides Clear all");
            find(details, "closeNotifications").clicked();
            if (!details.closed)
                throw new Error("Close must ask to close");
            console.log("NOTIFICATION-LIST-PROBE-PASS");
            Qt.quit();
        }
    }
}
