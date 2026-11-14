pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// The cover's status line under its mark: what is loading, or that it failed.
// Ryoku's look is the tracked JetBrains Mono line it always was. Under controls
// "crate" it is the kit's tracked label with its Japanese gloss (再読込 reload,
// 起動中 boot, 失敗 failure, after showJapaneseGloss), an indeterminate Beam
// while the cover holds (real waiting), and the failure in the theme's error
// role.
Item {
    id: status

    required property string mode      // "reload" | "boot"
    required property string phase     // "closing" | "hold" | "opening" | "failed"
    property real logoHeight: 0
    property bool showingDefault: true
    property real mediaOpacity: 1

    readonly property bool failed: phase === "failed"
    readonly property string line: failed
        ? (mode === "boot" ? I18n.tr("DESKTOP FAILED TO LOAD") : I18n.tr("RELOAD FAILED"))
        : (mode === "boot" ? I18n.tr("LOADING DESKTOP") : I18n.tr("SHELL RELOADING"))

    Loader {
        anchors.fill: parent
        active: !Tokens.controlsCrate
        sourceComponent: Item {
            Text {
                objectName: "coverLabel"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: status.logoHeight / 2 + (status.failed ? 28 : 18)
                visible: status.failed || (status.showingDefault && status.mediaOpacity > 0)
                text: status.line
                color: status.failed ? "#ff735d" : "#d8e8f5"
                opacity: status.failed ? 1 : status.mediaOpacity * 0.72
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: status.failed ? 14 : 11
                font.letterSpacing: status.failed ? 3 : 4
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: Tokens.controlsCrate
        sourceComponent: Item {
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: status.logoHeight / 2 + 24
                spacing: 14
                visible: status.failed || (status.showingDefault && status.mediaOpacity > 0)
                opacity: status.failed ? 1 : status.mediaOpacity

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    TrackLabel {
                        objectName: "coverLabel"
                        anchors.verticalCenter: parent.verticalCenter
                        text: status.line
                        color: status.failed ? Tokens.role("error", Tokens.alert) : toneInk
                    }
                    Text {
                        objectName: "coverGloss"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: UiPreferences.showJapaneseGloss
                        text: status.failed ? "失敗" : status.mode === "boot" ? "起動中" : "再読込"
                        color: status.failed ? Tokens.role("error", Tokens.alert) : Tokens.inkFaint
                        font.family: Tokens.jp
                        font.pixelSize: Tokens.fMicro
                    }
                }
                Beam {
                    objectName: "coverBeam"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 160
                    height: 12
                    visible: status.phase === "hold"
                    interactive: false
                    indeterminate: true
                }
            }
        }
    }
}
