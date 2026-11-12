import QtQuick
import "Singletons"

// A hairline rule; `quiet` for the softer one between rows.
Rectangle {
    property bool quiet: false
    implicitWidth: parent ? parent.width : 0
    implicitHeight: 1
    color: quiet ? Tokens.lineSoft : Tokens.line
}
