import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform

import "../" as AppTheme
import "../components" as Components

Item {
    id: page

    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    function isLoaded(ds) {
        if (!appController) return false
        return ds === 1 ? (appController.dataset1Name !== "") : (appController.dataset2Name !== "")
    }

    function datasetName(ds) {
        if (!appController) return qsTr("Not loaded")
        var n = ds === 1 ? appController.dataset1Name : appController.dataset2Name
        return n && n !== "" ? n : qsTr("Not loaded")
    }

    function datasetRows(ds) {
        if (!appController) return 0
        return ds === 1 ? appController.dataset1RowCount : appController.dataset2RowCount
    }

    function datasetColumns(ds) {
        if (!appController) return 0
        return ds === 1 ? appController.dataset1ColumnCount : appController.dataset2ColumnCount
    }

    property int activeDataset: isLoaded(1) ? 1 : (isLoaded(2) ? 2 : 1)
    property string pendingExportFormat: ""

    property string exportStatusMessage: ""
    property bool exportSuccess: true
    property string lastExportedPath: ""

    // =========================================================
    // RESPONSIVE DIMENSIONS & BREAKPOINTS
    // =========================================================
    readonly property real containerWidth: pageScrollView.availableWidth
    readonly property bool isWide: containerWidth >= 1050
    readonly property bool isMedium: containerWidth >= 700 && containerWidth < 1050
    readonly property bool isNarrow: containerWidth < 700

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onDataset1Changed() {
            if (page.isLoaded(1) && !page.isLoaded(2)) {
                page.activeDataset = 1
            }
        }

        function onDataset2Changed() {
            if (!page.isLoaded(1) && page.isLoaded(2)) {
                page.activeDataset = 2
            }
        }
    }

    function goToPage(index) {
        if (page.mainWindow) {
            if (page.mainWindow.navigateToPage)
                page.mainWindow.navigateToPage(index)
            else
                page.mainWindow.currentPage = index
        }
    }

    function clearStatus() {
        page.exportStatusMessage = ""
        page.lastExportedPath = ""
    }

    Platform.FileDialog {
        id: exportFileDialog
        title: qsTr("Export Dataset")
        fileMode: Platform.FileDialog.SaveFile
        folder: page.appController && page.appController.defaultExportDirectory !== ""
                    ? ("file:///" + page.appController.defaultExportDirectory.replace(/\\/g, "/").replace(/^\/+/, ""))
                    : ""
        defaultSuffix: page.pendingExportFormat

        onAccepted: {
            if (!page.appController) return
            var rawUrl = (currentFile || file).toString()
            var ok = page.appController.exportDataset(page.activeDataset, rawUrl, page.pendingExportFormat)
            if (ok) {
                var cleanPath = rawUrl.replace(/^file:\/\/\//, "").replace(/^file:\/\//, "")
                page.exportSuccess = true
                page.lastExportedPath = cleanPath
                page.exportStatusMessage = qsTr("Export completed successfully.")
            } else {
                page.exportSuccess = false
                page.lastExportedPath = ""
                page.exportStatusMessage = qsTr("✕ Export error: %1").arg(page.appController.lastError || qsTr("Error"))
            }
        }

        onRejected: {
            // Cancel durumunda hicbir export veya success notification olusturulmaz
        }
    }

    function exportData(format) {
        if (!appController) return
        if (!page.isLoaded(page.activeDataset)) {
            page.exportSuccess = false
            page.exportStatusMessage = qsTr("✕ Dataset %1 is not loaded.").arg(page.activeDataset)
            return
        }

        page.clearStatus()
        page.pendingExportFormat = format.toLowerCase()

        var suggestedName = appController.suggestedExportFileName(page.activeDataset, page.pendingExportFormat)
        var defDir = appController.defaultExportDirectory.replace(/\\/g, "/").replace(/^\/+/, "")
        var folderUrl = "file:///" + defDir
        var fullFileUrl = folderUrl + "/" + suggestedName

        exportFileDialog.folder = folderUrl
        exportFileDialog.currentFile = fullFileUrl
        exportFileDialog.title = qsTr("Export Dataset %1 (%2)").arg(page.activeDataset).arg(format.toUpperCase())
        exportFileDialog.defaultSuffix = page.pendingExportFormat

        if (page.pendingExportFormat === "xlsx") {
            exportFileDialog.nameFilters = [ qsTr("Excel Files (*.xlsx)"), qsTr("All Files (*)") ]
        } else if (page.pendingExportFormat === "csv") {
            exportFileDialog.nameFilters = [ qsTr("CSV Files (*.csv)"), qsTr("All Files (*)") ]
        } else if (page.pendingExportFormat === "json") {
            exportFileDialog.nameFilters = [ qsTr("JSON Files (*.json)"), qsTr("All Files (*)") ]
        } else {
            exportFileDialog.nameFilters = [ qsTr("All Files (*)") ]
        }

        exportFileDialog.open()
    }

    ScrollView {
        id: pageScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: mainCol.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: mainCol
            objectName: "mainCol"
            width: pageScrollView.availableWidth
            spacing: 16

            Item { Layout.preferredHeight: 4 }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 5
                title: qsTr("Dataset Export")
                subtitle: qsTr("Export cleaned and analyzed datasets into Excel, CSV, or JSON formats.")
                buttonVisible: false
            }

            // =================================================
            // HERO / OVERVIEW CARD WITH PROMINENT BYTE MASCOT
            // =================================================

            Rectangle {
                id: heroCard
                objectName: "heroCard"
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: heroLayout.implicitHeight + 36
                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    id: heroLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 18

                    // Prominent responsive Byte mascot
                    Components.ByteMascot {
                        Layout.alignment: Qt.AlignVCenter
                        sizeVariant: "hero"
                        source: page.exportStatusMessage !== ""
                                ? (page.exportSuccess ? "qrc:/assets/byte/byte_completed.png" : "qrc:/assets/byte/byte_error.png")
                                : (page.isLoaded(page.activeDataset) ? "qrc:/assets/byte/byte_exporting.png" : "qrc:/assets/byte/byte_ready.png")
                        animated: false
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: qsTr("Dataset Export Studio")
                                color: theme.text
                                font.pixelSize: page.isNarrow ? 15 : 18
                                font.bold: true
                            }

                            Rectangle {
                                visible: page.isLoaded(page.activeDataset)
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: 85
                                radius: 11
                                color: theme.darkMode ? "#1C3B2B" : "#E8F7EE"
                                border.width: 1
                                border.color: theme.success

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("Ready")
                                    color: theme.success
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Save your processed, cleaned and analyzed data. Choose between Excel (.xlsx) for spreadsheets, CSV (.csv) for database ingestion, or JSON (.json) for web applications.")
                            color: theme.textSecondary
                            font.pixelSize: page.isNarrow ? 11 : 12
                            wrapMode: Text.WordWrap
                        }

                        // Selected Dataset Quick Summary Pill
                        Rectangle {
                            Layout.preferredHeight: 26
                            Layout.preferredWidth: summaryPillRow.implicitWidth + 20
                            radius: 13
                            color: theme.surface
                            border.color: theme.border
                            border.width: 1

                            RowLayout {
                                id: summaryPillRow
                                anchors.centerIn: parent
                                spacing: 6

                                Label {
                                    text: qsTr("Target:")
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                Label {
                                    text: qsTr("Dataset %1 (%2)").arg(page.activeDataset).arg(page.datasetName(page.activeDataset))
                                    color: page.isLoaded(page.activeDataset) ? theme.primary : theme.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    Layout.maximumWidth: page.isNarrow ? 180 : 320
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // COMPLETION / STATUS STATE AREA
            // =================================================

            Rectangle {
                id: statusCard
                visible: page.exportStatusMessage !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: visible ? (statusCol.implicitHeight + 28) : 0
                radius: 12
                color: page.exportSuccess ? (theme.darkMode ? "#143823" : "#EAF7EE") : (theme.darkMode ? "#3D1717" : "#FDE8E8")
                border.width: 1
                border.color: page.exportSuccess ? theme.success : theme.danger

                ColumnLayout {
                    id: statusCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label {
                            text: page.exportSuccess ? "✓ " + page.exportStatusMessage : page.exportStatusMessage
                            color: page.exportSuccess ? theme.success : theme.danger
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            visible: page.exportSuccess && page.lastExportedPath !== ""
                            text: page.lastExportedPath
                            color: theme.textSecondary
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: page.isNarrow ? 160 : 360
                        }
                    }

                    // Action buttons in a responsive flow
                    GridLayout {
                        visible: page.exportSuccess
                        Layout.fillWidth: true
                        columns: page.isNarrow ? 1 : 3
                        columnSpacing: 10
                        rowSpacing: 8

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            text: qsTr("Export Another File")
                            onClicked: page.clearStatus()
                            contentItem: Text {
                                text: parent.text
                                color: theme.text
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: theme.surface
                                border.color: theme.border
                                border.width: 1
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            text: qsTr("Open File Location")
                            visible: page.lastExportedPath !== ""
                            onClicked: {
                                if (appController && page.lastExportedPath !== "") {
                                    appController.openInExplorer(page.lastExportedPath)
                                }
                            }
                            contentItem: Text {
                                text: parent.text
                                color: theme.text
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: theme.surface
                                border.color: theme.border
                                border.width: 1
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            text: qsTr("Back to Dashboard →")
                            onClicked: page.goToPage(0)
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: 6
                                color: theme.primary
                            }
                        }
                    }
                }
            }

            // =================================================
            // DATASET SELECTION CARD
            // =================================================

            Rectangle {
                id: datasetCard
                objectName: "datasetCard"
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: datasetCol.implicitHeight + 36
                radius: 14
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: datasetCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("1. Select Dataset to Export")
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Choose the dataset to export. Any cleaning modifications will be reflected in the exported file.")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Responsive Dataset Selector & Status Area
                    GridLayout {
                        Layout.fillWidth: true
                        columns: page.isNarrow ? 1 : 2
                        columnSpacing: 14
                        rowSpacing: 12

                        // Dataset 1 Selector Button
                        Button {
                            id: ds1SelectBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            enabled: page.isLoaded(1)
                            onClicked: {
                                page.activeDataset = 1
                                page.clearStatus()
                            }
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 10
                                    Layout.preferredHeight: 10
                                    radius: 5
                                    color: page.activeDataset === 1
                                           ? theme.primary
                                           : (page.isLoaded(1) ? theme.success : theme.textSecondary)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr("Dataset 1") + (page.isLoaded(1) ? ": " + page.datasetName(1) : qsTr(" (Not loaded)"))
                                        color: !parent.enabled
                                               ? theme.textSecondary
                                               : (page.activeDataset === 1 ? theme.primary : theme.text)
                                        font.pixelSize: 13
                                        font.bold: page.activeDataset === 1
                                        elide: Text.ElideMiddle
                                    }

                                    Label {
                                        text: page.isLoaded(1)
                                              ? qsTr("%1 rows · %2 columns").arg(page.datasetRows(1)).arg(page.datasetColumns(1))
                                              : qsTr("No data loaded")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                    }
                                }

                                Label {
                                    visible: page.activeDataset === 1
                                    text: "✓"
                                    color: theme.primary
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            background: Rectangle {
                                radius: 8
                                color: page.activeDataset === 1
                                       ? (theme.darkMode ? "#1E2A38" : "#EBF3FB")
                                       : (parent.enabled ? theme.surfaceAlt : theme.surface)
                                border.color: page.activeDataset === 1 ? theme.primary : theme.border
                                border.width: page.activeDataset === 1 ? 2 : 1
                            }
                        }

                        // Dataset 2 Selector Button
                        Button {
                            id: ds2SelectBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            enabled: page.isLoaded(2)
                            onClicked: {
                                page.activeDataset = 2
                                page.clearStatus()
                            }
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 10
                                    Layout.preferredHeight: 10
                                    radius: 5
                                    color: page.activeDataset === 2
                                           ? theme.primary
                                           : (page.isLoaded(2) ? theme.success : theme.textSecondary)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr("Dataset 2") + (page.isLoaded(2) ? ": " + page.datasetName(2) : qsTr(" (Not loaded)"))
                                        color: !parent.enabled
                                               ? theme.textSecondary
                                               : (page.activeDataset === 2 ? theme.primary : theme.text)
                                        font.pixelSize: 13
                                        font.bold: page.activeDataset === 2
                                        elide: Text.ElideMiddle
                                    }

                                    Label {
                                        text: page.isLoaded(2)
                                              ? qsTr("%1 rows · %2 columns").arg(page.datasetRows(2)).arg(page.datasetColumns(2))
                                              : qsTr("No data loaded")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                    }
                                }

                                Label {
                                    visible: page.activeDataset === 2
                                    text: "✓"
                                    color: theme.primary
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            background: Rectangle {
                                radius: 8
                                color: page.activeDataset === 2
                                       ? (theme.darkMode ? "#1E2A38" : "#EBF3FB")
                                       : (parent.enabled ? theme.surfaceAlt : theme.surface)
                                border.color: page.activeDataset === 2 ? theme.primary : theme.border
                                border.width: page.activeDataset === 2 ? 2 : 1
                            }
                        }
                    }
                }
            }

            // =================================================
            // EXPORT FORMAT CARDS (RESPONSIVE GRID)
            // =================================================

            Rectangle {
                id: formatCard
                objectName: "formatCard"
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: formatCol.implicitHeight + 36
                radius: 14
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: formatCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("2. Choose Format & Export")
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Select your desired export format below. The file save dialog will prompt for destination.")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Responsive Grid: Wide = 3 Columns, Medium = 2 Columns, Narrow = 1 Column
                    GridLayout {
                        id: formatGrid
                        Layout.fillWidth: true
                        columns: page.isWide ? 3 : (page.isMedium ? 2 : 1)
                        columnSpacing: 16
                        rowSpacing: 16

                        // =================================================
                        // Excel Card (.xlsx)
                        // =================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 220
                            implicitHeight: excelCardCol.implicitHeight + 32
                            radius: 12
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            ColumnLayout {
                                id: excelCardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 8
                                        color: theme.darkMode ? "#143823" : "#EAF7EE"
                                        border.color: theme.success
                                        border.width: 1

                                        Label {
                                            anchors.centerIn: parent
                                            text: "📊"
                                            font.pixelSize: 18
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: qsTr("Excel Spreadsheet")
                                            color: theme.text
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Label {
                                            text: qsTr(".xlsx standard format")
                                            color: theme.success
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Full multi-column workbook with formatted headers and auto-detected cell types.")
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.minimumHeight: 36
                                }

                                Button {
                                    id: exportXlsxBtn
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    text: qsTr("📥 Export Excel (.xlsx)")
                                    enabled: page.isLoaded(page.activeDataset)
                                    property bool clickFeedback: false
                                    Timer {
                                        id: xlsxTimer
                                        interval: 450
                                        onTriggered: exportXlsxBtn.clickFeedback = false
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.enabled ? theme.text : theme.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: exportXlsxBtn.down ? theme.surfaceAlt : (exportXlsxBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportXlsxBtn.clickFeedback ? theme.success : (parent.enabled ? theme.primary : theme.border)
                                        border.width: exportXlsxBtn.hovered ? 2 : 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        xlsxTimer.restart()
                                        page.exportData("xlsx")
                                    }
                                }
                            }
                        }

                        // =================================================
                        // CSV Card (.csv)
                        // =================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 220
                            implicitHeight: csvCardCol.implicitHeight + 32
                            radius: 12
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            ColumnLayout {
                                id: csvCardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 8
                                        color: theme.darkMode ? "#1E2A38" : "#EBF3FB"
                                        border.color: theme.info
                                        border.width: 1

                                        Label {
                                            anchors.centerIn: parent
                                            text: "📄"
                                            font.pixelSize: 18
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: qsTr("CSV Document")
                                            color: theme.text
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Label {
                                            text: qsTr(".csv tabular text")
                                            color: theme.info
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Comma-separated values text format, ideal for data pipelines, scripts, and SQL databases.")
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.minimumHeight: 36
                                }

                                Button {
                                    id: exportCsvBtn
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    text: qsTr("📥 Export CSV (.csv)")
                                    enabled: page.isLoaded(page.activeDataset)
                                    property bool clickFeedback: false
                                    Timer {
                                        id: csvTimer
                                        interval: 450
                                        onTriggered: exportCsvBtn.clickFeedback = false
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.enabled ? theme.text : theme.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: exportCsvBtn.down ? theme.surfaceAlt : (exportCsvBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportCsvBtn.clickFeedback ? theme.success : (parent.enabled ? theme.primary : theme.border)
                                        border.width: exportCsvBtn.hovered ? 2 : 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        csvTimer.restart()
                                        page.exportData("csv")
                                    }
                                }
                            }
                        }

                        // =================================================
                        // JSON Card (.json)
                        // =================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 220
                            implicitHeight: jsonCardCol.implicitHeight + 32
                            radius: 12
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            ColumnLayout {
                                id: jsonCardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 8
                                        color: theme.darkMode ? "#362A1A" : "#FFF4E5"
                                        border.color: theme.warning
                                        border.width: 1

                                        Label {
                                            anchors.centerIn: parent
                                            text: "🧩"
                                            font.pixelSize: 18
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: qsTr("JSON Array")
                                            color: theme.text
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Label {
                                            text: qsTr(".json key-value array")
                                            color: theme.warning
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Structured array of row objects with key-value pairs, ready for REST APIs and web apps.")
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    Layout.minimumHeight: 36
                                }

                                Button {
                                    id: exportJsonBtn
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    text: qsTr("📥 Export JSON (.json)")
                                    enabled: page.isLoaded(page.activeDataset)
                                    property bool clickFeedback: false
                                    Timer {
                                        id: jsonTimer
                                        interval: 450
                                        onTriggered: exportJsonBtn.clickFeedback = false
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.enabled ? theme.text : theme.textSecondary
                                        font.pixelSize: 13
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: exportJsonBtn.down ? theme.surfaceAlt : (exportJsonBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportJsonBtn.clickFeedback ? theme.success : (parent.enabled ? theme.primary : theme.border)
                                        border.width: exportJsonBtn.hovered ? 2 : 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        jsonTimer.restart()
                                        page.exportData("json")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 24 }
        }
    }
}
