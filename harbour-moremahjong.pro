# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-moremahjong
CONFIG += sailfishapp_qml

PKGCONFIG += qt5embedwidget

DISTFILES += \
    qml/cover/CoverPage.qml \
    qml/harbour-moremahjong.qml \
    qml/pages/About.qml \
    qml/pages/FirstPage.qml \
    qml/mah/* \
    qml/mah/assets/* \
    qml/mah/assets/sounds/* \
    qml/mah/assets/app/* \
    qml/mah/assets/data/* \
    qml/mah/assets/svg/* \
    qml/mah/assets/svg/*/* \
    qml/mah/assets/img/* \
    rpm/harbour-moremahjong.changes.in \
    rpm/harbour-moremahjong.changes.run \
    rpm/harbour-moremahjong.spec \
    translations/*.ts \
    harbour-morekmahjong.png \
    harbour-moremahjong.desktop \

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
# CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
# TRANSLATIONS += translations/harbour-greenmahjong-de.ts
