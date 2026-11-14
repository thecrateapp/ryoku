import QtQuick

// A kit control at the Game Bar's own scale. The kit draws Tabs and Seg at the
// shell's size; the bar has a scale of its own (Hub -> Game Bar -> Scale, times
// the monitor's), so this holds one child scaled by `s` from its top-left corner
// and takes the scaled size as its own for the layout around it.
Item {
    id: root

    property real s: 1
    default property Item content

    implicitWidth: root.content ? root.content.implicitWidth * root.s : 0
    implicitHeight: root.content ? root.content.implicitHeight * root.s : 0

    onContentChanged: {
        if (!root.content)
            return;
        root.content.parent = root;
        root.content.transformOrigin = Item.TopLeft;
        root.content.scale = Qt.binding(() => root.s);
    }
}
