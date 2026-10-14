import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: mainWindow
    visible:      !airPodsTrayApp.hideOnStart
    width:  400
    height: airPodsTrayApp.airpodsConnected ? 540 : 310
    title:  "LibrePods"
    objectName: "mainWindowObject"
    flags:  Qt.FramelessWindowHint | Qt.Window
    color:  "transparent"

    Behavior on height {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    // Window position: restored from C++ QSettings on startup, saved after moving
    Component.onCompleted: {
        var pos = airPodsTrayApp.savedWindowPos()
        if (pos.x !== -1) { mainWindow.x = pos.x; mainWindow.y = pos.y }
    }
    onXChanged: savePosTimer.restart()
    onYChanged: savePosTimer.restart()

    // Debounce: persist the position once the window has stopped moving
    Timer {
        id: savePosTimer
        interval: 500
        onTriggered: airPodsTrayApp.saveWindowPos(mainWindow.x, mainWindow.y)
    }

    palette.window:          "#1C1C1E"
    palette.base:            "#2C2C2E"
    palette.alternateBase:   "#3A3A3C"
    palette.text:            "#FFFFFF"
    palette.button:          "#3A3A3C"
    palette.buttonText:      "#FFFFFF"
    palette.highlight:       "#0A84FF"
    palette.highlightedText: "#FFFFFF"
    palette.placeholderText: "#636366"

    onClosing: mainWindow.visible = false

    // Keys cannot be attached to a Window, use a Shortcut instead
    Shortcut {
        sequence: "Escape"
        onActivated: mainWindow.visible = false
    }

    function reopen(pageToLoad) {
        if (pageToLoad === "settings") {
            if (stackView.depth === 1) stackView.push(settingsComp)
        } else {
            while (stackView.depth > 1) stackView.pop(null, StackView.Immediate)
        }
        if (!mainWindow.visible) {
            mainCard.opacity = 0
            mainCard.scale   = 0.93
            mainWindow.show()
        }
        mainWindow.raise()
        mainWindow.requestActivate()
    }

    onVisibleChanged: {
        if (visible) {
            mainCard.opacity = 0
            mainCard.scale   = 0.93
            appearAnim.start()
        }
    }

    FontLoader {
        id: iconFont
        source: "qrc:/icons/assets/fonts/SF-Symbols-6.ttf"
    }

    // Drop shadow
    Rectangle {
        anchors.fill:      mainCard
        anchors.margins:   -10
        anchors.topMargin: 6
        radius:  mainCard.radius + 10
        color:   Qt.rgba(0, 0, 0, 0.5)
        z:       mainCard.z - 1
        opacity: mainCard.opacity
    }

    Rectangle {
        id: mainCard
        anchors.fill:    parent
        anchors.margins: 14
        radius:  20
        color:   "#1C1C1E"

        ParallelAnimation {
            id: appearAnim
            NumberAnimation { target: mainCard; property: "opacity"; to: 1.0; duration: 200 }
            NumberAnimation { target: mainCard; property: "scale";   to: 1.0; duration: 350
                              easing.type: Easing.OutBack; easing.overshoot: 0.35 }
        }

        // ── Fixed header (outside StackView so dragging always works) ───────
        Item {
            id: fixedHeader
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 52

            // Drag via startSystemMove (works on X11 and Wayland)
            DragHandler {
                target: null
                onActiveChanged: if (active) mainWindow.startSystemMove()
            }

            // Left button: × on main page, ← on settings page
            RoundButton {
                anchors.left:           parent.left
                anchors.leftMargin:     12
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28
                background: Rectangle {
                    radius: width / 2
                    color:  Qt.rgba(1, 1, 1, 0.10)
                }
                contentItem: Text {
                    text:       stackView.depth > 1 ? "" : "✕"
                    color:      "#8E8E93"
                    font.family:    stackView.depth > 1 ? iconFont.name : ""
                    font.pixelSize: stackView.depth > 1 ? 18 : 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                onClicked: {
                    if (stackView.depth > 1) stackView.pop()
                    else mainWindow.visible = false
                }
            }

            // Title (device name or current page)
            Text {
                anchors.centerIn: parent
                text: stackView.depth > 1
                      ? qsTr("Settings")
                      : ((airPodsTrayApp.airpodsConnected && airPodsTrayApp.deviceInfo.deviceName !== "")
                          ? airPodsTrayApp.deviceInfo.deviceName
                          : "LibrePods")
                color: "#FFFFFF"
                font.pixelSize: 17
                font.weight:    Font.DemiBold
                font.family:    "Inter"
            }

            // ⚙ button (main page only)
            RoundButton {
                visible: stackView.depth === 1
                anchors.right:          parent.right
                anchors.rightMargin:    12
                anchors.verticalCenter: parent.verticalCenter
                width: 32; height: 32
                background: Rectangle {
                    radius: width / 2
                    color:  Qt.rgba(1, 1, 1, 0.08)
                }
                contentItem: Text {
                    text: "菱"
                    color: "#8E8E93"
                    font.family:    iconFont.name
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                onClicked: stackView.push(settingsComp)
            }
        }

        Rectangle {
            id: headerSep
            anchors.top:         fixedHeader.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  16
            anchors.rightMargin: 16
            height: 1
            color:  Qt.rgba(1, 1, 1, 0.08)
        }

        StackView {
            id: stackView
            anchors.top:    headerSep.bottom
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            initialItem:    mainComp

            pushEnter: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                NumberAnimation { property: "x"; from: 30; to: 0; duration: 220; easing.type: Easing.OutCubic }
            }
            pushExit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 } }
            popEnter:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            popExit:   Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
                NumberAnimation { property: "x"; from: 0; to: 30; duration: 200; easing.type: Easing.InCubic }
            }
        }
    }

    // Mouse navigation (back button)
    MouseArea {
        anchors.fill:    parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: mouse => { if (mouse.button === Qt.BackButton && stackView.depth > 1) stackView.pop() }
    }

    // Case lid popup
    Loader {
        id: casePopupLoader
        source: "CaseOpenPopup.qml"
        asynchronous: true
    }

    Connections {
        target: airPodsTrayApp
        function onCaseLidOpened() {
            if (!casePopupLoader.item) return
            var p = casePopupLoader.item
            p.modelName        = airPodsTrayApp.bleLidModelName
            p.podImageSource   = airPodsTrayApp.bleLidPodIcon !== ""
                                 ? "qrc:/icons/assets/" + airPodsTrayApp.bleLidPodIcon : ""
            p.leftBattery      = airPodsTrayApp.bleLidLeftBattery
            p.rightBattery     = airPodsTrayApp.bleLidRightBattery
            p.caseBatteryLevel = airPodsTrayApp.bleLidCaseBattery
            p.leftCharging     = airPodsTrayApp.bleLidLeftCharging
            p.rightCharging    = airPodsTrayApp.bleLidRightCharging
            p.caseCharging     = airPodsTrayApp.bleLidCaseCharging
            p.showPopup(mainWindow.screen)
        }
    }

    // =========================================================================
    // MAIN PAGE
    // =========================================================================
    Component {
        id: mainComp
        Item {
            ScrollView {
                id: mainScrollView
                anchors.fill: parent
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: mainScrollView.availableWidth
                    spacing: 12
                    topPadding: 8
                    bottomPadding: 16

                    // Connection state
                    Item {
                        visible: !airPodsTrayApp.airpodsConnected
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:  elsewhereRow.visible ? elsewhereRow.width : disconnectedPill.width
                        height: 26

                        // "Not connected" badge
                        Rectangle {
                            id: disconnectedPill
                            visible: !airPodsTrayApp.bleAirPodsElsewhere
                            anchors.centerIn: parent
                            width: 140; height: 26; radius: 13
                            color: "#FF453A"
                            Text {
                                anchors.centerIn: parent
                                text:  qsTr("Not Connected")
                                color: "white"
                                font.pixelSize: 12
                                font.weight:    Font.Medium
                                font.family:    "Inter"
                            }
                        }

                        // "In use elsewhere" badge + Take Over button
                        Row {
                            id: elsewhereRow
                            visible: airPodsTrayApp.bleAirPodsElsewhere
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                height: 26; radius: 13
                                width: elsewhereLabel.implicitWidth + 20
                                color: "#FF9F0A"
                                Text {
                                    id: elsewhereLabel
                                    anchors.centerIn: parent
                                    text:  qsTr("Playing on another device")
                                    color: "white"
                                    font.pixelSize: 12
                                    font.weight:    Font.Medium
                                    font.family:    "Inter"
                                }
                            }

                            Rectangle {
                                height: 26; radius: 13
                                width: takeOverLabel.implicitWidth + 20
                                color: "#0A84FF"
                                Text {
                                    id: takeOverLabel
                                    anchors.centerIn: parent
                                    text:  qsTr("Take Over")
                                    color: "white"
                                    font.pixelSize: 12
                                    font.weight:    Font.Medium
                                    font.family:    "Inter"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: airPodsTrayApp.takeOverAudio()
                                }
                            }
                        }
                    }

                    // Images + battery rings (PodColumn = image + ring)
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        PodColumn {
                            visible:      airPodsTrayApp.deviceInfo.battery.leftPodAvailable
                            iconSource:   "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.podIcon
                            batteryLevel: airPodsTrayApp.deviceInfo.battery.leftPodLevel
                            isCharging:   airPodsTrayApp.deviceInfo.battery.leftPodCharging
                            indicator:    "L"
                            inEar:        airPodsTrayApp.deviceInfo.leftPodInEar
                        }
                        PodColumn {
                            visible:      airPodsTrayApp.deviceInfo.battery.rightPodAvailable
                            iconSource:   "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.podIcon
                            batteryLevel: airPodsTrayApp.deviceInfo.battery.rightPodLevel
                            isCharging:   airPodsTrayApp.deviceInfo.battery.rightPodCharging
                            indicator:    "R"
                            inEar:        airPodsTrayApp.deviceInfo.rightPodInEar
                        }
                        PodColumn {
                            visible:      airPodsTrayApp.deviceInfo.battery.caseAvailable
                            iconSource:   "qrc:/icons/assets/" + airPodsTrayApp.deviceInfo.caseIcon
                            batteryLevel: airPodsTrayApp.deviceInfo.battery.caseLevel
                            isCharging:   airPodsTrayApp.deviceInfo.battery.caseCharging
                            indicator:    ""
                            inEar:        true
                        }
                        PodColumn {
                            visible:      airPodsTrayApp.deviceInfo.battery.headsetAvailable
                            iconSource:   "qrc:/icons/assets/airpods.png"
                            batteryLevel: airPodsTrayApp.deviceInfo.battery.headsetLevel
                            isCharging:   airPodsTrayApp.deviceInfo.battery.headsetCharging
                            indicator:    "H"
                            inEar:        true
                        }
                    }

                    // Noise control card
                    Rectangle {
                        visible: airPodsTrayApp.airpodsConnected
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: ancCardCol.implicitHeight + 24
                        radius: 14
                        color:  "#2C2C2E"

                        Column {
                            id: ancCardCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 10

                            Text {
                                text:  qsTr("Noise Control")
                                color: "#8E8E93"
                                font.pixelSize: 12
                                font.weight:    Font.Medium
                                font.family:    "Inter"
                            }

                            SegmentedControl {
                                id: ancControl
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                model: [qsTr("Off"), qsTr("ANC"), qsTr("Transparent"), qsTr("Adaptive")]
                                onCurrentIndexChanged: airPodsTrayApp.setNoiseControlModeInt(currentIndex)
                                Component.onCompleted: currentIndex = airPodsTrayApp.deviceInfo.noiseControlMode
                            }

                            Connections {
                                target: airPodsTrayApp.deviceInfo
                                function onNoiseControlModeChangedInt(mode) {
                                    if (ancControl.currentIndex !== mode) ancControl.currentIndex = mode
                                }
                            }

                            // Adaptive level slider
                            Column {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                visible: airPodsTrayApp.deviceInfo.adaptiveModeActive
                                spacing: 6

                                Item {
                                    anchors.left:  parent.left
                                    anchors.right: parent.right
                                    height: 18
                                    Text {
                                        anchors.left:           parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text:  qsTr("Adaptive Level")
                                        color: "#8E8E93"
                                        font.pixelSize: 12
                                        font.family:    "Inter"
                                    }
                                    Text {
                                        anchors.right:          parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text:  adaptiveSlider.value
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.weight:    Font.DemiBold
                                        font.family:    "Inter"
                                    }
                                }

                                Slider {
                                    id: adaptiveSlider
                                    anchors.left:  parent.left
                                    anchors.right: parent.right
                                    from: 0; to: 100; stepSize: 1
                                    value: airPodsTrayApp.deviceInfo.adaptiveNoiseLevel

                                    background: Rectangle {
                                        y: adaptiveSlider.topPadding + adaptiveSlider.availableHeight / 2 - height / 2
                                        height: 4; radius: 2; color: "#3A3A3C"
                                        Rectangle {
                                            width:  adaptiveSlider.visualPosition * parent.width
                                            height: parent.height; radius: 2; color: "#0A84FF"
                                        }
                                    }
                                    handle: Rectangle {
                                        x: adaptiveSlider.leftPadding + adaptiveSlider.visualPosition * (adaptiveSlider.availableWidth - width)
                                        y: adaptiveSlider.topPadding  + adaptiveSlider.availableHeight / 2 - height / 2
                                        width: 26; height: 26; radius: 13; color: "white"
                                    }

                                    Timer {
                                        id: adaptiveDebounce
                                        interval: 500
                                        onTriggered: if (!adaptiveSlider.pressed) airPodsTrayApp.setAdaptiveNoiseLevel(adaptiveSlider.value)
                                    }
                                    onPressedChanged: if (!pressed) airPodsTrayApp.setAdaptiveNoiseLevel(value)
                                    onValueChanged:   if (pressed)  adaptiveDebounce.restart()
                                }
                            }
                        }
                    }

                    // Options card
                    Rectangle {
                        visible: airPodsTrayApp.airpodsConnected
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: optCol.implicitHeight + 24
                        radius: 14
                        color:  "#2C2C2E"

                        Column {
                            id: optCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 0

                            Text {
                                text:  qsTr("Options")
                                color: "#8E8E93"
                                font.pixelSize: 12
                                font.weight:    Font.Medium
                                font.family:    "Inter"
                                bottomPadding:  6
                            }

                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Conversational Awareness")
                                checked: airPodsTrayApp.deviceInfo.conversationalAwareness
                                onToggled: airPodsTrayApp.setConversationalAwareness(!checked)
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1
                                color:  Qt.rgba(1, 1, 1, 0.07)
                            }
                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Hearing Aid")
                                checked: airPodsTrayApp.deviceInfo.hearingAidEnabled
                                onToggled: airPodsTrayApp.setHearingAidEnabled(!checked)
                            }
                        }
                    }

                }
            }
        }
    }

    // =========================================================================
    // SETTINGS PAGE
    // =========================================================================
    Component {
        id: settingsComp
        Page {
            background: Rectangle { color: "transparent" }

            ScrollView {
                id: settingsScrollView
                anchors.fill: parent
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: settingsScrollView.availableWidth
                    spacing: 12
                    topPadding: 8
                    bottomPadding: 20

                    // PLAYBACK
                    Text {
                        anchors.left:       parent.left
                        anchors.leftMargin: 20
                        text:  qsTr("PLAYBACK")
                        color: "#636366"
                        font.pixelSize: 12
                        font.weight:    Font.Medium
                        font.family:    "Inter"
                    }
                    Rectangle {
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: pauseCol.implicitHeight + 24
                        radius: 14; color: "#2C2C2E"
                        Column {
                            id: pauseCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 8
                            Text {
                                text:  qsTr("Pause when AirPods removed:")
                                color: "#8E8E93"
                                font.pixelSize: 12
                                font.family:    "Inter"
                            }
                            ComboBox {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                                currentIndex: airPodsTrayApp.earDetectionBehavior
                                onActivated:  airPodsTrayApp.earDetectionBehavior = currentIndex
                            }
                        }
                    }

                    // CONNECTIVITY
                    Text {
                        anchors.left:       parent.left
                        anchors.leftMargin: 20
                        text:  qsTr("CONNECTIVITY")
                        color: "#636366"
                        font.pixelSize: 12
                        font.weight:    Font.Medium
                        font.family:    "Inter"
                    }
                    Rectangle {
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: connCol.implicitHeight + 24
                        radius: 14; color: "#2C2C2E"
                        Column {
                            id: connCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 0

                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Cross-Device (Android)")
                                checked: airPodsTrayApp.crossDeviceEnabled
                                onToggled: airPodsTrayApp.setCrossDeviceEnabled(!checked)
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }

                            Item {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 44
                                Text {
                                    anchors.left:           parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:  qsTr("BT Retry Attempts")
                                    color: "#FFFFFF"
                                    font.pixelSize: 16
                                    font.family:    "Inter"
                                }
                                SpinBox {
                                    anchors.right:          parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 1; to: 10
                                    value: airPodsTrayApp.retryAttempts
                                    onValueChanged: airPodsTrayApp.retryAttempts = value
                                }
                            }
                        }
                    }

                    // GENERAL
                    Text {
                        anchors.left:       parent.left
                        anchors.leftMargin: 20
                        text:  qsTr("GENERAL")
                        color: "#636366"
                        font.pixelSize: 12
                        font.weight:    Font.Medium
                        font.family:    "Inter"
                    }
                    Rectangle {
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: genCol.implicitHeight + 24
                        radius: 14; color: "#2C2C2E"
                        Column {
                            id: genCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 0

                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Auto-Start on Login")
                                checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                                onToggled: airPodsTrayApp.autoStartManager.autoStartEnabled = !checked
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }
                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("System Notifications")
                                checked: airPodsTrayApp.notificationsEnabled
                                onToggled: airPodsTrayApp.notificationsEnabled = !checked
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }
                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Popup on Case Open")
                                checked: airPodsTrayApp.showCasePopupEnabled
                                onToggled: airPodsTrayApp.showCasePopupEnabled = !checked
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }
                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("Auto-Switch when playing")
                                checked: airPodsTrayApp.autoSwitchEnabled
                                onToggled: airPodsTrayApp.autoSwitchEnabled = !checked
                            }
                        }
                    }

                    // DEVICE (when connected)
                    Text {
                        visible: airPodsTrayApp.airpodsConnected
                        anchors.left:       parent.left
                        anchors.leftMargin: 20
                        text:  qsTr("DEVICE")
                        color: "#636366"
                        font.pixelSize: 12
                        font.weight:    Font.Medium
                        font.family:    "Inter"
                    }
                    Rectangle {
                        visible: airPodsTrayApp.airpodsConnected
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: devCol.implicitHeight + 24
                        radius: 14; color: "#2C2C2E"
                        Column {
                            id: devCol
                            anchors.left:    parent.left
                            anchors.right:   parent.right
                            anchors.top:     parent.top
                            anchors.margins: 14
                            spacing: 0

                            IOSSwitch {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                text:    qsTr("One Bud ANC Mode")
                                checked: airPodsTrayApp.deviceInfo.oneBudANCMode
                                onToggled: airPodsTrayApp.deviceInfo.oneBudANCMode = !checked
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }

                            Column {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                spacing: 6
                                topPadding:    10
                                bottomPadding: 6
                                Text {
                                    text:  qsTr("Rename AirPods")
                                    color: "#8E8E93"
                                    font.pixelSize: 12
                                    font.family:    "Inter"
                                }
                                Row {
                                    anchors.left:  parent.left
                                    anchors.right: parent.right
                                    spacing: 8
                                    TextField {
                                        id: newNameField
                                        width: parent.width - renameBtn.implicitWidth - 8
                                        placeholderText: airPodsTrayApp.deviceInfo.deviceName
                                        maximumLength: 32
                                        color: "white"; placeholderTextColor: "#636366"
                                        background: Rectangle { color: "#3A3A3C"; radius: 8 }
                                    }
                                    Button {
                                        id: renameBtn
                                        text: qsTr("Rename")
                                        onClicked: airPodsTrayApp.renameAirPods(newNameField.text)
                                        background: Rectangle { color: parent.pressed ? "#0060CC" : "#0A84FF"; radius: 8 }
                                        contentItem: Text {
                                            text: parent.text; color: "white"; font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment:   Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                height: 1; color: Qt.rgba(1, 1, 1, 0.07)
                            }

                            Column {
                                anchors.left:  parent.left
                                anchors.right: parent.right
                                spacing: 6
                                topPadding:    10
                                bottomPadding: 6
                                Text {
                                    text:  qsTr("Phone MAC Address")
                                    color: "#8E8E93"
                                    font.pixelSize: 12
                                    font.family:    "Inter"
                                }
                                Row {
                                    anchors.left:  parent.left
                                    anchors.right: parent.right
                                    spacing: 8
                                    TextField {
                                        id: newPhoneMacField
                                        width: parent.width - macBtn.implicitWidth - 8
                                        placeholderText: (PHONE_MAC_ADDRESS !== "" ? PHONE_MAC_ADDRESS : "00:00:00:00:00:00")
                                        maximumLength: 32
                                        color: "white"; placeholderTextColor: "#636366"
                                        background: Rectangle { color: "#3A3A3C"; radius: 8 }
                                    }
                                    Button {
                                        id: macBtn
                                        text: qsTr("Set MAC")
                                        onClicked: airPodsTrayApp.setPhoneMac(newPhoneMacField.text)
                                        background: Rectangle { color: parent.pressed ? "#0060CC" : "#0A84FF"; radius: 8 }
                                        contentItem: Text {
                                            text: parent.text; color: "white"; font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment:   Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // QR Code
                    Button {
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  16
                        anchors.rightMargin: 16
                        height: 44
                        text: qsTr("Show Magic Cloud Keys QR")
                        onClicked: keysQrDialog.show()
                        background: Rectangle { color: parent.pressed ? "#2C2C2E" : "#3A3A3C"; radius: 12 }
                        contentItem: Text {
                            text: parent.text; color: "#0A84FF"; font.pixelSize: 15; font.family: "Inter"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                    }

                    KeysQRDialog {
                        id: keysQrDialog
                        encKey: airPodsTrayApp.deviceInfo.magicAccEncKey
                        irk:    airPodsTrayApp.deviceInfo.magicAccIRK
                    }

                }
            }
        }
    }

}
