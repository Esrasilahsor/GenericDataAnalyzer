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
            text: "Veri Kalitesi"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "Veri setlerinin kalite, eksik değer ve bütünlük durumunu inceleyin."

            color: "#777184"

            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                radius: 16

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 5

                    Label {
                        text: "Eksik Değer"

                        color: "#777184"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"
                        font.pixelSize: 26
                        font.bold: true
                    }

                    Label {
                        text: "Toplam eksik değer"

                        color: "#777184"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                radius: 16

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 5

                    Label {
                        text: "Duplicate"

                        color: "#777184"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"
                        font.pixelSize: 26
                        font.bold: true
                    }

                    Label {
                        text: "Tekrarlanan kayıt"

                        color: "#777184"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                radius: 16

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 5

                    Label {
                        text: "Quality"

                        color: "#777184"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "—"

                        color: "#8BC9A3"
                        font.pixelSize: 26
                        font.bold: true
                    }

                    Label {
                        text: "Veri kalite skoru"

                        color: "#777184"
                        font.pixelSize: 11
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 18

            color: "#FFFFFF"

            border.width: 1
            border.color: "#E5DFF0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Label {
                    text: "Veri Kalitesi Detayları"

                    color: "#302B3D"

                    font.pixelSize: 17
                    font.bold: true
                }

                Label {
                    text: "Veri kalite analiz sonuçları burada sütun bazında görüntülenecektir."

                    color: "#777184"

                    font.pixelSize: 13

                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}