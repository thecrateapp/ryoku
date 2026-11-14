import QtQuick
import QtQuick.Layouts
import Quickshell
import Ryoku.Ui.Singletons
import stage
import stage.services
import stage.modules.common
import stage.modules.ii.editMode

// The Stage editor over a stand-in wallpaper: the toolbar above the framed
// desktop, the catalogue panel's plate and header with a page of rows, chips
// and captions in it, and the widget and bar menus. The panel itself reads the
// dock's window list, which needs a compositor, so the scene draws its plate
// and header around the same rows the panel's pages use.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1400
        implicitHeight: 860
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 1400
            height: 860
            // a stand-in wallpaper, so the glass has something to sit on
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.darker(Tokens.sun, 2.4) }
                GradientStop { position: 0.55; color: Tokens.paper }
                GradientStop { position: 1; color: Qt.darker(Tokens.sunHi, 2.8) }
            }

            // the framed desktop
            Rectangle {
                x: 60
                y: 90
                width: 860
                height: 520
                color: "transparent"
                radius: Tokens.radius
                border.width: 1
                border.color: Tokens.lineStrong
            }

            EditModeChromeContent {
                width: 980
                height: 860
                card: Qt.rect(60, 90, 860, 520)
                area: Qt.rect(0, 0, 980, 860)
            }

            EditDrawerPlate {
                x: 960
                y: 20
                width: 420
                height: 820

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    EditDrawerHeader {
                        Layout.fillWidth: true
                        canGoBack: true
                        title: "Clocks"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        EditPanelSectionLabel { text: "Placed" }
                        EditPanelRow {
                            Layout.fillWidth: true
                            symbol: "schedule"
                            title: "Digital clock"
                            subtitle: "2 on the desktop"
                            selected: true
                            trailingKind: "check"
                        }
                        EditPanelRow {
                            Layout.fillWidth: true
                            symbol: "widgets"
                            title: "Weather"
                            subtitle: "Today and the week"
                            trailingKind: "add"
                        }
                        EditPanelRow {
                            Layout.fillWidth: true
                            symbol: "keep"
                            title: "Pin position"
                            trailingKind: "switch"
                            switchChecked: true
                        }
                        EditPanelRow {
                            Layout.fillWidth: true
                            symbol: "aspect_ratio"
                            title: "Size"
                            trailingKind: "stepper"
                            valueText: "100%"
                        }
                        EditPanelRow {
                            Layout.fillWidth: true
                            symbol: "tune"
                            title: "Widget options"
                            trailingKind: "chevron"
                        }
                    }

                    EditOptionChips {
                        label: "Corner"
                        options: [{ "value": "round", "displayName": "Round", "icon": "circle" },
                                  { "value": "square", "displayName": "Square", "icon": "square" },
                                  { "value": "cut", "displayName": "Cut", "icon": "change_history" }]
                        currentValue: "round"
                    }

                    EditPanelNotice {
                        text: "The theme sets the corner while a preset is on."
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            EditWidgetMenu {
                x: 80
                y: 640
            }

            EditBarMenu {
                x: 380
                y: 640
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 1800)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            // the mode's own scalar, settled, so the toolbar's cascade is in
            GlobalStates.editProgress = 1;
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
