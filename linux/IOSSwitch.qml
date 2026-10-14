import QtQuick 2.15

// iOS-style toggle.
// Usage:
//   IOSSwitch { checked: backend.prop; onToggled: backend.setter(!checked) }
// The component never mutates `checked` internally → the parent binding stays alive.
Item {
    id: root

    property bool   checked: false
    property string text:    ""
    property bool   enabled: true

    readonly property bool containsMouse: mouseArea.containsMouse

    signal toggled()

    implicitHeight: 44
    implicitWidth:  300
    opacity: root.enabled ? 1.0 : 0.45

    // ── Label ────────────────────────────────────────────────────────────────
    Text {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right:          track.left
        anchors.rightMargin:    12
        text:      root.text
        color:     "#FFFFFF"
        font.pixelSize: 16
        font.family:    "Inter"
        elide: Text.ElideRight
    }

    // ── Track ────────────────────────────────────────────────────────────────
    Rectangle {
        id: track
        width:  51
        height: 31
        radius: height / 2
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? "#30D158" : "#39393D"

        Behavior on color { ColorAnimation { duration: 180 } }

        // ── Thumb ─────────────────────────────────────────────────────────────
        Rectangle {
            id: thumb
            width:  27
            height: 27
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2
            color: "white"

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
    }

    // ── Interaction ──────────────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill:  parent
        enabled:       root.enabled
        hoverEnabled:  true
        onClicked:     root.toggled()
    }
}
