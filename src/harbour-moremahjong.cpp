#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QGuiApplication>
#include <QLocale>
#include <QQuickView>
#include <QScopedPointer>
#include <QStandardPaths>
#include <QString>
#include <QStringList>
#include <QTranslator>
#include <QtQml>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QString>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <sailfishapp.h>

void migrateLocalStorage()
{

    // The new location of the LocalStorage database
    QDir newDbDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/de.poetaster/harbour-moremahjong/");
    QDir mozDbDir(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/de.poetaster/harbour-moremahjong/.mozilla");
    if(mozDbDir.exists())
        return;
    //newDbDir.mkpath(newDbDir.path());
    //QString pathOld = "/harbour-moremahjong/harbour-moremahjong/.mozilla/webappsstore.sqlite";
    //QString pathNew = "/de.poetaster/harbour-moremahjong/.mozilla/webappsstore.sqlite";
    QString pathOld = "/harbour-moremahjong/harbour-moremahjong/.mozilla";
    QString pathNew = "/de.poetaster/harbour-moremahjong/.mozilla";

    //QFile newDb(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +  pathNew );
    //newDb.remove();

    QFile oldDb(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +  pathOld );
    oldDb.rename(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) +  pathNew );

}

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/harbour-greenmahjong.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //   - SailfishApp::pathToMainQml() to get a QUrl to the main QML file
    //
    // To display the view, call "show()" (will show fullscreen on device).
   // migrateLocalStorage();
    return SailfishApp::main(argc, argv);
}
