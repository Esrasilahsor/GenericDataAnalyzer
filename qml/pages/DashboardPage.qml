import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

import "../components" as Components

Item {
    id: page

    /*
     * AppController, Main.qml tarafından Loader üzerinden verilir.
     *
     * Eğer henüz verilmemişse null olabilir.
     * Bu nedenle aşağıdaki kullanımlarda güvenli kontroller
     * yapılmaktadır.
     */
    property var appController

    property string firstFileName: appController
                               ? appController.dataset1Name
                               : ""

    property string secondFileName: appController
                                ? appController.dataset2Name
                                : ""

    property string firstRows: appController
                           ? String(appController.dataset1RowCount)
                           : "—"

    property string secondRows: appController
                            ? String(appController.dataset2RowCount)
                            : "—"

    property string firstColumns: appController
                              ? String(appController.dataset1ColumnCount)
                              : "—"

    property string secondColumns: appController
                               ? String(appController.dataset2ColumnCount)
                               : "—"


    // ============================================================
    // DOSYA SEÇİCİLER
    // ============================================================

    FileDialog {
        id: firstFileDialog

        title: "Birinci veri setini seçin"

        selectExisting: true

        nameFilters: [
            "Data files (*.xlsx *.csv *.txt)",
            "Excel files (*.xlsx)",
            "CSV files (*.csv)",
            "Text files (*.txt)"
        ]

        onAccepted: {

            if (page.appController) {
                page.appController.loadDataset1(
                    fileUrl.toString()
                )
            }
        }
    }


    FileDialog {
        id: secondFileDialog

        title: "İkinci veri setini seçin"

        selectExisting: true

        nameFilters: [
            "Data files (*.xlsx *.csv *.txt)",
            "Excel files (*.xlsx)",
            "CSV files (*.csv)",
            "Text files (*.txt)"
        ]

        onAccepted: {

            if (page.appController) {
                page.appController.loadDataset2(
                    fileUrl.toString()
                )
            }
        }
    }


    // ============================================================
    // ANA LAYOUT
    // ============================================================

    ColumnLayout {

        anchors.fill: parent

        anchors.margins: 24

        spacing: 18


        // ========================================================
        // BAŞLIK
        // ========================================================

        ColumnLayout {

            Layout.fillWidth: true

            spacing: 4

            Label {
                text: "Dashboard"

                color: "#302B3D"

                font.pixelSize: 26

                font.bold: true
            }

            Label {
                text: "Veri setlerinizi yükleyin ve analiz sürecini başlatın."

                color: "#777184"

                font.pixelSize: 13
            }
        }


        // ========================================================
        // DATASET KARTLARI
        // ========================================================

        RowLayout {

            Layout.fillWidth: true

            spacing: 16


            // ----------------------------------------------------
            // DATASET 1
            // ----------------------------------------------------

            Components.DatasetCard {

                Layout.fillWidth: true

                datasetTitle: "Dataset 1"

                fileName: page.firstFileName === ""
                           ? "Henüz dosya seçilmedi"
                           : page.firstFileName

                rows: page.firstRows

                columns: page.firstColumns

                loaded: page.firstFileName !== ""

                onBrowseRequested: {

                    firstFileDialog.open()
                }
            }


            // ----------------------------------------------------
            // DATASET 2
            // ----------------------------------------------------

            Components.DatasetCard {

                Layout.fillWidth: true

                datasetTitle: "Dataset 2"

                fileName: page.secondFileName === ""
                           ? "Henüz dosya seçilmedi"
                           : page.secondFileName

                rows: page.secondRows

                columns: page.secondColumns

                loaded: page.secondFileName !== ""

                onBrowseRequested: {

                    secondFileDialog.open()
                }
            }
        }


        // ========================================================
        // İSTATİSTİK KARTLARI
        // ========================================================

        RowLayout {

            Layout.fillWidth: true

            spacing: 12


            Components.StatCard {

                title: "Dataset 1"

                value: page.firstFileName === ""
                       ? "Bekleniyor"
                       : "Hazır"

                description: page.firstFileName === ""
                            ? "Henüz veri yüklenmedi"
                            : page.firstFileName

                icon: "▣"
            }


            Components.StatCard {

                title: "Dataset 2"

                value: page.secondFileName === ""
                       ? "Bekleniyor"
                       : "Hazır"

                description: page.secondFileName === ""
                            ? "Henüz veri yüklenmedi"
                            : page.secondFileName

                icon: "▣"
            }


            Components.StatCard {

                title: "Toplam Sütun"

                value: {
                    if (!page.appController)
                        return "—"

                    return String(
                        Number(page.appController.dataset1ColumnCount)
                        +
                        Number(page.appController.dataset2ColumnCount)
                    )
                }

                description: "İki veri setindeki toplam sütun"

                icon: "▥"
            }


            Components.StatCard {

                title: "Toplam Kayıt"

                value: {
                    if (!page.appController)
                        return "—"

                    return String(
                        Number(page.appController.dataset1RowCount)
                        +
                        Number(page.appController.dataset2RowCount)
                    )
                }

                description: "İki veri setindeki toplam kayıt"

                icon: "▤"
            }
        }


        // ========================================================
        // HIZLI BAŞLANGIÇ / DURUM
        // ========================================================

        Rectangle {

            Layout.fillWidth: true

            Layout.fillHeight: true

            radius: 18

            color: "#FFFFFF"

            border.width: 1

            border.color: "#E5DFF0"


            ColumnLayout {

                anchors.fill: parent

                anchors.margins: 22

                spacing: 12


                Label {

                    text: "Analiz Süreci"

                    color: "#302B3D"

                    font.pixelSize: 17

                    font.bold: true
                }


                Label {

                    text: "Veri setlerini yükledikten sonra aşağıdaki adımlardan devam edebilirsiniz."

                    color: "#777184"

                    font.pixelSize: 12

                    Layout.fillWidth: true
                }


                RowLayout {

                    Layout.fillWidth: true

                    spacing: 12


                    Rectangle {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 70

                        radius: 12

                        color: "#F7F5FB"

                        border.width: 1

                        border.color: "#E5DFF0"


                        ColumnLayout {

                            anchors.fill: parent

                            anchors.margins: 12

                            spacing: 3


                            Label {

                                text: "01"

                                color: "#A78BCE"

                                font.pixelSize: 12

                                font.bold: true
                            }

                            Label {

                                text: "Veri Setlerini Yükle"

                                color: "#302B3D"

                                font.pixelSize: 13

                                font.bold: true
                            }
                        }
                    }


                    Rectangle {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 70

                        radius: 12

                        color: "#F7F5FB"

                        border.width: 1

                        border.color: "#E5DFF0"


                        ColumnLayout {

                            anchors.fill: parent

                            anchors.margins: 12

                            spacing: 3


                            Label {

                                text: "02"

                                color: "#A78BCE"

                                font.pixelSize: 12

                                font.bold: true
                            }

                            Label {

                                text: "Veri Kalitesini İncele"

                                color: "#302B3D"

                                font.pixelSize: 13

                                font.bold: true
                            }
                        }
                    }


                    Rectangle {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 70

                        radius: 12

                        color: "#F7F5FB"

                        border.width: 1

                        border.color: "#E5DFF0"


                        ColumnLayout {

                            anchors.fill: parent

                            anchors.margins: 12

                            spacing: 3


                            Label {

                                text: "03"

                                color: "#A78BCE"

                                font.pixelSize: 12

                                font.bold: true
                            }

                            Label {

                                text: "Sütunları Eşleştir"

                                color: "#302B3D"

                                font.pixelSize: 13

                                font.bold: true
                            }
                        }
                    }


                    Rectangle {

                        Layout.fillWidth: true

                        Layout.preferredHeight: 70

                        radius: 12

                        color: "#F7F5FB"

                        border.width: 1

                        border.color: "#E5DFF0"


                        ColumnLayout {

                            anchors.fill: parent

                            anchors.margins: 12

                            spacing: 3


                            Label {

                                text: "04"

                                color: "#A78BCE"

                                font.pixelSize: 12

                                font.bold: true
                            }

                            Label {

                                text: "Karşılaştır"

                                color: "#302B3D"

                                font.pixelSize: 13

                                font.bold: true
                            }
                        }
                    }
                }


                Item {
                    Layout.fillHeight: true
                }


                // =================================================
                // DURUM MESAJI
                // =================================================

                Rectangle {

                    Layout.fillWidth: true

                    height: 48

                    radius: 10

                    color: page.firstFileName !== ""
                           && page.secondFileName !== ""
                           ? "#F0F8F2"
                           : "#F7F5FB"

                    border.width: 1

                    border.color: page.firstFileName !== ""
                                   && page.secondFileName !== ""
                                   ? "#CBE5D3"
                                   : "#E5DFF0"


                    Label {

                        anchors.centerIn: parent

                        text: {
                            if (page.firstFileName !== ""
                                    && page.secondFileName !== "") {
                                return "✓ İki veri seti de yüklendi. Analize başlayabilirsiniz."
                            }

                            if (page.firstFileName !== "") {
                                return "Dataset 1 yüklendi. Dataset 2'yi yükleyin."
                            }

                            if (page.secondFileName !== "") {
                                return "Dataset 2 yüklendi. Dataset 1'i yükleyin."
                            }

                            return "Analize başlamak için iki veri setini yükleyin."
                        }

                        color: page.firstFileName !== ""
                               && page.secondFileName !== ""
                               ? "#5A9B6C"
                               : "#777184"

                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}