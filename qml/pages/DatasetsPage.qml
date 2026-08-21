import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 10

        Label {
            text: "Veri Setleri"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "Yüklenen veri setlerinin yapısını ve sütun bilgilerini inceleyin."

            color: "#777184"

            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 18

            color: "#FFFFFF"

            border.color: "#E5DFF0"
            border.width: 1

            Label {
                anchors.centerIn: parent

                text: "Dataset detayları burada görüntülenecek."

                color: "#777184"

                font.pixelSize: 14
            }
        }
    }
}