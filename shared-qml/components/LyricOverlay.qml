import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import md3.Core
import "."

// QML chrome for the lyric page, composited on top of the host-drawn fluid
// backdrop + per-syllable lyrics.
//
// This version keeps the author's latest lyric-page architecture and adds:
// - Larger portrait cover
// - Refined landscape layout
// - Higher / cleaner landscape cover position
// - Better title / progress / artist hierarchy
// - Fixed-width time labels so artist text never shifts when time changes
// - Author's latest lyric offset panel
// - Author's latest MultiEffect cover shadows
// - Author's configurable lyric progress style
Item {
    id: overlay

    // Landscape (wide) layout: cover + transport on the left, lyrics on the right
    property bool landscape: overlay.width > overlay.height

    // Automatic no-lyrics/instrumental detection + manual cover mode
    property bool coverOnly: player.lyricsCoverOnly || player.coverModeManual

    property bool offsetPanelOpen: false

    // Top row inset for the three title buttons.
    property real topPad: settings.topInset + 6

    onOffsetPanelOpenChanged: {
        player.setLyricOffsetPanelOpen(offsetPanelOpen)

        // Synchronize once on entry.
        // Do not feed every player property change back into Slider.value while
        // its MouseArea is dragging.
        if (offsetPanelOpen)
            offsetSlider.value = player.lyricOffsetMs
    }

    // Mirror the lyric page state so the offset panel also closes when the page
    // is dismissed through Esc / Android back.
    property bool lyricsOpenMirror: player.lyricsOpen

    onLyricsOpenMirrorChanged:
        if (!lyricsOpenMirror)
            overlay.offsetPanelOpen = false


    function fmt(ms) {
        if (ms <= 0)
            return "0:00"

        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        var r = s % 60

        return m + ":" + (r < 10 ? "0" + r : r)
    }


    // Swallow taps on the empty lyrics area so they don't leak through.
    MouseArea {
        anchors.fill: parent
    }


    // ========================================================================
    // PORTRAIT COVER
    // ========================================================================

    CoverImage {
        id: pCover

        // Larger than the author's default version.
        visible: !overlay.landscape &&
                 (overlay.coverOnly || opacity > 0.01)

        // Refined larger portrait cover.
        // Maximum increased from the author's 420 to 480.
        property real coverSize:
            Math.max(
                180,
                Math.min(
                    overlay.width - 64,
                    overlay.height - 280,
                    480
                )
            )

        width: coverSize
        height: coverSize

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        radius: Math.min(width, height) * 0.06

        iconSize: 72
        fadeIn: true

        layer.enabled: visible

        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#CC000000"
            shadowBlur: 0.65
            shadowVerticalOffset: 8
            shadowOpacity: 0.46
            blurMax: 48
        }

        // Only use the resolved local cover path.
        source: player.coverPath

        // Zoom + fade with lyric transition.
        property bool shown:
            overlay.coverOnly && player.lyricSlide > 0.25

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
            }
        }

        // Tap cover to return to lyrics.
        MouseArea {
            anchors.fill: parent

            onClicked:
                player.setCoverMode(false)
        }
    }


    // ========================================================================
    // TOP BUTTONS
    // ========================================================================

    IconButton {
        id: backBtn

        anchors.top: parent.top
        anchors.topMargin: overlay.topPad

        anchors.left: parent.left
        anchors.leftMargin: 6

        type: "standard"
        icon: "expand_more"
        contentColor: "#FFFFFFFF"

        onClicked:
            player.setLyricsOpen(false)
    }


    // Lyric offset button.
    IconButton {
        id: offsetBtn

        anchors.top: parent.top
        anchors.topMargin: overlay.topPad

        anchors.right: parent.right
        anchors.rightMargin: 6

        type: "standard"
        icon: "sync"
        contentColor: "#FFFFFFFF"

        onClicked:
            overlay.offsetPanelOpen = !overlay.offsetPanelOpen
    }


    // Lyrics <-> cover button.
    IconButton {
        id: coverModeBtn

        visible: !overlay.coverOnly

        anchors.top: parent.top
        anchors.topMargin: overlay.topPad

        anchors.right: offsetBtn.left
        anchors.rightMargin: 6

        type: "standard"
        icon: "image"
        contentColor: "#FFFFFFFF"

        onClicked:
            player.setCoverMode(true)
    }


    // Scrim for lyric offset panel.
    MouseArea {
        id: offsetScrim

        visible: overlay.offsetPanelOpen

        anchors.fill: parent

        z: 1

        onClicked:
            overlay.offsetPanelOpen = false
    }


    // ========================================================================
    // LYRIC OFFSET PANEL
    // ========================================================================

    Rectangle {
        id: offsetPanel

        // Keep painting during exit animation.
        visible:
            overlay.offsetPanelOpen || opacity > 0.01

        opacity:
            overlay.offsetPanelOpen ? 1 : 0

        scale:
            overlay.offsetPanelOpen ? 1 : 0.9

        transformOrigin: Item.TopRight

        Behavior on opacity {
            NumberAnimation {
                duration: overlay.offsetPanelOpen ? 160 : 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: overlay.offsetPanelOpen ? 220 : 150
                easing.type:
                    overlay.offsetPanelOpen
                    ? Easing.OutBack
                    : Easing.InCubic
            }
        }

        z: 2

        anchors.top: offsetBtn.bottom
        anchors.topMargin: 8

        anchors.right: parent.right
        anchors.rightMargin: 6

        width: Math.min(320, parent.width - 24)
        height: 176

        radius: 20

        color: Theme.color.surfaceContainerHigh

        border.width: 1
        border.color: Theme.color.outlineVariant


        MouseArea {
            anchors.fill: parent
        }


        Text {
            id: offsetTitle

            anchors.top: parent.top
            anchors.topMargin: 18

            anchors.left: parent.left
            anchors.leftMargin: 18

            text: "歌词偏移"

            color: Theme.color.onSurfaceColor

            font.family:
                Theme.typography.titleSmall.family

            font.pixelSize:
                Theme.typography.titleSmall.size
        }


        Text {
            anchors.top: parent.top
            anchors.topMargin: 16

            anchors.right: parent.right
            anchors.rightMargin: 18

            text:
                (offsetSlider.value > 0 ? "+" : "")
                + offsetSlider.value
                + " ms"

            color: Theme.color.primary

            font.family:
                Theme.typography.titleMedium.family

            font.pixelSize:
                Theme.typography.titleMedium.size

            font.weight:
                Theme.typography.titleMedium.weight
        }


        Text {
            id: offsetCaption

            anchors.top: offsetTitle.bottom
            anchors.topMargin: 4

            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: 18
            anchors.rightMargin: 18

            text: "仅对当前歌曲生效 · 负值提前，正值延后"

            color: Theme.color.onSurfaceVariantColor

            font.family:
                Theme.typography.bodySmall.family

            font.pixelSize:
                Theme.typography.bodySmall.size

            elide: Text.ElideRight
        }


        Slider {
            id: offsetSlider

            anchors.top: offsetCaption.bottom
            anchors.topMargin: 10

            anchors.left: parent.left
            anchors.right: parent.right

            anchors.leftMargin: 18
            anchors.rightMargin: 18

            from: -5000
            to: 5000

            stepSize: 50

            snapMode: true

            value: 0

            // Keep dragging local.
            onEditingFinished:
                player.setLyricOffset(value)
        }


        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1

            anchors.left: parent.left
            anchors.leftMargin: 18

            text: "提前 5 秒"

            color: Theme.color.onSurfaceVariantColor

            font.family:
                Theme.typography.labelSmall.family

            font.pixelSize:
                Theme.typography.labelSmall.size
        }


        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1

            anchors.horizontalCenter: parent.horizontalCenter

            text: "0"

            color: Theme.color.onSurfaceVariantColor

            font.family:
                Theme.typography.labelSmall.family

            font.pixelSize:
                Theme.typography.labelSmall.size
        }


        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1

            anchors.right: parent.right
            anchors.rightMargin: 18

            text: "延后 5 秒"

            color: Theme.color.onSurfaceVariantColor

            font.family:
                Theme.typography.labelSmall.family

            font.pixelSize:
                Theme.typography.labelSmall.size
        }


        Button {
            id: resetBtn

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            anchors.right: parent.right
            anchors.rightMargin: 10

            type: "text"

            text: "重置为 0"

            enabled:
                offsetSlider.value !== 0

            onClicked: {
                offsetSlider.value = 0
                player.resetLyricOffset()
            }
        }
    }


    // ========================================================================
    // PORTRAIT TITLE / ARTIST
    // ========================================================================

    Text {
        id: titleText

        visible: !overlay.landscape

        anchors.top: backBtn.bottom
        anchors.topMargin: 2

        anchors.left: parent.left
        anchors.right: parent.right

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        text: player.title

        color: "#FFFFFFFF"

        font.family:
            Theme.typography.titleLarge.family

        font.pixelSize: 22

        wrapMode: Text.WordWrap

        maximumLineCount: 2

        elide: Text.ElideRight
    }


    Text {
        id: artistText

        visible: !overlay.landscape

        anchors.top: titleText.bottom
        anchors.topMargin: 4

        anchors.left: parent.left
        anchors.right: parent.right

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        text: player.artist

        color: "#B3FFFFFF"

        fontSize: 14

        elide: Text.ElideRight
    }


    // ========================================================================
    // PORTRAIT TRANSPORT
    // ========================================================================

    Item {
        id: transport

        visible: !overlay.landscape

        anchors.left: parent.left
        anchors.right: parent.right

        anchors.bottom: parent.bottom
        anchors.bottomMargin: settings.bottomInset + 12

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        height: 120


        LinearProgress {
            id: progress

            anchors.left: parent.left
            anchors.right: parent.right

            anchors.top: parent.top
            anchors.topMargin: 18

            // Keep author's configurable progress style.
            wavy:
                settings.value("lyricProgressStyle") === 0

            visible:
                player.lyricSlide > 0.001

            indeterminate:
                player.loading

            value:
                player.lyricProgress
        }


        MouseArea {
            anchors.fill: progress

            anchors.topMargin: -10
            anchors.bottomMargin: -10

            onPressed:
                if (player.durationMs > 0)
                    player.seek(
                        Math.round(
                            mouseX / width * player.durationMs
                        )
                    )

            onPositionChanged:
                if (pressed && player.durationMs > 0)
                    player.seek(
                        Math.round(
                            Math.max(
                                0,
                                Math.min(width, mouseX)
                            )
                            / width
                            * player.durationMs
                        )
                    )
        }


        Text {
            anchors.left: parent.left
            anchors.top: progress.bottom
            anchors.topMargin: 6

            text:
                overlay.fmt(player.positionMs)

            color: "#B3FFFFFF"

            fontSize: 11
        }


        Text {
            anchors.right: parent.right
            anchors.top: progress.bottom
            anchors.topMargin: 6

            text:
                overlay.fmt(player.durationMs)

            color: "#B3FFFFFF"

            fontSize: 11
        }


        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14

            spacing: 18


            IconButton {
                type: "standard"

                icon:
                    player.playMode === 1
                    ? "shuffle"
                    : (
                        player.playMode === 2
                        ? "repeat_one"
                        : "repeat"
                    )

                contentColor:
                    player.playMode === 0
                    ? "#99FFFFFF"
                    : "#FF82B1FF"

                onClicked:
                    player.cyclePlayMode()
            }


            IconButton {
                type: "standard"
                icon: "skip_previous"

                contentColor: "#FFFFFFFF"

                onClicked:
                    player.prev()
            }


            IconButton {
                type: "filled"

                icon:
                    player.playing
                    ? "pause"
                    : "play_arrow"

                onClicked:
                    player.toggle()
            }


            IconButton {
                type: "standard"
                icon: "skip_next"

                contentColor: "#FFFFFFFF"

                onClicked:
                    player.next()
            }


            IconButton {
                type: "standard"

                enabled:
                    player.currentLikeable

                icon:
                    player.currentLiked
                    ? "favorite"
                    : "favorite_border"

                contentColor:
                    player.currentLiked
                    ? "#FFFF5277"
                    : "#99FFFFFF"

                onClicked:
                    player.toggleLike()
            }
        }
    }


    // ========================================================================
    // LANDSCAPE
    // ========================================================================

    Item {
        id: landscapeChrome

        visible:
            overlay.landscape

        anchors.fill: parent


        // --------------------------------------------------------------------
        // Landscape region
        // --------------------------------------------------------------------

        readonly property real regionW:
            overlay.coverOnly
            ? overlay.width
            : overlay.width / 2


        // Slightly larger cover than the author's current version,
        // while keeping enough vertical room for title, progress and controls.
        readonly property real targetCoverSize:
            Math.max(
                160,
                Math.min(
                    regionW - 40,
                    overlay.height - 150,
                    420
                )
            )


        property real coverSize:
            targetCoverSize


        property real centerX:
            regionW / 2


        // Smooth but restrained movement when switching lyric / cover mode.
        Behavior on coverSize {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }


        Behavior on centerX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }


        // --------------------------------------------------------------------
        // Landscape cover
        // --------------------------------------------------------------------

        CoverImage {
            id: lCover

            width:
                landscapeChrome.coverSize

            height:
                landscapeChrome.coverSize

            // Our previous refinement:
            // move the cover slightly upward.
            anchors.top:
                parent.top

            anchors.topMargin:
                settings.topInset + 18

            anchors.horizontalCenter:
                parent.left

            anchors.horizontalCenterOffset:
                landscapeChrome.centerX

            radius:
                Math.min(width, height) * 0.08

            iconSize: 72

            fadeIn: true

            source:
                player.coverPath

            layer.enabled:
                visible

            // Restore the author's latest high-quality shadow.
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#CC000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 8
                shadowOpacity: 0.46
                blurMax: 48
            }


            MouseArea {
                anchors.fill: parent

                // In lyric mode this is effectively a no-op;
                // in cover mode it returns to lyrics.
                onClicked:
                    player.setCoverMode(false)
            }
        }


        // --------------------------------------------------------------------
        // Landscape information + progress area
        // --------------------------------------------------------------------

        Item {
            id: progressBox

            // Our previous layout places the title below the cover with
            // a slightly larger separation.
            anchors.top:
                lCover.bottom

            anchors.topMargin:
                16

            anchors.left:
                lCover.left

            anchors.right:
                lCover.right

            anchors.bottom:
                controlRow.top

            anchors.bottomMargin:
                6


            // ---------------------------------------------------------------
            // Song title
            // ---------------------------------------------------------------

            Text {
                id: lTitle

                anchors.bottom:
                    lProgress.top

                anchors.bottomMargin:
                    6

                anchors.left:
                    parent.left

                anchors.right:
                    parent.right

                anchors.leftMargin:
                    8

                anchors.rightMargin:
                    8

                text:
                    player.title

                color:
                    "#FFFFFFFF"

                font.family:
                    Theme.typography.titleMedium.family

                font.pixelSize:
                    17

                horizontalAlignment:
                    Text.AlignHCenter

                wrapMode:
                    Text.NoWrap

                elide:
                    Text.ElideRight
            }


            // ---------------------------------------------------------------
            // Progress bar
            // ---------------------------------------------------------------

            LinearProgress {
                id: lProgress

                anchors.left:
                    parent.left

                anchors.right:
                    parent.right

                anchors.bottom:
                    posText.top

                anchors.bottomMargin:
                    4

                // Keep author's new setting.
                wavy:
                    settings.value("lyricProgressStyle") === 0

                visible:
                    player.lyricSlide > 0.001

                indeterminate:
                    player.loading

                value:
                    player.lyricProgress
            }


            MouseArea {
                anchors.fill:
                    lProgress

                anchors.topMargin:
                    -10

                anchors.bottomMargin:
                    -10

                onPressed:
                    if (player.durationMs > 0)
                        player.seek(
                            Math.round(
                                mouseX / width
                                * player.durationMs
                            )
                        )

                onPositionChanged:
                    if (pressed && player.durationMs > 0)
                        player.seek(
                            Math.round(
                                Math.max(
                                    0,
                                    Math.min(width, mouseX)
                                )
                                / width
                                * player.durationMs
                            )
                        )
            }


            // ---------------------------------------------------------------
            // IMPORTANT:
            //
            // The left and right time labels deliberately live inside fixed
            // width containers.
            //
            // This prevents:
            //
            // 1:09 -> 1:10
            // 9:59 -> 10:00
            //
            // from changing the horizontal geometry of the artist Text.
            //
            // This is the direct fix for the subtle left/right "shaking"
            // of the artist name that appeared in the previous version.
            // ---------------------------------------------------------------

            Item {
                id: leftTimeBox

                width: 44
                height: 18

                anchors.left:
                    parent.left

                anchors.bottom:
                    parent.bottom
            }


            Text {
                id: posText

                anchors.fill:
                    leftTimeBox

                text:
                    overlay.fmt(player.positionMs)

                color:
                    "#B3FFFFFF"

                fontSize:
                    11

                horizontalAlignment:
                    Text.AlignLeft

                verticalAlignment:
                    Text.AlignVCenter

                // Reserve a stable rendering width.
                // Text itself never participates in horizontal layout.
                width:
                    leftTimeBox.width
            }


            // ---------------------------------------------------------------
            // Center artist
            //
            // It is anchored between two fixed-width time regions.
            // Therefore player.positionMs / durationMs updates can never
            // change its horizontal position.
            // ---------------------------------------------------------------

            Item {
                id: artistBox

                anchors.left:
                    leftTimeBox.right

                anchors.right:
                    rightTimeBox.left

                anchors.verticalCenter:
                    leftTimeBox.verticalCenter

                height:
                    18

                anchors.leftMargin:
                    8

                anchors.rightMargin:
                    8


                Text {
                    id: lArtist

                    anchors.fill:
                        parent

                    text:
                        player.artist

                    color:
                        "#B3FFFFFF"

                    font.pixelSize:
                        11

                    font.family:
                        Theme.typography.bodySmall.family

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter

                    wrapMode:
                        Text.NoWrap

                    elide:
                        Text.ElideRight
                }
            }


            // ---------------------------------------------------------------
            // Fixed-width right time container
            // ---------------------------------------------------------------

            Item {
                id: rightTimeBox

                width: 44
                height: 18

                anchors.right:
                    parent.right

                anchors.bottom:
                    parent.bottom
            }


            Text {
                id: durText

                anchors.fill:
                    rightTimeBox

                text:
                    overlay.fmt(player.durationMs)

                color:
                    "#B3FFFFFF"

                fontSize:
                    11

                horizontalAlignment:
                    Text.AlignRight

                verticalAlignment:
                    Text.AlignVCenter

                width:
                    rightTimeBox.width
            }
        }


        // --------------------------------------------------------------------
        // Landscape transport controls
        // --------------------------------------------------------------------

        Row {
            id: controlRow

            anchors.horizontalCenter:
                lCover.horizontalCenter

            anchors.bottom:
                parent.bottom

            anchors.bottomMargin:
                settings.bottomInset + 8

            spacing:
                18


            IconButton {
                type: "standard"

                icon:
                    player.playMode === 1
                    ? "shuffle"
                    : (
                        player.playMode === 2
                        ? "repeat_one"
                        : "repeat"
                    )

                contentColor:
                    player.playMode === 0
                    ? "#99FFFFFF"
                    : "#FF82B1FF"

                onClicked:
                    player.cyclePlayMode()
            }


            IconButton {
                type: "standard"

                icon:
                    "skip_previous"

                contentColor:
                    "#FFFFFFFF"

                onClicked:
                    player.prev()
            }


            IconButton {
                type: "filled"

                icon:
                    player.playing
                    ? "pause"
                    : "play_arrow"

                onClicked:
                    player.toggle()
            }


            IconButton {
                type: "standard"

                icon:
                    "skip_next"

                contentColor:
                    "#FFFFFFFF"

                onClicked:
                    player.next()
            }


            IconButton {
                type: "standard"

                enabled:
                    player.currentLikeable

                icon:
                    player.currentLiked
                    ? "favorite"
                    : "favorite_border"

                contentColor:
                    player.currentLiked
                    ? "#FFFF5277"
                    : "#99FFFFFF"

                onClicked:
                    player.toggleLike()
            }
        }
    }
}
