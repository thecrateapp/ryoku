import QtQuick
import "Singletons"

// 5-8 exclusive named options. wraps; the selected chip inverts.
Flow {
    id: chips
    property var options: []
    property string current: ""
    // optional value -> display map; a value not present falls back to I18n.tr(value)
    property var labels: ({})
    signal chose(string key)

    activeFocusOnTab: true
    function activate(i) { if (i >= 0 && i < options.length) chose(options[i]) }
    Keys.onPressed: event => {
        var i = options.indexOf(current);
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
            activate(Math.min(options.length - 1, i + 1)); event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            activate(Math.max(0, i - 1)); event.accepted = true;
        }
    }

    spacing: Tokens.controlsCrate ? 8 : 5
    height: childrenRect.height

    Repeater {
        model: chips.options
        Chip {
            required property string modelData
            text: chips.labels[modelData] !== undefined ? chips.labels[modelData] : I18n.tr(modelData)
            on: chips.current === modelData
            onClicked: chips.chose(modelData)
        }
    }
}
