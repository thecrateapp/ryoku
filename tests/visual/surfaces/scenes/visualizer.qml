import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "modules/visualizer"
import "modules/visualizer/Singletons" as Viz

// The desktop spectrum over a wallpaper-like gradient: the primary bars, lifted
// for the Stage Editor with its placement grip on them, a look pinned to an
// orange (painted as chosen in both looks) and the edge field on the two side
// rails. Each is the Item the visualiser's layer window hosts, since a layer
// window needs a compositor.
//
// The looks themselves are GPU shaders (SpectrumField, AuraField), which the
// offscreen software scene graph does not run. So each look also gets a
// software stand-in drawn from the colours it hands its shader: the bars in its
// box, one band per level of a fixed frame, take the ramp stop the shader would
// give that band, and each edge rail takes the field's triad. The colours are
// the view's own `ramp` and `auraTriad`, read live, so the render shows what
// the shader is told to paint in each look.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1280
        implicitHeight: 720
        color: Tokens.paper

        Item {
            id: sheet
            width: 1280
            height: 720

            // A fixed frame: a bass hump, a mid shelf and a falling treble, the
            // same on every run so the two looks compare band for band.
            function level(i, n) {
                const t = i / Math.max(1, n - 1);
                return Math.max(0.04, Math.min(1, 0.85 * Math.exp(-Math.pow((t - 0.12) / 0.1, 2))
                    + 0.45 * Math.exp(-Math.pow((t - 0.45) / 0.18, 2))
                    + 0.2 * (1 - t) * (0.6 + 0.4 * Math.sin(i * 1.7))));
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#1b2333" }
                    GradientStop { position: 0.6; color: "#2c3b4f" }
                    GradientStop { position: 1; color: "#0d1017" }
                }
            }

            component StandIn: Item {
                id: stand
                required property VisualizerView view
                readonly property rect box: stand.view.boxRect
                readonly property int n: 40
                Repeater {
                    model: stand.view.aura ? 0 : stand.n
                    Rectangle {
                        required property int index
                        readonly property real slot: stand.box.width / stand.n
                        readonly property real h: sheet.level(index, stand.n) * stand.box.height
                        x: stand.box.x + index * slot + slot * 0.21
                        y: stand.box.y + stand.box.height - h
                        width: slot * 0.58
                        height: h
                        radius: width / 2
                        color: stand.view.ramp[Math.min(7, Math.floor(index / stand.n * 8))]
                    }
                }
                // the edge field's two rails: the triad from the bottom up
                Repeater {
                    model: stand.view.aura ? [0, 1] : []
                    Rectangle {
                        required property int modelData
                        x: modelData === 0 ? 0 : sheet.width - width
                        width: 14
                        height: sheet.height
                        gradient: Gradient {
                            GradientStop { position: 0; color: stand.view.auraTriad[2] }
                            GradientStop { position: 0.5; color: stand.view.auraTriad[1] }
                            GradientStop { position: 1; color: stand.view.auraTriad[0] }
                        }
                    }
                }
            }

            VisualizerView {
                id: pinned
                width: sheet.width
                height: sheet.height
                index: 1
                instanceId: "scene-pinned"
                cfg: Viz.VizItem { data: ({ id: "scene-pinned", style: "bars", color: "#ff8800",
                                            x: 0.06, y: 0.08, w: 0.4, h: 0.3 }) }
            }
            StandIn { view: pinned }

            VisualizerView {
                id: aura
                width: sheet.width
                height: sheet.height
                index: 2
                instanceId: "scene-aura"
                cfg: Viz.VizItem { data: ({ id: "scene-aura", style: "aura", auraDepth: 90 }) }
            }
            StandIn { view: aura }

            // the primary, aimed in the Stage Editor
            VisualizerView {
                id: primary
                width: sheet.width
                height: sheet.height
                index: 0
                instanceId: Viz.Config.idAt(0)
                cfg: Viz.VizItem { data: Viz.Config.dataById(Viz.Config.idAt(0)) }
            }
            StandIn { view: primary }
            VisualizerGrip {
                instanceId: Viz.Config.idAt(0)
                composing: true
            }
            // lifted off the bottom edge in memory (a placement preview, never
            // written), so the size grip shows whole
            Component.onCompleted: Viz.Config.setPreview(Viz.Config.idAt(0), 0, 0.5)
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 1500)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
            // the Crate theme's switches (hub-fixture/crate.json), so the crate
            // look shows its mark, its hairline and its mono face
            if (look === "1") {
                Tokens.accentMarks = true;
                Tokens.selectFill = false;
                Tokens.labelAccent = true;
                Tokens.compact = true;
                Tokens.lineAlpha = 0.1;
                Tokens.mono = "JetBrainsMono Nerd Font";
            }
        }
    }
}
