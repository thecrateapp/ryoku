import QtQuick
import shell.services
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../modules/AudioOutput.js" as AudioOutput

// The volume panel's output devices under controls "crate": one PickRow per
// live sink, the default one picked. Each row's glyph is AudioOutput.sinkGlyph,
// the one the bar's audio widget draws for the default sink, so the bar shows
// the picked row's icon. VolumePanel hosts it; a probe or a scene loads it on
// its own (the panel's layer window does not load offscreen).
Column {
    id: rows

    // the sinks listed and the picked one: Audio's live outputs and default
    // sink, or a scene's stand-ins
    property var outputs: Audio.outputs.filter(Audio.alive)
    property var sink: Audio.sink

    spacing: 6

    Repeater {
        model: rows.outputs
        delegate: Kit.PickRow {
            required property var modelData
            objectName: "outputRow"
            width: rows.width
            title: Audio.nodeLabel(modelData)
            sub: Audio.isBluez(modelData) ? I18n.tr("Bluetooth") : ""
            glyph: AudioOutput.sinkGlyph(modelData, Kit.GlyphCatalog.has)
            glyphFont: "Material Symbols Rounded"
            picked: !!(rows.sink && modelData && rows.sink.name === modelData.name)
            onClicked: if (!picked) Audio.setOutput(modelData)
        }
    }
}
