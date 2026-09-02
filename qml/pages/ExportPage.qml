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
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: pageScrollView.availableWidth
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 6
                title: qsTr("Dataset Export")
                subtitle: qsTr("Export cleaned and analyzed datasets into Excel, CSV, or JSON formats.")
                buttonVisible: false
            }

            // =================================================
            // COMPLETION / STATUS STATE AREA
            // =================================================

            Rectangle {
                visible: page.exportStatusMessage !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: page.exportSuccess ? 96 : 46
                radius: 12
                color: page.exportSuccess ? (theme.darkMode ? "#143823" : "#EAF7EE") : (theme.darkMode ? "#3D1717" : "#FDE8E8")
                border.width: 1
                border.color: page.exportSuccess ? theme.success : theme.danger

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Components.ByteMascot {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            mascotWidth: 32
                            mascotHeight: 32
                            source: page.exportSuccess ? "qrc:/assets/byte/byte_completed.png" : "qrc:/assets/byte/byte_error.png"
                            animated: false
                        }

                        Label {
                            text: page.exportSuccess ? "✓ " + page.exportStatusMessage : page.exportStatusMessage
                            color: page.exportSuccess ? theme.success : theme.danger
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            visible: page.exportSuccess && page.lastExportedPath !== ""
                            text: page.lastExportedPath
                            color: theme.textSecondary
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 400
                        }
                    }

                    RowLayout {
                        visible: page.exportSuccess
                        spacing: 12

                        Button {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 150
                            text: qsTr("Export Another File")
                            onClicked: page.clearStatus()
                            contentItem: Text {
                                text: parent.text
                                color: theme.text
                                font.pixelSize: 11
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
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 150
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
                                font.pixelSize: 11
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
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 160
                            text: qsTr("Back to Dashboard →")
                            onClicked: page.goToPage(0)
                            contentItem: Text {
                                text: parent.text
                                color: "#FFFFFF"
                                font.pixelSize: 11
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
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: selectCol.implicitHeight + 36
                radius: 14
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: selectCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Components.ByteMascot {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            mascotWidth: 26
                            mascotHeight: 26
                            source: "qrc:/assets/byte/byte_exporting.png"
                            animated: false
                        }

                        Label {
                            text: qsTr("1. Select Dataset to Export")
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: pageScrollView.availableWidth < 950 ? 1 : 2
                        columnSpacing: 14
                        rowSpacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Button {
                                id: ds1SelectBtn
                                Layout.fillWidth: true
                                Layout.maximumWidth: 320
                                Layout.preferredHeight: 40
                                text: qsTr("Dataset 1: %1").arg(page.datasetName(1))
                                enabled: page.isLoaded(1)
                                onClicked: {
                                    page.activeDataset = 1
                                    page.clearStatus()
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: !parent.enabled
                                           ? theme.textSecondary
                                           : (page.activeDataset === 1 ? theme.primary : theme.text)
                                    font.pixelSize: 12
                                    font.bold: page.activeDataset === 1
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideMiddle
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: page.activeDataset === 1
                                           ? (theme.darkMode ? "#1E2A38" : "#EBF3FB")
                                           : (parent.enabled ? theme.surface : theme.surfaceAlt)
                                    border.color: page.activeDataset === 1 ? theme.primary : theme.border
                                    border.width: page.activeDataset === 1 ? 2 : 1
                                }
                            }

                            Button {
                                id: ds2SelectBtn
                                Layout.fillWidth: true
                                Layout.maximumWidth: 320
                                Layout.preferredHeight: 40
                                text: qsTr("Dataset 2: %1").arg(page.datasetName(2))
                                enabled: page.isLoaded(2)
                                onClicked: {
                                    page.activeDataset = 2
                                    page.clearStatus()
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: !parent.enabled
                                           ? theme.textSecondary
                                           : (page.activeDataset === 2 ? theme.primary : theme.text)
                                    font.pixelSize: 12
                                    font.bold: page.activeDataset === 2
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideMiddle
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: page.activeDataset === 2
                                           ? (theme.darkMode ? "#1E2A38" : "#EBF3FB")
                                           : (parent.enabled ? theme.surface : theme.surfaceAlt)
                                    border.color: page.activeDataset === 2 ? theme.primary : theme.border
                                    border.width: page.activeDataset === 2 ? 2 : 1
                                }
                            }
                        }

                        // Summary info
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Item {
                                visible: pageScrollView.availableWidth >= 950
                                Layout.fillWidth: true
                            }

                            ColumnLayout {
                                spacing: 3
                                Label {
                                    text: qsTr("Rows: %1  |  Columns: %2")
                                            .arg(page.datasetRows(page.activeDataset))
                                            .arg(page.datasetColumns(page.activeDataset))
                                    color: theme.text
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Label {
                                    text: page.isLoaded(page.activeDataset)
                                            ? qsTr("✓ Status: Loaded (%1)").arg(page.datasetName(page.activeDataset))
                                            : qsTr("✕ Status: Not loaded")
                                    color: page.isLoaded(page.activeDataset) ? theme.success : theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // EXPORT ACTIONS CARD
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: formatCol.implicitHeight + 36
                radius: 14
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    id: formatCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Label {
                        text: qsTr("2. Choose Format & Export")
                        color: theme.text
                        font.pixelSize: 14
                        font.bold: true
                    }

                    GridLayout {
                        id: formatGrid
                        Layout.fillWidth: true
                        columns: pageScrollView.availableWidth < 880 ? 1 : (pageScrollView.availableWidth < 1220 ? 2 : 3)
                        columnSpacing: 14
                        rowSpacing: 14

                        // Excel Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            Layout.minimumWidth: 220
                            radius: 10
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.topMargin: 12
                                anchors.bottomMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 3
                                    Label {
                                        text: qsTr("Excel Spreadsheet")
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr(".xlsx format with formatted headers")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                Button {
                                    id: exportXlsxBtn
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredHeight: 36
                                    Layout.preferredWidth: 120
                                    text: qsTr("📥 Export Excel")
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
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: exportXlsxBtn.down ? theme.surfaceAlt : (exportXlsxBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportXlsxBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        xlsxTimer.restart()
                                        page.exportData("xlsx")
                                    }
                                }
                            }
                        }

                        // CSV Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            Layout.minimumWidth: 220
                            radius: 10
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.topMargin: 12
                                anchors.bottomMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 3
                                    Label {
                                        text: qsTr("CSV Document")
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr(".csv comma-separated tabular text")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                Button {
                                    id: exportCsvBtn
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredHeight: 36
                                    Layout.preferredWidth: 120
                                    text: qsTr("📥 Export CSV")
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
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: exportCsvBtn.down ? theme.surfaceAlt : (exportCsvBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportCsvBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        csvTimer.restart()
                                        page.exportData("csv")
                                    }
                                }
                            }
                        }

                        // JSON Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            Layout.minimumWidth: 220
                            radius: 10
                            color: theme.surfaceAlt
                            border.color: theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                anchors.topMargin: 12
                                anchors.bottomMargin: 12
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 3
                                    Label {
                                        text: qsTr("JSON Array")
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: qsTr(".json structured key-value array")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                Button {
                                    id: exportJsonBtn
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredHeight: 36
                                    Layout.preferredWidth: 120
                                    text: qsTr("📥 Export JSON")
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
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: exportJsonBtn.down ? theme.surfaceAlt : (exportJsonBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: exportJsonBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
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
