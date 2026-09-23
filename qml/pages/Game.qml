import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import "MahData.js" as Mah
import "db.js" as DB

Page {
    id: page

    //allowedOrientations: Orientation.All

    // game state
    property var board          // the selected board object (pushed from Select)
    property string boardId: ""
    property string mode: "GAME_MODE_STANDARD"
    // Pre-computed game state dealt by Select.qml before the push, so the
    // solver never runs inside the page transition. Consumed once by
    // newGame(); later games (Restart / Again) deal on the spot.
    property var prepared: null

    readonly property bool isEasy: mode === "GAME_MODE_EASY"
    readonly property bool isExpert: mode === "GAME_MODE_EXPERT"
    // To-Do
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

    //  sounds  - only wav files
    SoundEffect { id: sndSelect; source: "../mah/assets/sounds/select.wav" }
    SoundEffect { id: sndMatch; source: "../mah/assets/sounds/match.wav" }
    SoundEffect { id: sndInvalid; source: "../mah/assets/sounds/invalid.wav" }
    SoundEffect { id: sndOver; source: "../mah/assets/sounds/over.wav" }

    //  clock - for game time
    Timer {
        id: clock
        interval: 1000
        repeat: true
        running: page.running //&& !AppCover.active
        onTriggered: page.elapsedMs += 1000
    }

    //  top bar  - just a spacer currently
    Item {
        id: topBar
        z: 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        width: parent.width
        height: 30
        Row {
            id: topRow
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.paddingLarge
            width: parent.width
            spacing: Theme.paddingMedium

            Column {
                id: titleCol
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                width: Math.min(160, topRow.width * 0.35)
            }
        }

    }

    // bottom bar visible as a 'right bar' 'twisted it is'
    Item {
        id: bottomBar
        z: 10
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: parent.width / 6
        height: parent.width / 5
        rotation:90
        transformOrigin: Item.TopRight
        Column {
            id: toolRow
            width: parent.width
            spacing: Theme.paddingMedium

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
                text: page.building ? qsTr("Preparing board…")
                      : (page.game.count || 0) + qsTr(" tiles") + "  \n  "
                        + Mah.formatTime(page.elapsedMs)
            }
            Label {
                id: bestLabel
                width: parent.width
                elide: Text.ElideRight
                opacity: 0.85
                font.pixelSize: Theme.fontSizeSmall
                text: {
                    var bt = DB.bestTimeFor(page.boardId)
                    return bt > 0 ? qsTr("Best %1").arg(Mah.formatTime(bt)) : ""
                }
            }
            Button {
                width: parent.width
                icon.source: "image://theme/icon-m-tab-return"

                //text: qsTr("Undo")
                visible: !page.isExpert
                enabled: page.running && page.undoAvailable
                onClicked: page.doUndo()
            }

            Button {
                width: parent.width
                icon.source: "image://theme/icon-m-search"
                //text: qsTr("Hint")
                visible: !page.isExpert
                enabled: page.running
                onClicked: page.doHint()
            }

            Button {
                width: parent.width
                icon.source: "image://theme/icon-m-shuffle"
                //text: qsTr("Shuffle")
                visible: page.isEasy
                enabled: page.running
                onClicked: page.doShuffle()
            }

            Button {
                width: parent.width
                icon.source: "image://theme/icon-m-cancel"
                //text: qsTr("Restart")
                enabled: page.running || page.resultMsg !== ""
                onClicked: page.newGame()
            }
            //  game over
            Column {
                id: gamePopup
                visible: false
                width: parent.width//Math.min(360, page.width - 2 * Theme.paddingLarge)
                spacing: Theme.paddingLarge

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    text: page.resultMsg === "win" ? qsTr("Oh, yes!") : qsTr("Oh, no!")
                }
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.85
                    font.pixelSize: Theme.fontSizeSmall
                    text: page.resultMsg === "win" ?
                              qsTr("Time %1").arg(Mah.formatTime(page.elapsedMs))
                            : qsTr("%1 tiles remain").arg(page.game.count || 0)
                }

                Button {
                    width: parent.width
                    text: qsTr("Again?")
                    onClicked: { gamePopup.visible = false; page.newGame() }
                }
            }
        }

    }

    //  board
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
        property real minX: 0
        property real minY: 0
        readonly property real scale: fitScale

        // Fit the whole board into the stage at the largest size that fits, centered.
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
            x: ( stage.width - boardItem.width ) / 2 - 100
            y: ( stage.height - boardItem.height ) / 2 - 100
            width: stage.boardW - (4*Theme.paddingLarge)
            height: stage.boardH - (4*Theme.paddingLarge)
            scale: stage.scale

            Repeater {
                id: rep
                // The ListModel itself (not its count): the delegate then
                // receives the row's roles (idx, px, py, zsort, src) as
                // context properties, and remove(i) destroys the right
                // delegate instead of just shrinking an int model.
                // This is reasonably fast :)
                model: tileModel

                delegate: Item {
                    id: tileDelegate
                    // rotated footprint: wide = TILE_H, tall = TILE_W
                    width: Mah.TILE_H
                    height: Mah.TILE_W
                    // px/py roles (renamed from x/y to avoid the Item.x
                    // self-reference trap); idx/zsort/src bind directly
                    // from the model context
                    x: px
                    y: py
                    z: zsort

                    Rectangle {
                        id: face
                        anchors.centerIn: parent
                        width: Mah.TILE_H + 1
                        height: Mah.TILE_W + 1
                        radius: 8
                        color: "#f4eeda"
                        property bool sel: idx === page.selectedIdx
                        property bool hin: page.hintIdxs.indexOf(idx) >= 0
                        border.width: sel ? 5 : (hin ? 4 : 2)
                        border.color: sel ? "#ffc400"
                                          : (hin ? "#00b7ff" : "rgba(60,50,30,0.55)")
                    }
                    Image {
                        anchors.centerIn: parent
                        width: Mah.TILE_H - 6
                        height: Mah.TILE_W - 6
                        source: src
                        smooth: true
                        asynchronous: true // mucho importanté!
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
            enabled: !page.building

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
                    if (bx >= t.px && bx <= t.px + Mah.TILE_H &&
                            by >= t.py && by <= t.py + Mah.TILE_W &&
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


    ListModel { id: tileModel }

    // progressive board build

    property bool building: false
    property var buildQueue: null
    property int buildPos: 0

    // with 50ms we see the animation briefly.
    Timer {
        id: buildTimer
        interval: 50
        repeat: true
        running: page.building
        onTriggered: {
            var t0 = Date.now()
            var q = page.buildQueue
            var n = q ? q.length : 0
            while (page.buildPos < n && Date.now() - t0 < 8) {
                var t = q[page.buildPos]
                page.buildPos++
                tileModel.append({ idx: t.idx, px: t.px, py: t.py,
                                   zsort: t.zsort, src: t.src })
            }
            if (page.buildPos >= n) {
                page.building = false
                page.running = true
                refreshFlags()
            }
        }
    }

    // Queue every remaining tile (bottom layers first, so the board
    // materializes from the base upwards) and start the chunked build.
    function rebuildModel() {
        var g = page.game
        if (!g || !g.stones)
            return
        tileModel.clear()
        var q = []
        for (var i = 0; i < g.stones.length; i++) {
            var s = g.stones[i]
            if (s.picked)
                continue
            var p = Mah.tilePos(s.z, s.x, s.y)
            var u = p.px - stage.minX
            var v = p.py - stage.minY
            var H = stage.boardW
            q.push({
                     idx: i,
                     // 90° CW rotation (board turned 180° vs the old view):
                     // old top-left (u,v) -> (H - v - TILE_H, u)
                     px: H - v - Mah.TILE_H,
                     py: u,
                     zsort: p.zsort,
                     src: Mah.imageFor(s.v)
                 })
        }
        q.sort(function(a, b) { return a.zsort - b.zsort })
        page.buildQueue = q
        page.buildPos = 0
        page.building = true
    }

    // Re-append just the tiles restored by an undo.
    function restorePicked() {
        var g = page.game
        if (!g || !g.stones)
            return
        var inModel = {}
        for (var i = 0; i < tileModel.count; i++)
            inModel[tileModel.get(i).idx] = true
        for (var j = 0; j < g.stones.length; j++) {
            var s = g.stones[j]
            if (s.picked || inModel[j])
                continue
            var p = Mah.tilePos(s.z, s.x, s.y)
            var u = p.px - stage.minX
            var v = p.py - stage.minY
            tileModel.append({
                               idx: j,
                               px: stage.boardW - v - Mah.TILE_H,
                               py: u,
                               zsort: p.zsort,
                               src: Mah.imageFor(s.v)
                           })
        }
        refreshFlags()
    }

    // Refresh only the selection/hint borders from the current game state.
    // reassigns two page properties which repaint the delegate borders
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

    // Remove just  matched (picked) tiles from the model,
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
        page.game = page.prepared ? page.prepared : Mah.dealBoard(board)
        page.prepared = null
        page.resultMsg = ""
        page.resultScore = {}
        page.elapsedMs = 0
        // page.running is enabled by buildTimer once the tiles are ready

        var box = Mah.boardBox(board.map)
        stage.minX = box.minx
        stage.minY = box.miny
        // Board is drawn rotated 90° CW (top edge becomes right edge) so the
        // wide board fills the tall portrait window.
        stage.boardW = box.h
        stage.boardH = box.w
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
            restorePicked()
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
        page.resultScore = DB.recordGame(page.boardId, won, page.elapsedMs)
        refreshFlags()
        gamePopup.visible = true
    }

    onWidthChanged: stage.adjustFit()
    onHeightChanged: stage.adjustFit()

    Component.onCompleted: {
        var theme = DB.getTheme();
        if (theme !== undefined) Mah.setTheme( theme.value )
        newGame()
    }


}
