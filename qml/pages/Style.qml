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
    //allowedOrientations: Orientation.All
    // nah, it just confuses the issue

    Timer {
        id: pushTimer
        interval: 1000
        repeat: false
        onTriggered: {
           DB.setTheme(t)
           pageStack.pop()
            //pageStack.push("Select.qml", {boards: view.boards, scores: view.scores, theme: t})
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
            BusyLabel {
                id:busyLabel
               text:qsTr("Current: ") + style
            }
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
                Label {
                    text: "Picasso"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - ( 4 * Theme.paddingLarge )
                    source: Qt.resolvedUrl("picasso.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    style = "picasso"
                    busyLabel.text = qsTr("Set to: ") + style
                    busy.running = true
                    pushTimer.start()
                }
            }
            BackgroundItem {
                id:thTwo
                contentHeight: 300//Theme.itemSizeExtraLarge
                Label {
                    text: "Classic"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - ( 4 * Theme.paddingLarge )
                    source: Qt.resolvedUrl("classic.png")
                    fillMode: Image.PreserveAspectCrop

                }
                onClicked: {
                    style = "classic"
                    busyLabel.text = qsTr("Set to: ") + style
                    busy.running = true
                    pushTimer.start()
                }
            }
            BackgroundItem {
                id:thThree
                contentHeight: 300//Theme.itemSizeExtraLarge
                Label {
                    text: "Recri"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    width: parent.width - ( 4 * Theme.paddingLarge )
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: Qt.resolvedUrl("recri.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    style = "recri"
                    busyLabel.text = qsTr("Set to: ") + style
                    busy.running = true
                    pushTimer.start()
                }
            }
            BackgroundItem {
                id:thFour
                contentHeight: 300//Theme.itemSizeExtraLarge
                Label {
                    text: "Cheshire"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    width: parent.width - ( 4 * Theme.paddingLarge )
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: Qt.resolvedUrl("cheshire137.png")
                    fillMode: Image.PreserveAspectCrop
                }
                onClicked: {
                    style = "cheshire137"
                    busyLabel.text = qsTr("Set to: ") + "Chesire"
                    busy.running = true
                    pushTimer.start()
                }
            }
            /*
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
            }*/

        }
    }

    onStatusChanged: {
            busy.running = false
    }


}
