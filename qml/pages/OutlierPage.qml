import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // =========================================================
        // BAŞLIK
        // =========================================================

        Label {
            text: "Outlier Analysis"

            color: "#302B3D"

            font.pixelSize: 24
            font.bold: true
        }

        Label {
            text: "Sayısal sütunlardaki aykırı değerleri IQR yöntemi kullanarak analiz edin."

            color: "#777184"

            font.pixelSize: 13
        }


        // =========================================================
        // ANALİZ AYARLARI
        // =========================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110

            radius: 16

            color: "#FFFFFF"

            border.width: 1
            border.color: "#E5DFF0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18

                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Veri Seti"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    ComboBox {
                        id: datasetCombo

                        Layout.fillWidth: true

                        model: [
                            "Dataset 1",
                            "Dataset 2"
                        ]
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Sayısal Sütun"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    ComboBox {
                        id: columnCombo

                        Layout.fillWidth: true

                        model: [
                            "Sütun seçiniz..."
                        ]
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 150

                    spacing: 5

                    Label {
                        text: "IQR Multiplier"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    TextField {
                        id: multiplierField

                        Layout.fillWidth: true

                        text: "1.5"

                        validator: DoubleValidator {
                            bottom: 0.000001
                        }

                        horizontalAlignment: Text.AlignHCenter

                        color: "#302B3D"

                        font.pixelSize: 13

                        background: Rectangle {
                            radius: 9

                            color: "#F7F5FB"

                            border.width: 1
                            border.color: "#E5DFF0"
                        }
                    }
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
                        console.log(
                            "Outlier analizi başlatıldı.",
                            "Multiplier:",
                            multiplierField.text
                        )
                    }
                }
            }
        }


        // =========================================================
        // İSTATİSTİK ÖZETİ
        // =========================================================

        RowLayout {
            Layout.fillWidth: true

            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 105

                radius: 14

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 4

                    Label {
                        text: "Valid Value Count"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#302B3D"

                        font.pixelSize: 24
                        font.bold: true
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 105

                radius: 14

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 4

                    Label {
                        text: "Q1"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"

                        font.pixelSize: 24
                        font.bold: true
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 105

                radius: 14

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 4

                    Label {
                        text: "Q3"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"

                        font.pixelSize: 24
                        font.bold: true
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 105

                radius: 14

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 4

                    Label {
                        text: "IQR"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#A78BCE"

                        font.pixelSize: 24
                        font.bold: true
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 105

                radius: 14

                color: "#FFFFFF"

                border.width: 1
                border.color: "#E5DFF0"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 4

                    Label {
                        text: "Outlier Count"

                        color: "#777184"

                        font.pixelSize: 11
                    }

                    Label {
                        text: "—"

                        color: "#DF929C"

                        font.pixelSize: 24
                        font.bold: true
                    }
                }
            }
        }


        // =========================================================
        // ALT SONUÇLAR
        // =========================================================

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: 16


            // -----------------------------------------------------
            // SINIRLAR
            // -----------------------------------------------------

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
                        text: "IQR Sınırları"

                        color: "#302B3D"

                        font.pixelSize: 17
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 58

                        radius: 10

                        color: "#F7F5FB"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Label {
                                text: "Lower Bound"

                                color: "#777184"

                                Layout.fillWidth: true
                            }

                            Label {
                                text: "—"

                                color: "#302B3D"

                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 58

                        radius: 10

                        color: "#F7F5FB"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Label {
                                text: "Upper Bound"

                                color: "#777184"

                                Layout.fillWidth: true
                            }

                            Label {
                                text: "—"

                                color: "#302B3D"

                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 58

                        radius: 10

                        color: "#F7F5FB"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12

                            Label {
                                text: "Outlier Percentage"

                                color: "#777184"

                                Layout.fillWidth: true
                            }

                            Label {
                                text: "—"

                                color: "#DF929C"

                                font.bold: true
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }


            // -----------------------------------------------------
            // OUTLIER DEĞERLERİ
            // -----------------------------------------------------

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
                        text: "Outlier Values"

                        color: "#302B3D"

                        font.pixelSize: 17
                        font.bold: true
                    }

                    Label {
                        text: "Tespit edilen aykırı değerler burada listelenecektir."

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

                        ScrollView {
                            anchors.fill: parent

                            clip: true

                            Label {
                                width: parent.width

                                text: "Henüz analiz gerçekleştirilmedi."

                                color: "#777184"

                                font.pixelSize: 13

                                horizontalAlignment: Text.AlignHCenter

                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}