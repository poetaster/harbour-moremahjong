import QtQuick 2.0
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
                title: "Simple Mahjong Solitaire"
            }
            Label {
                text: "Version 1.0.0, for Sailfish by poetaster, based on (C) Uwe Hoffmann 2018, Spinoff of Green-Mahjong, Copyright 2014, Daniel Beck and Karin Beck."
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
                text: "Contact the poetaster, <a href=\"mailto:blueprint@poetaster.de?subject=About%20Mahjong%20SailfishOS\">blueprint@poetaster.de</a>"
                color: Theme.primaryColor
                linkColor: "#ffffff"
                wrapMode: TextEdit.WordWrap
                width: parent.width
                font.pixelSize: units.fx("small")
                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
            Label {
                text: "Source code available in <a href=\"https://github.com/poetaster/harbour-hackernews\">github</a> under the terms of GPLv3 license."
                color: Theme.primaryColor
                linkColor: "#ffffff"
                wrapMode: TextEdit.WordWrap
                width: parent.width
                font.pixelSize: units.fx("small")
                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

        } // Column
    }
}






