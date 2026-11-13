import QtQuick
import Quickshell
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "pages" as Pages

ShellRoot {
    id: probe
    Binding { target: Tokens; property: "outlineSelections"; value: Tokens.controlsCrate }
    property int actionsTaken: 0
    property real stockHeight: 0

    FloatingWindow {
        implicitWidth: 660
        implicitHeight: 620

        Pages.RashinPage { id: rashin; anchors.fill: parent }
        Pages.ProfilePage { id: profile; anchors.fill: parent }
        Pages.CreditsPage { id: credits; anchors.fill: parent }
        Column {
            anchors.fill: parent
            Pages.ControlsPage { id: controls; width: parent.width; height: 380 }
            Kit.PageHeader {
                id: variants
                width: parent.width
                hubStyle: true
                title: "Displays"
                blurb: "Arrange your displays."
                eyebrow: "DEVICES"
                endMarks: true
                gloss: "画面"
                actions: Kit.Btn { text: "MIRROR"; onAct: probe.actionsTaken++ }
            }
        }
    }

    function matching(item, key, value) {
        if (!item || !item.visible) return null;
        if (item[key] === value) return item;
        for (const child of item.children) {
            const result = matching(child, key, value);
            if (result) return result;
        }
        return null;
    }
    function text(item, value) { return matching(item, "text", value); }
    function check(ok, message) {
        if (!ok) throw new Error("HUB-HEADER-FAIL " + message);
    }

    Timer {
        running: true
        interval: 120
        onTriggered: {
            Tokens.controlsCrate = false;
            UiPreferences.showJapaneseGloss = true;
            stock.start();
        }
    }
    Timer {
        id: stock
        interval: 50
        onTriggered: {
            const h = matching(controls, "objectName", "pageHeader");
            check(h && text(h, I18n.tr("Controls")), "real Controls page title");
            check(text(h, I18n.tr("CONTROL / LAYOUT")) && text(h, I18n.tr("DESKTOP")), "stock register and eyebrow");
            check(text(variants, "///") && text(variants, "+") && text(variants, "力") && text(variants, "画面"), "stock marks and gloss");
            check(text(rashin, "01"), "stock Rashin function index");
            check(text(credits, UiPreferences.text("RYOKU  ·  感謝 KANSHA  ·  SHOT ON BLACK", "")), "stock Credits colophon");
            probe.stockHeight = h.height;
            Tokens.controlsCrate = true;
            crate.start();
        }
    }
    Timer {
        id: crate
        interval: 50
        onTriggered: {
            const h = matching(controls, "objectName", "pageHeader");
            const title = text(h, I18n.tr("Controls"));
            const reg = text(h, I18n.tr("CONTROL / LAYOUT"));
            check(title && reg && title.mapToItem(h, title.width, 0).x <= reg.mapToItem(h, 0, 0).x, "register and title fit");
            check(!text(h, I18n.tr("DESKTOP")) && h.height < probe.stockHeight, "crate releases the eyebrow height");
            check(!text(variants, "///") && !text(variants, "+") && !text(variants, "力") && text(variants, "画面"), "crate chrome and optional gloss");
            const card = matching(rashin, "objectName", "rashinFunctionCard");
            check(card && card.radius === Tokens.radius && !text(card, "01"), "Crate Rashin card radius and index");
            check(!text(credits, UiPreferences.text("RYOKU  ·  感謝 KANSHA  ·  SHOT ON BLACK", "")), "Crate Credits margin");
            check(matching(profile, "objectName", "profileTelemetryLabel"), "Crate Profile telemetry label");
            const button = text(variants, "MIRROR");
            check(button && button.width > 0 && button.height > 0, "visible trailing action");
            check(button.mapToItem(variants, button.width, 0).x <= variants.width, "trailing action fits on the page");
            button.act();
            check(probe.actionsTaken === 1, "trailing action callback");
            UiPreferences.showJapaneseGloss = false;
            glossOff.start();
        }
    }
    Timer {
        id: glossOff
        interval: 50
        onTriggered: {
            check(!text(variants, "画面") && text(variants, "Displays"), "gloss off keeps translated title");
            Tokens.controlsCrate = false;
            restored.start();
        }
    }
    Timer {
        id: restored
        interval: 50
        onTriggered: {
            check(text(variants, "///") && text(variants, "R") && !text(variants, "力"), "stock returns with Japanese disabled");
            check(text(variants, "MIRROR") && text(variants, "Arrange your displays."), "restored action and blurb");
            console.log("HUB-HEADER-PROBE-PASS");
            Qt.quit();
        }
    }
}
