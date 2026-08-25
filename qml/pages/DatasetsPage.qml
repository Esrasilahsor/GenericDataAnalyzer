import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

import "../" as AppTheme
import "../components" as Components

Item {
    id: page

    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    // =========================================================
    // YARDIMCI PROPERTY'LER
    // =========================================================

    property bool dataset1Loaded:
        page.appController !== null &&
        page.appController !== undefined &&
        page.appController.dataset1Name !== undefined &&
        page.appController.dataset1Name !== ""

    property bool dataset2Loaded:
        page.appController !== null &&
        page.appController !== undefined &&
        page.appController.dataset2Name !== undefined &&
        page.appController.dataset2Name !== ""

    property int loadedCount:
        (page.dataset1Loaded ? 1 : 0) +
        (page.dataset2Loaded ? 1 : 0)

    // =========================================================
    // DOSYA DİYALOGLARI
    // =========================================================

    FileDialog {
        id: dataset1Dialog

        title: "Dataset 1 Dosyası Seç"

        selectExisting: true
        folder: page.appController && page.appController.dataDirectory !== ""
                    ? ("file:///" + page.appController.dataDirectory.replace(/\\/g, "/"))
                    : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"

        nameFilters: [
            "Desteklenen Dosyalar (*.csv *.xlsx *.txt)",
            "CSV Dosyaları (*.csv)",
            "Excel Dosyaları (*.xlsx)",
            "Text Dosyaları (*.txt)"
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
        id: dataset2Dialog

        title: "Dataset 2 Dosyası Seç"

        selectExisting: true
        selectMultiple: false

        folder: page.appController && page.appController.dataDirectory !== ""
                    ? ("file:///" + page.appController.dataDirectory.replace(/\\/g, "/"))
                    : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"

        nameFilters: [
            "Desteklenen Dosyalar (*.csv *.xlsx *.txt)",
            "CSV Dosyaları (*.csv)",
            "Excel Dosyaları (*.xlsx)",
            "Text Dosyaları (*.txt)"
        ]

        onAccepted: {
            if (page.appController) {
                page.appController.loadDataset2(
                    fileUrl.toString()
                )
            }
        }
    }

    // =========================================================
    // FONKSİYONLAR
    // =========================================================

    function datasetName(number) {
        if (!page.appController)
            return "Henüz yüklenmedi"

        if (number === 1)
            return page.appController.dataset1Name || "Henüz yüklenmedi"

        return page.appController.dataset2Name || "Henüz yüklenmedi"
    }

    function datasetRows(number) {
        if (!page.appController)
            return 0

        if (number === 1)
            return page.appController.dataset1RowCount || 0

        return page.appController.dataset2RowCount || 0
    }

    function datasetColumns(number) {
        if (!page.appController)
            return 0

        if (number === 1)
            return page.appController.dataset1ColumnCount || 0

        return page.appController.dataset2ColumnCount || 0
    }

    function goToPage(index) {
        if (page.mainWindow)
            page.mainWindow.currentPage = index
    }

    // =========================================================
    // ANA İÇERİK
    // =========================================================

    ScrollView {
        anchors.fill: parent

        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: page.width

            spacing: 18

            // =================================================
            // ÜST BİLGİ
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true

                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 24

                spacing: 5
            }

            // =================================================
            // DATASET KARTLARI
            // =================================================

            RowLayout {
                Layout.fillWidth: true

                Layout.leftMargin: 28
                Layout.rightMargin: 28

                spacing: 14

                // =================================================
                // DATASET 1
                // =================================================

                Rectangle {
                    Layout.fillWidth: true

                    Layout.preferredHeight: 225

                    radius: 17

                    color: theme.surface

                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        anchors.fill: parent

                        anchors.margins: 20

                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "Dataset 1"
                                color: theme.text
                                font.pixelSize: 18
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 28
                                radius: 14
                                color: page.dataset1Loaded ? "#E6F6EE" : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: page.dataset1Loaded ? "Yüklendi" : "Bekliyor"
                                    color: page.dataset1Loaded ? theme.success : theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: page.datasetName(1)
                            color: theme.textSecondary
                            font.pixelSize: 13
                            elide: Text.ElideMiddle
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 35

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Satır"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: page.datasetRows(1)
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Sütun"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: page.datasetColumns(1)
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            text:
                                page.dataset1Loaded
                                ? "Dataset 1'i Değiştir"
                                : "Excel / CSV Seç"

                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 10
                                color: parent.down ? theme.primaryDark : theme.primary
                            }

                            onClicked: {
                                dataset1Dialog.open()
                            }
                        }
                    }
                }

                // =================================================
                // DATASET 2
                // =================================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 225
                    radius: 17
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "Dataset 2"
                                color: theme.text
                                font.pixelSize: 18
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 28
                                radius: 14
                                color: page.dataset2Loaded ? "#E6F6EE" : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: page.dataset2Loaded ? "Yüklendi" : "Bekliyor"
                                    color: page.dataset2Loaded ? theme.success : theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: page.datasetName(2)
                            color: theme.textSecondary
                            font.pixelSize: 13
                            elide: Text.ElideMiddle
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 35

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Satır"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: page.datasetRows(2)
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Sütun"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    text: page.datasetColumns(2)
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            text:
                                page.dataset2Loaded
                                ? "Dataset 2'yi Değiştir"
                                : "Excel / CSV Seç"

                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 10
                                color: parent.down ? theme.primaryDark : theme.primary
                            }

                            onClicked: {
                                dataset2Dialog.open()
                            }
                        }
                    }
                }
            }

            // =================================================
            // YÜKLEME DURUMU
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 105

                radius: 16
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: page.loadedCount === 2 ? theme.success : theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: page.loadedCount === 2 ? "✓" : page.loadedCount + "/2"
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text:
                                page.loadedCount === 2
                                ? "İki veri seti de hazır"
                                : "Veri setlerini yükleyin"
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text:
                                page.loadedCount === 2
                                ? "Veri setleri başarıyla yüklendi. Aşağıdaki tablodan sütun yapılarını inceleyebilir veya analize geçebilirsiniz."
                                : "Karşılaştırma ve analiz için iki veri setinin de yüklenmesi gerekiyor."
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    Button {
                        visible: page.loadedCount === 2
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 40
                        text: "Veri Analizine Git →"

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 10
                            color: parent.down ? theme.primaryDark : theme.primary
                        }

                        onClicked: {
                            page.goToPage(2)
                        }
                    }
                }
            }

            // =================================================
            // DATASET 1 DETAY TABLOSU
            // =================================================

            Components.DatasetDetails {
                visible: page.dataset1Loaded
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 380

                title: "Dataset 1 Sütun Yapısı"
                datasetName: page.datasetName(1)
                rowCount: page.datasetRows(1)
                columnCount: page.datasetColumns(1)
                sheetName: page.appController ? page.appController.dataset1SheetName : ""
                model: page.appController ? page.appController.dataset1ColumnModel : null
            }

            // =================================================
            // DATASET 2 DETAY TABLOSU
            // =================================================

            // =================================================
            // HAM VERİ (RAW DATA) AYRIŞTIRMA KARTI
            // =================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 78
                radius: 14
                color: theme.surfaceAlt
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 10
                        color: "#FF4081"
                        Label {
                            anchors.centerIn: parent
                            text: "⚡"
                            color: "#FFFFFF"
                            font.bold: true
                            font.pixelSize: 18
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: "Ham Veri & Metadata Ayrıştırma (Raw Data Parsing)"
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: "Binary/text ham veri paketlerini parametre metadatasını kullanarak ayrıştırın ve tablo olarak inceleyin."
                            color: theme.textSecondary
                            font.pixelSize: 11
                        }
                    }

                    Button {
                        Layout.preferredWidth: 210
                        Layout.preferredHeight: 38
                        text: "⚡ Ham Veri Ayrıştır →"
                        onClicked: page.goToPage(6)
                    }
                }
            }

            Components.DatasetDetails {
                visible: page.dataset2Loaded
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 380

                title: "Dataset 2 Sütun Yapısı"
                datasetName: page.datasetName(2)
                rowCount: page.datasetRows(2)
                columnCount: page.datasetColumns(2)
                sheetName: page.appController ? page.appController.dataset2SheetName : ""
                model: page.appController ? page.appController.dataset2ColumnModel : null
            }

            // =================================================
            // HATA MESAJI
            // =================================================

            Rectangle {
                visible:
                    page.appController &&
                    page.appController.lastError !== ""

                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 72

                radius: 12
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.error

                Label {
                    anchors.fill: parent
                    anchors.margins: 15
                    text: page.appController ? page.appController.lastError : ""
                    color: theme.error
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // =================================================
            // ALT BOŞLUK
            // =================================================

            Item {
                Layout.preferredHeight: 25
            }
        }
    }
}