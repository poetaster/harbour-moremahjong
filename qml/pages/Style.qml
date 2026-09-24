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
           DB.setTheme(style)
           pageStack.pop()
            //pageStack.push("Select.qml", {boards: view.boards, scores: view.scores, theme: t})
        }
    }


    SilicaFlickable {
        anchors.fill: parent
        PageHeader {
            id:header
           title: qsTr("Select Style")
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
            y:280
            x:20
            id: selectSection
            width: parent.width - (  Theme.paddingLarge )
            spacing: Theme.paddingLarge

            BackgroundItem {
                width: parent.width
                height: thOneL.height + thOneI.height
                id:thOne

                Label {
                    id:thOneL
                    anchors.bottom:thOneI.top
                    width: parent.width - (  Theme.paddingLarge )
                    text: "Picasso"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    id:thOneI
                    anchors.top:thOneL.bottom // redundant anchors?
                    width: parent.width - (  Theme.paddingLarge )
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
                width: parent.width
                height: thTwoL.height + thTwoI.height
                Label {
                    id:thTwoL
                    anchors.bottom:thTwoI.top
                    width: parent.width - (  Theme.paddingLarge )
                    text: "Classic"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Image {
                    id:thTwoI
                    anchors.top:thTwoL.bottom
                    width: parent.width - (  Theme.paddingLarge )
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
                width: parent.width
                height: thThreeL.height + thThreeI.height
                Label {
                    id:thThreeL
                    width: parent.width - (  Theme.paddingLarge )
                    anchors.bottom:thThreeI.top
                    text: "Recri"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    id:thThreeI
                    anchors.top:thThreeL.bottom
                    width: parent.width - (  Theme.paddingLarge )
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
                height: thFourL.height + thFourI.height
                width: parent.width
                Label {
                    id:thFourL
                    width: parent.width - (  Theme.paddingLarge )
                    anchors.bottom:thFourI.top
                    text: "Cheshire"
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Image {
                    id:thFourI
                    anchors.top:thFourL.bottom
                    width: parent.width - (  Theme.paddingLarge )
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

        }
    }

    onStatusChanged: {
            busy.running = false
    }


}
