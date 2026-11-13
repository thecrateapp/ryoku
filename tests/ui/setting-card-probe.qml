import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

// SettingCard in both looks: the stock bordered sheet with its numbered caption,
// and the crate flat group (no sheet, a hairline above, the caption without its
// running number, the Solar caret), folding the same way in either.
ShellRoot {
    FloatingWindow {
        implicitWidth: 520
        implicitHeight: 400
        SettingCard {
            id: card
            width: 480
            title: "02 MOTION"
            kana: "動き"
            SettingRow { width: parent.width; label: "Gap animation" }
        }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }
    function sheet() {
        for (const child of card.children)
            if (child.border && child.border.width > 0 && child.anchors.fill === card) return child;
        return null;
    }

    Timer {
        id: crateCheck
        interval: 100
        onTriggered: {
            const title = find(card, "sectionTitle");
            if (title.text !== "MOTION") throw new Error("crate drops the running number, got " + title.text);
            if (!find(card, "sectionRule").visible) throw new Error("crate parts the group with a hairline above");
            if (sheet().visible) throw new Error("crate draws no sheet around the group");
            card.expanded = false;
            fold.start();
        }
    }
    Timer {
        id: fold
        interval: 400
        onTriggered: {
            if (card.height !== card.headerH) throw new Error("a folded group keeps only its header, got " + card.height);
            card.expanded = true;
            Tokens.controlsCrate = false;
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 400
        onTriggered: {
            if (find(card, "sectionTitle").text !== "02 MOTION") throw new Error("stock keeps the numbered caption");
            if (find(card, "sectionRule").visible) throw new Error("stock has no rule above");
            if (!sheet().visible) throw new Error("stock keeps the bordered sheet");
            console.log("SETTING-CARD-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
