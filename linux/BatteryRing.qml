import QtQuick 2.15

Item {
    id: root

    property int  batteryLevel: 0
    property bool isCharging:   false
    property string label: "L"   // "L", "R", "H" (headset), "" (case)

    implicitWidth:  72
    implicitHeight: 88

    readonly property bool   unknown:   root.batteryLevel < 0

    readonly property color ringColor: {
        if (isCharging)         return "#30D158"
        if (batteryLevel <= 20) return "#FF453A"
        if (batteryLevel <= 50) return "#FFD60A"
        return "#30D158"
    }

    // ── Background track ────────────────────────────────────────────────────
    Canvas {
        id: bgRing
        width: 60; height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = "#3A3A3C"
            ctx.lineWidth = 5
            ctx.beginPath()
            ctx.arc(width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI)
            ctx.stroke()
        }
    }

    // ── Progress arc ─────────────────────────────────────────────────────────
    Canvas {
        id: progressRing
        width: 60; height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        property real progress: 0

        Behavior on progress {
            NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
        }
        onProgressChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (progress <= 0) return
            ctx.strokeStyle = root.ringColor
            ctx.lineWidth = 5
            ctx.lineCap = "round"
            var start = -Math.PI / 2
            ctx.beginPath()
            if (progress >= 0.999) {
                ctx.arc(width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI)
            } else {
                ctx.arc(width / 2, height / 2, width / 2 - 5,
                        start, start + progress * 2 * Math.PI)
            }
            ctx.stroke()
        }
    }

    // ── Centre: percentage or bolt ────────────────────────────────────────────
    Text {
        anchors.centerIn: bgRing
        text: root.isCharging ? "⚡" : (root.unknown ? "—" : (root.batteryLevel + "%"))
        color: "white"
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.family: "Inter"
    }

    // ── Label L / R / Case / Headset ─────────────────────────────────────────
    Text {
        anchors.top: bgRing.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label === "L" ? qsTr("Left")
            : root.label === "R" ? qsTr("Right")
            : root.label === "H" ? qsTr("Headset")
            : qsTr("Case")
        color: "#8E8E93"
        font.pixelSize: 11
        font.weight: Font.Medium
        font.family: "Inter"
    }

    // ── Updates ───────────────────────────────────────────────────────────────
    onBatteryLevelChanged: progressRing.progress = root.unknown ? 0 : root.batteryLevel / 100
    onIsChargingChanged:   progressRing.requestPaint()
    onRingColorChanged:    progressRing.requestPaint()

    Component.onCompleted: progressRing.progress = root.unknown ? 0 : root.batteryLevel / 100
}
