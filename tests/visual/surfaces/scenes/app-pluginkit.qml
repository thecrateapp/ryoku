import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons as Kit

// A plugin's panel drawn from the plugin kit alone, as a third-party plugin would
// draw it: MicroLabel heads, a Card with its eyebrow, CornerTicks framing the
// sheet, the WaveMeter readout, and the shell kit's Beam, Chip, IconButton and
// TrackLabel through the kit's re-exports.
ShellRoot {
    FloatingWindow {
        implicitWidth: 520
        implicitHeight: 460
        color: "#1d2329"

        Rectangle {
            id: sheet
            width: 520
            height: 460
            color: Tokens.controlsCrate ? Tokens.popover : Kit.Theme.cardBot
            radius: Kit.Theme.radius
            border.width: 1
            border.color: Kit.Theme.border

            CornerTicks { anchors.fill: parent; anchors.margins: 6 }

            Column {
                x: 24; y: 22
                width: parent.width - 48
                spacing: 14

                Item {
                    width: parent.width
                    height: 32
                    MicroLabel { anchors.verticalCenter: parent.verticalCenter; label: "System" }
                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32
                        glyph: "close"
                        glyphFont: "Material Symbols Rounded"
                    }
                }
                Card {
                    width: parent.width
                    eyebrow: "Memory"
                    Text { text: "11.4 of 32 GiB"; color: Kit.Theme.bright; font.family: Kit.Theme.mono; font.pixelSize: 13 }
                    WaveMeter { width: parent.width; frac: 0.36 }
                }
                TrackLabel { text: "Volume"; tone: "accent" }
                Beam { width: parent.width; value: 0.62 }
                TrackLabel { text: "Profile" }
                Row {
                    spacing: 8
                    Chip { text: "Quiet" }
                    Chip { text: "Balanced"; on: true }
                    Chip { text: "Performance" }
                }
                Row {
                    spacing: 4
                    IconButton { glyph: "skip_previous"; glyphFont: "Material Symbols Rounded" }
                    IconButton { glyph: "pause"; glyphFont: "Material Symbols Rounded"; on: true }
                    IconButton { glyph: "skip_next"; glyphFont: "Material Symbols Rounded" }
                }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 2000)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
