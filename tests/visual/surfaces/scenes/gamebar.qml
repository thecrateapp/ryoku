import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/gamebar"
import "modules/gamebar/cards"

// The Game Bar as it floats over a game: the strip with two widgets on and every
// card in the catalogue on a backdrop, with a voice call of three people (one
// speaking, one muted) and the GPU tab of Resources. The host is a stand-in for
// GameBar.qml's PanelWindow, which a scene cannot map offscreen.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1520
        implicitHeight: 860
        color: Tokens.paper

        QtObject {
            id: host
            property bool live: true
            // suppressed: no card polls, so the scene spawns no samplers or helpers
            property bool suppressed: true
            readonly property var catalogue: [
                { id: "capture", label: "Capture", symbol: "screenshot_region" },
                { id: "performance", label: "Performance", symbol: "speed" },
                { id: "resources", label: "Resources", symbol: "monitoring" },
                { id: "tasks", label: "Tasks", symbol: "checklist" },
                { id: "media", label: "Media", symbol: "music_note" },
                { id: "voice", label: "Voice", symbol: "headset_mic", glyph: "discord", minimal: true },
                { id: "audio", label: "Audio", symbol: "volume_up" },
                { id: "gallery", label: "Gallery", symbol: "photo_library" }
            ]
            function entry(id) {
                for (let i = 0; i < host.catalogue.length; i++)
                    if (host.catalogue[i].id === id)
                        return host.catalogue[i];
                return {};
            }
            function symbolFor(id) { return host.entry(id).symbol || ""; }
            function glyphFor(id) { return host.entry(id).glyph || ""; }
            function beginDrag(id) {}
            function dragBy(id, dx, dy) {}
            function endDrag(id) {}
            function beginResize(id) {}
            function resizeBy(id, dx, dy) {}
            function endResize(id) {}
            function shoot(mode) {}
            function startRecording() {}
        }

        Rectangle {
            id: sheet
            width: 1520
            height: 860
            // a stand-in for the game under the overlay
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.darker(Tokens.sun, 3.2) }
                GradientStop { position: 1; color: Tokens.paper }
            }

            GameBarStrip {
                id: strip
                s: 1
                x: Math.round((sheet.width - width) / 2)
                y: 20
                cards: host.catalogue
                activeIds: ["performance", "voice"]
                snapping: true
            }

            Grid {
                x: 12
                y: 92
                columns: 4
                columnSpacing: 12
                rowSpacing: 8

                CaptureCard { s: 1; host: host; cardId: "capture"; width: 350; height: 240 }
                PerformanceCard { s: 1; host: host; cardId: "performance"; width: 340; height: 356 }
                ResourcesCard { s: 1; host: host; cardId: "resources"; width: 350; height: 200 }
                TasksCard { s: 1; host: host; cardId: "tasks"; width: 350; height: 270 }
                MediaCard { s: 1; host: host; cardId: "media"; width: 358; height: 235 }
                VoiceCard { s: 1; host: host; cardId: "voice"; width: 358; height: 336 }
                AudioCard { s: 1; host: host; cardId: "audio"; width: 350; height: 282 }
                GalleryCard { s: 1; host: host; cardId: "gallery"; width: 350; height: 290 }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 2500)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
            // the crate look as the Crate rice sets it (crate-for-ryoku
            // theme/crate/scheme.json), unless the config read already brought a
            // theme style: then the render keeps that palette and style
            if (look === "1" && !Tokens.styled) {
                Tokens.namedScheme = {
                    primary: "#06b6d4", secondary: "#67e8f9", tertiary: "#fbbf24", error: "#ef4444",
                    surface: "#0a0a0f", onSurface: "#f1f5f9", surfaceVariant: "#15161d",
                    onSurfaceVariant: "#999ca0", outline: "#4a4c52", inverseSurface: "#67e8f9",
                    inverseOnSurface: "#0a0a0f", surfaceContainerLow: "#0f1016", surfaceContainer: "#111218"
                };
                Tokens.lineAlpha = 0.1;
                Tokens.navCaps = true;
                Tokens.accentMarks = true;
                Tokens.focusAccent = true;
                Tokens.labelAccent = true;
                Tokens.selectFill = false;
                Tokens.compact = true;
                Tokens.mono = "JetBrainsMono Nerd Font";
                Tokens.navFont = "JetBrainsMono Nerd Font";
            }
            GameBarStore.resourceTab = 1;
            DiscordVoice.status = "authenticated";
            DiscordVoice.channel = { name: "Raid night" };
            DiscordVoice.updateParticipants([
                { id: "1", username: "kaede", speaking: true },
                { id: "2", username: "ryo", mute: true },
                { id: "3", username: "mio" }
            ]);
        }
    }
}
