import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// The runtime title stays compatible with ryoku-summon and both compositor
// providers. Ryoport is the visible product identity inside the window.
ShellRoot {
    Component.onCompleted: Quickshell.watchFiles = !Quickshell.shellDir.startsWith(
        (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/")

    FloatingWindow {
        id: win
        title: "ryovm"
        minimumSize: Qt.size(1180, 760)
        // Opaque from the first frame, so the compositor never flashes its
        // uncleared buffer before the QML paints; the panel grey under crate.
        color: Tokens.controlsCrate ? Tokens.popover : Tokens.paper
        onClosed: Qt.quit()

        App { anchors.fill: parent }
    }
}
