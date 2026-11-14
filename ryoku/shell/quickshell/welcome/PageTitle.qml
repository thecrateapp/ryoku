import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// A step's title over its description. Under crate it is the kit's PageHeader,
// the head every Crate page shares; stock keeps the Welcome's own pair.
Item {
    id: root

    property string title: ""
    property string description: ""

    implicitHeight: Tokens.controlsCrate ? kitHead.implicitHeight : stock.implicitHeight

    PageHeader {
        id: kitHead
        objectName: "welcomePageHeader"
        visible: Tokens.controlsCrate
        width: root.width
        title: root.title
        blurb: root.description
    }

    Column {
        id: stock
        visible: !Tokens.controlsCrate
        width: root.width
        spacing: Tokens.s2

        Text {
            width: root.width
            text: root.title
            color: Tokens.ink
            font.family: Tokens.display
            font.pixelSize: Tokens.fTitle
            font.weight: Tokens.displayWeightSet ? Tokens.displayWeight : Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            width: root.width
            text: root.description
            color: Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: Tokens.fBody
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }
    }
}
