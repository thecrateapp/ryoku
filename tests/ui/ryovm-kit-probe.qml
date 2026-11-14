import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryovm" as Ryovm
import "ryovm/Singletons" as RyovmState

// Ryoport on the kit, in both looks: the page head is the kit PageHeader under
// crate; downloads run on a Beam (its sweep while the size is unknown); the
// captions are TrackLabels under crate and keep their stock face otherwise; an
// operating system card is a PickCard; a picked list row takes the 1 px pick
// edge under crate; the window is opaque.
ShellRoot {
    id: probe
    property string look: "crate"
    property int chosen: 0

    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 700
        Item {
            x: 60; y: 60
            width: 800; height: 600
            Ryovm.App { id: app; width: 800; height: 600; visible: false }
            Ryovm.PageHead { id: head; width: 600; eyebrow: "FLEET"; title: "Ryoport"; blurb: "Local machines" }
            Ryovm.DownloadStack { id: downloads; y: 160; width: 400 }
            Ryovm.Caption { id: caption; y: 300; text: "Alias"; stockFamily: Tokens.mono; stockSize: 9 }
            Ryovm.OsCard {
                id: os
                x: 420; y: 160; width: 140; height: 130
                entry: ({ os: "fedora", name: "Fedora" })
                active: true
                onChosen: probe.chosen++
            }
            Ryovm.RemoteTile { id: remote; y: 340; width: 400; host: ({ alias: "nas" }) }
        }
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
    function all(item, name, out) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children) all(child, name, out);
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify(crate) {
        check(Qt.colorEqual(app.color, crate ? Tokens.popover : Tokens.paper) && app.color.a === 1, "an opaque window surface");
        const header = find(head, "ryovmPageHeader");
        check(header.visible === crate && header.title === "Ryoport" && header.blurb === "Local machines", "the head is the kit PageHeader under crate");
        check(head.implicitHeight > 20, "the head reports its height");
        const beams = all(downloads, "ryovmDownloadBeam", []);
        check(beams.length === 2 && beams.every(b => b.visible === crate), "downloads run on a Beam under crate");
        check(!beams[0].indeterminate && Math.abs(beams[0].value - 0.42) < 0.001 && beams[1].indeterminate, "a known size fills, an unknown one sweeps");
        if (crate)
            check(caption.font.family === Tokens.mono && caption.font.pixelSize === Tokens.fMicro
                  && caption.font.capitalization === Font.AllUppercase && String(caption.color) === String(caption.toneInk),
                  "a caption is the kit TrackLabel under crate");
        else
            check(caption.font.pixelSize === 9 && caption.font.capitalization === Font.MixedCase
                  && String(caption.color) === String(Tokens.inkMuted), "a caption keeps its stock face");
        check(os.picked && Qt.colorEqual(os.color, crate ? Tokens.pickFill : Tokens.tint10), "the OS card is a picked PickCard");
        check(Qt.colorEqual(os.border.color, crate ? Tokens.pickEdge : Tokens.ink), "the OS card's pick edge");
        check(remote.border.width === (crate ? 1 : 0), "a picked list row takes the pick edge only under crate");
        check(!crate || Qt.colorEqual(remote.border.color, Tokens.pickEdge), "the row's edge is the pick edge");
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            probe.verify(true);
            os.clicked();
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            probe.verify(false);
            probe.check(probe.chosen === 1, "a click chooses the OS once");
            console.log("RYOVM-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            RyovmState.Remotes.selectedAlias = "nas";
            RyovmState.Vm.dlJobs.append({ key: "a", name: "fedora-41", kind: "catalog", os: "fedora", release: "41", edition: "", progress: 0.42, bps: 0, indet: false, phase: "download", log: "", cancel: false });
            RyovmState.Vm.dlJobs.append({ key: "b", name: "nixos", kind: "catalog", os: "nixos", release: "25.05", edition: "", progress: 0, bps: 0, indet: true, phase: "resolve", log: "", cancel: false });
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
