import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Item {
    id: page

    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    function go(index) {
        if (page.mainWindow)
            page.mainWindow.currentPage = index
    }

    function loaded(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1Name !== ""
                : page.appController.dataset2Name !== ""
    }

    function name(dataset) {
        if (!page.appController)
            return qsTr("Not loaded")

        var value = dataset === 1
                ? page.appController.dataset1Name
                : page.appController.dataset2Name

        return value !== "" ? value : qsTr("Not loaded")
    }

    function rows(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1RowCount
                : page.appController.dataset2RowCount
    }

    function columns(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1ColumnCount
                : page.appController.dataset2ColumnCount
    }

    function qualityAvailable(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1QualityAvailable
                : page.appController.dataset2QualityAvailable
    }

    function problemCount(dataset) {
        if (!qualityAvailable(dataset))
            return 0

        var result = dataset === 1
                ? page.appController.dataset1QualityResult
                : page.appController.dataset2QualityResult

        var hasMissing = (Number(result.totalMissingValues || 0) > 0 || Number(result.columnsWithMissingValues || 0) > 0) ? 1 : 0
        var hasDuplicates = Number(result.duplicateRowCount || 0) > 0 ? 1 : 0
        var hasConstants = Number(result.constantColumnCount || 0) > 0 ? 1 : 0

        var isOutlierAvail = dataset === 1
                ? (page.appController && page.appController.dataset1OutlierAvailable)
                : (page.appController && page.appController.dataset2OutlierAvailable)
        var outResult = dataset === 1
                ? (page.appController ? page.appController.dataset1OutlierResult : null)
                : (page.appController ? page.appController.dataset2OutlierResult : null)
        var hasOutliers = 0
        if (isOutlierAvail && outResult) {
            hasOutliers = Number(outResult.outlierCount || 0) > 0 ? 1 : 0
        } else if (result && (result.hasOutliers === true || Number(result.outlierCount || 0) > 0)) {
            hasOutliers = 1
        }

        return hasMissing + hasDuplicates + hasConstants + hasOutliers
    }

    function datasetStatus(dataset) {
        if (!loaded(dataset))
            return qsTr("No file loaded")

        if (!qualityAvailable(dataset))
            return qsTr("Pending analysis")

        if (problemCount(dataset) > 0)
            return qsTr("⚠ Review required")

        var isModified = dataset === 1
            ? (page.appController && page.appController.dataset1Modified)
            : (page.appController && page.appController.dataset2Modified)

        return isModified
                ? qsTr("✓ Cleaned / Updated")
                : qsTr("✓ Ready for analysis")
    }

    function datasetStatusColor(dataset) {
        if (!loaded(dataset) || !qualityAvailable(dataset))
            return theme.textSecondary

        return problemCount(dataset) > 0
                ? theme.warning
                : theme.success
    }

    function isStepCompleted(stepIndex) {
        if (!page.appController)
            return false

        switch (stepIndex) {
        case 1:
            return page.loaded(1) || page.loaded(2)
        case 2:
            return (page.loaded(1) && page.qualityAvailable(1)) ||
                   (page.loaded(2) && page.qualityAvailable(2))
        case 3:
            return (page.loaded(1) || page.loaded(2)) &&
                   (page.appController.cleaningCompleted ||
                    page.appController.dataset1Modified ||
                    page.appController.dataset2Modified ||
                    (page.qualityAvailable(1) && page.problemCount(1) === 0 && (!page.loaded(2) || page.problemCount(2) === 0)))
        case 4:
            return page.appController.datasetComparisonAvailable
        case 5:
            return page.appController.visualizationAvailable
        default:
            return false
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

            // =================================================
            // HEADER
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 24
                spacing: 5
            }

            // =================================================
            // QUICK START
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 118

                radius: 18
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Start the analysis workflow")
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Load your datasets to complete data quality, statistics, outlier cleaning and comparison in one smooth workflow.")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 42
                        text: qsTr("Go to Datasets →")
                        onClicked: page.go(1)

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 9
                            color: theme.primary
                        }
                    }
                }
            }

            // =================================================
            // DATASET CARDS
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        id: datasetCard

                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        radius: 16
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

                        property int dataset: index + 1
                        property bool isLoaded: page.loaded(dataset)
                        property bool hasProblems: page.problemCount(dataset) > 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("DATASET %1").arg(datasetCard.dataset)
                                    color: theme.primary
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.datasetStatus(datasetCard.dataset)
                                    color: page.datasetStatusColor(datasetCard.dataset)
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Label {
                                text: page.name(datasetCard.dataset)
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Label {
                                text:
                                    datasetCard.isLoaded
                                    ? qsTr("%1 records  •  %2 columns").arg(page.rows(datasetCard.dataset)).arg(page.columns(datasetCard.dataset))
                                    : qsTr("No file loaded")
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }

                            Label {
                                property bool isMod: datasetCard.dataset === 1
                                    ? (page.appController && page.appController.dataset1Modified)
                                    : (page.appController && page.appController.dataset2Modified)

                                text:
                                    datasetCard.isLoaded && page.qualityAvailable(datasetCard.dataset)
                                    ? (datasetCard.hasProblems
                                       ? (page.problemCount(datasetCard.dataset) === 1
                                          ? qsTr("1 data quality issue detected.")
                                          : qsTr("%1 data quality issues detected.").arg(page.problemCount(datasetCard.dataset)))
                                       : (isMod
                                          ? qsTr("Cleaning applied (all issues resolved)")
                                          : qsTr("No data quality issues detected.")))
                                    : qsTr("Analysis result not yet generated.")
                                color:
                                    datasetCard.hasProblems ? theme.warning : (isMod ? theme.success : theme.textSecondary)
                                font.pixelSize: 12
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Button {
                                Layout.preferredWidth: 160
                                Layout.preferredHeight: 36

                                text:
                                    !datasetCard.isLoaded
                                    ? qsTr("Go to Datasets")
                                    : qsTr("Go to Data Analysis →")

                                onClicked:
                                    page.go(
                                        datasetCard.isLoaded ? 2 : 1
                                    )

                                contentItem: Text {
                                    text: parent.text
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    radius: 8
                                    color: theme.primary
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // WORKFLOW
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 185

                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Label {
                        text: qsTr("Analysis Workflow")
                        color: theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Label {
                        text: qsTr("Each step guides you through the full data pipeline.")
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Repeater {
                            model: [
                                {
                                    number: "01",
                                    title: qsTr("Datasets"),
                                    description: qsTr("Load and preview Excel / CSV / Text"),
                                    pageIndex: 1
                                },
                                {
                                    number: "02",
                                    title: qsTr("Data Analysis"),
                                    description: qsTr("Quality, statistics and outlier inspection"),
                                    pageIndex: 2
                                },
                                {
                                    number: "03",
                                    title: qsTr("Data Cleaning"),
                                    description: qsTr("Resolve issues and clean data"),
                                    pageIndex: 3
                                },
                                {
                                    number: "04",
                                    title: qsTr("Comparison"),
                                    description: qsTr("Map columns and compare differences"),
                                    pageIndex: 4
                                },
                                {
                                    number: "05",
                                    title: qsTr("Visualization"),
                                    description: qsTr("Generate charts and export results"),
                                    pageIndex: 5
                                }
                            ]

                            delegate: Rectangle {
                                id: workflowCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                radius: 11
                                color: workflowMouse.containsMouse
                                       ? theme.surfaceAlt
                                       : theme.background
                                border.width: workflowMouse.containsMouse ? 1 : 0
                                border.color: theme.primary

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Label {
                                            text: modelData.number
                                            color: page.isStepCompleted(modelData.pageIndex)
                                                   ? theme.success
                                                   : theme.primary
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            visible: page.isStepCompleted(modelData.pageIndex)
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 85
                                            radius: 10
                                            color: "#E6F6EE"
                                            border.width: 1
                                            border.color: theme.success

                                            Label {
                                                anchors.centerIn: parent
                                                text: qsTr("✓ Completed")
                                                color: theme.success
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Label {
                                        text: modelData.title
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Label {
                                        text: modelData.description
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                    }

                                    Label {
                                        text: page.isStepCompleted(modelData.pageIndex) ? qsTr("View →") : qsTr("Open →")
                                        color: page.isStepCompleted(modelData.pageIndex) ? theme.success : theme.primary
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: workflowMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: page.go(modelData.pageIndex)
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // RECENT SESSION & ACTIVITY HISTORY CARD
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 330
                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Card Header & Actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 8
                                Label {
                                    text: qsTr("🕒 Recent Operations & Session History")
                                    color: theme.text
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Rectangle {
                                    visible: page.appController && page.appController.sessionRestored
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 140
                                    radius: 10
                                    color: "#E6F6EE"
                                    border.width: 1
                                    border.color: theme.success

                                    Label {
                                        anchors.centerIn: parent
                                        text: qsTr("✓ Session Restored")
                                        color: theme.success
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Label {
                                text: qsTr("Files from your previous session and recent analysis / cleaning activities.")
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Button {
                            id: restoreSessionBtn
                            visible: page.appController && page.appController.hasPreviousSession && !page.appController.sessionRestored
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: 180
                            text: qsTr("🔄 Restore Last Session")
                            property bool clickFeedback: false
                            Timer {
                                id: restoreSessionTimer
                                interval: 450
                                onTriggered: restoreSessionBtn.clickFeedback = false
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
                                radius: 8
                                color: restoreSessionBtn.down ? theme.surfaceAlt : (restoreSessionBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: restoreSessionBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                restoreSessionTimer.restart()
                                if (page.appController) {
                                    page.appController.restoreLastSession()
                                }
                            }
                        }

                        Button {
                            id: clearHistoryBtn
                            visible: (page.appController && page.appController.recentActivities.length > 0) ||
                                     (page.appController && page.appController.recentFiles.length > 0)
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: 120
                            text: qsTr("🗑 Clear History")
                            property bool clickFeedback: false
                            Timer {
                                id: clearHistoryTimer
                                interval: 450
                                onTriggered: clearHistoryBtn.clickFeedback = false
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
                                radius: 8
                                color: clearHistoryBtn.down ? theme.surfaceAlt : (clearHistoryBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: clearHistoryBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                clearHistoryTimer.restart()
                                if (page.appController) {
                                    page.appController.clearRecentActivities()
                                    page.appController.clearRecentFiles()
                                }
                            }
                        }
                    }

                    // Content Split: Left (Recent Files) & Right (Recent Activities Timeline)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16

                        // Left Column: Recent Files
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: theme.background
                            border.width: 1
                            border.color: theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: qsTr("📂 Recent Files")
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: qsTr("%1 files").arg((page.appController && page.appController.recentFiles) ? page.appController.recentFiles.length : 0)
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
                                        width: parent.width
                                        height: 52
                                        radius: 8
                                        color: theme.surface
                                        border.width: 1
                                        border.color: theme.border

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 10

                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: 6
                                                color: modelData.type && modelData.type.indexOf("Bin") !== -1 ? "#EDE7F6" : "#E8F5E9"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: modelData.name && modelData.name.indexOf(".bin") !== -1 ? "BIN" : (modelData.name && modelData.name.indexOf(".csv") !== -1 ? "CSV" : "XLS")
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: modelData.type && modelData.type.indexOf("Bin") !== -1 ? "#5E35B1" : "#2E7D32"
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Label {
                                                    text: modelData.name || ""
                                                    color: theme.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    elide: Text.ElideMiddle
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: (modelData.type || "") + " • " + (modelData.rowCount ? qsTr("%1 records • ").arg(modelData.rowCount) : "") + (modelData.timestamp || "")
                                                    color: theme.textSecondary
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Button {
                                                id: loadD1Btn
                                                Layout.preferredHeight: 28
                                                Layout.preferredWidth: 68
                                                text: qsTr("Load D1")
                                                font.pixelSize: 10
                                                property bool clickFeedback: false
                                                Timer {
                                                    id: loadD1Timer
                                                    interval: 450
                                                    onTriggered: loadD1Btn.clickFeedback = false
                                                }
                                                background: Rectangle {
                                                    radius: 6
                                                    color: loadD1Btn.down ? theme.surfaceAlt : (loadD1Btn.hovered ? theme.surfaceAlt : theme.surface)
                                                    border.color: loadD1Btn.clickFeedback ? theme.success : theme.border
                                                    border.width: 1
                                                }
                                                onClicked: {
                                                    clickFeedback = true
                                                    loadD1Timer.restart()
                                                    if (page.appController && modelData.path) {
                                                        page.appController.loadRecentFileAsDataset(1, modelData.path)
                                                    }
                                                }
                                            }

                                            Button {
                                                id: loadD2Btn
                                                Layout.preferredHeight: 28
                                                Layout.preferredWidth: 68
                                                text: qsTr("Load D2")
                                                font.pixelSize: 10
                                                property bool clickFeedback: false
                                                Timer {
                                                    id: loadD2Timer
                                                    interval: 450
                                                    onTriggered: loadD2Btn.clickFeedback = false
                                                }
                                                background: Rectangle {
                                                    radius: 6
                                                    color: loadD2Btn.down ? theme.surfaceAlt : (loadD2Btn.hovered ? theme.surfaceAlt : theme.surface)
                                                    border.color: loadD2Btn.clickFeedback ? theme.success : theme.border
                                                    border.width: 1
                                                }
                                                onClicked: {
                                                    clickFeedback = true
                                                    loadD2Timer.restart()
                                                    if (page.appController && modelData.path) {
                                                        page.appController.loadRecentFileAsDataset(2, modelData.path)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !page.appController || !page.appController.recentFiles || page.appController.recentFiles.length === 0
                                        text: qsTr("No recent file history.")
                                        color: theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Right Column: Activity History Timeline
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: theme.background
                            border.width: 1
                            border.color: theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: qsTr("⚡ Recent Activities")
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: qsTr("%1 records").arg((page.appController && page.appController.recentActivities) ? page.appController.recentActivities.length : 0)
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
                                    model: page.appController ? page.appController.recentActivities : []

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: 8
                                        color: theme.surface
                                        border.width: 1
                                        border.color: theme.border

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredHeight: 22
                                                Layout.preferredWidth: 68
                                                radius: 4
                                                color: modelData.category === "Yükleme" || modelData.category === "Load" ? "#E3F2FD" :
                                                       modelData.category === "Temizleme" || modelData.category === "Cleaning" ? "#FFF3E0" :
                                                       modelData.category === "Karşılaştırma" || modelData.category === "Comparison" ? "#FCE4EC" :
                                                       modelData.category === "Görselleştirme" || modelData.category === "Visualization" ? "#E8F5E9" :
                                                       modelData.category === "Ham Veri" || modelData.category === "Raw Data" ? "#EDE7F6" : "#ECEFF1"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: modelData.category || qsTr("Action")
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: modelData.category === "Yükleme" || modelData.category === "Load" ? "#1565C0" :
                                                           modelData.category === "Temizleme" || modelData.category === "Cleaning" ? "#E65100" :
                                                           modelData.category === "Karşılaştırma" || modelData.category === "Comparison" ? "#AD1457" :
                                                           modelData.category === "Görselleştirme" || modelData.category === "Visualization" ? "#2E7D32" :
                                                           modelData.category === "Ham Veri" || modelData.category === "Raw Data" ? "#5E35B1" : "#455A64"
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Label {
                                                    text: modelData.title || ""
                                                    color: theme.text
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: modelData.detail || ""
                                                    color: theme.textSecondary
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Label {
                                                text: modelData.timeShort || ""
                                                color: theme.textSecondary
                                                font.pixelSize: 10
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !page.appController || !page.appController.recentActivities || page.appController.recentActivities.length === 0
                                        text: qsTr("No activity records yet.")
                                        color: theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // NEXT ACTION
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 92

                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: "i"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: qsTr("Recommended next step")
                            color: theme.text
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Label {
                            text:
                                !page.loaded(1) && !page.loaded(2)
                                ? qsTr("First, load your datasets.")
                                : (!page.qualityAvailable(1) &&
                                   (!page.loaded(2) || !page.qualityAvailable(2)))
                                  ? qsTr("Inspect data quality and statistics in the Data Analysis page.")
                                  : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                    ? qsTr("Manage and resolve detected problems in the Data Cleaning page.")
                                    : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                      ? qsTr("Map and compare your datasets in the Comparison page.")
                                      : qsTr("Explore charts and trends in the Visualization page.")
                            color: theme.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 38

                        text:
                            !page.loaded(1) && !page.loaded(2)
                            ? qsTr("Go to Datasets →")
                            : (!page.qualityAvailable(1) &&
                               (!page.loaded(2) || !page.qualityAvailable(2)))
                              ? qsTr("Data Analysis →")
                              : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                ? qsTr("Data Cleaning →")
                                : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                  ? qsTr("Comparison →")
                                  : qsTr("Visualization →")

                        onClicked:
                            !page.loaded(1) && !page.loaded(2)
                            ? page.go(1)
                            : (!page.qualityAvailable(1) &&
                               (!page.loaded(2) || !page.qualityAvailable(2)))
                              ? page.go(2)
                              : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                ? page.go(3)
                                : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                  ? page.go(4)
                                  : page.go(5)

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: theme.primary
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }
}
