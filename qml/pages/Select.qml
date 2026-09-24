import QtQuick 2.6
import Sailfish.Silica 1.0
import "MahData.js" as Mah
import "db.js" as DB
Page {
    id: page

    //allowedOrientations: Orientation.All

    property bool debug: false
    property var boards:[]
    property var theme
    property var scores: []
    property string mode: "GAME_MODE_STANDARD"

    // Pending Game push. A short delay lets the spinner paint (a synchronous
    // push never leaves a render pass for it); the deal then runs during
    // that gap, behind the spinner.
    property var pendingBoard: null
    property string pendingBoardId: ""

    Timer {
        id: pushTimer
        interval: 150
        repeat: false
        onTriggered: {
            var b = page.pendingBoard
            var bid = page.pendingBoardId
            page.pendingBoard = null
            page.pendingBoardId = ""
            if (b) {
                // Deal here, behind the spinner, and pass the finished
                // game to the Game page so the transition never waits
                // on the solver.
                var g = Mah.dealBoard(b)
                busy.running = false
                pageStack.push("Game.qml", { board: b, boardId: bid, mode: page.mode, prepared: g })
            }
        }
    }
    BusyIndicator {
        z:1
        id:busy
        running:  false
        //text:qsTr("Composing...")
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        BusyLabel {
            text: "Loading..."
        }
    }
    readonly property real thumbW: page.width / 2
    readonly property real thumbH: page.width / 2
    readonly property real cardH: page.width / 2 + Theme.paddingLarge


    function refreshScores() {
        page.scores = DB.loadScores()
    }

    function statsText(bid) {
        var s = page.scores ? page.scores[String(bid)] : undefined
        if (!s)
            return qsTr("Not played yet")
        return (s.playCount || 0) + qsTr(" plays")
    }

    function timeText(bid) {
        var s = page.scores ? page.scores[String(bid)] : undefined
        if (!s)
            return qsTr("")
        var t = s.bestTime > 0 ?
            qsTr("Best %1").arg(Mah.formatTime(s.bestTime)) :
            qsTr("No win yet")
        return t
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: col.height

        VerticalScrollDecorator { flickable: flickable }
        PullDownMenu {
            id: mainPulleyMenu
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"), {})
                }
            }
            MenuItem {
                text: qsTr("WebView")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("WebView.qml"), {})
                }
            }
            MenuItem {
                text: qsTr("Style")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("Style.qml"), {})
                }
            }

        }
        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Boards")
            }
            // currently this is a no-op which I'm not sure what to do with.
            ComboBox {
                id: modeControl
                width: parent.width - 2 * Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                menu: ContextMenu {
                   MenuItem {text: qsTr("Easy")}
                   MenuItem {text: qsTr("Standard")}
                   MenuItem {text: qsTr("Expert")}
                }
                currentIndex: 1
                onCurrentIndexChanged: {
                    var modes = ["GAME_MODE_EASY",
                                "GAME_MODE_STANDARD",
                                "GAME_MODE_EXPERT"]
                    page.mode = modes[currentIndex]
                }
            }

            Repeater {
                id: rep
                model: boards
                delegate: boardCard
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
        }
    }

    // One row per board: preview thumbnail + name / stats.
    Component {
        id: boardCard

        Item {
            id: card
            width: parent.width - 2 * Theme.paddingLarge
            x: Theme.paddingLarge
            height: page.cardH

            property var preview: null

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var b = boards[index]
                    if (!b)
                        return
                    busy.running = true
                    page.pendingBoard = b
                    page.pendingBoardId = String(b.id)
                    pushTimer.start()
                }
            }
            Row {
                id: content
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.paddingMedium

                Item {
                    id: thumb
                    width: page.thumbW
                    height: page.thumbH
                    anchors.verticalCenter: parent.verticalCenter

                    // Prerendered miniature: one image per card instead of ~144
                    // separate rectangle nodes,  sad, but, performance :)
                    // the fallback is the nice rendering method which is way too slow
                    Image {
                        id: thumbImage
                        anchors.fill: parent
                        asynchronous: true
                        smooth: true
                        source: Mah.assetBase() + "data/previews/" + boards[index].id + ".png"
                        onStatusChanged: {
                            if (status === Image.Error)
                                card.buildPreview()
                        }
                    }

                    // Fallback: draw the miniature live if the baked image
                    // is missing.
                    Repeater {
                        model: card.preview ? card.preview.tiles.length : 0
                        delegate: Rectangle {
                            width: card.preview.tiles[index].w
                            height: card.preview.tiles[index].h
                            x: card.preview.tiles[index].x
                            y: card.preview.tiles[index].y
                            z: card.preview.tiles[index].zsort
                            radius: 2
                            color: "#efe7cf"
                            border.width: 1
                            border.color: "#000000"//Theme.secondaryColor
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: content.width - thumb.width - content.spacing

                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: Theme.fontSizeMedium
                        text: boards[index].name
                    }
                    Label {
                        opacity: 0.85
                        font.pixelSize: Theme.fontSizeSmall
                        text: page.timeText(boards[index].id)
                    }
                    Label {
                        width: parent.width
                        elide: Text.ElideRight
                        opacity: 0.85
                        font.pixelSize: Theme.fontSizeSmall
                        text: page.statsText(boards[index].id)
                    }
                }
            }
            function buildPreview() {
                if (card.preview)
                    return
                try {
                    card.preview = Mah.previewTiles(boards[index].map, page.thumbW, page.thumbH)
                } catch (err) {
                    if (debug) console.error("preview failed for board " + boards[index].id + ": " + err)
                }
            }

            Component.onCompleted: {
                // Only pay for the live miniature if the baked image
                // failed to load.
                if (thumbImage.status === Image.Error)
                    card.buildPreview()
            }
        }
    }
    Component.onCompleted: {

        // used last loaded boards if it's a list ....
        var ok = false
        if (boards && boards.length > 0) {
            var b0 = boards[0]
            ok = b0 !== null && typeof b0 === "object" && b0.map !== undefined
        }
        if (ok) {
            if (debug) console.log("Select: using pushed boards, " + boards.length)
        } else {
            loadBoards()
        }

        page.refreshScores()
    }

    function loadBoards() {
        Mah.loadJSON("../mah/assets/data/boards.json", function(doc) {
            try {
                boards = JSON.parse(doc.responseText)
            } catch (err) {
                if (debug) console.error("Select: boards.json parse failed: " + err)
                return
            }
            if (debug) console.log("Select: loaded " + (arr.length ? arr.length : 0) + " boards from file")
        })
    }

    // Scores are read fresh from the database on activating
    onStatusChanged: {
        if (page.status == PageStatus.Activating) {
            busy.running = false
            page.refreshScores()
        }
    }
}
