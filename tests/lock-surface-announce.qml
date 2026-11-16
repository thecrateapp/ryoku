import QtQuick
import Quickshell
import "qylock/quickshell-lockscreen/surface_announce.js" as SurfaceAnnounce
ShellRoot {
    id: root
    function fail(name) { console.error("FAIL: " + name); Qt.quit() }
    Timer {
        interval: 100; running: true
        onTriggered: root.run()
    }
    // drive a sequence of "arm" and "recover" events, returning which arms announced
    function announces(events) {
        let state = SurfaceAnnounce.initial()
        const out = []
        for (const e of events) {
            if (e === "arm") {
                const step = SurfaceAnnounce.armed(state)
                state = step.state
                out.push(step.announce)
            } else {
                state = SurfaceAnnounce.recovered(state)
            }
        }
        return JSON.stringify(out)
    }
    function expect(name, events, want) {
        const got = announces(events)
        if (got !== JSON.stringify(want)) { fail(name + ": got " + got + " want " + JSON.stringify(want)); return false }
        return true
    }
    function run() {
        const ok = expect("first arm announces once", ["arm", "arm"], [true, false])
            && expect("a recovery announces again on the next arm", ["arm", "recover", "arm", "arm"], [true, true, false])
            && expect("every recovery announces once", ["arm", "recover", "arm", "recover", "arm"], [true, true, true])
            && expect("recoveries before re-arming announce once", ["arm", "recover", "recover", "arm", "arm"], [true, true, false])
            && expect("a recovery before the first arm adds nothing", ["recover", "arm", "arm"], [true, false])
        if (ok) console.log("PASS: the lock surface is announced on the first arm and again after each recovery")
        Qt.quit()
    }
}
