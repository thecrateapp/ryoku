import QtQuick
import Quickshell
import Quickshell.Widgets
import stage
import stage.services
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.common.functions
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/**
 * The Wallpaper catalogue's screens, where they stand: each monitor drawn at
 * its place in the layout, showing its own picture, named the way a person
 * knows it (WallpaperLayout.displayName). The screen being edited wears the
 * selection ring; a click on another one moves the mode there, with the
 * catalogue open (GlobalStates.switchEditMonitor).
 *
 * Hovering another screen offers what is done between two screens: trading
 * pictures with this one, and giving it this one's framing. The screen the
 * colours come from carries the palette badge.
 */
Item {
    id: root

    // Under crate a screen is a tile at the shared corner; the edited one
    // takes the 1 px pickEdge, its name a mono tag on the popover ground, and
    // the swap and copy actions the kit's IconButtons on popover tags.
    readonly property bool crate: Tokens.controlsCrate

    // The screen the mode is on.
    property string screenName: ""

    readonly property var rects: WallpaperLayout.screenRects
    readonly property var box: WallpaperLayout.screensBox
    // The map is as wide as the panel and at most this tall; the layout is
    // scaled to fit both and centred.
    readonly property real maxHeight: Tokens.s7 * 3 + Tokens.s5
    readonly property real fit: root.box.width > 0 && root.box.height > 0
        ? Math.min(Math.max(0, root.width) / root.box.width, root.maxHeight / root.box.height) : 0
    readonly property real gap: Tokens.s2

    implicitHeight: Math.round(root.box.height * root.fit)

    Item {
        id: canvas
        width: root.box.width * root.fit
        height: root.box.height * root.fit
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: root.rects
            delegate: ScreenTile {}
        }
    }

    component ScreenTile: Item {
        id: tile
        required property var modelData
        readonly property string name: tile.modelData.name
        readonly property bool current: tile.name === root.screenName
        readonly property bool coloursHere: WallpaperLayout.distinctWallpapers && WallpaperLayout.colourScreen === tile.name
        readonly property string picture: WallpaperLayout.sourcePathFor(tile.name)
        readonly property bool hovered: tileHover.hovered
        // Small screens get small actions; the pills keep one height.
        readonly property int actionSize: tile.height >= 76 ? 32 : 26

        x: (tile.modelData.x - root.box.x) * root.fit + root.gap / 2
        y: (tile.modelData.y - root.box.y) * root.fit + root.gap / 2
        width: Math.max(1, tile.modelData.width * root.fit - root.gap)
        height: Math.max(1, tile.modelData.height * root.fit - root.gap)

        // The selection ring (settings-expressive §3): 2.5px of primary,
        // standing 2px off the screen.
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.crate ? -3 : -4.5
            radius: root.crate ? Tokens.radius : face.radius + 4.5
            color: "transparent"
            border.width: root.crate ? Tokens.border : 2.5
            border.color: root.crate ? Tokens.pickEdge : Appearance.colors.colPrimary
            opacity: tile.current ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        ClippingRectangle {
            id: face
            anchors.fill: parent
            radius: root.crate ? Tokens.radius : Appearance.rounding.small
            color: Appearance.colors.colLayer2

            Loader {
                anchors.fill: parent
                active: tile.picture !== "" && !Wallpapers.isVideoFile(tile.picture)
                sourceComponent: ThumbnailImage {
                    sourcePath: tile.picture
                    thumbnailService: Wallpapers
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                }
            }

            Ui.Glyph {
                anchors.centerIn: parent
                visible: root.crate && (tile.picture === "" || Wallpapers.isVideoFile(tile.picture))
                name: Wallpapers.isVideoFile(tile.picture) ? "movie" : "monitor"
                color: Tokens.inkSubtle
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.crate && (tile.picture === "" || Wallpapers.isVideoFile(tile.picture))
                text: Wallpapers.isVideoFile(tile.picture) ? "movie" : "monitor"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer2
            }

            // Hover scrim, as on the hero.
            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.m3scrim
                opacity: tile.hovered && !tile.current ? 0.35 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        HoverHandler {
            id: tileHover
            cursorShape: tile.current ? Qt.ArrowCursor : Qt.PointingHandCursor
        }
        TapHandler {
            enabled: !tile.current
            onTapped: GlobalStates.switchEditMonitor(tile.name)
        }

        StyledToolTip {
            requireOverlay: false
            extraVisibleCondition: !tile.current && tile.hovered && !swapButton.hovered && !copyButton.hovered
            text: Translation.tr("Edit %1").arg(WallpaperLayout.displayName(tile.name))
        }

        // The name, bottom-left; the colour source's badge before it.
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 6
            spacing: 4
            width: Math.max(0, Math.min(implicitWidth, tile.width - Tokens.s3))

            Rectangle {
                visible: tile.coloursHere
                width: nameTag.height
                height: nameTag.height
                radius: root.crate ? Tokens.radius : height / 2
                color: root.crate ? Tokens.popover : Appearance.colors.colPrimaryContainer
                border.width: root.crate ? Tokens.border : 0
                border.color: Tokens.line

                Ui.Glyph {
                    anchors.centerIn: parent
                    visible: root.crate
                    name: "palette"
                    size: 12
                    color: Tokens.mark
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: !root.crate
                    text: "palette"
                    fill: 1
                    iconSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                }

                // A Rectangle has no `hovered` of its own, and a StyledToolTip
                // on a parent without one shows unconditionally.
                HoverHandler {
                    id: badgeHover
                }
                StyledToolTip {
                    requireOverlay: false
                    extraVisibleCondition: badgeHover.hovered
                    text: Translation.tr("The colours come from this screen's picture")
                }
            }

            Rectangle {
                id: nameTag
                width: Math.max(0, Math.min(nameLabel.implicitWidth + Tokens.s4,
                    tile.width - Tokens.s3 - (tile.coloursHere ? nameTag.height + Tokens.s1 : 0)))
                height: 22
                objectName: "screenNameTag"
                radius: root.crate ? Tokens.radius : Appearance.rounding.full
                color: root.crate ? Tokens.popover
                    : tile.current ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                border.width: root.crate ? Tokens.border : 0
                border.color: tile.current ? Tokens.pickEdge : Tokens.line
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                StyledText {
                    id: nameLabel
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: WallpaperLayout.displayName(tile.name)
                    font.family: root.crate ? Tokens.mono : nameLabel.defaultFont + (nameLabel.shouldUseNumberFont ? "," + Appearance.font.family.main : "")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: root.crate ? Font.Normal : Font.Bold
                    color: root.crate ? (tile.current ? Tokens.mark : Tokens.inkSecondary)
                        : tile.current ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                }
            }
        }

        // Between this screen and the edited one, top-right; they fade in
        // with the hover (settings-expressive §2.1).
        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.s2
            spacing: Tokens.s1
            visible: !tile.current && tile.width >= tile.actionSize * 2 + Tokens.s4
                && tile.height >= tile.actionSize + Tokens.s3 && opacity > 0
            opacity: tile.hovered ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            TileAction {
                id: swapButton
                size: tile.actionSize
                symbol: "swap_horiz"
                enabled: WallpaperLayout.canSwap(root.screenName, tile.name)
                tooltip: Translation.tr("Swap pictures with this screen")
                onClicked: WallpaperLayout.swapWallpapers(root.screenName, tile.name)
            }
            TileAction {
                id: copyButton
                size: tile.actionSize
                symbol: "crop"
                enabled: WallpaperLayout.canCopyFraming(root.screenName, tile.name)
                tooltip: Translation.tr("Give it this screen's position and zoom")
                onClicked: WallpaperLayout.copyFraming(root.screenName, tile.name)
            }
        }
    }

    // The swap and copy actions: the stock round button, or under crate the
    // kit's IconButton on a popover tag.
    component TileAction: Item {
        id: holder
        property int size: 32
        property string symbol: ""
        property string tooltip: ""
        signal clicked()
        readonly property bool hovered: root.crate ? kitAction.hot : action.hovered
        implicitWidth: holder.size
        implicitHeight: holder.size

        Rectangle {
            anchors.fill: parent
            visible: root.crate
            radius: Tokens.radius
            color: Tokens.popover
            border.width: Tokens.border
            border.color: Tokens.line

            Ui.IconButton {
                id: kitAction
                anchors.fill: parent
                glyph: holder.symbol
                enabled: holder.enabled
                onClicked: holder.clicked()
            }
            StyledToolTip {
                requireOverlay: false
                extraVisibleCondition: false
                alternativeVisibleCondition: kitAction.hot
                text: holder.tooltip
            }
        }

        StockTileAction {
            id: action
            anchors.fill: parent
            visible: !root.crate
            size: holder.size
            symbol: holder.symbol
            tooltip: holder.tooltip
            enabled: holder.enabled
            onClicked: holder.clicked()
        }
    }

    component StockTileAction: RippleButton {
        id: action
        property int size: 32
        property string symbol: ""
        property string tooltip: ""
        implicitWidth: action.size
        implicitHeight: action.size
        buttonRadius: action.size / 2
        opacity: action.enabled ? 1 : 0.5
        colBackground: Appearance.colors.colSurfaceContainerHigh
        colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
        colRipple: Appearance.colors.colSurfaceContainerHighestActive

        contentItem: MaterialSymbol {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: action.symbol
            iconSize: Math.round(action.size * 0.55)
            color: Appearance.colors.colOnSurface
        }

        StyledToolTip {
            requireOverlay: false
            text: action.tooltip
        }
    }
}
