import QtQuick 2.6
import Sailfish.Silica 1.0
import "MahData.js" as Mah
import "db.js" as DB
Page {
    id: view
    property var scores:[]
    property var boards:[]

    allowedOrientations: Orientation.All

    PageHeader {
        title: qsTr("Mah Solitaire")
    }

    Column {
        anchors.centerIn: parent
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 2 * Theme.paddingLarge, 420)
        spacing: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 128
            height: 128
            source: "/usr/share/icons/hicolor/128x128/apps/harbour-moremahjong.png"
        }

        Button {
            width: parent.width
            text: qsTr("Play")
            onClicked: pageStack.push("Select.qml",{boards: view.boards,scores:view.scores})
        }

        Button {
            width: parent.width
            text: qsTr("About")
            onClicked: pageStack.push("About.qml")
        }
    }


    Component.onCompleted: {// Load all board definitions from assets/data/boards.json.
    function loadBoards() {
        var response; // Qt.ope (Qt.resolvedUrl("../mah/assets/data/boards.json"))
        var out = []
        Mah.loadJSON("../mah/assets/data/boards.json", function(doc) {
            response = JSON.parse(doc.responseText);
            //var arr = resp.data
            for (var i = 0; i < response.length ; i++) {
                //page.boards.push({ id: response[i].id, name: response[i].name, map: response[i].map })
                 //boards.append(response[i]);
                 boards[i] = response[i];
               // console.debug(JSON.stringify(boards[i].name))
            };
            //return out
        });
        //if (!resp || resp.data === undefined)
        //    return []
        //var arr = resp.data
        //if (typeof arr === "string")
        //    arr = JSON.parse(arr)
        //for (var i = 0; i < arr.length; i++)
        //    out.push({ bid: arr[i].id, name: arr[i].name, map: arr[i].map })

        //return out
    }

    loadBoards()
    scores = DB.loadScores()
    }
}
