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

        title: qsTr("Select Dataset 1 File")

        selectExisting: true
        folder: page.appController && page.appController.dataDirectory !== ""
                    ? ("file:///" + page.appController.dataDirectory.replace(/\\/g, "/"))
                    : (page.appController && page.appController.defaultExportDirectory !== ""
                        ? ("file:///" + page.appController.defaultExportDirectory.replace(/\\/g, "/"))
                        : "")

        nameFilters: [
            qsTr("Supported Files (*.csv *.xlsx *.txt)"),
            qsTr("CSV Files (*.csv)"),
            qsTr("Excel Files (*.xlsx)"),
            qsTr("Text Files (*.txt)")
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

        title: qsTr("Select Dataset 2 File")

        selectExisting: true
        selectMultiple: false

        folder: page.appController && page.appController.dataDirectory !== ""
                    ? ("file:///" + page.appController.dataDirectory.replace(/\\/g, "/"))
                    : (page.appController && page.appController.defaultExportDirectory !== ""
                        ? ("file:///" + page.appController.defaultExportDirectory.replace(/\\/g, "/"))
                        : "")

        nameFilters: [
            qsTr("Supported Files (*.csv *.xlsx *.txt)"),
            qsTr("CSV Files (*.csv)"),
            qsTr("Excel Files (*.xlsx)"),
            qsTr("Text Files (*.txt)")
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
            return qsTr("Not loaded yet")

        if (number === 1)
            return page.appController.dataset1Name || qsTr("Not loaded yet")

        return page.appController.dataset2Name || qsTr("Not loaded yet")
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
        if (page.mainWindow) {
            if (page.mainWindow.navigateToPage)
                page.mainWindow.navigateToPage(index)
            else
                page.mainWindow.currentPage = index
        }
    }

    // =========================================================
    // ANA İÇERİK
    // =========================================================

    ScrollView {
        id: pageScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        readonly property real containerWidth: pageScrollView.availableWidth
        readonly property bool isNarrow: containerWidth < 700

        ColumnLayout {
            width: pageScrollView.availableWidth
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
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 0
                title: page.loadedCount === 2
                       ? qsTr("Both datasets ready")
                       : qsTr("Load your datasets")
                subtitle: page.loadedCount === 2
                          ? qsTr("Datasets loaded successfully. You can review the column structure below or proceed to Data Analysis.")
                          : qsTr("Both datasets must be loaded for full comparison and analysis.")
                buttonText: qsTr("Go to Data Analysis →")
                buttonVisible: page.loadedCount === 2
                onButtonClicked: page.goToPage(2)
            }

            // =================================================
            // DATASET KARTLARI
            // =================================================

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                columns: pageScrollView.isNarrow ? 1 : 2
                columnSpacing: 14
                rowSpacing: 14

                // =================================================
                // DATASET 1
                // =================================================

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: ds1Col.implicitHeight + 40

                    radius: 17
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: ds1Col
                        width: parent.width - 40
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 12

                            Components.ByteMascot {
                                sizeVariant: "section"
                                source: page.dataset1Loaded ? "qrc:/assets/byte/byte_dataset_loaded.png" : "qrc:/assets/byte/byte_ready.png"
                                animated: false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: 2

                                Label {
                                    text: qsTr("Dataset 1")
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: page.dataset1Loaded ? (page.dataset1Name || qsTr("Loaded")) : qsTr("Not loaded")
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 28
                                radius: 14
                                color: page.dataset1Loaded ? "#E6F6EE" : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: page.dataset1Loaded ? qsTr("Loaded") : qsTr("Pending")
                                    color: page.dataset1Loaded ? theme.success : theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: page.datasetName(1)
                            color: theme.textSecondary
                            font.pixelSize: 13
                            elide: Text.ElideMiddle
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 35

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: qsTr("Records")
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
                                    text: qsTr("Columns")
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

                        Button {
                            id: ds1Btn
                            Layout.fillWidth: true
                            Layout.maximumWidth: ds1Col.width
                            Layout.preferredHeight: 42
                            Layout.topMargin: 4

                            text:
                                page.dataset1Loaded
                                ? qsTr("Change Dataset 1")
                                : qsTr("Select Excel / CSV")

                            property bool clickFeedback: false
                            Timer {
                                id: ds1Timer
                                interval: 450
                                onTriggered: ds1Btn.clickFeedback = false
                            }

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
                                border.color: ds1Btn.clickFeedback ? theme.success : "transparent"
                                border.width: 1
                            }

                            onClicked: {
                                clickFeedback = true
                                ds1Timer.restart()
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
                    implicitHeight: ds2Col.implicitHeight + 40
                    radius: 17
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    ColumnLayout {
                        id: ds2Col
                        width: parent.width - 40
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 12

                            Components.ByteMascot {
                                sizeVariant: "section"
                                source: page.dataset2Loaded ? "qrc:/assets/byte/byte_dataset_loaded.png" : "qrc:/assets/byte/byte_ready.png"
                                animated: false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: 2

                                Label {
                                    text: qsTr("Dataset 2")
                                    color: theme.text
                                    font.pixelSize: 18
                                    font.bold: true
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: page.dataset2Loaded ? (page.dataset2Name || qsTr("Loaded")) : qsTr("Not loaded")
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 28
                                radius: 14
                                color: page.dataset2Loaded ? "#E6F6EE" : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: page.dataset2Loaded ? qsTr("Loaded") : qsTr("Pending")
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
                                    text: qsTr("Records")
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
                                    text: qsTr("Columns")
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

                        Button {
                            id: ds2Btn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            Layout.topMargin: 4

                            text:
                                page.dataset2Loaded
                                ? qsTr("Change Dataset 2")
                                : qsTr("Select Excel / CSV")

                            property bool clickFeedback: false
                            Timer {
                                id: ds2Timer
                                interval: 450
                                onTriggered: ds2Btn.clickFeedback = false
                            }

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
                                border.color: ds2Btn.clickFeedback ? theme.success : "transparent"
                                border.width: 1
                            }

                            onClicked: {
                                clickFeedback = true
                                ds2Timer.restart()
                                dataset2Dialog.open()
                            }
                        }
                    }
                }
            }

            // ================================================================
            // RECENT FILES QUICK ACCESS
            // =================================================

            Rectangle {
                visible: page.appController && page.appController.recentFiles && page.appController.recentFiles.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.min(220, 70 + (page.appController ? page.appController.recentFiles.length : 0) * 50)
                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: qsTr("📂 Recent Files (Quick Load)")
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: qsTr("Select a dataset to load")
                            color: theme.textSecondary
                            font.pixelSize: 11
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 6
                        model: page.appController ? page.appController.recentFiles : []

                        delegate: Rectangle {
                            id: recentDelegate
                            width: parent.width
                            readonly property bool isCompact: width < 520
                            height: isCompact ? 76 : 44
                            radius: 8
                            color: theme.background
                            border.width: 1
                            border.color: theme.border

                            // Wide Layout (single line)
                            RowLayout {
                                visible: !recentDelegate.isCompact
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Label {
                                    text: "📄"
                                    font.pixelSize: 14
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    spacing: 2
                                    Label {
                                        text: modelData.name || ""
                                        color: theme.text
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                    }
                                    Label {
                                        text: (modelData.type || "") + " • " + (modelData.path || "")
                                        color: theme.textSecondary
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                    }
                                }

                                Button {
                                    id: setDs1Btn
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: 120
                                    text: qsTr("Set as Dataset 1")
                                    font.pixelSize: 10
                                    property bool clickFeedback: false
                                    Timer {
                                        id: setDs1Timer
                                        interval: 450
                                        onTriggered: setDs1Btn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: setDs1Btn.down ? theme.surfaceAlt : (setDs1Btn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: setDs1Btn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        setDs1Timer.restart()
                                        if (page.appController && modelData.path) {
                                            page.appController.loadRecentFileAsDataset(1, modelData.path)
                                        }
                                    }
                                }

                                Button {
                                    id: setDs2Btn
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: 120
                                    text: qsTr("Set as Dataset 2")
                                    font.pixelSize: 10
                                    property bool clickFeedback: false
                                    Timer {
                                        id: setDs2Timer
                                        interval: 450
                                        onTriggered: setDs2Btn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: setDs2Btn.down ? theme.surfaceAlt : (setDs2Btn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: setDs2Btn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        setDs2Timer.restart()
                                        if (page.appController && modelData.path) {
                                            page.appController.loadRecentFileAsDataset(2, modelData.path)
                                        }
                                    }
                                }
                            }

                            // Compact Layout (2 lines)
                            ColumnLayout {
                                visible: recentDelegate.isCompact
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        text: "📄"
                                        font.pixelSize: 13
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        spacing: 1
                                        Label {
                                            text: modelData.name || ""
                                            color: theme.text
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                        }
                                        Label {
                                            text: (modelData.type || "") + " • " + (modelData.path || "")
                                            color: theme.textSecondary
                                            font.pixelSize: 9
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26
                                        text: qsTr("Set as Dataset 1")
                                        font.pixelSize: 10
                                        background: Rectangle {
                                            radius: 5
                                            color: parent.down ? theme.surfaceAlt : (parent.hovered ? theme.surfaceAlt : theme.surface)
                                            border.color: theme.border
                                            border.width: 1
                                        }
                                        onClicked: {
                                            if (page.appController && modelData.path) {
                                                page.appController.loadRecentFileAsDataset(1, modelData.path)
                                            }
                                        }
                                    }

                                    Button {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26
                                        text: qsTr("Set as Dataset 2")
                                        font.pixelSize: 10
                                        background: Rectangle {
                                            radius: 5
                                            color: parent.down ? theme.surfaceAlt : (parent.hovered ? theme.surfaceAlt : theme.surface)
                                            border.color: theme.border
                                            border.width: 1
                                        }
                                        onClicked: {
                                            if (page.appController && modelData.path) {
                                                page.appController.loadRecentFileAsDataset(2, modelData.path)
                                            }
                                        }
                                    }
                                }
                            }
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

                title: qsTr("Dataset 1 Column Structure")
                datasetName: page.datasetName(1)
                rowCount: page.datasetRows(1)
                columnCount: page.datasetColumns(1)
                sheetName: page.appController ? page.appController.dataset1SheetName : ""
                model: page.appController ? page.appController.dataset1ColumnModel : null
            }

            // =================================================
            // HAM VERİ (RAW DATA) AYRIŞTIRMA KARTI
            // =================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: rawBannerRow.implicitHeight + 32
                radius: 14
                color: theme.surfaceAlt
                border.color: theme.border

                GridLayout {
                    id: rawBannerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    columns: pageScrollView.isNarrow ? 1 : 3
                    rowSpacing: 12
                    columnSpacing: 14

                    Rectangle {
                        Layout.alignment: pageScrollView.isNarrow ? Qt.AlignLeft : Qt.AlignVCenter
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
                        Layout.minimumWidth: 0
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        Label {
                            text: qsTr("Raw Data & Metadata Parsing")
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: qsTr("Parse binary/text raw packet data streams using protocol metadata and inspect as tabular datasets.")
                            color: theme.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }
                    }

                    Button {
                        Layout.alignment: pageScrollView.isNarrow ? Qt.AlignLeft : Qt.AlignVCenter
                        Layout.preferredWidth: pageScrollView.isNarrow ? Math.min(240, rawBannerRow.width - 32) : 210
                        Layout.preferredHeight: 38
                        text: qsTr("⚡ Parse Raw Data →")
                        onClicked: page.goToPage(7)
                    }
                }
            }

            Components.DatasetDetails {
                visible: page.dataset2Loaded
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28

                title: qsTr("Dataset 2 Column Structure")
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
                implicitHeight: errorLabel.implicitHeight + 30

                radius: 12
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.error

                Label {
                    id: errorLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
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