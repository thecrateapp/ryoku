pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar power profile panel under the crate look: the profiles the daemon
// offers as one row of equal chips (three natural-width chips overflow the
// 320 px panel), then the thermal reading when a sensor exists. It reads and
// drives only the panel: profiles [{key, label}], current, thermalAvailable,
// thermalC and choose(key).
Column {
    id: details
    required property var panel
    signal closeRequested()
    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Power Profile")
        closeObjectName: "closePowerProfile"
        onCloseRequested: details.closeRequested()
    }

    Row {
        id: choices
        objectName: "powerProfileChoices"
        readonly property var profiles: details.panel.profiles || []
        readonly property var shortLabels: ({ "power-saver": "Saver" })
        width: parent.width
        spacing: Tokens.s2
        activeFocusOnTab: true
        Accessible.role: Accessible.Grouping
        Accessible.name: I18n.tr("Power Profile")

        function step(delta) {
            let at = -1;
            for (let i = 0; i < profiles.length; i++)
                if (profiles[i].key === details.panel.current) at = i;
            const next = Math.max(0, Math.min(profiles.length - 1, at + delta));
            if (next !== at && profiles[next]) details.panel.choose(profiles[next].key);
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                choices.step(1); event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                choices.step(-1); event.accepted = true;
            }
        }

        Repeater {
            model: choices.profiles
            Kit.Chip {
                required property var modelData
                objectName: "profile-" + modelData.key
                width: (choices.width - choices.spacing * Math.max(0, choices.profiles.length - 1))
                    / Math.max(1, choices.profiles.length)
                // the short name (Spanish "Ahorro de energía" overflows a third of the panel)
                text: I18n.tr(choices.shortLabels[modelData.key] || modelData.label)
                on: details.panel.current === modelData.key
                Accessible.role: Accessible.RadioButton
                Accessible.name: text
                Accessible.checked: on
                Accessible.onPressAction: details.panel.choose(modelData.key)
                onClicked: details.panel.choose(modelData.key)
            }
        }
    }

    Kit.Divider {
        width: parent.width
        quiet: true
        visible: details.panel.thermalAvailable
    }
    Kit.InfoRow {
        objectName: "powerThermal"
        width: parent.width
        visible: details.panel.thermalAvailable
        label: I18n.tr("Thermal")
        valueText: details.panel.thermalC + " °C"
    }
}
