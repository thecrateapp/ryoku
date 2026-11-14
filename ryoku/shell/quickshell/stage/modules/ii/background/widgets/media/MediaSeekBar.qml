import QtQuick
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons
/*
 * The wavy seek line of the Poster and Deck widgets: a draggable StyledSlider
 * when the player can seek, a StyledProgressBar otherwise. Both read the shell's
 * position clock (MprisController.trackProgressOf) through `source`.
 *
 * Under crate the line is the kit's Beam: draggable when the player can seek,
 * a progress line otherwise, the one hairline-and-head recipe every slider
 * and progress bar in the shell draws.
 */
Item {
    id: root

    required property var source
    property color highlightColor: root.source.colAccent
    property color trackColor: root.source.colTrack

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool canSeek: root.source.player?.canSeek ?? false

    implicitHeight: root.crate ? kitBeam.implicitHeight
        : Math.max(sliderLoader.implicitHeight, progressLoader.implicitHeight)

    Ui.Beam {
        id: kitBeam
        objectName: "mediaSeekBeam"
        visible: root.crate
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }
        value: root.source.progress
        interactive: root.canSeek && root.source.hasLength
        onMoved: v => root.source.seek(v)
    }

    Loader {
        id: sliderLoader
        anchors.fill: parent
        active: !root.crate && root.canSeek
        sourceComponent: StyledSlider {
            configuration: StyledSlider.Configuration.Wavy
            animateWave: root.source.animate
            highlightColor: root.highlightColor
            trackColor: root.trackColor
            handleColor: root.highlightColor
            usePercentTooltip: false
            tooltipContent: root.source.positionText
            value: root.source.progress
            // Nothing to seek to while the player publishes no length.
            enabled: root.source.hasLength
            onMoved: root.source.seek(value)
            // QQuickSlider writes `value` itself while dragging, which drops the
            // binding; put it back on release so the line follows the track again.
            onPressedChanged: if (!pressed)
                value = Qt.binding(() => root.source.progress)
        }
    }

    Loader {
        id: progressLoader
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }
        active: !root.crate && !sliderLoader.active
        sourceComponent: StyledProgressBar {
            wavy: root.source.isPlaying
            animateWave: root.source.animate
            highlightColor: root.highlightColor
            trackColor: root.trackColor
            value: root.source.progress
        }
    }
}
