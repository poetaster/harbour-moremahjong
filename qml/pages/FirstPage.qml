import QtQuick 2.6
import Sailfish.Silica 1.0
import "MahData.js" as Mah
import "db.js" as DB
Page {
    id: view
    property var scores:[]
    property var boards:[]
    property string style: {
        var thisTheme = DB.getTheme()
        console.log(thisTheme.value)
        if (thisTheme === undefined ) {
            DB.setTheme("picasso")
            Mah.setTheme("picasso")
            return "picasso"
        } else {
            return thisTheme.value
        }
}
    allowedOrientations: Orientation.All
    SilicaFlickable {
        anchors.fill: parent
        PageHeader {
            title: qsTr("Mah Solitaire")
        }
        PullDownMenu {
            id: mainPulleyMenu
            MenuItem {
                text: qsTr("About")
                visible: ! parent.profilePage
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"), {})
                }
            }
            MenuItem {
                text: qsTr("WebView")
                visible: ! parent.profilePage
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("WebView.qml"), {})
                }
            }

        }
        SectionHeader {
                text: qsTr("Select Style")
                anchors.bottom: selectSection.top
        }
        Column {
            id: selectSection
            anchors.centerIn: parent
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: 320

            BackgroundItem {
                id:thOne
                contentHeight: 320
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("picasso.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    DB.setTheme("picasso")
                    view.style = "picasso"
                    Mah.setTheme("picasso")
                    pageStack.push("Select.qml",{boards: view.boards,scores:view.scores, theme:style})
                }
            }
            BackgroundItem {
                id:thTwo
                contentHeight: 320//Theme.itemSizeExtraLarge
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("classic.png")
                    fillMode: Image.PreserveAspectCrop

                }
                onClicked: {
                    DB.setTheme("classic")
                    view.style = "classic"
                    Mah.setTheme("classic")
                    pageStack.push("Select.qml",{boards: view.boards,scores:view.scores, theme:style})
                }
            }
            BackgroundItem {
                id:thThree
                contentHeight: 320//Theme.itemSizeExtraLarge
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("recri.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    DB.setTheme("recri")
                    view.style = "recri"
                    Mah.setTheme("recri")
                    pageStack.push("Select.qml",{boards: view.boards,scores:view.scores, theme:style})
                }
            }
            BackgroundItem {
                id:thFour
                //contentHeight: Theme.itemSizeExtraLarge

                Button {
                    width: parent.width
                    text: qsTr("Play")
                    onClicked: pageStack.push("Select.qml",{boards: view.boards,scores:view.scores})
                }
            }

        }
    }


    Component.onCompleted: {// Load all board definitions from assets/data/boards.json.
        function loadBoards() {
            var response;
            var out = []
            Mah.loadJSON("../mah/assets/data/boards.json", function(doc) {
                response = JSON.parse(doc.responseText);
                for (var i = 0; i < response.length ; i++) {
                    boards[i] = response[i];
                };
            });
        }
        loadBoards()
        scores = DB.loadScores()
    }
}
