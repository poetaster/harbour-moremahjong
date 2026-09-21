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

    property var game: ({})          // engine state (see MahData.js)
    property string boardName: ""
    property bool running: false
    property bool undoAvailable: false
    property int elapsedMs: 0
    property string resultMsg: ""    // "" | "win" | "lose"
    property var resultScore: ({})

    //MahData { id: mah }

    function refreshUndo() {
        page.undoAvailable = page.game.undo.length >= 2
    }

    // ---- sounds ----------------------------------------------------------
    SoundEffect { id: sndSelect; source: "../mah/assets/sounds/select.ogg" }
    SoundEffect { id: sndMatch; source: "../mah/assets/sounds/match.ogg" }
    SoundEffect { id: sndInvalid; source: "../mah/assets/sounds/invalid.ogg" }
    SoundEffect { id: sndOver; source: "../mah/assets/sounds/over.ogg" }

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

            Button {
                width: (toolRow.width ) / 4
                icon.source: "image://theme/icon-m-restore"
                text: qsTr("Undo")
                visible: !page.isExpert
                enabled: page.running && page.undoAvailable
                onClicked: page.doUndo()
            }

            Button {
                width: (toolRow.width ) / 4
                icon.source: "image://theme/icon-m-search"
                text: qsTr("Hint")
                visible: !page.isExpert
                enabled: page.running
                onClicked: page.doHint()
            }

            Button {
                width: (toolRow.width ) / 4
                icon.source: "image://theme/icon-m-refresh"
                text: qsTr("Shuffle")
                visible: page.isEasy
                enabled: page.running
                onClicked: page.doShuffle()
            }

            Button {
                width: (toolRow.width ) / 4
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
        property real userScale: 1
        property real userX: 0
        property real userY: 0
        property real boardW: 1
        property real boardH: 1
        property real minX: 0
        property real minY: 0
        readonly property real scale: fitScale * userScale

        function resetView() {
            userScale = 1
            userX = 0
            userY = 0
        }

        function adjustFit() {
            if (boardW > 0 && boardH > 0 && width > 0 && height > 0)
                fitScale = Math.min(width / boardW, height / boardH) * 0.98
        }

        Item {
            id: boardItem
            x: (stage.width - boardItem.width * stage.scale) / 2 + stage.userX
            y: (stage.height - boardItem.height * stage.scale) / 2 + stage.userY
            width: stage.boardW
            height: stage.boardH
            scale: stage.scale

            Repeater {
                id: rep
                model: tileModel.count

                delegate: Item {
                    id: tileDelegate
                    width: Mah.TILE_W
                    height: Mah.TILE_H
                    x: tileModel.get(index).x
                    y: tileModel.get(index).y
                    z: tileModel.get(index).zsort

                    Rectangle {
                        id: face
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 8
                        color: "#f4eeda"
                        border.width: tileModel.get(index).selected ? 5 : (tileModel.get(index).hinted ? 4 : 2)
                        border.color: tileModel.get(index).selected ? "#ffc400"
                                   : (tileModel.get(index).hinted ? "#00b7ff" : "rgba(60,50,30,0.55)")
                    }
                    Image {
                        anchors.centerIn: parent
                        width: Mah.TILE_W - 6
                        height: Mah.TILE_H - 6
                        source: tileModel.get(index).src
                        smooth: true
                        mipmap: true
                    }
                }
            }
        }

        // Single input area over the whole stage: a tap picks a tile (the
        // topmost tile under the pointer in paint order) and a drag pans.
        MouseArea {
            id: stageMouse
            anchors.fill: parent
            z: 5
            property real lastX: 0
            property real lastY: 0
            property real movedDist: 0

            function tileAtPoint(mx, my) {
                if (stage.scale <= 0)
                    return -1
                var bx = (mx - boardItem.x) / stage.scale
                var by = (my - boardItem.y) / stage.scale
                var best = -1
                var bestZ = -1
                for (var i = 0; i < tileModel.count; i++) {
                    var t = tileModel.get(i)
                    if (bx >= t.x && bx <= t.x + Mah.TILE_W &&
                        by >= t.y && by <= t.y + Mah.TILE_H &&
                        t.zsort > bestZ) {
                        bestZ = t.zsort
                        best = t.idx
                    }
                }
                return best
            }

            onPressed: {
                lastX = mouseX
                lastY = mouseY
                movedDist = 0
            }
            onPositionChanged: {
                if (pressed) {
                    movedDist += Math.abs(mouseX - lastX) + Math.abs(mouseY - lastY)
                    if (movedDist > 12) {
                        stage.userX += mouseX - lastX
                        stage.userY += mouseY - lastY
                    }
                    lastX = mouseX
                    lastY = mouseY
                }
            }
            onClicked: {
                if (movedDist <= 12) {
                    var t = tileAtPoint(mouseX, mouseY)
                    console.log("tap at", mouseX, mouseY, " -> tile", t)
                    if (t >= 0)
                        page.tileClicked(t)
                }
            }
            onDoubleClicked: stage.resetView()
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
            tileModel.append({
                idx: i,
                x: p.px - stage.minX,
                y: p.py - stage.minY,
                zsort: p.zsort,
                src: Mah.imageFor(s.v),
                selected: g.selected === i,
                hinted: s.hinted
            })
        }
        page.refreshUndo()
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
        stage.boardW = box.w
        stage.boardH = box.h
        stage.resetView()
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
            sndSelect.play()
        }
        rebuildModel()
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
            rebuildModel()
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
        rebuildModel()
        gamePopup.show()
    }

    onWidthChanged: stage.adjustFit()
    onHeightChanged: stage.adjustFit()

    Component.onCompleted: newGame()
}
