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
        title: qsTr("Select Parameter Metadata File (.xlsx, .csv, .txt)")
        folder: appController && appController.dataDirectory !== ""
                    ? ("file:///" + String(appController.dataDirectory).replace(/\\/g, "/"))
                    : (appController && appController.defaultExportDirectory !== ""
                        ? ("file:///" + String(appController.defaultExportDirectory).replace(/\\/g, "/"))
                        : "")
        nameFilters: [qsTr("Metadata Files (*.xlsx *.csv *.txt)"), qsTr("All Files (*.*)")]
        onAccepted: {
            var path = String(fileUrl).replace("file:///", "")
            var ok = appController.loadRawMetadata(path)
            if (ok) {
                showStatus(qsTr("✓ Metadata loaded successfully: %1 parameter definitions found.").arg(appController.rawParameterDefinitionCount), true)
            } else {
                showStatus(qsTr("✕ Metadata loading error: %1").arg(appController.lastError || qsTr("Error")), false)
            }
        }
    }

    // Raw Data File Dialog
    FileDialog {
        id: rawDataDialog
        title: qsTr("Select Raw Data File (.bin, .txt, .dat, .raw)")
        folder: appController && appController.dataDirectory !== ""
                    ? ("file:///" + String(appController.dataDirectory).replace(/\\/g, "/"))
                    : (appController && appController.defaultExportDirectory !== ""
                        ? ("file:///" + String(appController.defaultExportDirectory).replace(/\\/g, "/"))
                        : "")
        nameFilters: [qsTr("Raw Data Files (*.bin *.dat *.txt *.raw)"), qsTr("All Files (*.*)")]
        onAccepted: {
            var path = String(fileUrl).replace("file:///", "")
            var ok = appController.loadRawDataFile(path)
            if (ok) {
                showStatus(qsTr("✓ Raw data loaded successfully: %1 bytes read.").arg(appController.rawDataByteCount), true)
            } else {
                showStatus(qsTr("✕ Raw data loading error: %1").arg(appController.lastError || qsTr("Error")), false)
            }
        }
    }

    Connections {
        target: appController
        function onRawParseCompleted(success, message) {
            if (success) {
                showStatus(qsTr("✓ %1").arg(message), true)
            } else {
                showStatus(qsTr("✕ %1").arg(message), false)
            }
        }
    }

    ScrollView {
        id: pageScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: pageScrollView.availableWidth
            spacing: 18

            // Header banner
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 70
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: theme.accentSoft

                        Label {
                            anchors.centerIn: parent
                            text: "📡"
                            font.pixelSize: 18
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Label {
                            text: qsTr("Raw Data Parser (Telemetry / Sensor Engine)")
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Parse binary & telemetry raw packet data using bit-level definitions and import directly into the analysis pipeline.")
                            color: theme.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // Status message
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 40
                radius: 8
                color: page.statusSuccess ? theme.successSoft : theme.errorSoft
                border.color: page.statusSuccess ? theme.success : theme.error
                border.width: 1
                visible: page.statusMessage !== ""

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: page.statusMessage
                        color: page.statusSuccess ? theme.success : theme.error
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Cards Grid
            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                columns: 2
                columnSpacing: 18
                rowSpacing: 18

                // 1. Parameter Metadata Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                text: "📋 " + qsTr("1. Parameter Metadata")
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 24
                                radius: 12
                                color: appController && appController.rawMetadataLoaded ? theme.successSoft : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: appController && appController.rawMetadataLoaded ? qsTr("Loaded") : qsTr("Not Loaded")
                                    color: appController && appController.rawMetadataLoaded ? theme.success : theme.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: qsTr("Load metadata containing struct names, bit offsets, sizes, data types, and units.")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            text: appController && appController.rawMetadataLoaded
                                  ? qsTr("File: %1 (%2 parameters)").arg(appController.rawMetadataFilePath.split("/").pop()).arg(appController.rawParameterDefinitionCount)
                                  : qsTr("No metadata file selected.")
                            color: appController && appController.rawMetadataLoaded ? theme.text : theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            id: metaBtn
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignHCenter
                            text: appController && appController.rawMetadataLoaded ? qsTr("Change Metadata") : qsTr("Load Metadata (.xlsx)")
                            property bool clickFeedback: false
                            Timer {
                                id: metaTimer
                                interval: 450
                                onTriggered: metaBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: metaBtn.down ? theme.surfaceAlt : (metaBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: metaBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                metaTimer.restart()
                                metadataDialog.open()
                            }
                        }
                    }
                }

                // 2. Raw Data File Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                text: "📦 " + qsTr("2. Raw Data Source")
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 24
                                radius: 12
                                color: appController && appController.rawDataLoaded ? theme.successSoft : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: appController && appController.rawDataLoaded ? qsTr("Loaded") : qsTr("Not Loaded")
                                    color: appController && appController.rawDataLoaded ? theme.success : theme.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            text: qsTr("Load binary packets (.bin, .raw) or formatted hex strings (.txt, .dat).")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Label {
                            text: appController && appController.rawDataLoaded
                                  ? qsTr("File: %1 (%2 bytes)").arg(appController.rawDataFilePath.split("/").pop()).arg(appController.rawDataByteCount)
                                  : qsTr("No raw data file selected.")
                            color: appController && appController.rawDataLoaded ? theme.text : theme.textSecondary
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            id: rawFileBtn
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignHCenter
                            text: appController && appController.rawDataLoaded ? qsTr("Change Raw Data") : qsTr("Load Raw Data (.bin)")
                            property bool clickFeedback: false
                            Timer {
                                id: rawFileTimer
                                interval: 450
                                onTriggered: rawFileBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: rawFileBtn.down ? theme.surfaceAlt : (rawFileBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: rawFileBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                rawFileTimer.restart()
                                rawDataDialog.open()
                            }
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
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    ColumnLayout {
                        spacing: 2

                        Button {
                            id: parseBtn
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 38
                            text: qsTr("⚡ Parse Raw Data")
                            enabled: appController && appController.rawMetadataLoaded && appController.rawDataLoaded && !appController.rawParsing
                            onClicked: {
                                var ok = appController.parseRawData()
                                if (ok) {
                                    showStatus(qsTr("Parsing raw data in background..."), true)
                                } else {
                                    showStatus(qsTr("✕ Parsing error: %1").arg(appController.lastError || qsTr("Error")), false)
                                }
                            }

                            background: Rectangle {
                                radius: 8
                                color: parseBtn.down ? theme.surfaceAlt : (parseBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: (appController && appController.rawParsing) ? theme.success : theme.border
                                border.width: 1
                            }
                        }

                        Components.CompactProgress {
                            Layout.preferredWidth: 160
                            running: appController && appController.rawParsing
                            progress: appController ? appController.rawParseProgress : 0
                            theme: page.theme
                        }
                    }

                    Button {
                        id: cancelParseBtn
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 38
                        text: qsTr("Cancel")
                        visible: appController && appController.rawParsing
                        property bool clickFeedback: false
                        Timer {
                            id: cancelTimer
                            interval: 450
                            onTriggered: cancelParseBtn.clickFeedback = false
                        }
                        background: Rectangle {
                            radius: 8
                            color: cancelParseBtn.down ? theme.surfaceAlt : (cancelParseBtn.hovered ? theme.surfaceAlt : theme.surface)
                            border.color: cancelParseBtn.clickFeedback ? theme.success : theme.border
                            border.width: 1
                        }
                        onClicked: {
                            clickFeedback = true
                            cancelTimer.restart()
                            appController.cancelRawParsing()
                        }
                    }

                    Button {
                        id: clearParseBtn
                        Layout.preferredWidth: 130
                        Layout.preferredHeight: 38
                        text: qsTr("✕ Clear Results")
                        enabled: appController && !appController.rawParsing && (appController.rawParseAvailable || appController.rawMetadataLoaded || appController.rawDataLoaded)
                        property bool clickFeedback: false
                        Timer {
                            id: clearTimer
                            interval: 450
                            onTriggered: clearParseBtn.clickFeedback = false
                        }
                        background: Rectangle {
                            radius: 8
                            color: clearParseBtn.down ? theme.surfaceAlt : (clearParseBtn.hovered ? theme.surfaceAlt : theme.surface)
                            border.color: clearParseBtn.clickFeedback ? theme.success : theme.border
                            border.width: 1
                        }
                        onClicked: {
                            clickFeedback = true
                            clearTimer.restart()
                            appController.clearRawParse()
                            showStatus(qsTr("Results cleared."), true)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Import as Dataset buttons
                    Button {
                        id: importDs1Btn
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 38
                        text: qsTr("📥 Import as Dataset 1")
                        enabled: appController && appController.rawParseAvailable && !appController.rawParsing
                        property bool clickFeedback: false
                        Timer {
                            id: importDs1Timer
                            interval: 450
                            onTriggered: importDs1Btn.clickFeedback = false
                        }
                        background: Rectangle {
                            radius: 8
                            color: importDs1Btn.down ? theme.surfaceAlt : (importDs1Btn.hovered ? theme.surfaceAlt : theme.surface)
                            border.color: importDs1Btn.clickFeedback ? theme.success : theme.border
                            border.width: 1
                        }
                        onClicked: {
                            clickFeedback = true
                            importDs1Timer.restart()
                            var ok = appController.importParsedRawDataAsDataset(1, "Parsed_Raw_Packet_1")
                            if (ok) {
                                showStatus(qsTr("✓ Parsed packet imported as Dataset 1! Ready for analysis."), true)
                            } else {
                                showStatus(qsTr("✕ Import error: %1").arg(appController.lastError || qsTr("Error")), false)
                            }
                        }
                    }

                    Button {
                        id: importDs2Btn
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 38
                        text: qsTr("📥 Import as Dataset 2")
                        enabled: appController && appController.rawParseAvailable && !appController.rawParsing
                        property bool clickFeedback: false
                        Timer {
                            id: importDs2Timer
                            interval: 450
                            onTriggered: importDs2Btn.clickFeedback = false
                        }
                        background: Rectangle {
                            radius: 8
                            color: importDs2Btn.down ? theme.surfaceAlt : (importDs2Btn.hovered ? theme.surfaceAlt : theme.surface)
                            border.color: importDs2Btn.clickFeedback ? theme.success : theme.border
                            border.width: 1
                        }
                        onClicked: {
                            clickFeedback = true
                            importDs2Timer.restart()
                            var ok = appController.importParsedRawDataAsDataset(2, "Parsed_Raw_Packet_2")
                            if (ok) {
                                showStatus(qsTr("✓ Parsed packet imported as Dataset 2! Ready for analysis."), true)
                            } else {
                                showStatus(qsTr("✕ Import error: %1").arg(appController.lastError || qsTr("Error")), false)
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
                        text: qsTr("Parsed Parameters")
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

                            Label { Layout.preferredWidth: 200; text: qsTr("Parameter"); color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 180; text: qsTr("Value"); color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 140; text: qsTr("Type"); color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 100; text: qsTr("Unit"); color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Label { Layout.preferredWidth: 100; text: qsTr("Status"); color: theme.textSecondary; font.pixelSize: 12; font.bold: true }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Table Rows
                    Repeater {
                        model: appController ? appController.parameterModel : null

                        delegate: Rectangle {
                            property var itemData: model
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 6
                            color: index % 2 === 0 ? "transparent" : theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Label {
                                    Layout.preferredWidth: 200
                                    text: (itemData && itemData.dataName !== undefined) ? itemData.dataName : ""
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                }

                                Label {
                                    Layout.preferredWidth: 180
                                    text: (itemData && itemData.displayValue !== undefined) ? itemData.displayValue : ""
                                    color: (itemData && itemData.status === "Ok") ? theme.primary : (itemData && itemData.status === "Warning" ? theme.warning : theme.error)
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Label {
                                    Layout.preferredWidth: 140
                                    text: (itemData && itemData.dataType !== undefined) ? itemData.dataType : ""
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Label {
                                    Layout.preferredWidth: 100
                                    text: (itemData && itemData.unit !== undefined && itemData.unit !== "") ? itemData.unit : "-"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }

                                Rectangle {
                                    Layout.preferredWidth: 70
                                    Layout.preferredHeight: 22
                                    radius: 11
                                    color: (itemData && itemData.status === "Ok") ? theme.successSoft : (itemData && itemData.status === "Warning" ? theme.warningSoft : theme.errorSoft)

                                    Label {
                                        anchors.centerIn: parent
                                        text: (itemData && itemData.status !== undefined) ? itemData.status : ""
                                        color: (itemData && itemData.status === "Ok") ? theme.success : (itemData && itemData.status === "Warning" ? theme.warning : theme.error)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    // Empty / Parsing State
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !appController || !appController.parameterModel || appController.parameterModel.count === 0

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 10

                            Components.ByteMascot {
                                Layout.alignment: Qt.AlignHCenter
                                mascotWidth: 120
                                mascotHeight: 120
                                source: (appController && appController.rawParsing)
                                        ? "qrc:/assets/byte/byte_parsing.png"
                                        : "qrc:/assets/byte/byte_ready.png"
                                animated: appController && appController.rawParsing
                            }

                            Label {
                                Layout.alignment: Qt.AlignHCenter
                                text: (appController && appController.rawParsing)
                                      ? qsTr("Parsing raw data packets...")
                                      : qsTr("Load metadata and raw data to parse parameters.")
                                color: theme.textSecondary
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
