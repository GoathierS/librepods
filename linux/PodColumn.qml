import QtQuick 2.15

// Colonne icône + anneau de batterie pour un écouteur ou le boîtier.
Column {
    id: root
    property bool   inEar:      true
    property string iconSource: ""
    property int    batteryLevel: 0
    property bool   isCharging:   false
    property string indicator:    ""   // "L", "R" ou "" pour le boîtier

    readonly property real targetOpacity: inEar ? 1.0 : 0.5

    spacing: 4

    Behavior on opacity { NumberAnimation { duration: 200 } }

    onInEarChanged: root.opacity = targetOpacity

    Component.onCompleted: root.opacity = targetOpacity

    Image {
        source: root.iconSource
        width:  root.indicator === "" ? 80 : 60
        height: 60
        fillMode: Image.PreserveAspectFit
        mipmap: true
        mirror: root.indicator === "R"
        anchors.horizontalCenter: parent.horizontalCenter
    }

    BatteryRing {
        batteryLevel: root.batteryLevel
        isCharging:   root.isCharging
        label:        root.indicator   // "L", "R" ou "" → "Case"
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
