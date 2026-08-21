import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: card

    property string title: ""
    property string value: "—"
    property string description: ""
    property string icon: "•"

    Layout.fillWidth: true
    Layout.preferredHeight: 110

    radius: 16
    color: "#FFFFFF"

    border.width: 1
    border.color: "#E5DFF0"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 5

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: card.title
                color: "#777184"
                font.pixelSize: 13
                Layout.fillWidth: true
            }

            Label {
                text: card.icon
                color: "#A78BCE"
                font.pixelSize: 18
            }
        }

        Label {
            text: card.value
            color: "#302B3D"
            font.pixelSize: 25
            font.bold: true
        }

        Label {
            text: card.description
            color: "#777184"
            font.pixelSize: 11
        }
    }
}