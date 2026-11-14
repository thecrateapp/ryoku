import QtQuick
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.common.functions
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons
/*
 * A button on a desktop widget's card: a fill with an icon and/or a label.
 * Hover and press tint the fill with its own content colour (8 % / 16 %), the
 * M3E card action recipe. `restRadius` is the corner the caller morphs to show
 * state (pill idle, rounded square active). Disabled keeps the fill and dims
 * only the content, so a row of keys never looks washed out.
 */
RippleButton {
    id: root

    property string symbol: ""
    property string label: ""
    property color colFill: "gray"
    property color colContent: "white"
    property real symbolSize: 22
    property bool symbolFilled: true
    property real labelSize: Appearance.font.pixelSize.normal
    property var labelAxes: ({ "wght": 600, "wdth": 100, "ROND": 100 })
    property real restRadius: Math.min(width, height) / 2
    property real contentSpacing: 6
    // Under crate the symbol is the kit's Solar glyph (the font's where the
    // catalogue has none) and the label the kit's face.
    readonly property bool crate: Tokens.controlsCrate

    opacity: 1
    colBackground: root.colFill
    colBackgroundHover: ColorUtils.mix(root.colContent, root.colFill, 0.08)
    colBackgroundActive: ColorUtils.mix(root.colContent, root.colFill, 0.16)
    colRipple: ColorUtils.mix(root.colContent, root.colFill, 0.24)
    buttonRadius: root.restRadius

    contentItem: Item {
        opacity: root.enabled ? 1 : 0.38

        Row {
            anchors.centerIn: parent
            spacing: root.contentSpacing

            Ui.Glyph {
                objectName: "widgetButtonGlyph"
                anchors.verticalCenter: parent.verticalCenter
                visible: root.crate && root.symbol !== ""
                name: root.symbol
                size: root.symbolSize
                color: root.colContent
            }

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.crate && root.symbol !== ""
                text: root.symbol
                fill: root.symbolFilled ? 1 : 0
                iconSize: root.symbolSize
                color: root.colContent
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.label !== ""
                // Long translations shrink to the key instead of spilling out of it.
                width: Math.min(implicitWidth, root.width - (root.symbol !== "" ? root.symbolSize + root.contentSpacing : 0) - 20)
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 9
                text: root.label
                color: root.colContent
                font.family: root.crate ? Tokens.ui : Appearance.font.family.main
                font.pixelSize: root.labelSize
                font.variableAxes: root.labelAxes
            }
        }
    }
}
