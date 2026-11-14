import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryostore" as Ryo
import "ryostore/Singletons" as RyoState

// Ryostore at its full window size three times: the Apps marketplace (featured
// hero, keyed category tabs with counts, sort tabs, the search field, picked
// tiles), the Rices artwork grid with a picked card and an install in progress,
// and a rice's detail with its provenance links.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1180
        implicitHeight: 2328
        color: Tokens.controlsCrate ? Tokens.popover : Tokens.paper

        Item {
            id: sheet
            width: 1180
            height: 2328
            Ryo.App { id: apps; width: 1180; height: 760 }
            Ryo.App { id: rices; y: 784; width: 1180; height: 760 }
            Ryo.App { id: detail; y: 1568; width: 1180; height: 760 }
        }

        Timer {
            interval: 1200
            running: true
            onTriggered: {
                apps.openRoute("flatpak");
                rices.openRoute("rices");
                detail.openRoute("rices");
                route.start();
            }
        }
        Timer {
            id: route
            interval: 600
            onTriggered: {
                apps.selectKey("flatpak:org.example.Alpha");
                rices.selectKey("rices:neon");
                detail.selectKey("rices:paper");
                detail.openSelectedDetail();
                RyoState.Store.busyKey = "rices:neon";
                RyoState.Store.installProgressStage = "download";
                RyoState.Store.installProgressDone = 31457280;
                RyoState.Store.installProgressTotal = 73400320;
                shot.start();
            }
        }
        Timer {
            id: shot
            interval: Number(Quickshell.env("BENCH_WAIT") || 1500)
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
