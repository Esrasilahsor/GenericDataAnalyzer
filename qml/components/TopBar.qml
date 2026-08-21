import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: topBar

    height: 76
    color: "#F7F5FB"

    property string title: "Dashboard"
    property string subtitle: "Veri setlerinizi yönetin ve analiz edin."

    RowLayout {
        anchors.fill: parent

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        spacing: 20

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: topBar.title

                color: "#302B3D"

                font.pixelSize: 25
                font.bold: true
            }

            Label {
                text: topBar.subtitle

                color: "#777184"

                font.pixelSize: 13
            }
        }

        Rectangle {
            width: 42
            height: 42

            radius: 21

            color: "#FFFFFF"

            border.width: 1
            border.color: "#E5DFF0"

            Label {
                anchors.centerIn: parent

                text: "✦"

                color: "#A78BCE"

                font.pixelSize: 19
            }
        }
    }
}