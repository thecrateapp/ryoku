import QtQuick
import Quickshell
import QtQuick.Effects
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var descriptor: ({ path: "", name: "", kind: "default", bytes: 0, enabled: true })
    property bool active: true
    property bool forceDefault: false
    // a theme's own cover mark (Tokens.coverMark under controls "crate"): drawn
    // emblem-sized as shipped, in its own colours, in place of Ryoku's wordmark,
    // failure included; "" keeps the wordmark. markEffects gives it the Crate
    // site's treatment (a breathing glow in markGlow, a sheen sweep, a soft
    // aura); without markMotion the glow holds still and the sheen goes.
    property string themeMark: ""
    property bool markEffects: false
    property bool markMotion: true
    property color markGlow: "#67e8f9"
    readonly property bool wantsThemeMark: themeMark !== ""
    // the theme's mark replaces the wordmark only once its image has loaded: a
    // deleted file or one that is not an image keeps Ryoku's wordmark
    readonly property bool themed: wantsThemeMark && themeMarkLoader.status === Loader.Ready
        && themeMarkLoader.item !== null && themeMarkLoader.item.ready
    // a path as a file URL, each segment encoded so a '#', '?' or '%' stays in the name
    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }
    readonly property int themeMarkHeight: 96
    onMediaPathChanged: {
        orientationKnown = false
        imageTall = false
    }

    readonly property string mediaPath: descriptor && typeof descriptor.path === "string" ? descriptor.path : ""
    readonly property string mediaKind: descriptor && typeof descriptor.kind === "string" ? descriptor.kind : "default"
    readonly property bool customEnabled: !descriptor || descriptor.enabled !== false
    readonly property bool wantsVideo: customEnabled && mediaPath !== "" && mediaKind === "video"
    readonly property bool wantsImage: customEnabled && mediaPath !== "" && (mediaKind === "image" || mediaKind === "animated")
    // brand.json stores an absolute path today, but a hand-edited or ported
    // config may carry a ~ (the shell expands it for the brand mark too); a bare
    // "file://~/..." resolves to nothing and silently falls back to the default
    // cover, so expand it here before building the URL.
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string resolvedPath: mediaPath === "~"
        ? root.homeDir
        : (mediaPath.indexOf("~/") === 0 ? root.homeDir + mediaPath.substring(1) : mediaPath)
    readonly property string imageSource: resolvedPath.indexOf("://") >= 0 ? resolvedPath : "file://" + resolvedPath
    readonly property size orientationProbeSize: Qt.size(64, 64)
    property bool orientationKnown: false
    property bool imageTall: false
    readonly property bool probeReady: imageProbeLoader.status === Loader.Ready
        && imageProbeLoader.item
        && imageProbeLoader.item.status === Image.Ready
    readonly property bool probeFailed: imageProbeLoader.status === Loader.Ready
        && imageProbeLoader.item
        && imageProbeLoader.item.status === Image.Error
    readonly property bool probeReleased: wantsImage && orientationKnown
        && imageProbeLoader.status === Loader.Null
    readonly property bool imageReady: wantsImage
        && customImageLoader.status === Loader.Ready
        && customImageLoader.item
        && customImageLoader.item.status === Image.Ready
    readonly property bool videoReady: videoLoader.status === Loader.Ready && videoLoader.item && videoLoader.item.ready
    readonly property bool customReady: customEnabled && !forceDefault && (imageReady || videoReady)
    readonly property bool mediaError: wantsImage
        ? probeFailed
            || (orientationKnown && (customImageLoader.status === Loader.Error
                || (customImageLoader.status === Loader.Ready
                    && customImageLoader.item
                    && customImageLoader.item.status === Image.Error)))
        : (wantsVideo && (videoLoader.status === Loader.Error
            || (videoLoader.status === Loader.Ready && videoLoader.item && videoLoader.item.failed)))
    readonly property string mediaErrorText: wantsVideo && videoLoader.status === Loader.Ready && videoLoader.item
        ? videoLoader.item.errorText
        : ""
    readonly property bool showingDefault: forceDefault || !customReady
    readonly property real defaultLogoWidth: Math.min(width * 0.58, 928)
    readonly property real defaultLogoHeight: themed ? themeMarkHeight : defaultLogoWidth * 160 / 928

    // The bundled wordmark with its loading light sweep: the cue that the
    // cover is working, not frozen. Lost in the ReloadMedia refactor merge;
    // restored here where the default mark now lives.
    Item {
        id: defaultLogo
        anchors.centerIn: parent
        width: root.defaultLogoWidth
        height: root.defaultLogoHeight
        visible: root.showingDefault && !root.themed

        Image {
            id: logo
            objectName: "wordmark"
            anchors.fill: parent
            source: "assets/logo.png"
            sourceSize.width: Math.round(root.defaultLogoWidth)
            fillMode: Image.PreserveAspectFit
        }

        Item {
            id: loadingSweep
            x: defaultLogo.width
            width: Math.max(36, defaultLogo.width * 0.24)
            height: defaultLogo.height
            clip: true

            ColorOverlay {
                x: -loadingSweep.x
                width: defaultLogo.width
                height: defaultLogo.height
                source: logo
                color: "#e2f0ff"
                opacity: 0.28
            }

            NumberAnimation on x {
                from: defaultLogo.width
                to: -loadingSweep.width
                duration: 1200
                running: defaultLogo.visible && root.active
                loops: Animation.Infinite
            }
        }
    }

    Loader {
        id: themeMarkLoader
        anchors.centerIn: parent
        active: root.wantsThemeMark
        visible: root.showingDefault && root.themed
        sourceComponent: Item {
            id: markBox
            objectName: "markBox"
            readonly property bool pulsing: pulseAnim.running
            readonly property bool ready: themeMarkImage.status === Image.Ready
            implicitWidth: themeMarkImage.implicitWidth
            implicitHeight: themeMarkImage.implicitHeight

            // 0..1, breathing over 3.2 s like the site's solid-pulse; held at
            // the midpoint without motion
            property real pulse: 0.5
            SequentialAnimation on pulse {
                id: pulseAnim
                running: root.markEffects && root.markMotion && root.active && markBox.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: 1; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1; to: 0; duration: 1600; easing.type: Easing.InOutSine }
            }

            // the site's solid-aura: a faint accent disc behind the mark
            Loader {
                active: root.markEffects
                anchors.centerIn: parent
                width: parent.width * 1.24
                height: parent.height * 1.24
                sourceComponent: RadialGradient {
                    objectName: "markAura"
                    // a disc that fades out at 65 % of the half-width, so the
                    // square it is drawn in never shows
                    horizontalRadius: width * 0.5 * 0.65
                    verticalRadius: horizontalRadius
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(root.markGlow, 0.08) }
                        GradientStop { position: 1; color: Qt.alpha(root.markGlow, 0) }
                    }
                }
            }

            Image {
                id: themeMarkImage
                objectName: "themeMark"
                visible: !root.markEffects
                source: root.fileUrl(root.themeMark)
                sourceSize.height: root.themeMarkHeight
                fillMode: Image.PreserveAspectFit
            }

            // the site's solid-pulse: a 4 to 8 px accent glow and a touch of
            // brightness, breathing with pulse
            Loader {
                active: root.markEffects
                anchors.fill: themeMarkImage
                sourceComponent: MultiEffect {
                    objectName: "markGlow"
                    source: themeMarkImage
                    shadowEnabled: true
                    shadowColor: Qt.alpha(root.markGlow, 0.25 + 0.15 * markBox.pulse)
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    blurMax: 16
                    shadowBlur: 0.25 + 0.25 * markBox.pulse
                    brightness: 0.08 * markBox.pulse
                }
            }

            // the site's solid-sheen: a pale diagonal light crossing the mark,
            // masked to its shape, every 3.6 s
            Loader {
                active: root.markEffects && root.markMotion
                anchors.fill: themeMarkImage
                sourceComponent: Item {
                    objectName: "markSheen"
                    Item {
                        id: sheenBand
                        anchors.fill: parent
                        visible: false
                        Rectangle {
                            id: sheenStripe
                            width: parent.width * 0.6
                            height: parent.height * 2
                            y: -parent.height / 2
                            rotation: 25
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 0.42; color: Qt.rgba(0.925, 0.996, 1, 0.5) }
                                GradientStop { position: 0.58; color: Qt.alpha(root.markGlow, 0.25) }
                                GradientStop { position: 1; color: "transparent" }
                            }
                            SequentialAnimation on x {
                                running: root.active && sheenBand.parent.visible
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: sheenBand.width * 1.2
                                    to: -sheenStripe.width * 1.2
                                    duration: 2160
                                    easing.type: Easing.InOutQuad
                                }
                                PauseAnimation { duration: 1440 }
                            }
                        }
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: sheenBand
                        maskSource: themeMarkImage
                    }
                }
            }
        }
    }

    Component {
        id: orientationProbe
        Image {
            objectName: "imageProbe"
            source: root.imageSource
            fillMode: Image.PreserveAspectFit
            sourceSize: root.orientationProbeSize
            asynchronous: true
            cache: false
            onStatusChanged: {
                if (status === Image.Ready) {
                    root.imageTall = implicitHeight > implicitWidth
                    root.orientationKnown = true
                }
            }
        }
    }

    Loader {
        id: imageProbeLoader
        objectName: "imageProbeLoader"
        active: root.wantsImage && !root.orientationKnown && !root.forceDefault
        sourceComponent: orientationProbe
    }

    Component {
        id: wideImage
        AnimatedImage {
            objectName: "customImage"
            anchors.fill: parent
            source: root.imageSource
            sourceSize.width: Math.max(1, Math.ceil(width))
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            playing: root.active && root.imageReady && !root.forceDefault && status === Image.Ready
        }
    }

    Component {
        id: tallImage
        AnimatedImage {
            objectName: "customImage"
            anchors.fill: parent
            source: root.imageSource
            sourceSize.height: Math.max(1, Math.ceil(height))
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            playing: root.active && root.imageReady && !root.forceDefault && status === Image.Ready
        }
    }

    Loader {
        id: customImageLoader
        anchors.fill: parent
        active: root.wantsImage && root.orientationKnown && !root.forceDefault
        visible: root.imageReady && !root.forceDefault
        sourceComponent: root.imageTall ? tallImage : wideImage
    }

    Loader {
        id: videoLoader
        anchors.fill: parent
        active: root.active && root.wantsVideo && !root.forceDefault
        source: active ? Qt.resolvedUrl("ReloadVideo.qml") : ""
        onLoaded: {
            if (status === Loader.Ready && item) {
                item.path = Qt.binding(() => root.resolvedPath)
                item.active = Qt.binding(() => root.active && !root.forceDefault)
            }
        }
    }
}
