import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import "MahData.js" as Mah

Page {
    id: page

    // ---- game state ------------------------------------------------------
    property var boards
    property var board          // the selected board object (pushed from Select)
    property string boardId: ""
    property string mode: "GAME_MODE_STANDARD"
    readonly property bool isEasy: mode === "GAME_MODE_EASY"
    readonly property bool isExpert: mode === "GAME_MODE_EXPERT"
    // How many bottom-bar buttons are visible in this mode, so the row can
    // size them to fill evenly instead of leaving an empty slot:
    //   Easy:     Undo, Hint, Shuffle, Restart = 4
    //   Standard: Undo, Hint, Restart          = 3
    //   Expert:   Restart                      = 1
    readonly property int visibleBtns: isEasy ? 4 : (isExpert ? 1 : 3)

    property var game: ({})          // engine state (see MahData.js)
    property string boardName: ""
    property bool running: false
    property bool undoAvailable: false
    property int elapsedMs: 0
    property string resultMsg: ""    // "" | "win" | "lose"
    property var resultScore: ({})

    property int selectedIdx: -1     // game stone index of the selected tile
    property var hintIdxs: []        // list of game stone indices that are hinted

    //MahData { id: mah }

    function refreshUndo() {
        page.undoAvailable = page.game.undo.length >= 2
    }

    // ---- sounds ----------------------------------------------------------
    SoundEffect { id: sndSelect; source: "../mah/assets/sounds/select.wav" }
    SoundEffect { id: sndMatch; source: "../mah/assets/sounds/match.wav" }
    SoundEffect { id: sndInvalid; source: "../mah/assets/sounds/invalid.wav" }
    SoundEffect { id: sndOver; source: "../mah/assets/sounds/over.wav" }

    // ---- clock -----------------------------------------------------------
    Timer {
        id: clock
        interval: 1000
        repeat: true
        running: page.running //&& !AppCover.active
        onTriggered: page.elapsedMs += 1000
    }

    // ---- top bar ---------------------------------------------------------
    Item {
        id: topBar
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.headerHeight

        Row {
            id: topRow
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.paddingSmall
            width: parent.width - 2 * Theme.paddingSmall
            spacing: Theme.paddingMedium

            IconButton {
                id: backButton
                icon.source: "image://theme/icon-m-back"
                onClicked: pageStack.pop()
            }

            Column {
                id: titleCol
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                width: Math.min(160, topRow.width * 0.35)

                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    text: page.boardName
                    font.pixelSize: Theme.fontSizeMedium
                }
                Label {
                    width: parent.width
                    elide: Text.ElideRight
                    opacity: 0.85
                    font.pixelSize: Theme.fontSizeSmall
                    text: (page.game.count || 0) + qsTr(" tiles") + "  ·  "
                         + Mah.formatTime(page.elapsedMs)
                }
            }

            Label {
                id: bestLabel
                anchors.verticalCenter: parent.verticalCenter
                width: topRow.width - backButton.width - titleCol.width -  2
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                opacity: 0.85
                font.pixelSize: Theme.fontSizeSmall
                text: {
                    var bt = Mah.bestTimeFor(page.boardId)
                    return bt > 0 ? qsTr("Best %1").arg(Mah.formatTime(bt)) : ""
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: height - 1
            height: 1
            color: Theme.secondaryHighlightColor
            opacity: 0.5
        }
    }

    // ---- bottom bar ------------------------------------------------------
    Item {
        id: bottomBar
        z: 10
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 72

        Row {
            id: toolRow
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            spacing: Theme.paddingMedium
            // Size each visible button so they fill the row exactly (the Row
            // skips invisible buttons), instead of reserving 6 equal slots.
            property real btnW: (width - (page.visibleBtns - 1) * spacing) / page.visibleBtns

            Button {
                width: toolRow.btnW
                icon.source: "image://theme/icon-m-restore"
                text: qsTr("Undo")
                visible: !page.isExpert
                enabled: page.running && page.undoAvailable
                onClicked: page.doUndo()
            }

            Button {
                width: toolRow.btnW
                icon.source: "image://theme/icon-m-search"
                text: qsTr("Hint")
                visible: !page.isExpert
                enabled: page.running
                onClicked: page.doHint()
            }

            Button {
                width: toolRow.btnW
                icon.source: "image://theme/icon-m-refresh"
                text: qsTr("Shuffle")
                visible: page.isEasy
                enabled: page.running
                onClicked: page.doShuffle()
            }

            Button {
                width: toolRow.btnW
                icon.source: "image://theme/icon-m-cancel"
                text: qsTr("Restart")
                enabled: page.running || page.resultMsg !== ""
                onClicked: page.newGame()
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: 0
            height: 1
            color: Theme.secondaryHighlightColor
            opacity: 0.5
        }
    }

    // ---- board -----------------------------------------------------------
    Item {
        id: stage
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        property real fitScale: 1
        property real boardW: 1
        property real boardH: 1
        property real contentW: 1    // unrotated board width, for the tile mapping
        property real minX: 0
        property real minY: 0
        readonly property real scale: fitScale

        // Fit the whole board into the stage at the largest size that fits,
        // centered. There is no user zoom/pan: the board is always the best fit.
        function adjustFit() {
            if (boardW > 0 && boardH > 0 && width > 0 && height > 0)
                fitScale = Math.min(width / boardW, height / boardH) * 0.95
        }

        Item {
            id: boardItem
            // Scale about the top-left corner, NOT the default center: the
            // x/y centering formula and the hit test both assume a top-left
            // anchored scale. With the default (center) origin every tap is
            // offset by (w/2)(1-s) in each axis.
            transformOrigin: ItemOrigin.TopLeft
            x: ( stage.width - boardItem.width ) / 2 - 100
            y: ( stage.height - boardItem.height ) / 2 - 100
            width: stage.boardW - (4*Theme.paddingLarge)
            height: stage.boardH - (4*Theme.paddingLarge)
            scale: stage.scale

            Repeater {
                id: rep
                model: tileModel.count

                delegate: Item {
                    id: tileDelegate
                    // rotated footprint: wide = TILE_H, tall = TILE_W
                    width: Mah.TILE_H
                    height: Mah.TILE_W
                    x: tileModel.get(index).x
                    y: tileModel.get(index).y
                    z: tileModel.get(index).zsort

                    Rectangle {
                        id: face
                        anchors.centerIn: parent
                        width: Mah.TILE_H + 1
                        height: Mah.TILE_W + 1
                        radius: 8
                        color: "#f4eeda"
                        property bool sel: tileModel.get(index).idx === page.selectedIdx
                        property bool hin: page.hintIdxs.indexOf(tileModel.get(index).idx) >= 0
                        border.width: sel ? 5 : (hin ? 4 : 2)
                        border.color: sel ? "#ffc400"
                                   : (hin ? "#00b7ff" : "rgba(60,50,30,0.55)")
                    }
                    Image {
                        anchors.centerIn: parent
                        width: Mah.TILE_H - 6
                        height: Mah.TILE_W - 6
                        source: tileModel.get(index).src
                        smooth: true
                        mipmap: true
                    }
                }
            }
        }

        // Input area over the whole stage: a tap picks the topmost tile
        // under the pointer in paint order.
        MouseArea {
            id: stageMouse
            anchors.fill: parent
            z: 5

            function tileAtPoint(mx, my) {
                if (stage.scale <= 0)
                    return -1
                // Map through the item's *actual* transform (mapFromItem
                // honors transformOrigin), instead of assuming a top-left
                // anchored scale. Fallback: manual top-left math.
                var bx, by
                try {
                    var p = boardItem.mapFromItem(stage, mx, my)
                    bx = p.x
                    by = p.y
                } catch (e) {
                    bx = (mx - boardItem.x) / stage.scale
                    by = (my - boardItem.y) / stage.scale
                }
                var best = -1
                var bestZ = -1
                for (var i = 0; i < tileModel.count; i++) {
                    var t = tileModel.get(i)
                    if (bx >= t.x && bx <= t.x + Mah.TILE_H &&
                        by >= t.y && by <= t.y + Mah.TILE_W &&
                        t.zsort > bestZ) {
                        bestZ = t.zsort
                        best = t.idx
                    }
                }
                return best
            }

            onClicked: {
                var t = tileAtPoint(mouseX, mouseY)
                if (t >= 0)
                    page.tileClicked(t)
            }
        }
    }

    // ---- game over -------------------------------------------------------
    Dialog{
        id: gamePopup
        z: 20

        Column {
            width: Math.min(360, page.width - 2 * Theme.paddingLarge)
            spacing: Theme.paddingLarge

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                text: page.resultMsg === "win" ? qsTr("You win!") : qsTr("No more moves")
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.85
                text: page.resultMsg === "win" ?
                    qsTr("Time %1").arg(Mah.formatTime(page.elapsedMs))
                    : qsTr("%1 tiles remain").arg(page.game.count || 0)
            }
            Row {
                width: parent.width
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width ) / 2
                    text: qsTr("Play again")
                    onClicked: { gamePopup.hide(); page.newGame() }
                }
                Button {
                    width: (parent.width ) / 2
                    text: qsTr("Boards")
                    onClicked: { gamePopup.hide(); pageStack.pop() }
                }
            }
        }
    }

    // ---- engine glue -----------------------------------------------------
    ListModel { id: tileModel }

    function rebuildModel() {
        var g = page.game
        if (!g || !g.stones)
            return
        tileModel.clear()
        for (var i = 0; i < g.stones.length; i++) {
            var s = g.stones[i]
            if (s.picked)
                continue
            var p = Mah.tilePos(s.z, s.x, s.y)
            var u = p.px - stage.minX
            var v = p.py - stage.minY
            var W = stage.contentW
            tileModel.append({
                idx: i,
                // 90° CCW rotation: old top-left (u,v) -> (v, W - u - TILE_W)
                x: v,
                y: W - u - Mah.TILE_W,
                zsort: p.zsort,
                src: Mah.imageFor(s.v)
            })
        }
        refreshFlags()
    }

    // Refresh only the selection/hint borders from the current game state.
    // Cheap: it just reassigns two page properties (which repaint the
    // delegate borders) instead of destroying and recreating every tile.
    function refreshFlags() {
        var g = page.game
        if (!g) {
            page.selectedIdx = -1
            page.hintIdxs = []
            return
        }
        page.selectedIdx = (g.selected >= 0) ? g.selected : -1
        var h = []
        if (g.stones)
            for (var i = 0; i < g.stones.length; i++)
                if (g.stones[i].hinted)
                    h.push(i)
        page.hintIdxs = h
        page.refreshUndo()
    }

    // Remove just the matched (picked) tiles from the model, instead of
    // rebuilding the whole board. Fast: only two delegates are destroyed.
    function removePickedTiles() {
        var g = page.game
        if (!g || !g.stones)
            return
        var toRemove = []
        for (var i = 0; i < tileModel.count; i++) {
            var s = g.stones[tileModel.get(i).idx]
            if (s && s.picked)
                toRemove.push(i)
        }
        for (var r = toRemove.length - 1; r >= 0; r--)
            tileModel.remove(toRemove[r])
        refreshFlags()
    }


    function newGame() {
        var board = page.board
        if (!board && page.boards)
            board = Mah.findBoard(page.boards, page.boardId)
        if (!board)
            return
        page.boardName = board.name
        page.game = Mah.dealBoard(board)
        page.resultMsg = ""
        page.resultScore = {}
        page.elapsedMs = 0
        page.running = true

        var box = Mah.boardBox(board.map)
        stage.minX = box.minx
        stage.minY = box.miny
        // Board is drawn rotated 90° CCW (top edge becomes left edge) so the
        // wide board fills the tall portrait window.
        stage.boardW = box.h
        stage.boardH = box.w
        stage.contentW = box.w
        stage.adjustFit()
        rebuildModel()
    }

    function tileClicked(i) {
        var g = page.game
        if (!g || !g.stones || !page.running)
            return
        if (i < 0 || i >= g.stones.length)
            return
        var s = g.stones[i]
        if (s.picked)
            return
        if (s.blocked) {
            sndInvalid.play()
            return
        }
        if (g.selected >= 0 && g.selected !== i
            && g.stones[g.selected].groupnr === s.groupnr) {
            Mah.pickPair(g, g.selected, i)
            removePickedTiles()   // just drop the two matched tiles
            if (g.count < 2) {
                gameOver(true)
                return
            }
            if (g.free.length < 1) {
                gameOver(false)
                return
            }
            sndMatch.play()
        } else {
            if (g.selected >= 0 && g.stones[g.selected])
                g.stones[g.selected].selected = false
            g.selected = (g.selected === i) ? -1 : i
            if (g.selected >= 0)
                g.stones[i].selected = true
            refreshFlags()   // only the selection border changed: cheap update
            sndSelect.play()
        }
    }

    function doUndo() {
        if (!page.running || page.game.undo.length < 2)
            return
        if (Mah.back(page.game))
            rebuildModel()
    }

    function doHint() {
        if (!page.running)
            return
        if (Mah.hint(page.game))
            refreshFlags()
    }

    function doShuffle() {
        if (!page.running || !page.isEasy)
            return
        Mah.shuffleGame(page.game)
        rebuildModel()
    }

    function gameOver(won) {
        page.running = false
        sndOver.play()
        page.resultMsg = won ? "win" : "lose"
        page.resultScore = Mah.recordGame(page.boardId, won, page.elapsedMs)
        refreshFlags()
        gamePopup.show()
    }

    onWidthChanged: stage.adjustFit()
    onHeightChanged: stage.adjustFit()

    Component.onCompleted: newGame()
}
