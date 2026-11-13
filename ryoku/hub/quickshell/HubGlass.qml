import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower as Power
import Ryoku.Ui.Singletons

// The Hub runs in its own process. Read the same preferences as the shell
// without starting its samplers or writing the settings it owns. The Hub window
// itself is opaque; this only keeps Tokens.glass opaque inside it when blur is
// off (power saver, game mode), as the shell does.
Item {
    id: glass

    readonly property bool allowBlur: !effects.lowPowerMode && !effects.disableBlur && !flags.gameMode
        && (!effects.powerProfileEffects || Power.PowerProfiles.profile !== Power.PowerProfile.PowerSaver)

    Binding { target: Tokens; property: "glassBlur"; value: glass.allowBlur; when: Tokens.controlsCrate }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Paths.home + "/.config") + "/ryoku/performance.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter {
            id: effects
            property bool lowPowerMode: false
            property bool disableBlur: false
            property bool powerProfileEffects: true
        }
    }
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Paths.home + "/.local/state") + "/ryoku/flags.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        JsonAdapter { id: flags; property bool gameMode: false }
    }
}
