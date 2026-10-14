// Popup boîtier AirPods — haut-droite, glisse depuis le haut, draggable.
// Wayland : si le positionnement est ignoré par le compositeur, lancer avec
//   QT_QPA_PLATFORM=xcb librepods
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Window {
    id: popupWindow

    property string modelName:        "AirPods"
    property string podImageSource:   ""           // ex: "qrc:/icons/assets/podpro.png"
    property int    leftBattery:      0
    property int    rightBattery:     0
    property int    caseBatteryLevel: 0
    property bool   leftCharging:     false
    property bool   rightCharging:    false
    property bool   caseCharging:     false

    flags:  Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color:  "transparent"
    width:  320
    height: 185

    function showPopup() {
        var sc = Qt.application.screens[0]
        popupWindow.x = Math.round(sc.width  - popupWindow.width  - 16)
        popupWindow.y = 16
        popupWindow.opacity = 1
        popupWindow.show()
        popupWindow.raise()
        card.y = -popupWindow.height
        slideIn.restart()
        autoClose.restart()
        timerBar.restartBar()
    }

    // Ombre douce
    Rectangle {
        anchors.fill:      card
        anchors.margins:   -6
        anchors.topMargin: 2
        radius:   card.radius + 6
        color:    Qt.rgba(0, 0, 0, 0.40)
        z:        card.z - 1
        visible:  card.visible
        opacity:  card.opacity
    }

    // Carte principale
    Rectangle {
        id: card
        width:  parent.width  - 20
        height: parent.height - 16
        anchors.horizontalCenter: parent.horizontalCenter
        y: -parent.height
        radius: 18
        color:  "#2C2C2E"

        // Drag
        DragHandler {
            target: null
            onActiveChanged: if (active) popupWindow.startSystemMove()
        }

        // Glisse depuis le haut
        NumberAnimation {
            id: slideIn
            target: card; property: "y"
            to: 8; duration: 400
            easing.type: Easing.OutBack; easing.overshoot: 0.5
        }

        // Contenu
        Column {
            anchors.left:    parent.left
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: 14
            spacing: 10

            // Header : image + nom du modèle + bouton ×
            Item {
                anchors.left:  parent.left
                anchors.right: parent.right
                height: 36

                // Image du modèle (si disponible)
                Image {
                    id: podImg
                    source:   popupWindow.podImageSource
                    width:    36; height: 36
                    fillMode: Image.PreserveAspectFit
                    mipmap:   true
                    visible:  source !== ""
                    anchors.left:           parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Nom du modèle
                Text {
                    anchors.left:           podImg.visible ? podImg.right : parent.left
                    anchors.leftMargin:     podImg.visible ? 8 : 0
                    anchors.right:          closeBtn.left
                    anchors.rightMargin:    8
                    anchors.verticalCenter: parent.verticalCenter
                    text:  popupWindow.modelName
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.weight:    Font.DemiBold
                    font.family:    "Inter"
                    elide:          Text.ElideRight
                }

                // Bouton fermer
                RoundButton {
                    id: closeBtn
                    anchors.right:          parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22; height: 22
                    background: Rectangle {
                        radius: width / 2
                        color:  Qt.rgba(1, 1, 1, 0.12)
                    }
                    contentItem: Text {
                        text: "✕"; color: "#8E8E93"
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }
                    onClicked: fadeOut.start()
                    z: 2
                }
            }

            // Trois anneaux de batterie
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                BatteryRing {
                    batteryLevel: popupWindow.leftBattery
                    isCharging:   popupWindow.leftCharging
                    label: "L"
                }
                BatteryRing {
                    batteryLevel: popupWindow.rightBattery
                    isCharging:   popupWindow.rightCharging
                    label: "R"
                }
                BatteryRing {
                    batteryLevel: popupWindow.caseBatteryLevel
                    isCharging:   popupWindow.caseCharging
                    label: ""
                }
            }
        }

        // Barre de progression auto-close (en bas de la carte)
        Rectangle {
            id: timerBar
            anchors.bottom:      parent.bottom
            anchors.left:        parent.left
            anchors.leftMargin:  12
            anchors.rightMargin: 12
            anchors.bottomMargin: 6
            height: 3
            radius: 1.5
            color:  "#0A84FF"
            width:  parent.width - 24

            property real fullWidth: parent.width - 24

            function restartBar() {
                width = fullWidth
                shrink.restart()
            }

            NumberAnimation {
                id: shrink
                target: timerBar; property: "width"
                to: 0; duration: 5000
                easing.type: Easing.Linear
            }
        }

        // Hover → pause du timer
        HoverHandler {
            id: cardHover
            onHoveredChanged: {
                if (hovered) {
                    autoClose.stop()
                    shrink.pause()
                } else {
                    autoClose.restart()
                    shrink.resume()
                }
            }
        }

        // Clic sur fond pour fermer
        MouseArea {
            anchors.fill: parent
            onClicked: fadeOut.start()
            z: 1
        }
    }

    Timer {
        id: autoClose
        interval: 5000
        onTriggered: fadeOut.start()
    }

    SequentialAnimation {
        id: fadeOut
        NumberAnimation {
            target: popupWindow; property: "opacity"
            to: 0; duration: 280
        }
        ScriptAction {
            script: { popupWindow.hide(); popupWindow.opacity = 1 }
        }
    }
}
