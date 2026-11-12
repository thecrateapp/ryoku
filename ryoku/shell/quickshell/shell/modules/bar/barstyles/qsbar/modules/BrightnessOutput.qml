import QtQuick
import Quickshell
import Quickshell.Io

// One queue per physical bar. Polls, the slider and wheel events share a single
// hardware operation; a slow DDC reply cannot roll back a newer drag.
Scope {
    id: output
    required property string outputName
    property bool active: true
    property bool available: false
    property int percent: 0

    property int confirmedPercent: 0
    property var pending: []
    property int generation: 0
    property bool ready: false
    property bool writeErrorNotified: false

    function applySteps(value, changes) {
        for (const change of changes) {
            if (change === "up") value = Math.min(100, value + (value < 5 ? 1 : 5))
            else if (change === "down") value = Math.max(1, value - (value <= 5 ? 1 : 5))
            else value = change
        }
        return value
    }

    function setPercent(value) {
        if (!active || !available || !Number.isFinite(value)) return
        percent = Math.max(1, Math.min(100, Math.round(value)))
        pending = [percent]
        if (!writeTimer.running) writeTimer.start()
    }

    function step(up) {
        if (!active || !available) return
        const direction = up ? "up" : "down"
        percent = applySteps(percent, [direction])
        pending = pending.concat(direction)
        flush()
    }

    function refresh() {
        if (ready && active && outputName && !runner.operation && !pending.length)
            start("get")
    }

    function flush() {
        if (!active || !available || runner.operation || !pending.length) return
        // Relative steps must advance real hardware levels, including on a
        // display whose native brightness scale has fewer than 100 levels.
        const change = pending[0]
        pending = pending.slice(1)
        if (typeof change === "string")
            start("step", change)
        else
            start("set", String(change))
    }

    function start(operation, value) {
        runner.operation = operation
        runner.generation = generation
        runner.result = ""
        const args = ["ryoku-brightness-output", operation, outputName]
        if (value !== undefined) args.push(value)
        runner.command = args
        runner.running = true
    }

    function finished(code) {
        const operation = runner.operation
        runner.operation = ""
        if (runner.generation !== generation) {
            Qt.callLater(refresh)
            return
        }

        const valid = code === 0 && /^(100|[1-9]?[0-9])$/.test(runner.result)
        if (valid) {
            confirmedPercent = Number(runner.result)
            percent = applySteps(confirmedPercent, pending)
            available = true
            if (operation !== "get") writeErrorNotified = false
            if (!writeTimer.running) Qt.callLater(flush)
        } else {
            pending = []
            percent = confirmedPercent
            if (operation === "get") {
                available = false
            } else {
                if (!writeErrorNotified) {
                    Quickshell.execDetached(["notify-send", "-a", "QS-Shell",
                        "Brightness command failed", outputName])
                    writeErrorNotified = true
                }
                Qt.callLater(refresh)
            }
        }
    }

    function reset() {
        generation++
        available = false
        percent = 0
        confirmedPercent = 0
        pending = []
        writeErrorNotified = false
        if (ready) {
            writeTimer.stop()
            Qt.callLater(refresh)
        }
    }

    onOutputNameChanged: reset()
    onActiveChanged: reset()
    Component.onCompleted: {
        ready = true
        refresh()
    }

    Timer {
        interval: output.available ? 5000 : 30000
        running: output.active && output.outputName !== ""
        repeat: true
        onTriggered: output.refresh()
    }
    Timer { id: writeTimer; interval: 60; onTriggered: output.flush() }

    Process {
        id: runner
        property int generation: -1
        property string operation: ""
        property string result: ""
        stdout: SplitParser { onRead: data => runner.result = data.trim() }
        onExited: code => output.finished(code)
    }
}
