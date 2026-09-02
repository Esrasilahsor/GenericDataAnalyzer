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

    property int activeDataset: 1
    property string chartType: "histogram" // histogram, boxplot, timeseries, distribution, correlation, comparison
    property bool isDualMode: false

    property string selectedCol1: ""
    property string selectedCol2: ""
    property string selectedBarCategoryCol: ""
    property string selectedBarValueCol: ""
    property string selectedBarCategoryCol2: ""
    property string selectedBarValueCol2: ""
    property string barAggregation: "Mean" // Mean, Sum, Count, Min, Max
    property int binCount: 10
    property double boxPlotMultiplier: 1.5

    property var chartData1: ({})
    property var chartData2: ({})

    property string saveStatusMessage: ""
    property bool saveSuccess: true
    property bool isRendering: false
    property bool sessionPromptHandled: false
    property bool sessionRestored: false

    function checkSessionRestore() {
        if (page.sessionRestored || !page.appController) return
        if (page.appController.sessionRestoreDecision === 1) {
            page.sessionRestored = true
            var s = page.appController.getSavedVisualizationSession()
            if (s && s.chartType) {
                if (s.activeDataset !== undefined) page.activeDataset = s.activeDataset
                if (s.chartType !== undefined && s.chartType !== "") {
                    page.chartType = s.chartType
                    var idx = 0
                    switch (s.chartType) {
                    case "histogram": idx = 0; break;
                    case "boxplot": idx = 1; break;
                    case "scatter": idx = 2; break;
                    case "line": idx = 3; break;
                    case "bar": idx = 4; break;
                    case "correlation": idx = 5; break;
                    case "comparison": idx = 6; break;
                    }
                    chartTypeCombo.currentIndex = idx
                }
                if (s.isDualMode !== undefined) page.isDualMode = s.isDualMode
                if (s.selectedCol1 !== undefined) page.selectedCol1 = s.selectedCol1
                if (s.selectedCol2 !== undefined) page.selectedCol2 = s.selectedCol2
                if (s.selectedBarCategoryCol !== undefined) page.selectedBarCategoryCol = s.selectedBarCategoryCol
                if (s.selectedBarValueCol !== undefined) page.selectedBarValueCol = s.selectedBarValueCol
                if (s.barAggregation !== undefined) page.barAggregation = s.barAggregation
                if (s.binCount !== undefined) page.binCount = s.binCount
                if (s.boxPlotMultiplier !== undefined) page.boxPlotMultiplier = s.boxPlotMultiplier
                page.generateChart()
            }
        }
    }

    onVisibleChanged: {
        if (page.visible) {
            page.checkSessionRestore()
        }
    }

    Connections {
        target: page.appController
        ignoreUnknownSignals: true
        function onSessionRestoreDecisionChanged() {
            page.checkSessionRestore()
        }
        function onDataset1Changed() {
            page.sessionPromptHandled = false
        }
        function onDataset2Changed() {
            page.sessionPromptHandled = false
        }
    }

    Component.onCompleted: {
        if (page.visible) {
            page.checkSessionRestore()
        }
    }

    function saveVisState() {
        if (!appController) return
        var state = {
            activeDataset: page.activeDataset,
            chartType: page.chartType,
            isDualMode: page.isDualMode,
            selectedCol1: page.selectedCol1,
            selectedCol2: page.selectedCol2,
            selectedBarCategoryCol: page.selectedBarCategoryCol,
            selectedBarValueCol: page.selectedBarValueCol,
            barAggregation: page.barAggregation,
            binCount: page.binCount,
            boxPlotMultiplier: page.boxPlotMultiplier
        }
        appController.saveVisualizationSession(state)
    }

    function isLoaded(ds) {
        if (!appController) return false
        return ds === 1 ? (appController.dataset1Name !== "") : (appController.dataset2Name !== "")
    }

    function name(ds) {
        if (!appController) return qsTr("Dataset %1").arg(ds)
        var n = ds === 1 ? appController.dataset1Name : appController.dataset2Name
        return n && n !== "" ? n : qsTr("Dataset %1").arg(ds)
    }

    function columnModel(ds) {
        if (!appController) return null
        return ds === 1 ? appController.dataset1ColumnModel : appController.dataset2ColumnModel
    }

    function generateChart() {
        if (!appController) return
        if (page.chartType === "bar") {
            var catCol = page.selectedBarCategoryCol !== "" ? page.selectedBarCategoryCol : page.selectedCol1
            var valCol = page.selectedBarValueCol !== "" ? page.selectedBarValueCol : page.selectedCol2
            if (catCol === "" || catCol === qsTr("-- Select Column --") || catCol === "-- Select Column --" || catCol === "-- Sütun Seçiniz --") {
                page.saveSuccess = false
                page.saveStatusMessage = qsTr("Please select a Category Column for Bar Chart.")
                statusTimer.restart()
                return
            }
            if (page.barAggregation !== "Count" && page.barAggregation !== "Sayım" && (valCol === "" || valCol === qsTr("-- Select Column --") || valCol === "-- Select Column --" || valCol === "-- Sütun Seçiniz --")) {
                page.saveSuccess = false
                page.saveStatusMessage = qsTr("Please select a numeric Value Column for Bar Chart.")
                statusTimer.restart()
                return
            }
        }
        else if (page.chartType !== "correlation" && (page.selectedCol1 === "" || page.selectedCol1 === qsTr("-- Select Column --") || page.selectedCol1 === "-- Select Column --" || page.selectedCol1 === "-- Sütun Seçiniz --")) {
            page.saveSuccess = false
            page.saveStatusMessage = qsTr("Please select a column to visualize.")
            statusTimer.restart()
            return
        }

        page.isRendering = true
        renderTimer.restart()
    }

    Timer {
        id: renderTimer
        interval: 30
        repeat: false
        onTriggered: {
            if (page.chartType === "histogram") {
                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1Histogram(page.selectedCol1, page.binCount)
                    page.chartData2 = appController.createDataset2Histogram(page.selectedCol2, page.binCount)
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1Histogram(page.selectedCol1, page.binCount)
                    else
                        page.chartData1 = appController.createDataset2Histogram(page.selectedCol1, page.binCount)
                }
            }
            else if (page.chartType === "bar") {
                var cat1 = page.selectedBarCategoryCol !== "" ? page.selectedBarCategoryCol : page.selectedCol1
                var val1 = page.selectedBarValueCol !== "" ? page.selectedBarValueCol : page.selectedCol2
                var cat2 = page.selectedBarCategoryCol2 !== "" ? page.selectedBarCategoryCol2 : cat1
                var val2 = page.selectedBarValueCol2 !== "" ? page.selectedBarValueCol2 : val1

                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1BarChart(cat1, val1, page.barAggregation)
                    page.chartData2 = appController.createDataset2BarChart(cat2, val2, page.barAggregation)
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1BarChart(cat1, val1, page.barAggregation)
                    else
                        page.chartData1 = appController.createDataset2BarChart(cat1, val1, page.barAggregation)
                }
            }
            else if (page.chartType === "boxplot") {
                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1BoxPlot(page.selectedCol1, page.boxPlotMultiplier)
                    page.chartData2 = appController.createDataset2BoxPlot(page.selectedCol2, page.boxPlotMultiplier)
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1BoxPlot(page.selectedCol1, page.boxPlotMultiplier)
                    else
                        page.chartData1 = appController.createDataset2BoxPlot(page.selectedCol1, page.boxPlotMultiplier)
                }
            }
            else if (page.chartType === "line" || page.chartType === "timeseries" || page.chartType === "scatter") {
                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1TimeSeries(page.selectedCol1, "")
                    page.chartData2 = appController.createDataset2TimeSeries(page.selectedCol2, "")
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1TimeSeries(page.selectedCol1, "")
                    else
                        page.chartData1 = appController.createDataset2TimeSeries(page.selectedCol1, "")
                }
            }
            else if (page.chartType === "distribution") {
                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1Distribution(page.selectedCol1, page.binCount)
                    page.chartData2 = appController.createDataset2Distribution(page.selectedCol2, page.binCount)
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1Distribution(page.selectedCol1, page.binCount)
                    else
                        page.chartData1 = appController.createDataset2Distribution(page.selectedCol1, page.binCount)
                }
            }
            else if (page.chartType === "correlation") {
                if (page.isDualMode) {
                    page.chartData1 = appController.createDataset1CorrelationMatrix()
                    page.chartData2 = appController.createDataset2CorrelationMatrix()
                } else {
                    if (page.activeDataset === 1)
                        page.chartData1 = appController.createDataset1CorrelationMatrix()
                    else
                        page.chartData1 = appController.createDataset2CorrelationMatrix()
                }
            }
            else if (page.chartType === "comparison") {
                var comp = appController.createDatasetComparisonChart(page.selectedCol1, page.selectedCol2)
                page.chartData1 = comp
                page.chartData2 = comp
            }

            page.isRendering = false
            if (appController) {
                appController.setVisualizationAvailable(true)
                page.saveVisState()
            }
            chartCanvas1.requestPaint()
            if (chartCanvas2) chartCanvas2.requestPaint()
        }
    }

    function saveChart(canvasObj, prefix) {
        if (!appController || !canvasObj) return
        var dataUrl = canvasObj.toDataURL("image/png")
        var path = appController.saveChartImage(dataUrl, prefix)
        if (path && path !== "") {
            page.saveSuccess = true
            page.saveStatusMessage = qsTr("✓ Chart successfully saved: %1").arg(path)
        } else {
            page.saveSuccess = false
            page.saveStatusMessage = qsTr("✕ Failed to save chart: %1").arg(appController.lastError || qsTr("Error"))
        }
        statusTimer.restart()
    }

    function goToPage(index) {
        if (page.mainWindow) {
            page.mainWindow.currentPage = index
        }
    }

    Timer {
        id: statusTimer
        interval: 6000
        onTriggered: page.saveStatusMessage = ""
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
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 5
                title: qsTr("Data Visualization")
                subtitle: qsTr("Generate interactive charts, inspect distribution trends and save chart visualizations.")
                buttonText: qsTr("Continue to Export →")
                buttonVisible: true
                buttonEnabled: page.isLoaded(1) || page.isLoaded(2)
                onButtonClicked: page.goToPage(6)
            }

            // Status message
            Rectangle {
                visible: page.saveStatusMessage !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 40
                radius: 8
                color: page.saveSuccess ? "#1B5E20" : "#B71C1C"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    Label {
                        text: page.saveStatusMessage
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // Loading overlay indicator
            Rectangle {
                visible: page.isRendering
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 42
                radius: 8
                color: theme.surfaceAlt
                border.color: theme.primary
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10
                    Label {
                        text: qsTr("⏳ Generating and rendering chart, please wait...")
                        color: theme.primary
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }

            // Controls Card
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 185
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Row 1: Mode & Export
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        RowLayout {
                            spacing: 6
                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 130
                                text: qsTr("📊 Single Chart")
                                highlighted: !page.isDualMode
                                onClicked: {
                                    page.isDualMode = false
                                    chartCanvas1.requestPaint()
                                }
                            }
                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 170
                                text: qsTr("⇆ Side-by-Side Dual Chart")
                                highlighted: page.isDualMode
                                enabled: page.isLoaded(1) && page.isLoaded(2)
                                onClicked: {
                                    page.isDualMode = true
                                    chartCanvas1.requestPaint()
                                    if (chartCanvas2) chartCanvas2.requestPaint()
                                }
                            }
                        }

                        RowLayout {
                            visible: !page.isDualMode && page.chartType !== "comparison"
                            spacing: 6
                            Label { text: qsTr("• Dataset:"); color: theme.text; font.pixelSize: 12; font.bold: true }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 110
                                text: qsTr("Dataset 1")
                                enabled: page.isLoaded(1)
                                highlighted: page.activeDataset === 1
                                onClicked: {
                                    page.activeDataset = 1
                                    page.selectedCol1 = ""
                                    page.chartData1 = ({})
                                    chartCanvas1.requestPaint()
                                }
                            }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 110
                                text: qsTr("Dataset 2")
                                enabled: page.isLoaded(2)
                                highlighted: page.activeDataset === 2
                                onClicked: {
                                    page.activeDataset = 2
                                    page.selectedCol1 = ""
                                    page.chartData1 = ({})
                                    chartCanvas1.requestPaint()
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }

                    // Row 2: Selectors & Draw Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Label { text: qsTr("Chart Type"); color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                id: chartTypeCombo
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 34
                                model: [qsTr("Histogram"), qsTr("Box Plot"), qsTr("Scatter Plot"), qsTr("Line / Trend"), qsTr("Bar Chart"), qsTr("Correlation Heatmap"), qsTr("Comparison Chart")]
                                currentIndex: 0
                                onActivated: {
                                    switch (currentIndex) {
                                    case 0: page.chartType = "histogram"; break;
                                    case 1: page.chartType = "boxplot"; break;
                                    case 2: page.chartType = "scatter"; break;
                                    case 3: page.chartType = "line"; break;
                                    case 4: page.chartType = "bar"; break;
                                    case 5: page.chartType = "correlation"; break;
                                    case 6: page.chartType = "comparison"; break;
                                    }
                                }
                            }
                        }

                        // Column 1
                        ColumnLayout {
                            visible: page.chartType !== "correlation" && page.chartType !== "bar"
                            spacing: 2
                            Label {
                                text: (page.isDualMode || page.chartType === "comparison") ? qsTr("Dataset 1 Column") : ((page.chartType === "timeseries" || page.chartType === "line") ? qsTr("Line Column") : qsTr("Analysis Column"))
                                color: (page.isDualMode || page.chartType === "comparison") ? "#FF4081" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode || page.chartType === "comparison"
                            }
                            ComboBox {
                                id: col1Combo
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 36
                                model: (page.isDualMode || page.chartType === "comparison") ? page.columnModel(1) : page.columnModel(page.activeDataset)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedCol1 !== "" ? page.selectedCol1 : qsTr("-- Select Column --")
                                onActivated: page.selectedCol1 = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedCol1 = currentText
                                }
                            }
                        }

                        // Column 2
                        ColumnLayout {
                            visible: (page.isDualMode || page.chartType === "comparison") && page.chartType !== "correlation" && page.chartType !== "bar"
                            spacing: 2
                            Label {
                                text: qsTr("Dataset 2 Column")
                                color: "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            ComboBox {
                                id: col2Combo
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 36
                                model: page.columnModel(2)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedCol2 !== "" ? page.selectedCol2 : qsTr("-- Select Column --")
                                onActivated: page.selectedCol2 = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedCol2 = currentText
                                }
                            }
                        }

                        // Bar Chart Controls
                        // Category Column (D1 or Single)
                        ColumnLayout {
                            visible: page.chartType === "bar"
                            spacing: 2
                            Label {
                                text: page.isDualMode ? qsTr("D1 Category Column") : qsTr("Category Column")
                                color: page.isDualMode ? "#FF4081" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: barCatCombo
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 36
                                model: page.columnModel(page.isDualMode ? 1 : page.activeDataset)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedBarCategoryCol !== "" ? page.selectedBarCategoryCol : qsTr("-- Select Column --")
                                onActivated: page.selectedBarCategoryCol = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedBarCategoryCol = currentText
                                }
                            }
                        }

                        // Value Column (D1 or Single)
                        ColumnLayout {
                            visible: page.chartType === "bar"
                            spacing: 2
                            Label {
                                text: page.isDualMode ? qsTr("D1 Value Column") : qsTr("Value Column")
                                color: page.isDualMode ? "#FF4081" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: barValCombo
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 36
                                model: page.columnModel(page.isDualMode ? 1 : page.activeDataset)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedBarValueCol !== "" ? page.selectedBarValueCol : qsTr("-- Select Column --")
                                onActivated: page.selectedBarValueCol = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedBarValueCol = currentText
                                }
                            }
                        }

                        // Dual Mode D2 Category Column
                        ColumnLayout {
                            visible: page.chartType === "bar" && page.isDualMode
                            spacing: 2
                            Label {
                                text: qsTr("D2 Category Column")
                                color: "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            ComboBox {
                                id: barCatCombo2
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 36
                                model: page.columnModel(2)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedBarCategoryCol2 !== "" ? page.selectedBarCategoryCol2 : qsTr("-- Select Column --")
                                onActivated: page.selectedBarCategoryCol2 = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedBarCategoryCol2 = currentText
                                }
                            }
                        }

                        // Dual Mode D2 Value Column
                        ColumnLayout {
                            visible: page.chartType === "bar" && page.isDualMode
                            spacing: 2
                            Label {
                                text: qsTr("D2 Value Column")
                                color: "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            ComboBox {
                                id: barValCombo2
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 36
                                model: page.columnModel(2)
                                textRole: "name"
                                valueRole: "name"
                                displayText: page.selectedBarValueCol2 !== "" ? page.selectedBarValueCol2 : qsTr("-- Select Column --")
                                onActivated: page.selectedBarValueCol2 = currentText
                                onCurrentTextChanged: {
                                    if (activeFocus && currentText !== "") page.selectedBarValueCol2 = currentText
                                }
                            }
                        }

                        // Aggregation ComboBox (Bar Chart only)
                        ColumnLayout {
                            visible: page.chartType === "bar"
                            spacing: 2
                            Label { text: qsTr("Aggregation"); color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                id: barAggCombo
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 36
                                model: ["Mean", "Sum", "Count", "Min", "Max"]
                                currentIndex: Math.max(0, model.indexOf(page.barAggregation))
                                onActivated: page.barAggregation = currentText
                            }
                        }

                        // Parameters
                        ColumnLayout {
                            visible: page.chartType === "histogram" || page.chartType === "distribution"
                            spacing: 2
                            Label { text: qsTr("Bin Count"); color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                Layout.preferredWidth: 90
                                Layout.preferredHeight: 36
                                model: [5, 10, 15, 20]
                                currentIndex: 1
                                onActivated: page.binCount = Number(currentText)
                            }
                        }

                        ColumnLayout {
                            visible: page.chartType === "boxplot"
                            spacing: 2
                            Label { text: qsTr("IQR Multiplier"); color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                Layout.preferredWidth: 90
                                Layout.preferredHeight: 36
                                model: [1.5, 2.0, 3.0]
                                currentIndex: 0
                                onActivated: page.boxPlotMultiplier = Number(currentText)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            id: drawChartBtn
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 38
                            text: page.isRendering ? qsTr("⏳ Drawing...") : qsTr("📊 Draw Chart")
                            property bool clickFeedback: false
                            Timer {
                                id: drawChartTimer
                                interval: 450
                                onTriggered: drawChartBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: drawChartBtn.down ? theme.surfaceAlt : (drawChartBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: drawChartBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                drawChartTimer.restart()
                                page.generateChart()
                            }
                        }
                    }
                }
            }

            // Canvas Layout: Single or Dual Side-by-Side
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                // Panel 1 (Dataset 1 or Active Dataset or Overlaid Single Comparison)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 340
                    Layout.preferredHeight: 500
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: page.chartType === "comparison" && !page.isDualMode
                                      ? qsTr("Two Datasets Comparison Chart (D1: %1 vs D2: %2)").arg(page.name(1)).arg(page.name(2))
                                      : (page.isDualMode ? qsTr("Dataset 1: %1%2").arg(page.name(1)).arg(page.selectedCol1 !== "" ? " (" + page.selectedCol1 + ")" : "") : qsTr("%1%2 Chart").arg(page.name(page.activeDataset)).arg(page.selectedCol1 !== "" ? " (" + page.selectedCol1 + ")" : ""))
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideMiddle
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                id: saveChart1Btn
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 30
                                text: qsTr("💾 Save Chart")
                                property bool clickFeedback: false
                                Timer {
                                    id: saveChart1Timer
                                    interval: 450
                                    onTriggered: saveChart1Btn.clickFeedback = false
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: saveChart1Btn.down ? theme.surfaceAlt : (saveChart1Btn.hovered ? theme.surfaceAlt : theme.surface)
                                    border.color: saveChart1Btn.clickFeedback ? theme.success : theme.border
                                    border.width: 1
                                }
                                onClicked: {
                                    clickFeedback = true
                                    saveChart1Timer.restart()
                                    page.saveChart(chartCanvas1, page.chartType + "_D1")
                                }
                            }
                        }

                        // Legend for comparison in single mode
                        RowLayout {
                            visible: page.chartType === "comparison" && !page.isDualMode
                            spacing: 14
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#FF4081" }
                                Label { text: "D1: " + (page.selectedCol1 || "-"); color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#7C4DFF" }
                                Label { text: "D2: " + (page.selectedCol2 || "-"); color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Canvas {
                                id: chartCanvas1
                                anchors.fill: parent

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    if (page.chartType !== "correlation" && (page.selectedCol1 === "" || page.selectedCol1 === qsTr("-- Select Column --") || page.selectedCol1 === "-- Select Column --" || page.selectedCol1 === "-- Sütun Seçiniz --")) {
                                        return
                                    }

                                    if (!page.chartData1 || !page.chartData1.success) {
                                        return
                                    }

                                var padL = 60, padR = 25, padT = 30, padB = 45
                                var plotW = width - padL - padR
                                var plotH = height - padT - padB

                                if (page.chartType === "correlation" && page.chartData1.columnNames) {
                                    var cols = page.chartData1.columnNames
                                    var n = cols.length
                                    if (n === 0) return
                                    var cellW = Math.min(plotW / n, 50)
                                    var cellH = Math.min(plotH / n, 50)
                                    var startX = padL + (plotW - n * cellW) / 2
                                    var startY = padT + (plotH - n * cellH) / 2

                                    for (var r = 0; r < n; ++r) {
                                        for (var c = 0; c < n; ++c) {
                                            var val = page.chartData1.values[r * n + c]
                                            var x = startX + c * cellW
                                            var y = startY + r * cellH

                                            if (val >= 0) {
                                                ctx.fillStyle = "rgba(255, 64, 129, " + Math.max(0.15, val) + ")"
                                            } else {
                                                ctx.fillStyle = "rgba(41, 121, 255, " + Math.max(0.15, Math.abs(val)) + ")"
                                            }
                                            ctx.fillRect(x, y, cellW - 2, cellH - 2)

                                            ctx.fillStyle = "#FFFFFF"
                                            ctx.font = "bold 9px sans-serif"
                                            ctx.textAlign = "center"
                                            ctx.fillText(Number(val).toFixed(2), x + cellW / 2, y + cellH / 2 + 3)
                                        }
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "9px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(cols[r], startX - 6, startY + r * cellH + cellH / 2 + 3)
                                    }
                                    return
                                }

                                // Axes
                                ctx.strokeStyle = theme.border
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(padL, padT)
                                ctx.lineTo(padL, height - padB)
                                ctx.lineTo(width - padR, height - padB)
                                ctx.stroke()

                                if (page.chartType === "histogram" && page.chartData1.frequencies) {
                                    var freqs = page.chartData1.frequencies
                                    var maxF = 1
                                    for (var i = 0; i < freqs.length; ++i) if (freqs[i] > maxF) maxF = freqs[i]
                                    var bW = plotW / freqs.length
                                    var low = page.chartData1.binLowerBounds || []

                                    for (var j = 0; j < freqs.length; ++j) {
                                        var bH = (freqs[j] / maxF) * (plotH - 30)
                                        var bX = padL + j * bW + 4
                                        var bY = height - padB - bH
                                        var barWidth = bW - 8

                                        var grad = ctx.createLinearGradient(bX, bY, bX, height - padB)
                                        grad.addColorStop(0, "#FF4081")
                                        grad.addColorStop(1, "#FF80AB")
                                        ctx.fillStyle = grad
                                        ctx.fillRect(bX, bY, barWidth, bH)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "bold 11px sans-serif"
                                        ctx.textAlign = "center"
                                        if (freqs[j] > 0) ctx.fillText(String(freqs[j]), bX + barWidth / 2, bY - 6)

                                        if (low.length > j) {
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.fillText(Number(low[j]).toFixed(1), bX + barWidth / 2, height - padB + 15)
                                        }
                                    }
                                }
                                else if (page.chartType === "bar" && page.chartData1.labels && page.chartData1.values) {
                                    var bLabels = page.chartData1.labels || []
                                    var bVals = page.chartData1.values || []
                                    var bCount = Math.min(bLabels.length, bVals.length)
                                    if (bCount > 0) {
                                        var bMin = 0, bMax = -999999
                                        for (var bi = 0; bi < bCount; ++bi) {
                                            if (bVals[bi] < bMin) bMin = bVals[bi]
                                            if (bVals[bi] > bMax) bMax = bVals[bi]
                                        }
                                        if (bMax <= bMin) bMax = bMin + 1
                                        var bRng = bMax - bMin

                                        var bSlotW = plotW / bCount
                                        var bActualW = Math.max(6, Math.min(bSlotW - 12, 60))

                                        for (var bj = 0; bj < bCount; ++bj) {
                                            var valB = bVals[bj]
                                            var bHeight = Math.max(2, ((valB - bMin) / bRng) * (plotH - 35))
                                            var bPosX = padL + bj * bSlotW + (bSlotW - bActualW) / 2
                                            var bPosY = height - padB - bHeight

                                            var bGrad = ctx.createLinearGradient(bPosX, bPosY, bPosX, height - padB)
                                            bGrad.addColorStop(0, "#FF4081")
                                            bGrad.addColorStop(1, "#FF80AB")
                                            ctx.fillStyle = bGrad
                                            ctx.fillRect(bPosX, bPosY, bActualW, bHeight)

                                            // Value label above bar
                                            ctx.fillStyle = theme.text
                                            ctx.font = "bold 11px sans-serif"
                                            ctx.textAlign = "center"
                                            var dVal = (Number(valB) % 1 === 0) ? String(valB) : Number(valB).toFixed(2)
                                            ctx.fillText(dVal, bPosX + bActualW / 2, bPosY - 6)

                                            // Category label below axis
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.textAlign = "center"
                                            var bLbl = String(bLabels[bj])
                                            if (bLbl.length > 12) bLbl = bLbl.substring(0, 10) + ".."
                                            ctx.fillText(bLbl, bPosX + bActualW / 2, height - padB + 16)
                                        }

                                        // Y-axis min/max
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "10px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(Number(bMax).toFixed(1), padL - 8, padT + 10)
                                        ctx.fillText(Number(bMin).toFixed(1), padL - 8, height - padB)
                                    }
                                }
                                else if (page.chartType === "distribution" && page.chartData1.relativeFrequencies) {
                                    var distFreqs = page.chartData1.relativeFrequencies
                                    var maxD = 0.001
                                    for (var df = 0; df < distFreqs.length; ++df) if (distFreqs[df] > maxD) maxD = distFreqs[df]

                                    ctx.strokeStyle = "#FF4081"
                                    ctx.fillStyle = "rgba(255, 64, 129, 0.25)"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(padL, height - padB)
                                    for (var di = 0; di < distFreqs.length; ++di) {
                                        var dX = padL + (di / Math.max(1, distFreqs.length - 1)) * plotW
                                        var dY = (height - padB) - (distFreqs[di] / maxD) * (plotH - 30)
                                        ctx.lineTo(dX, dY)
                                    }
                                    ctx.lineTo(width - padR, height - padB)
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.stroke()
                                }
                                else if (page.chartType === "boxplot" && page.chartData1.minimum !== undefined) {
                                    var min = page.chartData1.minimum, max = page.chartData1.maximum
                                    var q1 = page.chartData1.q1, med = page.chartData1.median, q3 = page.chartData1.q3
                                    var lW = page.chartData1.lowerWhisker !== undefined ? page.chartData1.lowerWhisker : min
                                    var uW = page.chartData1.upperWhisker !== undefined ? page.chartData1.upperWhisker : max
                                    var rng = (max - min) === 0 ? 1 : (max - min)
                                    function toY(v) { return (height - padB) - ((v - min) / rng) * (plotH - 40) - 20 }

                                    var cX = width / 2, boxW = 90
                                    ctx.strokeStyle = "#FF4081"; ctx.lineWidth = 2
                                    ctx.beginPath()
                                    ctx.moveTo(cX, toY(lW)); ctx.lineTo(cX, toY(uW))
                                    ctx.moveTo(cX - 20, toY(lW)); ctx.lineTo(cX + 20, toY(lW))
                                    ctx.moveTo(cX - 20, toY(uW)); ctx.lineTo(cX + 20, toY(uW))
                                    ctx.stroke()

                                    var yQ3 = toY(q3), yQ1 = toY(q1)
                                    var gradB = ctx.createLinearGradient(cX - boxW/2, yQ3, cX + boxW/2, yQ1)
                                    gradB.addColorStop(0, "#FF4081")
                                    gradB.addColorStop(1, "#FF80AB")
                                    ctx.fillStyle = gradB
                                    ctx.fillRect(cX - boxW / 2, yQ3, boxW, yQ1 - yQ3)
                                    ctx.strokeStyle = "#C2185B"
                                    ctx.strokeRect(cX - boxW / 2, yQ3, boxW, yQ1 - yQ3)

                                    ctx.strokeStyle = "#FFD600"; ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(cX - boxW / 2, toY(med)); ctx.lineTo(cX + boxW / 2, toY(med))
                                    ctx.stroke()

                                    ctx.fillStyle = theme.text; ctx.font = "bold 10px sans-serif"; ctx.textAlign = "left"
                                    ctx.fillText("Max: " + Number(max).toFixed(1), cX + boxW / 2 + 10, toY(max))
                                    ctx.fillText("Median: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY(min))
                                }
                                else if ((page.chartType === "line" || page.chartType === "timeseries") && page.chartData1.pointCount > 0) {
                                    var pts = page.chartData1.pointCount
                                    var yVals = page.chartData1.yValues || []
                                    var minY = 999999, maxY = -999999
                                    for (var p = 0; p < yVals.length; ++p) {
                                        if (yVals[p] < minY) minY = yVals[p]
                                        if (yVals[p] > maxY) maxY = yVals[p]
                                    }
                                    if (minY === 999999) { minY = 0; maxY = 1; }
                                    var rngY = (maxY - minY) === 0 ? 1 : (maxY - minY)

                                    var step = Math.max(1, Math.floor(pts / 1200))
                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    var first = true
                                    for (var k = 0; k < pts; k += step) {
                                        var xP = padL + (k / Math.max(1, pts - 1)) * plotW
                                        var yP = (height - padB) - ((yVals[k] - minY) / rngY) * (plotH - 20)
                                        if (first) { ctx.moveTo(xP, yP); first = false } else { ctx.lineTo(xP, yP) }
                                    }
                                    ctx.stroke()

                                    // Y min/max labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(maxY).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(minY).toFixed(1), padL - 8, height - padB)
                                }
                                else if (page.chartType === "scatter" && page.chartData1.pointCount > 0) {
                                    var spts = page.chartData1.pointCount
                                    var syVals = page.chartData1.yValues || []
                                    var sminY = 999999, smaxY = -999999
                                    for (var sp = 0; sp < syVals.length; ++sp) {
                                        if (syVals[sp] < sminY) sminY = syVals[sp]
                                        if (syVals[sp] > smaxY) smaxY = syVals[sp]
                                    }
                                    if (sminY === 999999) { sminY = 0; smaxY = 1; }
                                    var srngY = (smaxY - sminY) === 0 ? 1 : (smaxY - sminY)

                                    var sStep = Math.max(1, Math.floor(spts / 800))
                                    ctx.fillStyle = "rgba(255, 64, 129, 0.75)"
                                    for (var sk = 0; sk < spts; sk += sStep) {
                                        var sxP = padL + (sk / Math.max(1, spts - 1)) * plotW
                                        var syP = (height - padB) - ((syVals[sk] - sminY) / srngY) * (plotH - 20)
                                        ctx.beginPath()
                                        ctx.arc(sxP, syP, 3.5, 0, 2 * Math.PI)
                                        ctx.fill()
                                    }

                                    // Y min/max labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(smaxY).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(sminY).toFixed(1), padL - 8, height - padB)
                                }
                                else if (page.chartType === "comparison" && page.chartData1.pointCount > 0) {
                                    var cpts = page.chartData1.pointCount
                                    var sVals = page.chartData1.sourceValues || []
                                    var tVals = page.chartData1.targetValues || []
                                    var minComp = 999999, maxComp = -999999
                                    for (var cp = 0; cp < sVals.length; ++cp) {
                                        if (sVals[cp] < minComp) minComp = sVals[cp]
                                        if (sVals[cp] > maxComp) maxComp = sVals[cp]
                                    }
                                    for (var cq = 0; cq < tVals.length; ++cq) {
                                        if (tVals[cq] < minComp) minComp = tVals[cq]
                                        if (tVals[cq] > maxComp) maxComp = tVals[cq]
                                    }
                                    if (minComp === 999999) { minComp = 0; maxComp = 1; }
                                    var rngComp = (maxComp - minComp) === 0 ? 1 : (maxComp - minComp)
                                    var cStep = Math.max(1, Math.floor(cpts / 1000))

                                    // Line 1: Dataset 1 in Pink
                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2.2
                                    ctx.beginPath()
                                    var cFirst1 = true
                                    for (var ck1 = 0; ck1 < sVals.length; ck1 += cStep) {
                                        var cxP1 = padL + (ck1 / Math.max(1, sVals.length - 1)) * plotW
                                        var cyP1 = (height - padB) - ((sVals[ck1] - minComp) / rngComp) * (plotH - 20)
                                        if (cFirst1) { ctx.moveTo(cxP1, cyP1); cFirst1 = false } else { ctx.lineTo(cxP1, cyP1) }
                                    }
                                    ctx.stroke()

                                    // If Single Mode, overlay Line 2: Dataset 2 in Purple
                                    if (!page.isDualMode) {
                                        ctx.strokeStyle = "#7C4DFF"
                                        ctx.lineWidth = 2.2
                                        ctx.beginPath()
                                        var cFirst2 = true
                                        for (var ck2 = 0; ck2 < tVals.length; ck2 += cStep) {
                                            var cxP2 = padL + (ck2 / Math.max(1, tVals.length - 1)) * plotW
                                            var cyP2 = (height - padB) - ((tVals[ck2] - minComp) / rngComp) * (plotH - 20)
                                            if (cFirst2) { ctx.moveTo(cxP2, cyP2); cFirst2 = false } else { ctx.lineTo(cxP2, cyP2) }
                                        }
                                        ctx.stroke()
                                    }

                                    // Labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(maxComp).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(minComp).toFixed(1), padL - 8, height - padB)
                                }
                            }

                            Item {
                                anchors.fill: parent
                                visible: !page.chartData1 || !page.chartData1.success

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 10

                                    Components.ByteMascot {
                                        Layout.alignment: Qt.AlignHCenter
                                        mascotWidth: 120
                                        mascotHeight: 120
                                        source: "qrc:/assets/byte/byte_visualization.png"
                                        animated: false
                                    }

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: (page.chartData1 && page.chartData1.errorMessage)
                                              ? (qsTr("Error: ") + page.chartData1.errorMessage)
                                              : qsTr("Select parameters above and click 'Draw Chart' to view the visualization.")
                                        color: theme.textSecondary
                                        font.pixelSize: 13
                                    }
                                }
                            }
                        }
                    }
                }

                // Panel 2 (Dataset 2 in Dual Mode)
                Rectangle {
                    visible: page.isDualMode
                    Layout.fillWidth: true
                    Layout.minimumWidth: 340
                    Layout.preferredHeight: 500
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: qsTr("Dataset 2: %1%2").arg(page.name(2)).arg(page.selectedCol2 !== "" ? " (" + page.selectedCol2 + ")" : "")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideMiddle
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                id: saveChart2Btn
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 30
                                text: qsTr("💾 Save Chart")
                                property bool clickFeedback: false
                                Timer {
                                    id: saveChart2Timer
                                    interval: 450
                                    onTriggered: saveChart2Btn.clickFeedback = false
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: saveChart2Btn.down ? theme.surfaceAlt : (saveChart2Btn.hovered ? theme.surfaceAlt : theme.surface)
                                    border.color: saveChart2Btn.clickFeedback ? theme.success : theme.border
                                    border.width: 1
                                }
                                onClicked: {
                                    clickFeedback = true
                                    saveChart2Timer.restart()
                                    page.saveChart(chartCanvas2, page.chartType + "_D2")
                                }
                            }
                        }

                        Canvas {
                            id: chartCanvas2
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                if (page.chartType !== "correlation" && (page.selectedCol2 === "" || page.selectedCol2 === qsTr("-- Select Column --") || page.selectedCol2 === "-- Select Column --" || page.selectedCol2 === "-- Sütun Seçiniz --")) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText(qsTr("Please select a column for Dataset 2 and click 'Draw Chart'."), width / 2, height / 2)
                                    return
                                }

                                if (!page.chartData2 || !page.chartData2.success) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    var errMsg2 = (page.chartData2 && page.chartData2.errorMessage) ? (qsTr("Error: ") + page.chartData2.errorMessage) : qsTr("Click 'Draw Chart' to view Dataset 2 visualization.")
                                    ctx.fillText(errMsg2, width / 2, height / 2)
                                    return
                                }

                                var padL = 60, padR = 25, padT = 30, padB = 45
                                var plotW = width - padL - padR
                                var plotH = height - padT - padB

                                if (page.chartType === "correlation" && page.chartData2.columnNames) {
                                    var cols = page.chartData2.columnNames
                                    var n = cols.length
                                    if (n === 0) return
                                    var cellW = Math.min(plotW / n, 50)
                                    var cellH = Math.min(plotH / n, 50)
                                    var startX = padL + (plotW - n * cellW) / 2
                                    var startY = padT + (plotH - n * cellH) / 2

                                    for (var r = 0; r < n; ++r) {
                                        for (var c = 0; c < n; ++c) {
                                            var val = page.chartData2.values[r * n + c]
                                            var x = startX + c * cellW
                                            var y = startY + r * cellH

                                            if (val >= 0) {
                                                ctx.fillStyle = "rgba(124, 77, 255, " + Math.max(0.15, val) + ")"
                                            } else {
                                                ctx.fillStyle = "rgba(0, 229, 255, " + Math.max(0.15, Math.abs(val)) + ")"
                                            }
                                            ctx.fillRect(x, y, cellW - 2, cellH - 2)

                                            ctx.fillStyle = "#FFFFFF"
                                            ctx.font = "bold 9px sans-serif"
                                            ctx.textAlign = "center"
                                            ctx.fillText(Number(val).toFixed(2), x + cellW / 2, y + cellH / 2 + 3)
                                        }
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "9px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(cols[r], startX - 6, startY + r * cellH + cellH / 2 + 3)
                                    }
                                    return
                                }

                                // Axes
                                ctx.strokeStyle = theme.border
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(padL, padT)
                                ctx.lineTo(padL, height - padB)
                                ctx.lineTo(width - padR, height - padB)
                                ctx.stroke()

                                if (page.chartType === "histogram" && page.chartData2.frequencies) {
                                    var freqs2 = page.chartData2.frequencies
                                    var maxF2 = 1
                                    for (var i2 = 0; i2 < freqs2.length; ++i2) if (freqs2[i2] > maxF2) maxF2 = freqs2[i2]
                                    var bW2 = plotW / freqs2.length
                                    var low2 = page.chartData2.binLowerBounds || []

                                    for (var j2 = 0; j2 < freqs2.length; ++j2) {
                                        var bH2 = (freqs2[j2] / maxF2) * (plotH - 30)
                                        var bX2 = padL + j2 * bW2 + 4
                                        var bY2 = height - padB - bH2
                                        var barWidth2 = bW2 - 8

                                        var grad2 = ctx.createLinearGradient(bX2, bY2, bX2, height - padB)
                                        grad2.addColorStop(0, "#7C4DFF")
                                        grad2.addColorStop(1, "#00E5FF")
                                        ctx.fillStyle = grad2
                                        ctx.fillRect(bX2, bY2, barWidth2, bH2)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "bold 11px sans-serif"
                                        ctx.textAlign = "center"
                                        if (freqs2[j2] > 0) ctx.fillText(String(freqs2[j2]), bX2 + barWidth2 / 2, bY2 - 6)

                                        if (low2.length > j2) {
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.fillText(Number(low2[j2]).toFixed(1), bX2 + barWidth2 / 2, height - padB + 15)
                                        }
                                    }
                                }
                                else if (page.chartType === "bar" && page.chartData2.labels && page.chartData2.values) {
                                    var bLabels2 = page.chartData2.labels || []
                                    var bVals2 = page.chartData2.values || []
                                    var bCount2 = Math.min(bLabels2.length, bVals2.length)
                                    if (bCount2 > 0) {
                                        var bMin2 = 0, bMax2 = -999999
                                        for (var bi2 = 0; bi2 < bCount2; ++bi2) {
                                            if (bVals2[bi2] < bMin2) bMin2 = bVals2[bi2]
                                            if (bVals2[bi2] > bMax2) bMax2 = bVals2[bi2]
                                        }
                                        if (bMax2 <= bMin2) bMax2 = bMin2 + 1
                                        var bRng2 = bMax2 - bMin2

                                        var bSlotW2 = plotW / bCount2
                                        var bActualW2 = Math.max(6, Math.min(bSlotW2 - 12, 60))

                                        for (var bj2 = 0; bj2 < bCount2; ++bj2) {
                                            var valB2 = bVals2[bj2]
                                            var bHeight2 = Math.max(2, ((valB2 - bMin2) / bRng2) * (plotH - 35))
                                            var bPosX2 = padL + bj2 * bSlotW2 + (bSlotW2 - bActualW2) / 2
                                            var bPosY2 = height - padB - bHeight2

                                            var bGrad2 = ctx.createLinearGradient(bPosX2, bPosY2, bPosX2, height - padB)
                                            bGrad2.addColorStop(0, "#7C4DFF")
                                            bGrad2.addColorStop(1, "#00E5FF")
                                            ctx.fillStyle = bGrad2
                                            ctx.fillRect(bPosX2, bPosY2, bActualW2, bHeight2)

                                            // Value label above bar
                                            ctx.fillStyle = theme.text
                                            ctx.font = "bold 11px sans-serif"
                                            ctx.textAlign = "center"
                                            var dVal2 = (Number(valB2) % 1 === 0) ? String(valB2) : Number(valB2).toFixed(2)
                                            ctx.fillText(dVal2, bPosX2 + bActualW2 / 2, bPosY2 - 6)

                                            // Category label below axis
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.textAlign = "center"
                                            var bLbl2 = String(bLabels2[bj2])
                                            if (bLbl2.length > 12) bLbl2 = bLbl2.substring(0, 10) + ".."
                                            ctx.fillText(bLbl2, bPosX2 + bActualW2 / 2, height - padB + 16)
                                        }

                                        // Y-axis min/max
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "10px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(Number(bMax2).toFixed(1), padL - 8, padT + 10)
                                        ctx.fillText(Number(bMin2).toFixed(1), padL - 8, height - padB)
                                    }
                                }
                                else if (page.chartType === "distribution" && page.chartData2.relativeFrequencies) {
                                    var distFreqs2 = page.chartData2.relativeFrequencies
                                    var maxD2 = 0.001
                                    for (var df2 = 0; df2 < distFreqs2.length; ++df2) if (distFreqs2[df2] > maxD2) maxD2 = distFreqs2[df2]

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.fillStyle = "rgba(124, 77, 255, 0.25)"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(padL, height - padB)
                                    for (var di2 = 0; di2 < distFreqs2.length; ++di2) {
                                        var dX2 = padL + (di2 / Math.max(1, distFreqs2.length - 1)) * plotW
                                        var dY2 = (height - padB) - (distFreqs2[di2] / maxD2) * (plotH - 30)
                                        ctx.lineTo(dX2, dY2)
                                    }
                                    ctx.lineTo(width - padR, height - padB)
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.stroke()
                                }
                                else if (page.chartType === "boxplot" && page.chartData2.minimum !== undefined) {
                                    var min2 = page.chartData2.minimum, max2 = page.chartData2.maximum
                                    var q1_2 = page.chartData2.q1, med2 = page.chartData2.median, q3_2 = page.chartData2.q3
                                    var lW2 = page.chartData2.lowerWhisker !== undefined ? page.chartData2.lowerWhisker : min2
                                    var uW2 = page.chartData2.upperWhisker !== undefined ? page.chartData2.upperWhisker : max2
                                    var rng2 = (max2 - min2) === 0 ? 1 : (max2 - min2)
                                    function toY2(v) { return (height - padB) - ((v - min2) / rng2) * (plotH - 40) - 20 }

                                    var cX2 = width / 2, boxW2 = 90
                                    ctx.strokeStyle = "#7C4DFF"; ctx.lineWidth = 2
                                    ctx.beginPath()
                                    ctx.moveTo(cX2, toY2(lW2)); ctx.lineTo(cX2, toY2(uW2))
                                    ctx.moveTo(cX2 - 20, toY2(lW2)); ctx.lineTo(cX2 + 20, toY2(lW2))
                                    ctx.moveTo(cX2 - 20, toY2(uW2)); ctx.lineTo(cX2 + 20, toY2(uW2))
                                    ctx.stroke()

                                    var yQ3_2 = toY2(q3_2), yQ1_2 = toY2(q1_2)
                                    var gradB2 = ctx.createLinearGradient(cX2 - boxW2/2, yQ3_2, cX2 + boxW2/2, yQ1_2)
                                    gradB2.addColorStop(0, "#7C4DFF")
                                    gradB2.addColorStop(1, "#00E5FF")
                                    ctx.fillStyle = gradB2
                                    ctx.fillRect(cX2 - boxW2 / 2, yQ3_2, boxW2, yQ1_2 - yQ3_2)
                                    ctx.strokeStyle = "#512DA8"
                                    ctx.strokeRect(cX2 - boxW2 / 2, yQ3_2, boxW2, yQ1_2 - yQ3_2)

                                    ctx.strokeStyle = "#FFD600"; ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(cX2 - boxW2 / 2, toY2(med2)); ctx.lineTo(cX2 + boxW2 / 2, toY2(med2))
                                    ctx.stroke()

                                    ctx.fillStyle = theme.text; ctx.font = "bold 10px sans-serif"; ctx.textAlign = "left"
                                    ctx.fillText("Max: " + Number(max2).toFixed(1), cX2 + boxW2 / 2 + 10, toY2(max2))
                                    ctx.fillText("Median: " + Number(med2).toFixed(1), cX2 + boxW2 / 2 + 10, toY2(med2))
                                    ctx.fillText("Min: " + Number(min2).toFixed(1), cX2 + boxW2 / 2 + 10, toY2(min2))
                                }
                                else if ((page.chartType === "line" || page.chartType === "timeseries") && page.chartData2.pointCount > 0) {
                                    var pts2 = page.chartData2.pointCount
                                    var yVals2 = page.chartData2.yValues || []
                                    var minY2 = 999999, maxY2 = -999999
                                    for (var p2 = 0; p2 < yVals2.length; ++p2) {
                                        if (yVals2[p2] < minY2) minY2 = yVals2[p2]
                                        if (yVals2[p2] > maxY2) maxY2 = yVals2[p2]
                                    }
                                    if (minY2 === 999999) { minY2 = 0; maxY2 = 1; }
                                    var rngY2 = (maxY2 - minY2) === 0 ? 1 : (maxY2 - minY2)
                                    var step2 = Math.max(1, Math.floor(pts2 / 1200))

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    var first2 = true
                                    for (var k2 = 0; k2 < pts2; k2 += step2) {
                                        var xP2 = padL + (k2 / Math.max(1, pts2 - 1)) * plotW
                                        var yP2 = (height - padB) - ((yVals2[k2] - minY2) / rngY2) * (plotH - 20)
                                        if (first2) { ctx.moveTo(xP2, yP2); first2 = false } else { ctx.lineTo(xP2, yP2) }
                                    }
                                    ctx.stroke()

                                    // Y min/max labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(maxY2).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(minY2).toFixed(1), padL - 8, height - padB)
                                }
                                else if (page.chartType === "scatter" && page.chartData2.pointCount > 0) {
                                    var spts2 = page.chartData2.pointCount
                                    var syVals2 = page.chartData2.yValues || []
                                    var sminY2 = 999999, smaxY2 = -999999
                                    for (var sp2 = 0; sp2 < syVals2.length; ++sp2) {
                                        if (syVals2[sp2] < sminY2) sminY2 = syVals2[sp2]
                                        if (syVals2[sp2] > smaxY2) smaxY2 = syVals2[sp2]
                                    }
                                    if (sminY2 === 999999) { sminY2 = 0; smaxY2 = 1; }
                                    var srngY2 = (smaxY2 - sminY2) === 0 ? 1 : (smaxY2 - sminY2)

                                    var sStep2 = Math.max(1, Math.floor(spts2 / 800))
                                    ctx.fillStyle = "rgba(124, 77, 255, 0.75)"
                                    for (var sk2 = 0; sk2 < spts2; sk2 += sStep2) {
                                        var sxP2 = padL + (sk2 / Math.max(1, spts2 - 1)) * plotW
                                        var syP2 = (height - padB) - ((syVals2[sk2] - sminY2) / srngY2) * (plotH - 20)
                                        ctx.beginPath()
                                        ctx.arc(sxP2, syP2, 3.5, 0, 2 * Math.PI)
                                        ctx.fill()
                                    }

                                    // Y min/max labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(smaxY2).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(sminY2).toFixed(1), padL - 8, height - padB)
                                }
                                else if (page.chartType === "comparison" && page.chartData2.pointCount > 0) {
                                    var tVals2 = page.chartData2.targetValues || []
                                    var minT = 999999, maxT = -999999
                                    for (var tp = 0; tp < tVals2.length; ++tp) {
                                        if (tVals2[tp] < minT) minT = tVals2[tp]
                                        if (tVals2[tp] > maxT) maxT = tVals2[tp]
                                    }
                                    if (minT === 999999) { minT = 0; maxT = 1; }
                                    var rngT = (maxT - minT) === 0 ? 1 : (maxT - minT)
                                    var stepT = Math.max(1, Math.floor(tVals2.length / 1000))

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2.2
                                    ctx.beginPath()
                                    var firstT = true
                                    for (var tk = 0; tk < tVals2.length; tk += stepT) {
                                        var xPT = padL + (tk / Math.max(1, tVals2.length - 1)) * plotW
                                        var yPT = (height - padB) - ((tVals2[tk] - minT) / rngT) * (plotH - 20)
                                        if (firstT) { ctx.moveTo(xPT, yPT); firstT = false } else { ctx.lineTo(xPT, yPT) }
                                    }
                                    ctx.stroke()

                                    // Labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(maxT).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(minT).toFixed(1), padL - 8, height - padB)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
}