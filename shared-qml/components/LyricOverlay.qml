import QtQuick
import QtQuick.Layouts
import md3.Core
import "."

// QML chrome for the lyric page, composited on top of the host-drawn fluid
// backdrop + per-syllable lyrics.
Item {
id: overlay

property bool landscape: overlay.width > overlay.height
property bool coverOnly: player.lyricsCoverOnly || player.coverModeManual
property bool offsetPanelOpen: false
// Top row inset for the three title buttons. Desktop overrides this to 6
// (Main.qml hides the custom title bar while the lyric page is open, so the
// buttons sit flush at the very top of the window); mobile keeps the status
// bar inset so they clear the system bar.
property real topPad: settings.topInset + 6
onOffsetPanelOpenChanged: {
player.setLyricOffsetPanelOpen(offsetPanelOpen)
if (offsetPanelOpen) offsetSlider.value = player.lyricOffsetMs
}

property bool lyricsOpenMirror: player.lyricsOpen
onLyricsOpenMirrorChanged: if (!lyricsOpenMirror) overlay.offsetPanelOpen = false

function fmt(ms) {
if (ms <= 0) return "0:00";
var s = Math.floor(ms / 1000), m = Math.floor(s / 60), r = s % 60;
return m + ":" + (r < 10 ? "0" + r : r);
}

MouseArea { anchors.fill: parent }

// 【修改点 1】：竖屏封面放大一圈（调整了 coverSize 计算，最大允许尺寸调大至 480）
CoverImage {
id: pCover
visible: !overlay.landscape && (overlay.coverOnly || opacity > 0.01)
property real coverSize: Math.max(180, Math.min(overlay.width - 64, overlay.height - 280, 480))
width: coverSize
height: coverSize
anchors.horizontalCenter: parent.horizontalCenter
anchors.verticalCenter: parent.verticalCenter
radius: Math.min(width, height) * 0.06
iconSize: 72
fadeIn: true
source: player.coverPath
property bool shown: overlay.coverOnly && player.lyricSlide > 0.25
opacity: shown ? 1 : 0
scale: shown ? 1 : 0.95
Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

MouseArea {
anchors.fill: parent
onClicked: player.setCoverMode(false)
}
}

IconButton {
id: backBtn
anchors.top: parent.top
anchors.topMargin: overlay.topPad
anchors.left: parent.left
anchors.leftMargin: 6
type: "standard"
icon: "expand_more"
contentColor: "#FFFFFFFF"
onClicked: player.setLyricsOpen(false)
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
font.family: Theme.typography.titleLarge.family
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
font.pixelSize: 14
elide: Text.ElideRight
}

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
wavy: true
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
font.pixelSize: 11
}
Text {
anchors.right: parent.right
anchors.top: progress.bottom
anchors.topMargin: 6
text: overlay.fmt(player.durationMs)
color: "#B3FFFFFF"
font.pixelSize: 11
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

Item {
id: landscapeChrome
visible: overlay.landscape
anchors.fill: parent

readonly property real regionW: overlay.coverOnly ? overlay.width : overlay.width / 2
readonly property real targetCoverSize: Math.max(160, Math.min(regionW - 40, overlay.height - 150, 420))
property real coverSize: targetCoverSize
property real centerX: regionW / 2
Behavior on coverSize { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
Behavior on centerX { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

// 1. 封面（【修改点 2】：把上边距由 32 缩小至 18，将整个封面往上提升一点点）
CoverImage {
id: lCover
width: landscapeChrome.coverSize
height: landscapeChrome.coverSize
anchors.top: parent.top
anchors.topMargin: settings.topInset + 18
anchors.horizontalCenter: parent.left
anchors.horizontalCenterOffset: landscapeChrome.centerX
radius: Math.min(width, height) * 0.08
iconSize: 72
fadeIn: true
source: player.coverPath

MouseArea {
anchors.fill: parent
onClicked: player.setCoverMode(false)
}
}

// 2. 进度条与曲目信息区域
// 【修改点 3】：将 topMargin 从 10 调大到 16，强制歌名往下降一点点，彻底避免与封面叠在一起
Item {
id: progressBox
anchors.top: lCover.bottom
anchors.topMargin: 16
anchors.left: lCover.left
anchors.right: lCover.right
anchors.bottom: controlRow.top
anchors.bottomMargin: 6

// 歌名
Text {
id: lTitle
anchors.bottom: lProgress.top
anchors.bottomMargin: 6
anchors.left: parent.left
anchors.right: parent.right
anchors.leftMargin: 8
anchors.rightMargin: 8
text: player.title
color: "#FFFFFFFF"
font.pixelSize: 17
font.family: Theme.typography.titleMedium.family
horizontalAlignment: Text.AlignHCenter
wrapMode: Text.NoWrap
elide: Text.ElideRight
}

// 波浪进度条
LinearProgress {
id: lProgress
anchors.left: parent.left
anchors.right: parent.right
anchors.bottom: posText.top
anchors.bottomMargin: 4
wavy: true
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

// 左边：已播时间
Text {
id: posText
anchors.left: parent.left
anchors.bottom: parent.bottom
text: overlay.fmt(player.positionMs)
color: "#B3FFFFFF"
font.pixelSize: 11
}

// 中间：歌手名
Text {
id: lArtist
anchors.verticalCenter: posText.verticalCenter
anchors.left: parent.left
anchors.right: parent.right
anchors.leftMargin: 36
anchors.rightMargin: 36
text: player.artist
color: "#B3FFFFFF"
font.pixelSize: 11
font.family: Theme.typography.bodySmall.family
horizontalAlignment: Text.AlignHCenter
wrapMode: Text.NoWrap
elide: Text.ElideRight
}

// 右边：总时长
Text {
id: durText
anchors.right: parent.right
anchors.bottom: parent.bottom
text: overlay.fmt(player.durationMs)
color: "#B3FFFFFF"
font.pixelSize: 11
}
}

// 3. 最下方的控制按钮
Row {
id: controlRow
anchors.horizontalCenter: lCover.horizontalCenter
anchors.bottom: parent.bottom
anchors.bottomMargin: settings.bottomInset + 8
spacing: 18

IconButton {
type: "standard"
icon: player.playMode === 1 ? "shuffle"
: (player.playMode === 2 ? "repeat_one" : "repeat")
contentColor: player.playMode === 0 ? "#99FFFFFF" : "#FF82B1FF"
onClicked: player.cyclePlayMode()
}

IconButton {
type: "standard"
icon: "skip_previous"
contentColor: "#FFFFFFFF"
onClicked: player.prev()
}

IconButton {
type: "filled"
icon: player.playing ? "pause" : "play_arrow"
onClicked: player.toggle()
}

IconButton {
type: "standard"
icon: "skip_next"
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
}

