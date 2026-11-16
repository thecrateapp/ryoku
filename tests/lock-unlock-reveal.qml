import QtQuick
import Quickshell
import "qylock/quickshell-lockscreen/unlock_reveal.js" as UnlockReveal
ShellRoot {
    id: root
    function check(name, got, want) {
        if (got !== want) { console.error("FAIL: " + name + " got " + got + " want " + want); Qt.quit(); return false }
        return true
    }
    Timer {
        interval: 100; running: true
        onTriggered: root.run()
    }
    function run() {
        const d = UnlockReveal.revealDelay
        const cw = {enableWindup: "true"}
        const ok = check("no keys", d("other/skin", {}, false), 100)
            && check("no keys sensor", d("other/skin", {}, true), 100)
            && check("undefined config", d("other/skin", undefined, false), 100)
            && check("password key", d("other/skin", {unlockRevealMs: "900"}, false), 900)
            && check("password key on sensor win falls back", d("other/skin", {unlockRevealMs: "900"}, true), 900)
            && check("sensor key", d("other/skin", {unlockRevealMs: "900", unlockSensorRevealMs: "2500"}, true), 2500)
            && check("sensor key ignored on password win", d("other/skin", {unlockRevealMs: "900", unlockSensorRevealMs: "2500"}, false), 900)
            && check("sensor key alone, password win", d("other/skin", {unlockSensorRevealMs: "2500"}, false), 100)
            && check("zero is valid", d("other/skin", {unlockRevealMs: "0"}, false), 0)
            && check("clamped high", d("other/skin", {unlockRevealMs: "99999"}, false), 5000)
            && check("negative invalid", d("other/skin", {unlockRevealMs: "-5"}, false), 100)
            && check("non-integer invalid", d("other/skin", {unlockRevealMs: "12.5"}, false), 100)
            && check("garbage invalid", d("other/skin", {unlockRevealMs: "fast"}, false), 100)
            && check("invalid sensor falls to password", d("other/skin", {unlockRevealMs: "300", unlockSensorRevealMs: "x"}, true), 300)
            && check("clockwork password", d("clockwork/orbital", cw, false), 720)
            && check("clockwork sensor", d("clockwork/orbital", cw, true), 2300)
            && check("clockwork windup off", d("clockwork/orbital", {enableWindup: "false"}, false), 100)
            && check("windup ignored off clockwork", d("other/skin", cw, false), 100)
            && check("keys override clockwork", d("clockwork/orbital", {enableWindup: "true", unlockRevealMs: "50"}, false), 50)
        if (ok) console.log("PASS: unlock reveal delay: defaults, skin keys, sensor fallback, clockwork rule, clamping")
        Qt.quit()
    }
}
