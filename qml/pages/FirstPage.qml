import QtQuick 2.0
import Sailfish.Silica 1.0
import QtWebKit 3.0

Page {
    id:view
    allowedOrientations: Orientation.Landscape

    /*onStatusChanged: {
        if (PageStatus.Activating) {
            //console.debug(webView.width)
            //console.debug(webView.height)
            if (listModel.count < 1) {
                    page.reloadStories();
                }
        }
    }*/
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"),{});
                }
            }
        }
    //WebView { }
    WebView {
        id: webView
        anchors.fill: parent
        url: "../mah/index.html"
    }

    }

}
