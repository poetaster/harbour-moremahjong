import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Page {
    id:view
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        /* Sadly this ruins the layout
    *      PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("About.qml"),{});
                }
            }
        }*/
        WebView {
            /* This will probably be required from 4.4 on. */
            Component.onCompleted: {
                //WebEngineSettings.setPreference("security.disable_cors_checks", true, WebEngineSettings.BoolPref)
                WebEngineSettings.setPreference("security.fileuri.strict_origin_policy", false, WebEngineSettings.BoolPref)
            }
            id: webView
            anchors.fill: parent
            url: "../mah/index.html"
        }

    }

}
