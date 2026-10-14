// AirPods case lid popup — top-right corner, slides in from the top, draggable.
// Wayland: if the compositor ignores window positioning, run with
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

    function showPopup(targetScreen) {
        var sc = targetScreen ? targetScreen : Qt.application.screens[0]
        popupWindow.screen = sc
        popupWindow.x = Math.round(sc.virtualX + sc.width - popupWindow.width - 16)
        popupWindow.y = sc.virtualY + 16
        popupWindow.opacity = 1
        popupWindow.show()
        popupWindow.raise()
        card.y = -popupWindow.height
        slideIn.restart()
        autoClose.restart()
        timerBar.restartBar()
    }

    // Soft shadow
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

    // Main card
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

        // Slide in from the top
        NumberAnimation {
            id: slideIn
            target: card; property: "y"
            to: 8; duration: 400
            easing.type: Easing.OutBack; easing.overshoot: 0.5
        }

        // Content
        Column {
            anchors.left:    parent.left
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: 14
            spacing: 10

            // Header: image + model name + × button
            Item {
                anchors.left:  parent.left
                anchors.right: parent.right
                height: 36

                // Model image (if available)
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

                // Model name
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

                // Close button
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

            // Three battery rings
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

        // Auto-close progress bar (bottom of the card)
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

        // Hover → pause the timer
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

        // Click on the card to close (a TapHandler, unlike a MouseArea, does not
        // grab the press, so the DragHandler above can still move the window)
        TapHandler {
            onTapped: fadeOut.start()
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
