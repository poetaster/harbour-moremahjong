import QtQuick 2.6
import Sailfish.Silica 1.0
import "."
import "MahData.js" as Mah
Page {
    id: page

    property var boards
    property var scores: []
    property string mode: "GAME_MODE_STANDARD"

    readonly property real thumbW: 320
    readonly property real thumbH: 320
    readonly property real cardH: 384


    function statsText(bid) {
        var s = page.scores ? page.scores[String(bid)] : undefined
        if (!s)
            return qsTr("Not played yet")
        var t = s.bestTime > 0 ?
            qsTr("Best %1").arg(Mah.formatTime(s.bestTime)) :
            qsTr("No win yet")
        return t + "  ·  " + (s.playCount || 0) + qsTr(" plays")
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: col.height

        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Boards")
            }

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
                onClicked: pageStack.push("Game.qml", { board: boards[index], boardId: String(boards[index].id), mode: page.mode })
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
                    height: card.preview ? card.preview.height : 0
                    anchors.verticalCenter: parent.verticalCenter

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
                            border.color: Theme.highlightColor
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
                        text: (card.preview ? card.preview.count : 0) + qsTr(" tiles")
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
            Component.onCompleted: {
                try {
                    //console.error("id " + boards[index].id + " name:" + boards[index].name )
                    card.preview = Mah.previewTiles(boards[index].map, page.thumbW, page.thumbH)
                } catch (err) {
                    console.error("preview failed for board " + boards[index].id + ": " + err)
                }
            }
        }
    }
    Component.onCompleted: {
                console.log("T=", typeof boards, " L=", boards.length,
                            " 0=", typeof boards[0],
                            " S=", JSON.stringify(boards[0]).substring(0, 100))
                // Use the pushed list only if its entries are real objects;
                // otherwise load the data file ourselves.
                var ok = false
                if (boards && boards.length > 0) {
                    var b0 = boards[0]
                    ok = b0 !== null && typeof b0 === "object" && b0.map !== undefined
                }
                if (ok)
                    console.log("Select: using pushed boards, " + boards.length)
                else
                    loadBoards()
            }

            function loadBoards() {
                Mah.loadJSON("../mah/assets/data/boards.json", function(doc) {
                    var arr
                    try {
                        arr = JSON.parse(doc.responseText)
                    } catch (err) {
                        console.error("Select: boards.json parse failed: " + err)
                        return
                    }
                    page.boards = arr
                    console.log("Select: loaded " + (arr.length ? arr.length : 0) + " boards from file")
                })
            }
}
