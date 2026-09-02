import QtQuick 2.15

Item {
    id: root

    property string source: ""
    property real mascotWidth: 180
    property real mascotHeight: 180
    property bool animated: false

    implicitWidth: mascotWidth
    implicitHeight: mascotHeight

    Image {
        id: mascotImage

        anchors.centerIn: parent

        width: root.mascotWidth
        height: root.mascotHeight

        source: root.source

        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        cache: true

        opacity: 1.0
    }

    SequentialAnimation {
        running: root.animated
        loops: Animation.Infinite

        NumberAnimation {
            target: mascotImage
            property: "y"
            from: 0
            to: -5
            duration: 900
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: mascotImage
            property: "y"
            from: -5
            to: 0
            duration: 900
            easing.type: Easing.InOutQuad
        }
    }
}
