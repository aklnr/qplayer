import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import md3.Core
import "."

// QML chrome for the lyric page, composited on top of the host-drawn fluid
// backdrop + per-syllable lyrics. Transparent everywhere except the title band
// (top) and the transport band (bottom), so the host lyrics show through the
// middle. Visibility/opacity follow player.lyricSlide (published by the host) so
// it fades in lockstep with the host layer.
Item {
    id: overlay
    signal closeRequested()

    // Landscape (wide) layout: cover + transport on the left, lyrics on the right
    // half (host-drawn). Driven by aspect so a desktop window, tablet, or phone in
    // landscape all adopt it. coverOnly (no lyrics / instrumental) centers the cover.
    property bool landscape: overlay.width > overlay.height
    // OR of the automatic no-lyrics/instrumental detection and the user's manual
    // lyrics<->cover toggle (the button below / tapping the cover to return).
    property bool coverOnly: player.lyricsCoverOnly || player.coverModeManual
    property bool offsetPanelOpen: false
    // Top row inset for the three title buttons. Desktop overrides this to 6
    // (Main.qml hides the custom title bar while the lyric page is open, so the
    // buttons sit flush at the very top of the window); mobile keeps the status
    // bar inset so they clear the system bar.
    property real topPad: settings.topInset + 6
    onOffsetPanelOpenChanged: {
        player.setLyricOffsetPanelOpen(offsetPanelOpen)
        // Synchronize once on entry. Do not feed every player property change back
        // into Slider.value while its MouseArea is dragging: that re-entrant write
        // interrupts qml4j's active gesture as soon as the thumb moves one step.
        if (offsetPanelOpen) offsetSlider.value = player.lyricOffsetMs
    }
    // The page can also close via Esc / Android back, which bypasses this QML
    // entirely (PlayerController.pressBack), so mirror the other direction too. A
    // plain binding + local onChanged, not Connections { target: player }: player is
    // a PlayerController, not a QObject, and qml4j's Connections codegen requires a
    // QObject target (a non-QObject target crashes with a ClassCastException at
    // Property.fireListeners on load).
    property bool lyricsOpenMirror: player.lyricsOpen
    onLyricsOpenMirrorChanged: if (!lyricsOpenMirror) overlay.offsetPanelOpen = false


    function fmt(ms) {
        if (ms <= 0) return "0:00";
        var s = Math.floor(ms / 1000), m = Math.floor(s / 60), r = s % 60;
        return m + ":" + (r < 10 ? "0" + r : r);
    }

    function showToast(message) {
        lyricSnack.show(message)
    }

    // Swallow taps on the empty (lyrics) area so they don't leak through.
    MouseArea { anchors.fill: parent }

    // --- portrait: big centred cover for no-lyric / instrumental tracks. It zooms +
    // fades in/out on the lyrics↔cover switch (SPlayer's zoom transition) — no big/small
    // morph, title/artist stay put. Landscape has its own cover in the left chrome.
    PlaybackCoverImage {
        id: pCover
        visible: !overlay.landscape && (overlay.coverOnly || opacity > 0.01)
        property real coverSize: Math.max(160, Math.min(overlay.width - 96, overlay.height - 360, 420))
        width: coverSize
        height: coverSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: Math.min(width, height) * 0.06
        iconSize: 72
        fadeIn: true
        playing: player.playing
        layer.enabled: visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#CC000000"
            shadowBlur: 0.65
            shadowVerticalOffset: 8
            shadowOpacity: 0.46
            blurMax: 48
        }
        source: player.coverPath
        property bool shown: overlay.coverOnly && player.lyricSlide > 0.25
        opacity: shown ? 1 : 0
        baseScale: shown ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on baseScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        MouseArea {
            anchors.fill: parent
            onClicked: player.setCoverMode(false)
        }
    }

    // --- top: dismiss + title + artist ---------------------------------
    IconButton {
        id: backBtn
        anchors.top: parent.top
        anchors.topMargin: overlay.topPad
        anchors.left: parent.left
        anchors.leftMargin: 6
        type: "standard"
        icon: "expand_more"
        contentColor: "#FFFFFFFF"
        onClicked: overlay.closeRequested()
    }

    IconButton {
        id: offsetBtn
        anchors.top: parent.top
        anchors.topMargin: overlay.topPad
        anchors.right: parent.right
        anchors.rightMargin: 6
        type: "standard"
        icon: "sync"
        contentColor: "#FFFFFFFF"
        onClicked: overlay.offsetPanelOpen = !overlay.offsetPanelOpen
    }

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
        onClicked: player.setCoverMode(true)
    }

    MouseArea {
        id: offsetScrim
        visible: overlay.offsetPanelOpen
        anchors.fill: parent
        z: 1
        onClicked: overlay.offsetPanelOpen = false
    }

    Rectangle {
        id: offsetPanel
        visible: overlay.offsetPanelOpen || opacity > 0.01
        opacity: overlay.offsetPanelOpen ? 1 : 0
        scale: overlay.offsetPanelOpen ? 1 : 0.9
        transformOrigin: Item.TopRight
        Behavior on opacity {
            NumberAnimation { duration: overlay.offsetPanelOpen ? 160 : 120; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation {
                duration: overlay.offsetPanelOpen ? 220 : 150
                easing.type: overlay.offsetPanelOpen ? Easing.OutBack : Easing.InCubic
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

        MouseArea { anchors.fill: parent }

        Text {
            id: offsetTitle
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.leftMargin: 18
            text: "歌词偏移"
            color: Theme.color.onSurfaceColor
            font.family: Theme.typography.titleSmall.family
            font.pixelSize: Theme.typography.titleSmall.size
        }
        Text {
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 18
            text: (offsetSlider.value > 0 ? "+" : "") + offsetSlider.value + " ms"
            color: Theme.color.primary
            font.family: Theme.typography.titleMedium.family
            font.pixelSize: Theme.typography.titleMedium.size
            font.weight: Theme.typography.titleMedium.weight
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
            font.family: Theme.typography.bodySmall.family
            font.pixelSize: Theme.typography.bodySmall.size
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
            onEditingFinished: player.setLyricOffset(value)
        }

        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1
            anchors.left: parent.left
            anchors.leftMargin: 18
            text: "提前 5 秒"
            color: Theme.color.onSurfaceVariantColor
            font.family: Theme.typography.labelSmall.family
            font.pixelSize: Theme.typography.labelSmall.size
        }
        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            text: "0"
            color: Theme.color.onSurfaceVariantColor
            font.family: Theme.typography.labelSmall.family
            font.pixelSize: Theme.typography.labelSmall.size
        }
        Text {
            anchors.top: offsetSlider.bottom
            anchors.topMargin: 1
            anchors.right: parent.right
            anchors.rightMargin: 18
            text: "延后 5 秒"
            color: Theme.color.onSurfaceVariantColor
            font.family: Theme.typography.labelSmall.family
            font.pixelSize: Theme.typography.labelSmall.size
        }
        Button {
            id: resetBtn
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 10
            type: "text"
            text: "重置为 0"
            enabled: offsetSlider.value !== 0
            onClicked: {
                offsetSlider.value = 0
                player.resetLyricOffset()
            }
        }
    }

    MarqueeText {
        id: titleText
        visible: !overlay.landscape
        anchors.top: backBtn.bottom
        anchors.topMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        text: player.title
        textColor: "#FFFFFFFF"
        fontFamily: Theme.typography.titleLarge.family
        fontSize: 22
    }
    MarqueeText {
        id: artistText
        visible: !overlay.landscape
        anchors.top: titleText.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        text: player.artist
        textColor: "#B3FFFFFF"
        fontSize: 14
    }
    MouseArea {
        anchors.fill: artistText
        visible: !overlay.landscape
        enabled: player.playingArtistId !== 0
        hoverEnabled: enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            player.openArtist(player.playingArtistId)
        }
    }

    // --- bottom: transport (portrait) ---------------------------------
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
            wavy: settings.value("lyricProgressStyle") === 0
            visible: player.lyricSlide > 0.001
            indeterminate: player.loading
            value: player.lyricProgress
        }
        MouseArea {
            anchors.fill: progress
            anchors.topMargin: -10
            anchors.bottomMargin: -10
            onPressed: if (player.durationMs > 0)
                           player.seek(Math.round(mouseX / width * player.durationMs))
            onPositionChanged: if (pressed && player.durationMs > 0)
                                   player.seek(Math.round(Math.max(0, Math.min(width, mouseX)) / width * player.durationMs))
        }
        Text {
            anchors.left: parent.left
            anchors.top: progress.bottom
            anchors.topMargin: 6
            text: overlay.fmt(player.positionMs)
            color: "#B3FFFFFF"
            fontSize: 11
        }
        Text {
            anchors.right: parent.right
            anchors.top: progress.bottom
            anchors.topMargin: 6
            text: overlay.fmt(player.durationMs)
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
                icon: player.playMode === 1 ? "shuffle"
                      : (player.playMode === 2 ? "repeat_one" : "repeat")
                contentColor: player.playMode === 0 ? "#99FFFFFF" : "#FF82B1FF"
                onClicked: player.cyclePlayMode()
            }
            IconButton {
                type: "standard"; icon: "skip_previous"
                contentColor: "#FFFFFFFF"
                onClicked: player.prev()
            }
            IconButton {
                type: "filled"
                icon: player.playing ? "pause" : "play_arrow"
                onClicked: player.toggle()
            }
            IconButton {
                type: "standard"; icon: "skip_next"
                contentColor: "#FFFFFFFF"
                onClicked: player.next()
            }
            IconButton {
                type: "standard"
                enabled: player.currentLikeable
                icon: player.currentLiked ? "favorite" : "favorite_border"
                contentColor: player.currentLiked ? "#FFFF5277" : "#99FFFFFF"
                onClicked: player.toggleLike()
            }
        }
    }

    // --- landscape: cover + title + progress + artist + 5 buttons -----
    Item {
        id: landscapeChrome
        visible: overlay.landscape
        anchors.fill: parent

        readonly property real regionW: overlay.coverOnly ? overlay.width : overlay.width / 2
        readonly property real targetCoverSize:
            Math.max(140, Math.min(regionW - 32, overlay.height - 140, 460))

        property real coverSize: targetCoverSize
        property real centerX: regionW / 2
        Behavior on coverSize { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        Behavior on centerX { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

        Item {
            id: col
            width: landscapeChrome.coverSize
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 8
            height: lCover.height + lTitle.height + lProgress.height + lArtist.height + lRowContainer.height + 10
            anchors.horizontalCenter: parent.left
            anchors.horizontalCenterOffset: landscapeChrome.centerX

            // 1. 封面
            PlaybackCoverImage {
                id: lCover
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: landscapeChrome.coverSize
                height: landscapeChrome.coverSize
                radius: Math.min(width, height) * 0.06
                iconSize: 64
                fadeIn: true
                playing: player.playing
                source: player.coverPath
                layer.enabled: visible
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
                    onClicked: player.setCoverMode(false)
                }
            }

            // 2. 歌名
            MarqueeText {
                id: lTitle
                anchors.top: lCover.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                text: player.title
                textColor: "#FFFFFFFF"
                fontFamily: Theme.typography.titleLarge.family
                fontSize: 16
                centered: true
            }

            // 3. 播放进度条
            LinearProgress {
                id: lProgress
                anchors.top: lTitle.bottom
                anchors.topMargin: 3
                anchors.left: parent.left
                anchors.right: parent.right
                wavy: settings.value("lyricProgressStyle") === 0
                visible: player.lyricSlide > 0.001
                indeterminate: player.loading
                value: player.lyricProgress
            }

            MouseArea {
                anchors.fill: lProgress
                anchors.topMargin: -10
                anchors.bottomMargin: -10
                onPressed: if (player.durationMs > 0)
                               player.seek(Math.round(mouseX / width * player.durationMs))
                onPositionChanged: if (pressed && player.durationMs > 0)
                                       player.seek(Math.round(Math.max(0, Math.min(width, mouseX)) / width * player.durationMs))
            }

            // 4. 时间文本与歌手名字
            Text {
                id: lPos
                anchors.left: parent.left
                anchors.top: lProgress.bottom
                anchors.topMargin: 1
                width: 40
                horizontalAlignment: Text.AlignLeft
                text: overlay.fmt(player.positionMs)
                color: "#B3FFFFFF"
                fontSize: 10
            }

            Text {
                id: lDur
                anchors.right: parent.right
                anchors.top: lProgress.bottom
                anchors.topMargin: 1
                width: 40
                horizontalAlignment: Text.AlignRight
                text: overlay.fmt(player.durationMs)
                color: "#B3FFFFFF"
                fontSize: 10
            }

            MarqueeText {
                id: lArtist
                anchors.top: lProgress.bottom
                anchors.topMargin: 1
                anchors.left: lPos.right
                anchors.right: lDur.left
                text: player.artist
                textColor: "#B3FFFFFF"
                fontSize: 11
                centered: true
            }

            MouseArea {
                anchors.fill: lArtist
                enabled: player.playingArtistId !== 0
                hoverEnabled: enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    player.openArtist(player.playingArtistId)
                }
            }

            // 5. 按钮控制栏（向左右各自再外拓 8px）
            Item {
                id: lRowContainer
                anchors.top: lArtist.bottom
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: -8
                anchors.rightMargin: -8
                height: 48
                z: 10

                readonly property real totalBtnsWidth: btn1.width + btn2.width + btn3.width + btn4.width + btn5.width
                readonly property real gap: Math.max(0, (width - totalBtnsWidth) / 4)

                IconButton {
                    id: btn1
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    type: "standard"
                    icon: player.playMode === 1 ? "shuffle"
                          : (player.playMode === 2 ? "repeat_one" : "repeat")
                    contentColor: player.playMode === 0 ? "#99FFFFFF" : "#FF82B1FF"
                    onClicked: player.cyclePlayMode()
                }

                IconButton {
                    id: btn2
                    anchors.left: btn1.right
                    anchors.leftMargin: lRowContainer.gap
                    anchors.verticalCenter: parent.verticalCenter
                    type: "standard"
                    icon: "skip_previous"
                    contentColor: "#FFFFFFFF"
                    onClicked: player.prev()
                }

                IconButton {
                    id: btn3
                    anchors.left: btn2.right
                    anchors.leftMargin: lRowContainer.gap
                    anchors.verticalCenter: parent.verticalCenter
                    type: "filled"
                    icon: player.playing ? "pause" : "play_arrow"
                    onClicked: player.toggle()
                }

                IconButton {
                    id: btn4
                    anchors.left: btn3.right
                    anchors.leftMargin: lRowContainer.gap
                    anchors.verticalCenter: parent.verticalCenter
                    type: "standard"
                    icon: "skip_next"
                    contentColor: "#FFFFFFFF"
                    onClicked: player.next()
                }

                IconButton {
                    id: btn5
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    type: "standard"
                    enabled: player.currentLikeable
                    icon: player.currentLiked ? "favorite" : "favorite_border"
                    contentColor: player.currentLiked ? "#FFFF5277" : "#99FFFFFF"
                    onClicked: player.toggleLike()
                }
            }
        }
    }

    ToastStack {
        id: lyricSnack
        z: 100
    }
}

