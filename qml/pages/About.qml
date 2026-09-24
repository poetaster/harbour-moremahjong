import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: page

    Column {
        id: column
        //anchors.fill: parent
        x: 3 * Theme.paddingLarge
        width: parent.width - (5 * Theme.paddingLarge )
        spacing: Theme.paddingLarge

        PageHeader {
            title: qsTr("Mah Solitaire")
        }
        Item {
            width: 1
            height: 3 * Theme.paddingLarge
        }
        Label {
            anchors.top: mahImage.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            id: label
            text: qsTr("Mah Solitaire") + " 2.0.2"
        }

        Label {
            text: qsTr("Based on") + "<a href=\"https://ffalt.github.io/mah\"> mah ffalt.github.io</a>"
            color: Theme.primaryColor
            wrapMode: TextEdit.WordWrap
            width: parent.width
            onLinkActivated: {
                Qt.openUrlExternally(link)
            }
            linkColor: Theme.highlightColor
        }

        Item {
            width: 1
            height: 3 * Theme.paddingLarge
        }

        Label {
            color: Theme.primaryColor
            linkColor: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
            width: parent.width
            text: "<a href=\"https://github.com/poetaster/harbour-moremahjong\">Source: github</a>" +
                  "\n © 2021 - 2026 Mark Washeim \n" +
                  qsTr("MIT license.")
            onLinkActivated: {
                Qt.openUrlExternally(link)
            }
        }
        Label {
            color: Theme.primaryColor
            linkColor: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
            width: parent.width
            text:  'gleitz theme  based on images from \n https://github.com/gleitz/mahjong/tree/master/public/img/tiles \n' +
                   'MIT https://github.com/gleitz/mahjong/blob/master/LICENSE \n' +
                   'by https://github.com/gleitz'
            onLinkActivated: {
                Qt.openUrlExternally(link)
            }
        }

        Label {
            color: Theme.primaryColor
            linkColor: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
            width: parent.width
            text:    "<a href=\"https://github.com/recri\">recri</a> "+
                     "images come from https://github.com/recri/mahjong \n"
            onLinkActivated: {
                Qt.openUrlExternally(link)
            }
        }
        Label {
            color: Theme.primaryColor
            linkColor: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
            width: parent.width
            text: "picasso.svg classic.svg modern.svg \n" +
                  "based on images from <a href=\"http://star.physics.yale.edu/~ullrich/software/SolitaireMahjong/\"> picasso </a> \n" +
                  "GNU General Public License 3 http://www.gnu.org/licenses/  by Thomas S. Ullrich"
            onLinkActivated: {
                Qt.openUrlExternally(link)
            }
        }

    } // Column
}






