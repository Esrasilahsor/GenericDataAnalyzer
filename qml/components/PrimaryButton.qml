import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: button

    property bool destructive: false

    implicitHeight: 42
    leftPadding: 18
    rightPadding: 18

    contentItem: Text {
        text: button.text

        color: button.enabled
               ? "#FFFFFF"
               : "#777184"

        font.pixelSize: 13
        font.bold: true

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 10

        color: !button.enabled
               ? "#F1EDF8"
               : button.destructive
                 ? "#DF929C"
                 : button.down
                   ? "#8F72B8"
                   : "#A78BCE"
    }
}