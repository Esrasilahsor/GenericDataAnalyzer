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
            text: "Veri Analizi"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "Seçilen veri setleri üzerinde istatistiksel ve yapısal analiz gerçekleştirin."

            color: "#777184"

            font.pixelSize: 13
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130

                radius: 16

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 6

                    Label {
                        text: "Dataset 1"

                        color: "#777184"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "Hazır değil"

                        color: "#302B3D"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        text: "Analiz için veri seti seçin."

                        color: "#777184"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130

                radius: 16

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 6

                    Label {
                        text: "Dataset 2"

                        color: "#777184"
                        font.pixelSize: 12
                    }

                    Label {
                        text: "Hazır değil"

                        color: "#302B3D"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        text: "Analiz için veri seti seçin."

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
                spacing: 14

                Label {
                    text: "Analiz Seçenekleri"

                    color: "#302B3D"

                    font.pixelSize: 17
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    CheckBox {
                        id: descriptiveCheck

                        text: "Tanımlayıcı İstatistikler"

                        checked: true
                    }

                    CheckBox {
                        id: distributionCheck

                        text: "Dağılım Analizi"
                    }

                    CheckBox {
                        id: correlationCheck

                        text: "Korelasyon Analizi"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1

                    color: "#E5DFF0"
                }

                Label {
                    text: "Analiz Sonuçları"

                    color: "#302B3D"

                    font.pixelSize: 16
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: 12

                    color: "#F7F5FB"

                    border.width: 1
                    border.color: "#E5DFF0"

                    ColumnLayout {
                        anchors.centerIn: parent

                        spacing: 8

                        Label {
                            text: "Henüz analiz gerçekleştirilmedi."

                            color: "#777184"

                            font.pixelSize: 14

                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "Analiz seçeneklerini belirleyerek işlemi başlatabilirsiniz."

                            color: "#777184"

                            font.pixelSize: 12

                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Analizi Başlat"

                        implicitWidth: 130
                        implicitHeight: 42

                        contentItem: Text {
                            text: "Analizi Başlat"

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
                            console.log("Veri analizi başlatıldı.")
                        }
                    }
                }
            }
        }
    }
}