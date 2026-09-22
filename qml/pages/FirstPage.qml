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
            spacing: 300

            BackgroundItem {
                id:thOne
                contentHeight: 300
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("picasso.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    busy.visible = true
                    DB.setTheme("picasso")
                    pageStack.push("Select.qml",{boards: view.boards,scores:view.scores, theme:style})
                }
            }
            BackgroundItem {
                id:thTwo
                contentHeight: 300//Theme.itemSizeExtraLarge
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("classic.png")
                    fillMode: Image.PreserveAspectCrop

                }
                onClicked: {
                    busy.visible = true
                    DB.setTheme("classic")
                    pageStack.push("Select.qml",{boards: view.boards,scores:view.scores, theme:style})
                }
            }
            BackgroundItem {
                id:thThree
                contentHeight: 300//Theme.itemSizeExtraLarge
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.paddingLarge
                    source: Qt.resolvedUrl("recri.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    busy.visible = true
                    DB.setTheme("recri")
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
            Label {
                id:busy
                visible:  false
                text: qsTr("Loading...")
            }

        }
    }

    onStatusChanged: {
            busy.visible = false
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
