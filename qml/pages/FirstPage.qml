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

    // Which Select push to perform once the "Loading..." label has painted.
    // "" = idle; "play" = plain push; otherwise the theme name.
    property string pendingTheme: ""

    // A synchronous pageStack.push never leaves a render pass to paint the
    // busy label before the transition covers the page, so the label only
    // appears near the end of the push. Deferring the push by one beat lets
    // the label paint first (and also absorbs fast double-taps into one push).
    Timer {
        id: pushTimer
        interval: 150
        repeat: false
        onTriggered: {
            var t = view.pendingTheme
            view.pendingTheme = ""
            if (t === "play") {
                pageStack.push("Select.qml", {boards: view.boards, scores: view.scores})
            } else if (t !== "") {
                DB.setTheme(t)
                pageStack.push("Select.qml", {boards: view.boards, scores: view.scores, theme: t})
            }
        }
    }


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
            id: header
                text: qsTr("Select Style")
                anchors.bottom: selectSection.top
        }
        BusyIndicator {
            z:10
            id:busy
            running:  false
            anchors.bottom:header.top
            anchors.left:header.left
            size: BusyIndicatorSize.Large
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
                    busy.running = true
                    view.pendingTheme = "picasso"
                    pushTimer.start()
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
                    busy.running = true
                    view.pendingTheme = "classic"
                    pushTimer.start()
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
                    view.pendingTheme = "recri"
                    pushTimer.start()
                }
            }
            BackgroundItem {
                id:thFour
                //contentHeight: Theme.itemSizeExtraLarge

                Button {
                    width: parent.width
                    text: qsTr("Play")
                    onClicked: {
                        busy.running = true
                        view.pendingTheme = "play"
                        pushTimer.start()
                    }
                }
            }

        }
    }

    onStatusChanged: {
            busy.running = false
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
