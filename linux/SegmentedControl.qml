import QtQuick 2.15
import QtQuick.Controls 2.15

// iOS-style segmented control with a sliding pill indicator.
// Keyboard navigation: Left/Right arrows, Home/End, digit keys 1-9.
Control {
    id: root

    property var model:        ["Option 1", "Option 2"]
    property int currentIndex: 0

    focusPolicy: Qt.StrongFocus
    activeFocusOnTab: true

    implicitHeight: 36
    implicitWidth:  root.model.length * 90

    background: Rectangle {
        radius: height / 2
        color:  "#3A3A3C"
        border.width: root.activeFocus ? 1 : 0
        border.color: "#0A84FF"
    }

    contentItem: Item {
        anchors.fill: parent

        // ── Sliding pill ──────────────────────────────────────────────────────
        Rectangle {
            id: pill
            y: 2
            height: parent.height - 4
            width:  parent.width / root.model.length - 4
            x:      root.currentIndex * (parent.width / root.model.length) + 2
            radius: height / 2
            color:  "#636366"

            Behavior on x {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        // ── Segment labels + tap areas ────────────────────────────────────────
        Row {
            anchors.fill: parent

            Repeater {
                model: root.model

                Item {
                    required property int    index
                    required property string modelData

                    width:  root.width / root.model.length
                    height: root.height

                    Text {
                        anchors.centerIn: parent
                        text:  modelData
                        color: root.currentIndex === index ? "#FFFFFF" : "#8E8E93"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        font.family: "Inter"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.currentIndex = index
                    }
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left && root.currentIndex > 0) {
            root.currentIndex--; event.accepted = true
        } else if (event.key === Qt.Key_Right && root.currentIndex < root.model.length - 1) {
            root.currentIndex++; event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            root.currentIndex = 0; event.accepted = true
        } else if (event.key === Qt.Key_End) {
            root.currentIndex = root.model.length - 1; event.accepted = true
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            var i = event.key - Qt.Key_1
            if (i < root.model.length) { root.currentIndex = i; event.accepted = true }
        }
    }
}
