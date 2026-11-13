import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate workspace list with a stand-in panel: a row per
// workspace with its window count, the active one takes the pick, the one the
// arrow keys reached shows its edge, a row goes to its workspace, close closes.
ShellRoot {
    QtObject {
        id: panel
        property var workspaces: [
            { id: 11, name: "1", windows: 3 },
            { id: 12, name: "2", windows: 1 },
            { id: 13, name: "3", windows: 0 }
        ]
        property int activeId: 12
        property int navIndex: 2
        property int went: -1
        property bool closed: false
        function goTo(id) { went = id }
        function close() { closed = true }
    }

    Item {
        width: 288
        height: 400
        CrateWorkspacesBody { id: body; width: 288; panel: panel }
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
            const one = find(body, "ws-11"), two = find(body, "ws-12"), three = find(body, "ws-13");
            if (!one || !two || !three)
                throw new Error("Every workspace is a row");
            if (!two.on || one.on)
                throw new Error("The active workspace takes the pick");
            if (three.quiet || !one.quiet)
                throw new Error("The keyboard's row shows its edge");
            if (one.sub.indexOf("3") < 0 || three.sub === one.sub)
                throw new Error("A row tells its window count");
            find(body, "wsGo-13").activate();
            if (panel.went !== 13)
                throw new Error("A row goes to its workspace");
            find(body, "closeWorkspaces").clicked();
            if (!panel.closed)
                throw new Error("Close closes");
            console.log("WORKSPACES-PROBE-PASS");
            Qt.quit();
        }
    }
}
