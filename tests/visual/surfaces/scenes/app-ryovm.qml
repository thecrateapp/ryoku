import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryovm" as Ryovm
import "ryovm/Singletons" as RyovmState

// Ryoport at its minimum window size three times: the fleet dashboard (the
// page head, the resource rows with the live one picked), the machine library
// (rows, the detail with its section heads) and the catalogue (operating system
// cards with one picked, a download in progress).
ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 1180
        implicitHeight: 2328
        color: Tokens.controlsCrate ? Tokens.popover : Tokens.paper

        Item {
            id: sheet
            width: 1180
            height: 2328
            Ryovm.App { id: dash; width: 1180; height: 760 }
            Ryovm.App { id: library; y: 784; width: 1180; height: 760; section: "machines" }
            Ryovm.App { id: catalogue; y: 1568; width: 1180; height: 760; section: "machines" }
        }

        function machinesOf(item) {
            if (item.mode !== undefined && item.channel !== undefined) return item;
            for (const child of item.children) {
                const hit = machinesOf(child);
                if (hit) return hit;
            }
            return null;
        }

        Timer {
            interval: 1500
            running: true
            onTriggered: {
                const mach = win.machinesOf(catalogue);
                mach.channel = "catalog";
                mach.mode = "new";
                pick.start();
            }
        }
        Timer {
            id: pick
            interval: 800
            onTriggered: {
                const fedora = RyovmState.Vm.osList.find(o => o.os === "fedora");
                if (fedora) RyovmState.Vm.selectOs(fedora);
                RyovmState.Vm.dlJobs.append({ key: "fedora-41", name: "fedora-41", kind: "catalog", os: "fedora", release: "41",
                                              edition: "", progress: 0.42, bps: 6291456, indet: false,
                                              phase: "download", log: "", cancel: false });
                RyovmState.Vm.dlJobs.append({ key: "nixos", name: "nixos-25.05", kind: "catalog", os: "nixos", release: "25.05",
                                              edition: "", progress: 0, bps: 0, indet: true, phase: "resolve",
                                              log: "mirror: channels.nixos.org", cancel: false });
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
