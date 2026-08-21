import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // =====================================================
        // BAŞLIK
        // =====================================================

        Label {
            text: "Veri Seti Karşılaştırma"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "Eşleştirilmiş sütunları kullanarak veri setlerini karşılaştırın."

            color: "#777184"

            font.pixelSize: 13
        }


        // =====================================================
        // KARŞILAŞTIRMA DURUMU
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90

            radius: 16

            color: "#FFFFFF"

            border.width: 1
            border.color: "#E5DFF0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18

                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Karşılaştırma Durumu"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        id: comparisonStatus

                        text: "Hazır değil"

                        color: "#302B3D"

                        font.pixelSize: 18
                        font.bold: true
                    }
                }

                Label {
                    text: "⇄"

                    color: "#A78BCE"

                    font.pixelSize: 28
                    font.bold: true
                }

                Button {
                    text: "Karşılaştırmayı Başlat"

                    implicitWidth: 170
                    implicitHeight: 42

                    contentItem: Text {
                        text: "Karşılaştırmayı Başlat"

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
                        comparisonStatus.text = "Karşılaştırma gerçekleştirildi"
                        console.log("Dataset-level comparison başlatıldı.")
                    }
                }
            }
        }


        // =====================================================
        // ÖZET KARTLARI
        // =====================================================

        RowLayout {
            Layout.fillWidth: true

            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110

                radius: 15

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    Label {
                        text: "Karşılaştırılan Alan"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"

                        font.pixelSize: 25
                        font.bold: true
                    }

                    Label {
                        text: "Eşleştirilmiş sütun"

                        color: "#777184"

                        font.pixelSize: 11
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110

                radius: 15

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    Label {
                        text: "Karşılaştırılan Kayıt"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"

                        font.pixelSize: 25
                        font.bold: true
                    }

                    Label {
                        text: "Toplam kayıt"

                        color: "#777184"

                        font.pixelSize: 11
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110

                radius: 15

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    Label {
                        text: "Farklılık"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#DF929C"

                        font.pixelSize: 25
                        font.bold: true
                    }

                    Label {
                        text: "Fark bulunan alan / kayıt"

                        color: "#777184"

                        font.pixelSize: 11
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 110

                radius: 15

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    Label {
                        text: "Fark Oranı"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#302B3D"

                        font.pixelSize: 25
                        font.bold: true
                    }

                    Label {
                        text: "Genel karşılaştırma oranı"

                        color: "#777184"

                        font.pixelSize: 11
                    }
                }
            }
        }


        // =====================================================
        // SONUÇLAR
        // =====================================================

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
                    text: "Karşılaştırma Sonuçları"

                    color: "#302B3D"

                    font.pixelSize: 17
                    font.bold: true
                }

                Label {
                    text: "Eşleştirilmiş alanların karşılaştırma sonuçları burada görüntülenecektir."

                    color: "#777184"

                    font.pixelSize: 12

                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    radius: 12

                    color: "#F7F5FB"

                    border.width: 1
                    border.color: "#E5DFF0"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14

                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            height: 42

                            Label {
                                text: "Sütun"

                                color: "#302B3D"

                                font.bold: true

                                Layout.fillWidth: true
                            }

                            Label {
                                text: "Kayıt"

                                color: "#302B3D"

                                font.bold: true

                                Layout.preferredWidth: 100
                            }

                            Label {
                                text: "Fark"

                                color: "#302B3D"

                                font.bold: true

                                Layout.preferredWidth: 100
                            }

                            Label {
                                text: "Durum"

                                color: "#302B3D"

                                font.bold: true

                                Layout.preferredWidth: 120
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true

                            height: 1

                            color: "#E5DFF0"
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Label {
                                anchors.centerIn: parent

                                text: "Henüz karşılaştırma sonucu bulunmuyor."

                                color: "#777184"

                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }
}