import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0

Page {
    id:view
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
/*        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"),{});
                }
            }
        }*/
    //WebView { }
    WebView {
        id: webView
        anchors.fill: parent
        url: "../mah/index.html"
    }

    }

}
