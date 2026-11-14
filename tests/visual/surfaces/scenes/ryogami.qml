import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.Ryogami

// The Ryogami picker's chrome over a stand-in wallpaper. BENCH_OPEN picks what
// is open over the masthead filter bar: "" for the bare chrome, "search",
// "help", "rice" (the rice workshop), "riceshare" (its export dialog),
// "themebar" (the theme strip), or
// "sheet:NAME[:TAB]" for a sheet ("sheet:settings:picker").
ShellRoot {
    FloatingWindow {
        implicitWidth: 1600
        implicitHeight: 1000
        color: "#20262e"

        Item {
            id: sheet
            width: 1600
            height: 1000

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "#3d4a5a" }
                    GradientStop { position: 0.6; color: "#1d2329" }
                    GradientStop { position: 1; color: "#121519" }
                }
            }

            PickerState {
                id: pickerState
                view: LibraryView { collection: pickerState.collection }
                shown: true
                filterBarToggled: true
            }

            readonly property var sampleRice: ({
                slug: "harbour", name: "Harbour", author: "Ryoku", blurb: "A quiet dark desktop.",
                compat: "hyprland", createdWith: "1.0.9", live: true, active: true, tags: ["dark", "minimal"]
            })

            FilterBar { anchors.fill: parent; state: pickerState }
            RiceWorkshop { anchors.fill: parent; state: pickerState }
            RiceShare { anchors.fill: parent; state: pickerState }
            ThemeBar { anchors.fill: parent; state: pickerState }
            SearchPanel { anchors.fill: parent; state: pickerState }
            HelpOverlay { anchors.fill: parent; state: pickerState }
            SheetHost { anchors.fill: parent; state: pickerState }
            ToastLayer { id: toasts; anchors.fill: parent; state: pickerState }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: {
                const open = Quickshell.env("BENCH_OPEN") || "";
                if (open === "search")
                    pickerState.searchOpen = true;
                else if (open === "help")
                    pickerState.helpOpen = true;
                else if (open === "rice") {
                    pickerState.riceEntry = sheet.sampleRice;
                    pickerState.riceWorkshopOpen = true;
                } else if (open === "themebar")
                    pickerState.themeBarOpen = true;
                else if (open === "riceshare")
                    pickerState.openRiceShare("export", sheet.sampleRice);
                else if (open.startsWith("sheet:")) {
                    const parts = open.split(":");
                    pickerState.openSheet(parts[1], parts[2] ? { tab: parts[2] } : ({}));
                }
                if (Quickshell.env("BENCH_TOAST"))
                    toasts.show(Quickshell.env("BENCH_TOAST"), "info");
            }
        }
        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 3000)
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
