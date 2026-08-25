import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import "../" as AppTheme

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    property string statusMessage: ""
    property bool statusSuccess: true

    function showStatus(msg, ok) {
        page.statusMessage = msg
        page.statusSuccess = ok
        statusTimer.restart()
    }

    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: page.statusMessage = ""
    }

    // Metadata File Dialog
    FileDialog {
        id: metadataDialog
        title: "Parametre Metadata Dosyası Seç (.xlsx)"
        folder: appController ? ("file:///" + appController.dataDirectory().replace(/\\/g, "/")) : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"
        nameFilters: ["Excel Dosyaları (*.xlsx *.xls)", "Tüm Dosyalar (*.*)"]
        onAccepted: {
            var path = String(fileUrl).replace("file:///", "")
            var ok = appController.loadRawMetadata(path)
            if (ok) {
                showStatus("✓ Metadata başarıyla yüklendi: " + appController.rawParameterDefinitionCount + " parametre tanımı bulundu.", true)
            } else {
                showStatus("✕ Metadata yükleme hatası: " + (appController.lastError || "Hata"), false)
            }
        }
    }

    // Raw Data File Dialog
    FileDialog {
        id: rawDataDialog
        title: "Ham Veri Dosyası Seç (.bin, .txt, .dat, .raw)"
        folder: appController ? ("file:///" + appController.dataDirectory().replace(/\\/g, "/")) : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"
        nameFilters: ["Ham Veri Dosyaları (*.bin *.dat *.txt *.raw)", "Tüm Dosyalar (*.*)"]
        onAccepted: {
            var path = String(fileUrl).replace("file:///", "")
            var ok = appController.loadRawDataFile(path)
            if (ok) {
                showStatus("✓ Ham veri başarıyla yüklendi: " + appController.rawDataByteCount + " bayt okundu.", true)
            } else {
                showStatus("✕ Ham veri yükleme hatası: " + (appController.lastError || "Hata"), false)
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // Status message
            Rectangle {
                visible: page.statusMessage !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 40
                radius: 8
                color: page.statusSuccess ? "#1B5E20" : "#B71C1C"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Label {
                        text: page.statusMessage
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // Top Cards: Parameter Metadata & Raw Data
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                // Card 1: Parameter Metadata
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 8

                        Label {
                            text: "Parameter Metadata"
                            color: theme.text
                            font.pixelSize: 17
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: appController && appController.rawMetadataLoaded ? "Metadata loaded successfully" : "No metadata loaded"
                            color: appController && appController.rawMetadataLoaded ? theme.success : theme.textSecondary
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: appController && appController.rawMetadataLoaded ? (appController.rawParameterDefinitionCount + " parameter definitions") : "Select an Excel metadata definition file"
                            color: theme.textSecondary
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignHCenter
                            text: appController && appController.rawMetadataLoaded ? "Change Metadata" : "Load Metadata (.xlsx)"
                            onClicked: metadataDialog.open()
                        }
                    }
                }

                // Card 2: Raw Data
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 8

                        Label {
                            text: "Raw Data"
                            color: theme.text
                            font.pixelSize: 17
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: appController && appController.rawDataLoaded ? "Raw data loaded successfully" : "No raw data loaded"
                            color: appController && appController.rawDataLoaded ? theme.success : theme.textSecondary
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: appController && appController.rawDataLoaded ? (appController.rawDataByteCount + " bytes") : "Select a binary/text packet file"
                            color: theme.textSecondary
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignHCenter
                            text: appController && appController.rawDataLoaded ? "Change Raw Data" : "Load Raw Data (.bin)"
                            onClicked: rawDataDialog.open()
                        }
                    }
                }
            }

            // Action Buttons & Status Row
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 70
                radius: 14
                color: theme.surfaceAlt
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Button {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        text: "⚡ Parse Raw Data"
                        enabled: appController && appController.rawMetadataLoaded && appController.rawDataLoaded
                        onClicked: {
                            var ok = appController.parseRawData()
                            if (ok) {
                                showStatus("✓ Ham veri paketi başarıyla ayrıştırıldı!", true)
                            } else {
                                showStatus("✕ Ayrıştırma hatası: " + (appController.lastError || "Hata"), false)
                            }
                        }
                    }

                    Button {
                        Layout.preferredWidth: 130
                        Layout.preferredHeight: 38
                        text: "✕ Clear Results"
                        enabled: appController && (appController.rawParseAvailable || appController.rawMetadataLoaded || appController.rawDataLoaded)
                        onClicked: {
                            appController.clearRawParse()
                            showStatus("Sonuçlar temizlendi.", true)
                        }
                    }

                    Label {
                        text: appController && appController.rawParseAvailable ? "✓ Parse completed" : ""
                        color: theme.success
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Import as Dataset buttons
                    Button {
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 38
                        text: "📥 Dataset 1 Olarak Aktar"
                        enabled: appController && appController.rawParseAvailable
                        onClicked: {
                            var ok = appController.importParsedRawDataAsDataset(1, "Parsed_Raw_Packet_1")
                            if (ok) {
                                showStatus("✓ Ayrıştırılmış paket Dataset 1 olarak aktarıldı! Analiz edebilirsiniz.", true)
                            } else {
                                showStatus("✕ Aktarma hatası: " + (appController.lastError || "Hata"), false)
                            }
                        }
                    }

                    Button {
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 38
                        text: "📥 Dataset 2 Olarak Aktar"
                        enabled: appController && appController.rawParseAvailable
                        onClicked: {
                            var ok = appController.importParsedRawDataAsDataset(2, "Parsed_Raw_Packet_2")
                            if (ok) {
                                showStatus("✓ Ayrıştırılmış paket Dataset 2 olarak aktarıldı! Analiz edebilirsiniz.", true)
                            } else {
                                showStatus("✕ Aktarma hatası: " + (appController.lastError || "Hata"), false)
                            }
                        }
                    }
                }
            }

            // Parsed Parameters Table
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(340, 100 + (appController && appController.parameterModel ? appController.parameterModel.count : 0) * 44)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Label {
                        text: "Parsed Parameters"
                        color: theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    // Table Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 8
                        color: theme.surfaceAlt

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Label { Layout.preferredWidth: 200; text: "Parameter"; color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 180; text: "Value"; color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 140; text: "Type"; color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 100; text: "Unit"; color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 100; text: "Status"; color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Table Rows
                    ListView {
                        id: paramList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: appController ? appController.parameterModel : null

                        delegate: Rectangle {
                            width: paramList.width
                            height: 40
                            radius: 6
                            color: index % 2 === 0 ? "transparent" : theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Label {
                                    Layout.preferredWidth: 200
                                    text: model.dataName || ""
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                }
                                Label {
                                    Layout.preferredWidth: 180
                                    text: model.displayValue !== undefined && model.displayValue !== "" ? String(model.displayValue) : String(model.value || "-")
                                    color: theme.primary
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                }
                                Label {
                                    Layout.preferredWidth: 140
                                    text: model.dataType || "-"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }
                                Label {
                                    Layout.preferredWidth: 100
                                    text: model.unit && model.unit !== "" ? model.unit : "-"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }
                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 22
                                    radius: 4
                                    color: model.status === "OK" || model.valid ? "#1B5E20" : "#B71C1C"
                                    Label {
                                        anchors.centerIn: parent
                                        text: model.status === "OK" || model.valid ? "OK" : "ERROR"
                                        color: "#FFFFFF"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    Label {
                        visible: !appController || !appController.parameterModel || appController.parameterModel.count === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: "Henüz ham veri ayrıştırılmadı. Metadata ve Ham Veri dosyalarını yükleyip 'Parse Raw Data' butonuna tıklayın."
                        color: theme.textSecondary
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
