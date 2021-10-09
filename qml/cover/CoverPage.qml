

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        id: spacer
    }
    /*Label {
        anchors.horizontalCenter: parent.horizontalCenter
        id: label
        text: qsTr("Mah Solitaire")
    }*/
    Image {
        id:mahImage
        anchors.centerIn: parent
        source: "/usr/share/icons/hicolor/128x128/apps/harbour-moremahjong.png"
    }

    CoverActionList {
        id: coverAction
       /*
        CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }
        */
    }
}


