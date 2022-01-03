import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - (2 * Theme.paddingLarge)
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Mah Solitaire")
            }
            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                wrapMode: Text.WrapWord
                text: ""
            }
            Label {
                anchors.centerIn: parent
                text: qsTr("Based on") + "\n https://ffalt.github.io/mah. \n " +
                                  "© 2021 Mark Washeim \n" +
                                  qsTr("MIT license.")
                color: Theme.primaryColor
                wrapMode: TextEdit.WordWrap
                width: parent.width
            }
            Label {
                width: parent.width - (2 * Theme.paddingLarge)
                wrapMode: Text.WrapWord
                text: ""
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.primaryColor
                linkColor: "#ffffff"
                wrapMode: TextEdit.WordWrap
                width: parent.width
                //font.pixelSize: units.fx("small")
                text: "<a href=\"https://github.com/poetaster/harbour-moremahjong\">Source: github</a>"
                onLinkActivated: {
                    //console.log("Opening external browser: " + link);
                    Qt.openUrlExternally(link)
                }
            }

        } // Column
    }
}






