import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Label {
            text: "Sütun Eşleştirme"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "İki veri setindeki karşılaştırılacak sütunları eşleştirin."

            color: "#777184"

            font.pixelSize: 13
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

                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Dataset 1"

                        color: "#302B3D"

                        font.pixelSize: 16
                        font.bold: true

                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Dataset 2"

                        color: "#302B3D"

                        font.pixelSize: 16
                        font.bold: true

                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1

                    color: "#E5DFF0"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ComboBox {
                        id: leftColumnCombo

                        Layout.fillWidth: true

                        model: [
                            "Sütun seçiniz..."
                        ]

                        currentIndex: 0
                    }

                    Label {
                        text: "↔"

                        color: "#A78BCE"

                        font.pixelSize: 22
                        font.bold: true
                    }

                    ComboBox {
                        id: rightColumnCombo

                        Layout.fillWidth: true

                        model: [
                            "Sütun seçiniz..."
                        ]

                        currentIndex: 0
                    }

                    Button {
                        text: "Ekle"

                        implicitWidth: 90
                        implicitHeight: 40

                        contentItem: Text {
                            text: "Ekle"

                            color: "#FFFFFF"

                            font.pixelSize: 12
                            font.bold: true

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10

                            color: "#A78BCE"
                        }

                        onClicked: {
                            console.log("Sütun eşleştirme eklendi.")
                        }
                    }
                }

                Label {
                    text: "Oluşturulan Eşleştirmeler"

                    color: "#302B3D"

                    font.pixelSize: 16
                    font.bold: true

                    Layout.topMargin: 8
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: 12

                    color: "#F7F5FB"

                    border.width: 1
                    border.color: "#E5DFF0"

                    Label {
                        anchors.centerIn: parent

                        text: "Henüz sütun eşleştirmesi oluşturulmadı."

                        color: "#777184"

                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Karşılaştırmaya Devam Et"

                        implicitHeight: 42

                        contentItem: Text {
                            text: "Karşılaştırmaya Devam Et"

                            color: "#FFFFFF"

                            font.pixelSize: 12
                            font.bold: true

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10

                            color: "#A78BCE"
                        }

                        onClicked: {
                            console.log("Karşılaştırma için eşleştirmeler hazır.")
                        }
                    }
                }
            }
        }
    }
}