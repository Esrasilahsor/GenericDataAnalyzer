import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import QtCharts 2.15

ApplicationWindow {
    id: window

    visible: true
    width: 1350
    height: 850

    minimumWidth: 1050
    minimumHeight: 700

    title: "Generic Data Analyzer"
    color: "#151922"

    // =====================================================
    // VISUALIZATION STATE
    // =====================================================

    property var dataset1VisualizationResult: ({})
    property var dataset2VisualizationResult: ({})
    property var comparisonVisualizationResult: ({})

    // =====================================================
    // HELPERS
    // =====================================================

    function formatNumber(value) {
        if (value === undefined || value === null)
            return "-"

        return Number(value).toFixed(2)
    }

    function formatDifference(value) {
        if (value === undefined || value === null)
            return "-"

        var number = Number(value)

        if (number > 0)
            return "+" + number.toFixed(2)

        return number.toFixed(2)
    }

    function formatList(value) {
        if (value === undefined || value === null)
            return "-"

        if (value.length === 0)
            return "None"

        return value.join(", ")
    }

    function correlationLabel(value) {
        if (value === undefined || value === null)
            return "-"

        var number = Number(value)

        if (number >= 0.70)
            return "Strong positive correlation"

        if (number >= 0.30)
            return "Moderate positive correlation"

        if (number > -0.30)
            return "Weak / no linear correlation"

        if (number > -0.70)
            return "Moderate negative correlation"

        return "Strong negative correlation"
    }

    function ensureExportExtension(fileUrl, extension) {
        var path = String(fileUrl)

        if (path.toLowerCase().endsWith(extension.toLowerCase()))
            return path

        return path + extension
    }

    function listMinimum(values, fallbackValue) {
        if (values === undefined || values === null || values.length === 0)
            return fallbackValue

        var result = Number(values[0])

        for (var i = 1; i < values.length; ++i)
            result = Math.min(result, Number(values[i]))

        return result
    }

    function listMaximum(values, fallbackValue) {
        if (values === undefined || values === null || values.length === 0)
            return fallbackValue

        var result = Number(values[0])

        for (var i = 1; i < values.length; ++i)
            result = Math.max(result, Number(values[i]))

        return result
    }

    function histogramLabels(result) {
        if (!result || !result["success"])
            return []

        var lower = result["binLowerBounds"] || []
        var upper = result["binUpperBounds"] || []
        var labels = []

        for (var i = 0; i < Math.min(lower.length, upper.length); ++i)
            labels.push(Number(lower[i]).toFixed(1) + "–" + Number(upper[i]).toFixed(1))

        return labels
    }

    function correlationCellColor(value) {
        var number = Number(value)

        if (number >= 0.70)
            return "#24543E"

        if (number >= 0.30)
            return "#3C5A46"

        if (number <= -0.70)
            return "#64343D"

        if (number <= -0.30)
            return "#573E46"

        return "#343C49"
    }

    function drawAxes(ctx, width, height, left, top, right, bottom) {
        ctx.strokeStyle = "#667085"
        ctx.lineWidth = 1

        ctx.beginPath()
        ctx.moveTo(left, top)
        ctx.lineTo(left, height - bottom)
        ctx.lineTo(width - right, height - bottom)
        ctx.stroke()
    }

    function drawHistogram(canvas, ctx, result) {
        var width = canvas.width
        var height = canvas.height

        ctx.clearRect(0, 0, width, height)

        var frequencies = result["frequencies"] || []
        if (frequencies.length === 0)
            return

        var left = 45
        var top = 20
        var right = 20
        var bottom = 48

        drawAxes(ctx, width, height, left, top, right, bottom)

        var maxFrequency = Math.max(1, listMaximum(frequencies, 1))
        var plotWidth = width - left - right
        var plotHeight = height - top - bottom
        var barWidth = plotWidth / frequencies.length

        for (var i = 0; i < frequencies.length; ++i) {
            var value = Number(frequencies[i])
            var barHeight = (value / maxFrequency) * (plotHeight - 12)

            ctx.fillStyle = "#6EA8E5"
            ctx.fillRect(
                        left + i * barWidth + 2,
                        height - bottom - barHeight,
                        Math.max(2, barWidth - 4),
                        barHeight)

            ctx.fillStyle = "#D7DCE5"
            ctx.font = "11px sans-serif"
            ctx.textAlign = "center"
            ctx.fillText(
                        String(value),
                        left + (i + 0.5) * barWidth,
                        height - bottom - barHeight - 4)
        }

        var labels = histogramLabels(result)
        ctx.fillStyle = "#9FA8B8"
        ctx.font = "9px sans-serif"
        ctx.textAlign = "center"

        for (var j = 0; j < labels.length; ++j) {
            if (labels.length <= 6 || j % 2 === 0) {
                ctx.save()
                ctx.translate(left + (j + 0.5) * barWidth, height - bottom + 12)
                ctx.rotate(-0.45)
                ctx.fillText(labels[j], 0, 0)
                ctx.restore()
            }
        }
    }

    function drawBoxPlot(canvas, ctx, result) {
        var width = canvas.width
        var height = canvas.height

        ctx.clearRect(0, 0, width, height)

        var minimum = Number(result["minimum"])
        var maximum = Number(result["maximum"])
        var q1 = Number(result["q1"])
        var median = Number(result["median"])
        var q3 = Number(result["q3"])
        var lowerWhisker = Number(result["lowerWhisker"])
        var upperWhisker = Number(result["upperWhisker"])
        var outliers = result["outlierValues"] || []

        var left = 55
        var right = 35
        var centerY = height / 2
        var boxHeight = 70

        var range = maximum - minimum
        if (range === 0)
            range = 1

        function xFor(value) {
            return left + ((value - minimum) / range) * (width - left - right)
        }

        ctx.strokeStyle = "#D7DCE5"
        ctx.lineWidth = 2

        ctx.beginPath()
        ctx.moveTo(xFor(lowerWhisker), centerY)
        ctx.lineTo(xFor(q1), centerY)
        ctx.moveTo(xFor(q3), centerY)
        ctx.lineTo(xFor(upperWhisker), centerY)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(xFor(lowerWhisker), centerY - 18)
        ctx.lineTo(xFor(lowerWhisker), centerY + 18)
        ctx.moveTo(xFor(upperWhisker), centerY - 18)
        ctx.lineTo(xFor(upperWhisker), centerY + 18)
        ctx.stroke()

        ctx.fillStyle = "#31506D"
        ctx.strokeStyle = "#9CCBFF"
        ctx.fillRect(xFor(q1), centerY - boxHeight / 2,
                     Math.max(2, xFor(q3) - xFor(q1)), boxHeight)
        ctx.strokeRect(xFor(q1), centerY - boxHeight / 2,
                       Math.max(2, xFor(q3) - xFor(q1)), boxHeight)

        ctx.strokeStyle = "#FFE29A"
        ctx.beginPath()
        ctx.moveTo(xFor(median), centerY - boxHeight / 2)
        ctx.lineTo(xFor(median), centerY + boxHeight / 2)
        ctx.stroke()

        ctx.fillStyle = "#FFB4AB"
        for (var i = 0; i < outliers.length; ++i) {
            ctx.beginPath()
            ctx.arc(xFor(Number(outliers[i])), centerY, 5, 0, Math.PI * 2)
            ctx.fill()
        }

        ctx.fillStyle = "#AAB2C0"
        ctx.font = "11px sans-serif"
        ctx.textAlign = "center"
        ctx.fillText(formatNumber(lowerWhisker), xFor(lowerWhisker), centerY + 62)
        ctx.fillText("Q1 " + formatNumber(q1), xFor(q1), centerY - 52)
        ctx.fillText("Median " + formatNumber(median), xFor(median), centerY + 62)
        ctx.fillText("Q3 " + formatNumber(q3), xFor(q3), centerY - 52)
        ctx.fillText(formatNumber(upperWhisker), xFor(upperWhisker), centerY + 62)
    }

    function drawLineChart(canvas, ctx, xValues, yValues, secondValues) {
        var width = canvas.width
        var height = canvas.height

        ctx.clearRect(0, 0, width, height)

        if (!xValues || !yValues || xValues.length === 0 || yValues.length === 0)
            return

        var left = 55
        var top = 20
        var right = 25
        var bottom = 40

        drawAxes(ctx, width, height, left, top, right, bottom)

        var xMin = listMinimum(xValues, 0)
        var xMax = listMaximum(xValues, 1)
        var yMin = listMinimum(yValues, 0)
        var yMax = listMaximum(yValues, 1)

        if (secondValues && secondValues.length > 0) {
            yMin = Math.min(yMin, listMinimum(secondValues, yMin))
            yMax = Math.max(yMax, listMaximum(secondValues, yMax))
        }

        if (xMax === xMin)
            xMax = xMin + 1

        if (yMax === yMin)
            yMax = yMin + 1

        function px(x) {
            return left + ((Number(x) - xMin) / (xMax - xMin)) * (width - left - right)
        }

        function py(y) {
            return height - bottom -
                    ((Number(y) - yMin) / (yMax - yMin)) * (height - top - bottom)
        }

        function drawSeries(values, stroke) {
            ctx.strokeStyle = stroke
            ctx.lineWidth = 2
            ctx.beginPath()

            for (var i = 0; i < Math.min(xValues.length, values.length); ++i) {
                if (i === 0)
                    ctx.moveTo(px(xValues[i]), py(values[i]))
                else
                    ctx.lineTo(px(xValues[i]), py(values[i]))
            }

            ctx.stroke()
        }

        drawSeries(yValues, "#9CCBFF")

        if (secondValues && secondValues.length > 0)
            drawSeries(secondValues, "#D2B4FF")

        ctx.fillStyle = "#AAB2C0"
        ctx.font = "11px sans-serif"
        ctx.textAlign = "left"
        ctx.fillText(formatNumber(yMax), 4, top + 8)
        ctx.fillText(formatNumber(yMin), 4, height - bottom)
    }

    function drawDistribution(canvas, ctx, result) {
        drawLineChart(
                    canvas,
                    ctx,
                    result["centers"] || [],
                    result["relativeFrequencies"] || [],
                    [])
    }

    function drawVisualization(canvas, ctx, type, result) {
        if (!result || !result["success"]) {
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            return
        }

        if (type === "Histogram")
            drawHistogram(canvas, ctx, result)
        else if (type === "Box Plot")
            drawBoxPlot(canvas, ctx, result)
        else if (type === "Time Series")
            drawLineChart(canvas, ctx,
                          result["xValues"] || [],
                          result["yValues"] || [],
                          [])
        else if (type === "Distribution")
            drawDistribution(canvas, ctx, result)
    }

    // =====================================================
    // FILE DIALOGS
    // =====================================================

    FileDialog {
        id: dataset1Dialog

        title: "Select Dataset 1"

        nameFilters: [
            "Supported Data Files (*.xlsx *.csv *.txt)",
            "Excel Files (*.xlsx)",
            "CSV Files (*.csv)",
            "Text Files (*.txt)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadDataset1(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }

            dataset1OutlierColumn.currentIndex = -1
            dataset1FillColumn.currentIndex = -1
            dataset1CleaningOutlierColumn.currentIndex = -1
            dataset1CleaningOutlierMethod.currentIndex = 0
            dataset1CleaningOutlierAction.currentIndex = 0
            dataset1EdaColumn.currentIndex = -1
            dataset1CorrelationColumnA.currentIndex = -1
            dataset1CorrelationColumnB.currentIndex = -1
            dataset1VisualizationColumn.currentIndex = -1
            dataset1TimeXColumn.currentIndex = -1
            dataset1TimeYColumn.currentIndex = -1
        }
    }

    FileDialog {
        id: dataset2Dialog

        title: "Select Dataset 2"

        nameFilters: [
            "Supported Data Files (*.xlsx *.csv *.txt)",
            "Excel Files (*.xlsx)",
            "CSV Files (*.csv)",
            "Text Files (*.txt)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadDataset2(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }

            dataset2OutlierColumn.currentIndex = -1
            dataset2FillColumn.currentIndex = -1
            dataset2CleaningOutlierColumn.currentIndex = -1
            dataset2CleaningOutlierMethod.currentIndex = 0
            dataset2CleaningOutlierAction.currentIndex = 0
            dataset2EdaColumn.currentIndex = -1
            dataset2CorrelationColumnA.currentIndex = -1
            dataset2CorrelationColumnB.currentIndex = -1
            dataset2VisualizationColumn.currentIndex = -1
            dataset2TimeXColumn.currentIndex = -1
            dataset2TimeYColumn.currentIndex = -1
        }
    }

    FileDialog {
        id: rawMetadataDialog

        title: "Select Raw Metadata Excel"

        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadRawMetadata(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }
        }
    }

    FileDialog {
        id: rawDataDialog

        title: "Select Raw Data File"

        nameFilters: [
            "Raw Data Files (*.bin *.dat *.raw)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadRawDataFile(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }
        }
    }

    MessageDialog {
        id: errorDialog

        title: "Error"
        icon: StandardIcon.Critical
    }

    MessageDialog {
        id: exportSuccessDialog

        title: "Export Complete"
        icon: StandardIcon.Information
    }

    FileDialog {
        id: dataset1CsvExportDialog

        title: "Export Dataset 1 as CSV"

        nameFilters: [
            "CSV Files (*.csv)",
            "All Files (*)"
        ]

        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath =
                    ensureExportExtension(
                        fileUrl,
                        ".csv"
                    )

            var success =
                    appController.exportDataset1ToCsv(
                        exportPath
                    )

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 1 was exported successfully as CSV."

            exportSuccessDialog.open()
        }
    }

    FileDialog {
        id: dataset1JsonExportDialog

        title: "Export Dataset 1 as JSON"

        nameFilters: [
            "JSON Files (*.json)",
            "All Files (*)"
        ]

        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath =
                    ensureExportExtension(
                        fileUrl,
                        ".json"
                    )

            var success =
                    appController.exportDataset1ToJson(
                        exportPath
                    )

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 1 was exported successfully as JSON."

            exportSuccessDialog.open()
        }
    }

    FileDialog {
        id: dataset1XlsxExportDialog
        title: "Export Dataset 1 as Excel"
        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]
        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath = ensureExportExtension(fileUrl, ".xlsx")
            var success = appController.exportDataset1ToXlsx(exportPath)

            if (!success) {
                errorDialog.text = appController.lastError
                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 1 was exported successfully as Excel."
            exportSuccessDialog.open()
        }
    }

    FileDialog {
        id: dataset2CsvExportDialog

        title: "Export Dataset 2 as CSV"

        nameFilters: [
            "CSV Files (*.csv)",
            "All Files (*)"
        ]

        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath =
                    ensureExportExtension(
                        fileUrl,
                        ".csv"
                    )

            var success =
                    appController.exportDataset2ToCsv(
                        exportPath
                    )

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 2 was exported successfully as CSV."

            exportSuccessDialog.open()
        }
    }

    FileDialog {
        id: dataset2JsonExportDialog

        title: "Export Dataset 2 as JSON"

        nameFilters: [
            "JSON Files (*.json)",
            "All Files (*)"
        ]

        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath =
                    ensureExportExtension(
                        fileUrl,
                        ".json"
                    )

            var success =
                    appController.exportDataset2ToJson(
                        exportPath
                    )

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 2 was exported successfully as JSON."

            exportSuccessDialog.open()
        }
    }

    FileDialog {
        id: dataset2XlsxExportDialog
        title: "Export Dataset 2 as Excel"
        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]
        selectExisting: false
        selectMultiple: false

        onAccepted: {
            var exportPath = ensureExportExtension(fileUrl, ".xlsx")
            var success = appController.exportDataset2ToXlsx(exportPath)

            if (!success) {
                errorDialog.text = appController.lastError
                errorDialog.open()
                return
            }

            exportSuccessDialog.text =
                    "Dataset 2 was exported successfully as Excel."
            exportSuccessDialog.open()
        }
    }

    // =====================================================
    // HEADER
    // =====================================================

    Rectangle {
        id: headerBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 70

        color: "#1D2330"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            spacing: 20

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: "Generic Data Analyzer"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Item {
                width: Math.max(
                           0,
                           headerBar.width - 500
                       )

                height: 1
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: "Excel & Raw Data Analysis Platform"

                color: "#AAB2C0"

                font.pixelSize: 14
            }
        }
    }

    // =====================================================
    // MAIN SCROLL AREA
    // =====================================================

    Flickable {
        id: flickable

        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        clip: true

        contentWidth: width
        contentHeight: contentColumn.height + 60

        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: contentColumn

            width: flickable.width

            spacing: 24

            Item {
                width: 1
                height: 25
            }

            // =================================================
            // DATASET SELECTION
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Dataset Selection"

                    color: "white"

                    font.pixelSize: 28
                    font.bold: true
                }

                Text {
                    text: "Select two Excel datasets to start the analysis."

                    color: "#AAB2C0"

                    font.pixelSize: 15
                }
            }

            Row {
                width: parent.width - 60
                height: 215

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Dataset 1"

                            color: "white"

                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.dataset1Name.length > 0
                                ? appController.dataset1Name
                                : "No Excel file selected"

                            color: "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset1Name.length > 0

                            text:
                                "Sheet: "
                                + appController.dataset1SheetName

                            color: "#AAB2C0"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset1Name.length > 0

                            text:
                                "Rows: "
                                + appController.dataset1RowCount
                                + " | Columns: "
                                + appController.dataset1ColumnCount

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 175
                            height: 42

                            text:
                                appController.dataset1Name.length > 0
                                ? "Change Excel 1"
                                : "Select Excel 1"

                            onClicked:
                                dataset1Dialog.open()
                        }
                    }
                }

                // =============================================
                // DATASET 2
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Dataset 2"

                            color: "white"

                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.dataset2Name.length > 0
                                ? appController.dataset2Name
                                : "No Excel file selected"

                            color: "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset2Name.length > 0

                            text:
                                "Sheet: "
                                + appController.dataset2SheetName

                            color: "#AAB2C0"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset2Name.length > 0

                            text:
                                "Rows: "
                                + appController.dataset2RowCount
                                + " | Columns: "
                                + appController.dataset2ColumnCount

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 175
                            height: 42

                            text:
                                appController.dataset2Name.length > 0
                                ? "Change Excel 2"
                                : "Select Excel 2"

                            onClicked:
                                dataset2Dialog.open()
                        }
                    }
                }
            }

            // =================================================
            // COLUMN DISCOVERY
            // =================================================

            Text {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                text: "Column Discovery"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Row {
                width: parent.width - 60
                height: 340

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 COLUMNS
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15

                        spacing: 10

                        Text {
                            text: "Dataset 1 Columns"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width
                            height: 40

                            radius: 6
                            color: "#262E3D"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    width: parent.width - 245

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Column"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Type"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Missing"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Unique"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: 245

                            clip: true

                            model:
                                appController.dataset1ColumnModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        width: parent.width - 245

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.name

                                        color: "white"

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 85

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.dataType

                                        color:
                                            model.isNumeric
                                            ? "#9CCBFF"
                                            : "#D2B4FF"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.missingCount

                                        color:
                                            model.missingCount > 0
                                            ? "#FFB4AB"
                                            : "#AAB2C0"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.uniqueCount

                                        color: "#AAB2C0"
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                visible:
                                    appController.dataset1ColumnModel.count() === 0

                                text:
                                    "Load Dataset 1 to discover columns"

                                color: "#7F899A"
                            }
                        }
                    }
                }

                // =============================================
                // DATASET 2 COLUMNS
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15

                        spacing: 10

                        Text {
                            text: "Dataset 2 Columns"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width
                            height: 40

                            radius: 6
                            color: "#262E3D"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    width: parent.width - 245

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Column"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Type"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Missing"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Unique"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: 245

                            clip: true

                            model:
                                appController.dataset2ColumnModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        width: parent.width - 245

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.name

                                        color: "white"

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 85

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.dataType

                                        color:
                                            model.isNumeric
                                            ? "#9CCBFF"
                                            : "#D2B4FF"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.missingCount

                                        color:
                                            model.missingCount > 0
                                            ? "#FFB4AB"
                                            : "#AAB2C0"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.uniqueCount

                                        color: "#AAB2C0"
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                visible:
                                    appController.dataset2ColumnModel.count() === 0

                                text:
                                    "Load Dataset 2 to discover columns"

                                color: "#7F899A"
                            }
                        }
                    }
                }
            }

            // =================================================
            // DATA QUALITY
            // =================================================

            Text {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                text: "Dataset Quality Analysis"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Row {
                width: parent.width - 60
                height: 480

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 QUALITY
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1QualityAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Row {
                            width: parent.width
                            height: 42

                            Text {
                                width: parent.width - 170

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1 Quality"

                                color: "white"

                                font.pixelSize: 18
                                font.bold: true
                            }

                            Button {
                                width: 170
                                height: 38

                                text:
                                    appController.dataset1QualityAvailable
                                    ? "Reanalyze Quality"
                                    : "Analyze Quality"

                                enabled:
                                    appController.dataset1Name.length > 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset1Quality()

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset1QualityAvailable

                            width: parent.width

                            text:
                                appController.dataset1Name.length > 0
                                ? "Click Analyze Quality to inspect this dataset."
                                : "Load Dataset 1 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 6

                            visible:
                                appController.dataset1QualityAvailable

                            Rectangle {
                                width: parent.width
                                height: 36

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Rows: "
                                        + appController.dataset1QualityResult["rowCount"]
                                        + "   |   Columns: "
                                        + appController.dataset1QualityResult["columnCount"]

                                    color: "white"
                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Missing Values: "
                                    + appController.dataset1QualityResult["totalMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Missing Percentage: "
                                    + formatNumber(
                                          appController.dataset1QualityResult["missingPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset1QualityResult["totalMissingValues"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Columns With Missing: "
                                    + appController.dataset1QualityResult["columnsWithMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Missing Columns: "
                                    + formatList(
                                          appController.dataset1QualityResult["columnsWithMissing"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Duplicate Rows: "
                                    + appController.dataset1QualityResult["duplicateRowCount"]

                                color:
                                    appController.dataset1QualityResult["duplicateRowCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Duplicate Percentage: "
                                    + formatNumber(
                                          appController.dataset1QualityResult["duplicatePercentage"]
                                      )
                                    + "%"

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Constant Columns: "
                                    + appController.dataset1QualityResult["constantColumnCount"]

                                color:
                                    appController.dataset1QualityResult["constantColumnCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Constant Column Names: "
                                    + formatList(
                                          appController.dataset1QualityResult["constantColumns"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Numeric Columns: "
                                    + appController.dataset1QualityResult["numericColumnCount"]

                                color: "#9CCBFF"
                            }

                            Text {
                                text:
                                    "Non-Numeric Columns: "
                                    + appController.dataset1QualityResult["nonNumericColumnCount"]

                                color: "#D2B4FF"
                            }
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 140
                            height: 36

                            visible:
                                appController.dataset1QualityAvailable

                            text: "Clear Quality"

                            onClicked:
                                appController.clearDataset1Quality()
                        }
                    }
                }

                // =============================================
                // DATASET 2 QUALITY
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2QualityAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Row {
                            width: parent.width
                            height: 42

                            Text {
                                width: parent.width - 170

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2 Quality"

                                color: "white"

                                font.pixelSize: 18
                                font.bold: true
                            }

                            Button {
                                width: 170
                                height: 38

                                text:
                                    appController.dataset2QualityAvailable
                                    ? "Reanalyze Quality"
                                    : "Analyze Quality"

                                enabled:
                                    appController.dataset2Name.length > 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset2Quality()

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset2QualityAvailable

                            width: parent.width

                            text:
                                appController.dataset2Name.length > 0
                                ? "Click Analyze Quality to inspect this dataset."
                                : "Load Dataset 2 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 6

                            visible:
                                appController.dataset2QualityAvailable

                            Rectangle {
                                width: parent.width
                                height: 36

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Rows: "
                                        + appController.dataset2QualityResult["rowCount"]
                                        + "   |   Columns: "
                                        + appController.dataset2QualityResult["columnCount"]

                                    color: "white"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Missing Values: "
                                    + appController.dataset2QualityResult["totalMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Missing Percentage: "
                                    + formatNumber(
                                          appController.dataset2QualityResult["missingPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset2QualityResult["totalMissingValues"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Columns With Missing: "
                                    + appController.dataset2QualityResult["columnsWithMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Missing Columns: "
                                    + formatList(
                                          appController.dataset2QualityResult["columnsWithMissing"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Duplicate Rows: "
                                    + appController.dataset2QualityResult["duplicateRowCount"]

                                color:
                                    appController.dataset2QualityResult["duplicateRowCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Duplicate Percentage: "
                                    + formatNumber(
                                          appController.dataset2QualityResult["duplicatePercentage"]
                                      )
                                    + "%"

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Constant Columns: "
                                    + appController.dataset2QualityResult["constantColumnCount"]

                                color:
                                    appController.dataset2QualityResult["constantColumnCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Constant Column Names: "
                                    + formatList(
                                          appController.dataset2QualityResult["constantColumns"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Numeric Columns: "
                                    + appController.dataset2QualityResult["numericColumnCount"]

                                color: "#9CCBFF"
                            }

                            Text {
                                text:
                                    "Non-Numeric Columns: "
                                    + appController.dataset2QualityResult["nonNumericColumnCount"]

                                color: "#D2B4FF"
                            }
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 140
                            height: 36

                            visible:
                                appController.dataset2QualityAvailable

                            text: "Clear Quality"

                            onClicked:
                                appController.clearDataset2Quality()
                        }
                    }
                }
            }


            // =========================================================
            // DATA CLEANING
            // =========================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Data Cleaning"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text:
                        "Cleaning operations are applied only to the working dataset. "
                        + "The original dataset is preserved and can be restored."

                    color: "#AAB2C0"

                    font.pixelSize: 14

                    wrapMode: Text.WordWrap
                }
            }


            // =========================================================
            // CLEANING PANELS
            // =========================================================

            Row {
                width: parent.width - 60
                height: 1280

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20


                // =====================================================
                // DATASET 1
                // =====================================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1Modified
                        ? "#C792EA"
                        : "#30394A"

                    border.width: 1


                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12


                        // -------------------------------------------------
                        // TITLE
                        // -------------------------------------------------

                        Text {
                            text: "Dataset 1 Cleaning"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }


                        // -------------------------------------------------
                        // STATUS
                        // -------------------------------------------------

                        Text {
                            width: parent.width

                            text:
                                appController.dataset1Name.length > 0
                                ?
                                (
                                    appController.dataset1Modified
                                    ? "Working dataset has been modified."
                                    : "Working dataset is identical to the original."
                                )
                                :
                                "Load Dataset 1 first."

                            color:
                                appController.dataset1Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"

                            wrapMode: Text.WordWrap
                        }


                        // -------------------------------------------------
                        // ROW COUNT
                        // -------------------------------------------------

                        Rectangle {
                            width: parent.width
                            height: 42

                            radius: 6

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    appController.dataset1Name.length > 0
                                    ?
                                    "Current Rows: "
                                    + appController.dataset1RowCount
                                    :
                                    "No Dataset"

                                color: "white"

                                font.bold: true
                            }
                        }


                        // =================================================
                        // ROW OPERATIONS
                        // =================================================

                        Text {
                            text: "Row Operations"

                            color: "#9CCBFF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Duplicate Rows"

                            enabled:
                                appController.dataset1Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset1Duplicates()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Rows With Missing Values"

                            enabled:
                                appController.dataset1Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset1MissingRows()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 1

                            color: "#30394A"
                        }


                        // =================================================
                        // FILL MISSING
                        // =================================================

                        Text {
                            text: "Fill Missing Values"

                            color: "#9CCBFF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Text {
                            text: "Select Column"

                            color: "#AAB2C0"
                        }


                        ComboBox {
                            id: dataset1FillColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset1ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }


                        // -------------------------------------------------
                        // SELECTED COLUMN INFO
                        // -------------------------------------------------

                        Rectangle {
                            width: parent.width
                            height: 38

                            radius: 5

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    dataset1FillColumn.currentIndex >= 0
                                    ?
                                    "Selected Column: "
                                    + dataset1FillColumn.currentText
                                    :
                                    "No column selected"

                                color:
                                    dataset1FillColumn.currentIndex >= 0
                                    ? "#9CCBFF"
                                    : "#7F899A"

                                font.bold:
                                    dataset1FillColumn.currentIndex >= 0
                            }
                        }


                        // -------------------------------------------------
                        // MEAN
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mean"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MEAN COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMean(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MEAN SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        // -------------------------------------------------
                        // MEDIAN
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Median"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MEDIAN COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMedian(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MEDIAN SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        // -------------------------------------------------
                        // MODE
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mode"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MODE COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMode(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MODE SUCCESS:",
                                    success
                                )

                                console.log(
                                    "MODE ERROR:",
                                    appController.lastError
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }



                        // =================================================
                        // OUTLIER CLEANING
                        // =================================================

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#30394A"
                        }

                        Text {
                            text: "Outlier Cleaning"
                            color: "#FFB4A9"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: "Select Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierColumn

                            width: parent.width
                            height: 42

                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Text {
                            text: "Detection Method"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierMethod

                            width: parent.width
                            height: 42

                            model: [
                                "IQR",
                                "Z-Score"
                            ]

                            currentIndex: 0
                        }

                        Text {
                            text:
                                dataset1CleaningOutlierMethod.currentText === "IQR"
                                ? "IQR Multiplier"
                                : "Z-Score Threshold"

                            color: "#AAB2C0"
                        }

                        TextField {
                            id: dataset1CleaningOutlierParameter

                            width: parent.width
                            height: 42

                            text:
                                dataset1CleaningOutlierMethod.currentText === "IQR"
                                ? "1.5"
                                : "3.0"

                            validator: DoubleValidator {
                                bottom: 0.01
                                top: 100.0
                                decimals: 3
                            }
                        }

                        Text {
                            text: "Action"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierAction

                            width: parent.width
                            height: 42

                            model: [
                                "Keep",
                                "Mark",
                                "Remove"
                            ]

                            currentIndex: 0
                        }

                        Button {
                            width: parent.width
                            height: 42

                            text: "Apply Outlier Operation"

                            enabled:
                                dataset1CleaningOutlierColumn.currentIndex >= 0
                                &&
                                dataset1CleaningOutlierParameter.text.length > 0

                            onClicked: {
                                var success =
                                        appController.applyDataset1OutlierAction(
                                            dataset1CleaningOutlierColumn.currentText,
                                            dataset1CleaningOutlierMethod.currentText,
                                            dataset1CleaningOutlierAction.currentText,
                                            Number(
                                                dataset1CleaningOutlierParameter.text
                                            )
                                        )

                                if (!success) {
                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 150

                            visible:
                                Object.keys(
                                    appController.dataset1OutlierCleaningResult
                                ).length > 0

                            radius: 6
                            color: "#262E3D"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Text {
                                    text:
                                        "Method: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["method"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Action: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["action"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Outliers: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["outlierCount"]
                                            || 0
                                        )

                                    color: "#FFB4A9"
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Marked Rows: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["markedRows"]
                                            || []
                                        ).join(", ")

                                    color: "#FFE29A"
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        appController.dataset1OutlierCleaningResult["message"]
                                        || ""

                                    color: "#9FE3B5"
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // =================================================
                        // RESTORE
                        // =================================================

                        Button {
                            width: parent.width
                            height: 44

                            text: "Restore Original Dataset"

                            enabled:
                                appController.dataset1Modified

                            onClicked: {

                                var success =
                                        appController.restoreDataset1()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }

                                dataset1FillColumn.currentIndex = -1
                                dataset1CleaningOutlierColumn.currentIndex = -1
                            }
                        }
                    }
                }

                // =====================================================
                // DATASET 2
                // =====================================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2Modified
                        ? "#C792EA"
                        : "#30394A"

                    border.width: 1


                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12


                        Text {
                            text: "Dataset 2 Cleaning"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }


                        Text {
                            width: parent.width

                            text:
                                appController.dataset2Name.length > 0
                                ?
                                (
                                    appController.dataset2Modified
                                    ? "Working dataset has been modified."
                                    : "Working dataset is identical to the original."
                                )
                                :
                                "Load Dataset 2 first."

                            color:
                                appController.dataset2Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"

                            wrapMode: Text.WordWrap
                        }


                        Rectangle {
                            width: parent.width
                            height: 42

                            radius: 6

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    appController.dataset2Name.length > 0
                                    ?
                                    "Current Rows: "
                                    + appController.dataset2RowCount
                                    :
                                    "No Dataset"

                                color: "white"

                                font.bold: true
                            }
                        }


                        // =================================================
                        // ROW OPERATIONS
                        // =================================================

                        Text {
                            text: "Row Operations"

                            color: "#D2B4FF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Duplicate Rows"

                            enabled:
                                appController.dataset2Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset2Duplicates()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Rows With Missing Values"

                            enabled:
                                appController.dataset2Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset2MissingRows()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 1

                            color: "#30394A"
                        }


                        // =================================================
                        // FILL MISSING
                        // =================================================

                        Text {
                            text: "Fill Missing Values"

                            color: "#D2B4FF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Text {
                            text: "Select Column"

                            color: "#AAB2C0"
                        }


                        ComboBox {
                            id: dataset2FillColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset2ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }


                        Rectangle {
                            width: parent.width
                            height: 38

                            radius: 5

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    dataset2FillColumn.currentIndex >= 0
                                    ?
                                    "Selected Column: "
                                    + dataset2FillColumn.currentText
                                    :
                                    "No column selected"

                                color:
                                    dataset2FillColumn.currentIndex >= 0
                                    ? "#D2B4FF"
                                    : "#7F899A"

                                font.bold:
                                    dataset2FillColumn.currentIndex >= 0
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mean"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MEAN COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMean(
                                            dataset2FillColumn.currentText
                                        )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Median"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MEDIAN COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMedian(
                                            dataset2FillColumn.currentText
                                        )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mode"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MODE COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMode(
                                            dataset2FillColumn.currentText
                                        )

                                console.log(
                                    "DATASET 2 MODE SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }



                        // =================================================
                        // OUTLIER CLEANING
                        // =================================================

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#30394A"
                        }

                        Text {
                            text: "Outlier Cleaning"
                            color: "#FFB4A9"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: "Select Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierColumn

                            width: parent.width
                            height: 42

                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Text {
                            text: "Detection Method"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierMethod

                            width: parent.width
                            height: 42

                            model: [
                                "IQR",
                                "Z-Score"
                            ]

                            currentIndex: 0
                        }

                        Text {
                            text:
                                dataset2CleaningOutlierMethod.currentText === "IQR"
                                ? "IQR Multiplier"
                                : "Z-Score Threshold"

                            color: "#AAB2C0"
                        }

                        TextField {
                            id: dataset2CleaningOutlierParameter

                            width: parent.width
                            height: 42

                            text:
                                dataset2CleaningOutlierMethod.currentText === "IQR"
                                ? "1.5"
                                : "3.0"

                            validator: DoubleValidator {
                                bottom: 0.01
                                top: 100.0
                                decimals: 3
                            }
                        }

                        Text {
                            text: "Action"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierAction

                            width: parent.width
                            height: 42

                            model: [
                                "Keep",
                                "Mark",
                                "Remove"
                            ]

                            currentIndex: 0
                        }

                        Button {
                            width: parent.width
                            height: 42

                            text: "Apply Outlier Operation"

                            enabled:
                                dataset2CleaningOutlierColumn.currentIndex >= 0
                                &&
                                dataset2CleaningOutlierParameter.text.length > 0

                            onClicked: {
                                var success =
                                        appController.applyDataset2OutlierAction(
                                            dataset2CleaningOutlierColumn.currentText,
                                            dataset2CleaningOutlierMethod.currentText,
                                            dataset2CleaningOutlierAction.currentText,
                                            Number(
                                                dataset2CleaningOutlierParameter.text
                                            )
                                        )

                                if (!success) {
                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 150

                            visible:
                                Object.keys(
                                    appController.dataset2OutlierCleaningResult
                                ).length > 0

                            radius: 6
                            color: "#262E3D"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Text {
                                    text:
                                        "Method: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["method"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Action: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["action"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Outliers: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["outlierCount"]
                                            || 0
                                        )

                                    color: "#FFB4A9"
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Marked Rows: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["markedRows"]
                                            || []
                                        ).join(", ")

                                    color: "#FFE29A"
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        appController.dataset2OutlierCleaningResult["message"]
                                        || ""

                                    color: "#9FE3B5"
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Button {
                            width: parent.width
                            height: 44

                            text: "Restore Original Dataset"

                            enabled:
                                appController.dataset2Modified

                            onClicked: {

                                var success =
                                        appController.restoreDataset2()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }

                                dataset2FillColumn.currentIndex = -1
                                dataset2CleaningOutlierColumn.currentIndex = -1
                            }
                        }
                    }
                }
            }


            // =================================================
            // EXPLORATORY DATA ANALYSIS
            // =================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    text: "Exploratory Data Analysis"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: "Select a numeric column to calculate descriptive statistics for the current working dataset."
                    color: "#AAB2C0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                width: parent.width - 60
                height: 620
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: appController.dataset1EdaAvailable ? "#4E8A68" : "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "Dataset 1 EDA Summary"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text { text: "Select Numeric Column"; color: "#AAB2C0" }

                        ComboBox {
                            id: dataset1EdaColumn
                            width: parent.width
                            height: 42
                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1
                            enabled: appController.dataset1Name.length > 0
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40
                                text: appController.dataset1EdaAvailable ? "Reanalyze EDA" : "Analyze EDA"
                                enabled: dataset1EdaColumn.currentIndex >= 0

                                onClicked: {
                                    var success = appController.analyzeDataset1Eda(
                                                dataset1EdaColumn.currentText)
                                    if (!success) {
                                        errorDialog.text = appController.lastError
                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40
                                text: "Clear"
                                enabled: appController.dataset1EdaAvailable
                                onClicked: appController.clearDataset1Eda()
                            }
                        }

                        Text {
                            width: parent.width
                            visible: !appController.dataset1EdaAvailable
                            text: appController.dataset1Name.length > 0
                                  ? "Choose a numeric column and run EDA."
                                  : "Load Dataset 1 first."
                            color: "#7F899A"
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 0
                            visible: appController.dataset1EdaAvailable

                            Rectangle {
                                width: parent.width
                                height: 42
                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Column: " + (appController.dataset1EdaResult["columnName"] || "-")
                                    color: "#9CCBFF"
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: [
                                    { label: "Count", key: "count", format: false },
                                    { label: "Mean", key: "mean", format: true },
                                    { label: "Median", key: "median", format: true },
                                    { label: "Minimum", key: "minimum", format: true },
                                    { label: "Maximum", key: "maximum", format: true },
                                    { label: "Range", key: "range", format: true },
                                    { label: "Variance", key: "variance", format: true },
                                    { label: "Std. Deviation", key: "standardDeviation", format: true },
                                    { label: "Q1", key: "q1", format: true },
                                    { label: "Q3", key: "q3", format: true },
                                    { label: "IQR", key: "iqr", format: true }
                                ]

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 36
                                    color: index % 2 === 0 ? "#1D2330" : "#202735"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12

                                        Text {
                                            width: parent.width * 0.50
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: "white"
                                        }

                                        Text {
                                            width: parent.width * 0.50
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: {
                                                var value = appController.dataset1EdaResult[modelData.key]
                                                return modelData.format ? formatNumber(value) : value
                                            }
                                            horizontalAlignment: Text.AlignRight
                                            color: "#AAB2C0"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: appController.dataset2EdaAvailable ? "#4E8A68" : "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "Dataset 2 EDA Summary"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text { text: "Select Numeric Column"; color: "#AAB2C0" }

                        ComboBox {
                            id: dataset2EdaColumn
                            width: parent.width
                            height: 42
                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1
                            enabled: appController.dataset2Name.length > 0
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40
                                text: appController.dataset2EdaAvailable ? "Reanalyze EDA" : "Analyze EDA"
                                enabled: dataset2EdaColumn.currentIndex >= 0

                                onClicked: {
                                    var success = appController.analyzeDataset2Eda(
                                                dataset2EdaColumn.currentText)
                                    if (!success) {
                                        errorDialog.text = appController.lastError
                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40
                                text: "Clear"
                                enabled: appController.dataset2EdaAvailable
                                onClicked: appController.clearDataset2Eda()
                            }
                        }

                        Text {
                            width: parent.width
                            visible: !appController.dataset2EdaAvailable
                            text: appController.dataset2Name.length > 0
                                  ? "Choose a numeric column and run EDA."
                                  : "Load Dataset 2 first."
                            color: "#7F899A"
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 0
                            visible: appController.dataset2EdaAvailable

                            Rectangle {
                                width: parent.width
                                height: 42
                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Column: " + (appController.dataset2EdaResult["columnName"] || "-")
                                    color: "#D2B4FF"
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: [
                                    { label: "Count", key: "count", format: false },
                                    { label: "Mean", key: "mean", format: true },
                                    { label: "Median", key: "median", format: true },
                                    { label: "Minimum", key: "minimum", format: true },
                                    { label: "Maximum", key: "maximum", format: true },
                                    { label: "Range", key: "range", format: true },
                                    { label: "Variance", key: "variance", format: true },
                                    { label: "Std. Deviation", key: "standardDeviation", format: true },
                                    { label: "Q1", key: "q1", format: true },
                                    { label: "Q3", key: "q3", format: true },
                                    { label: "IQR", key: "iqr", format: true }
                                ]

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 36
                                    color: index % 2 === 0 ? "#1D2330" : "#202735"

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12

                                        Text {
                                            width: parent.width * 0.50
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: "white"
                                        }

                                        Text {
                                            width: parent.width * 0.50
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: {
                                                var value = appController.dataset2EdaResult[modelData.key]
                                                return modelData.format ? formatNumber(value) : value
                                            }
                                            horizontalAlignment: Text.AlignRight
                                            color: "#AAB2C0"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }

            // =================================================
            // CORRELATION ANALYSIS
            // =================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    text: "Correlation Analysis"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text:
                        "Calculate Pearson correlation between two numeric columns "
                        + "within the same working dataset."

                    color: "#AAB2C0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                width: parent.width - 60
                height: 470

                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12
                    color: "#1D2330"

                    border.color:
                        appController.dataset1CorrelationAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "Dataset 1 Correlation"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "First Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CorrelationColumnA

                            width: parent.width
                            height: 42

                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Text {
                            text: "Second Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CorrelationColumnB

                            width: parent.width
                            height: 42

                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40

                                text:
                                    appController.dataset1CorrelationAvailable
                                    ? "Recalculate"
                                    : "Calculate"

                                enabled:
                                    dataset1CorrelationColumnA.currentIndex >= 0
                                    &&
                                    dataset1CorrelationColumnB.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset1Correlation(
                                                dataset1CorrelationColumnA.currentText,
                                                dataset1CorrelationColumnB.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError
                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset1CorrelationAvailable

                                onClicked:
                                    appController.clearDataset1Correlation()
                            }
                        }

                        Text {
                            width: parent.width

                            visible:
                                !appController.dataset1CorrelationAvailable

                            text:
                                appController.dataset1Name.length > 0
                                ? "Choose two numeric columns and calculate Pearson correlation."
                                : "Load Dataset 1 first."

                            color: "#7F899A"
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            visible:
                                appController.dataset1CorrelationAvailable

                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: 6
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        (
                                            appController.dataset1CorrelationResult["firstColumnName"]
                                            || "-"
                                        )
                                        + "  ↔  "
                                        + (
                                            appController.dataset1CorrelationResult["secondColumnName"]
                                            || "-"
                                        )

                                    color: "#9CCBFF"
                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Paired Values: "
                                    + (
                                        appController.dataset1CorrelationResult["pairedValueCount"]
                                        || 0
                                    )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Pearson Correlation: "
                                    + formatNumber(
                                        appController.dataset1CorrelationResult["correlation"]
                                    )

                                color: "#9CCBFF"
                                font.pixelSize: 17
                                font.bold: true
                            }

                            Text {
                                width: parent.width

                                text:
                                    correlationLabel(
                                        appController.dataset1CorrelationResult["correlation"]
                                    )

                                color: "#FFE29A"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12
                    color: "#1D2330"

                    border.color:
                        appController.dataset2CorrelationAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Text {
                            text: "Dataset 2 Correlation"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "First Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CorrelationColumnA

                            width: parent.width
                            height: 42

                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Text {
                            text: "Second Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CorrelationColumnB

                            width: parent.width
                            height: 42

                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40

                                text:
                                    appController.dataset2CorrelationAvailable
                                    ? "Recalculate"
                                    : "Calculate"

                                enabled:
                                    dataset2CorrelationColumnA.currentIndex >= 0
                                    &&
                                    dataset2CorrelationColumnB.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset2Correlation(
                                                dataset2CorrelationColumnA.currentText,
                                                dataset2CorrelationColumnB.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError
                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width: (parent.width - 10) / 2
                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset2CorrelationAvailable

                                onClicked:
                                    appController.clearDataset2Correlation()
                            }
                        }

                        Text {
                            width: parent.width

                            visible:
                                !appController.dataset2CorrelationAvailable

                            text:
                                appController.dataset2Name.length > 0
                                ? "Choose two numeric columns and calculate Pearson correlation."
                                : "Load Dataset 2 first."

                            color: "#7F899A"
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            visible:
                                appController.dataset2CorrelationAvailable

                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: 6
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        (
                                            appController.dataset2CorrelationResult["firstColumnName"]
                                            || "-"
                                        )
                                        + "  ↔  "
                                        + (
                                            appController.dataset2CorrelationResult["secondColumnName"]
                                            || "-"
                                        )

                                    color: "#D2B4FF"
                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Paired Values: "
                                    + (
                                        appController.dataset2CorrelationResult["pairedValueCount"]
                                        || 0
                                    )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Pearson Correlation: "
                                    + formatNumber(
                                        appController.dataset2CorrelationResult["correlation"]
                                    )

                                color: "#D2B4FF"
                                font.pixelSize: 17
                                font.bold: true
                            }

                            Text {
                                width: parent.width

                                text:
                                    correlationLabel(
                                        appController.dataset2CorrelationResult["correlation"]
                                    )

                                color: "#FFE29A"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

            }

            // =================================================
            // OUTLIER ANALYSIS
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 6

                Text {
                    text: "Outlier Analysis"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text:
                        "Detect numeric outliers using the IQR method (multiplier: 1.5)."

                    color: "#AAB2C0"

                    font.pixelSize: 14
                }
            }

            Row {
                width: parent.width - 60
                height: 500

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 OUTLIER
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1OutlierAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Text {
                            text: "Dataset 1 Outliers"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "Select a numeric column"

                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1OutlierColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset1ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Row {
                            width: parent.width

                            spacing: 10

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Analyze Outliers"

                                enabled:
                                    dataset1OutlierColumn.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset1Outliers(
                                                dataset1OutlierColumn.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset1OutlierAvailable

                                onClicked:
                                    appController.clearDataset1Outliers()
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset1OutlierAvailable

                            text:
                                appController.dataset1Name.length > 0
                                ? "Choose a numeric column and run the analysis."
                                : "Load Dataset 1 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 7

                            visible:
                                appController.dataset1OutlierAvailable

                            Rectangle {
                                width: parent.width
                                height: 38

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Column: "
                                        + appController.dataset1OutlierResult["columnName"]

                                    color: "#9CCBFF"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Valid Values: "
                                    + appController.dataset1OutlierResult["validValueCount"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q1: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["q1"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q3: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["q3"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "IQR: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["iqr"]
                                      )

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Lower Bound: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["lowerBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Text {
                                text:
                                    "Upper Bound: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["upperBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Outlier Count: "
                                    + appController.dataset1OutlierResult["outlierCount"]

                                color:
                                    appController.dataset1OutlierResult["outlierCount"] > 0
                                    ? "#FFB4AB"
                                    : "#9FE3B5"

                                font.bold: true
                            }

                            Text {
                                text:
                                    "Outlier Percentage: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["outlierPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset1OutlierResult["outlierCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Outlier Values: "
                                    + formatList(
                                          appController.dataset1OutlierResult["outlierValues"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // =============================================
                // DATASET 2 OUTLIER
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2OutlierAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Text {
                            text: "Dataset 2 Outliers"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "Select a numeric column"

                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2OutlierColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset2ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Row {
                            width: parent.width

                            spacing: 10

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Analyze Outliers"

                                enabled:
                                    dataset2OutlierColumn.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset2Outliers(
                                                dataset2OutlierColumn.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset2OutlierAvailable

                                onClicked:
                                    appController.clearDataset2Outliers()
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset2OutlierAvailable

                            text:
                                appController.dataset2Name.length > 0
                                ? "Choose a numeric column and run the analysis."
                                : "Load Dataset 2 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 7

                            visible:
                                appController.dataset2OutlierAvailable

                            Rectangle {
                                width: parent.width
                                height: 38

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Column: "
                                        + appController.dataset2OutlierResult["columnName"]

                                    color: "#D2B4FF"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Valid Values: "
                                    + appController.dataset2OutlierResult["validValueCount"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q1: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["q1"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q3: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["q3"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "IQR: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["iqr"]
                                      )

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Lower Bound: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["lowerBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Text {
                                text:
                                    "Upper Bound: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["upperBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Outlier Count: "
                                    + appController.dataset2OutlierResult["outlierCount"]

                                color:
                                    appController.dataset2OutlierResult["outlierCount"] > 0
                                    ? "#FFB4AB"
                                    : "#9FE3B5"

                                font.bold: true
                            }

                            Text {
                                text:
                                    "Outlier Percentage: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["outlierPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset2OutlierResult["outlierCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Outlier Values: "
                                    + formatList(
                                          appController.dataset2OutlierResult["outlierValues"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // =================================================
            // COLUMN MATCHING
            // =================================================

            Row {
                width: parent.width - 60
                height: 45

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 10

                Text {
                    width: parent.width - 330

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text: "Column Matching Suggestions"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Button {
                    width: 160
                    height: 40

                    text: "Regenerate Matches"

                    enabled:
                        appController.dataset1Name.length > 0
                        &&
                        appController.dataset2Name.length > 0

                    onClicked:
                        appController.generateMappings()
                }

                Button {
                    width: 140
                    height: 40

                    text: "Clear"

                    enabled:
                        mappingList.count > 0

                    onClicked:
                        appController.clearMappings()
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 400

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 45

                        radius: 6
                        color: "#262E3D"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Text {
                                width: parent.width * 0.24

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1 Column"

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 40

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "→"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#8FA9C4"

                                font.pixelSize: 18
                            }

                            Text {
                                width: parent.width * 0.24

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2 Column"

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 130

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Similarity"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 85

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Accept"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 110

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Analysis"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }
                        }
                    }

                    ListView {
                        id: mappingList

                        width: parent.width
                        height: 310

                        clip: true

                        model:
                            appController.mappingModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 55

                            color:
                                index % 2 === 0
                                ? "#1D2330"
                                : "#202735"

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 15
                                anchors.rightMargin: 15

                                Text {
                                    width: parent.width * 0.24

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.sourceColumn

                                    color: "white"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: 40

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "→"

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    color: "#8FA9C4"

                                    font.pixelSize: 17
                                }

                                Text {
                                    width: parent.width * 0.24

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.targetColumn.length > 0
                                        ? model.targetColumn
                                        : "No match"

                                    color:
                                        model.targetColumn.length > 0
                                        ? "white"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 130
                                    height: 30

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    radius: 15

                                    color: {
                                        if (model.similarityScore >= 80)
                                            return "#234B3A"

                                        if (model.similarityScore >= 50)
                                            return "#514525"

                                        return "#512C32"
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            Number(
                                                model.similarityScore
                                            ).toFixed(1) + "%"

                                        color: "white"

                                        font.bold: true
                                    }
                                }

                                CheckBox {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    checked: model.accepted

                                    enabled:
                                        model.targetColumn.length > 0

                                    onToggled: {
                                        appController.mappingModel.setAccepted(
                                            index,
                                            checked
                                        )
                                    }
                                }

                                Button {
                                    width: 110
                                    height: 36

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Analyze"

                                    enabled:
                                        model.targetColumn.length > 0

                                    onClicked: {
                                        var success =
                                                appController.analyzeColumns(
                                                    model.sourceColumn,
                                                    model.targetColumn
                                                )

                                        if (!success) {
                                            errorDialog.text =
                                                    appController.lastError

                                            errorDialog.open()
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            visible:
                                mappingList.count === 0

                            text:
                                "No matching suggestions available."

                            color: "#7F899A"

                            font.pixelSize: 15
                        }
                    }
                }
            }

            // =================================================
            // COMPARISON ANALYSIS
            // =================================================

            Row {
                width: parent.width - 60
                height: 45

                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    width: parent.width - 140

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text: "Comparison Analysis"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Button {
                    width: 140
                    height: 40

                    text: "Clear Analysis"

                    enabled:
                        appController.analysisAvailable

                    onClicked:
                        appController.clearAnalysis()
                }
            }

            Rectangle {
                width: parent.width - 60

                height:
                    appController.analysisAvailable
                    ? 580
                    : 170

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent

                    spacing: 10

                    visible:
                        !appController.analysisAvailable

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text: "No analysis result"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text:
                            "Click Analyze on a numeric column mapping."

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20

                    spacing: 15

                    visible:
                        appController.analysisAvailable

                    Rectangle {
                        width: parent.width
                        height: 75

                        radius: 8
                        color: "#202735"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20

                            Text {
                                width: parent.width * 0.45

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text:
                                    appController.analysisAvailable
                                    ? appController.analysisResult["sourceColumn"]
                                    : ""

                                color: "#9CCBFF"

                                font.pixelSize: 17
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width * 0.10

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "↔"

                                color: "#AAB2C0"

                                font.pixelSize: 22
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter
                            }

                            Text {
                                width: parent.width * 0.45

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text:
                                    appController.analysisAvailable
                                    ? appController.analysisResult["targetColumn"]
                                    : ""

                                color: "#D2B4FF"

                                font.pixelSize: 17
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 45

                        radius: 6
                        color: "#262E3D"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Statistic"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#9CCBFF"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D2B4FF"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Difference"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"

                                font.bold: true
                            }
                        }
                    }

                    Column {
                        width: parent.width

                        spacing: 0

                        Repeater {
                            model: [
                                {
                                    label: "Count",
                                    sourceKey: "count",
                                    targetKey: "count",
                                    differenceKey: "",
                                    format: false
                                },
                                {
                                    label: "Mean",
                                    sourceKey: "mean",
                                    targetKey: "mean",
                                    differenceKey: "meanDifference",
                                    format: true
                                },
                                {
                                    label: "Median",
                                    sourceKey: "median",
                                    targetKey: "median",
                                    differenceKey: "medianDifference",
                                    format: true
                                },
                                {
                                    label: "Minimum",
                                    sourceKey: "minimum",
                                    targetKey: "minimum",
                                    differenceKey: "minimumDifference",
                                    format: true
                                },
                                {
                                    label: "Maximum",
                                    sourceKey: "maximum",
                                    targetKey: "maximum",
                                    differenceKey: "maximumDifference",
                                    format: true
                                },
                                {
                                    label: "Range",
                                    sourceKey: "range",
                                    targetKey: "range",
                                    differenceKey: "rangeDifference",
                                    format: true
                                },
                                {
                                    label: "Std. Deviation",
                                    sourceKey: "standardDeviation",
                                    targetKey: "standardDeviation",
                                    differenceKey: "standardDeviationDifference",
                                    format: true
                                },
                                {
                                    label: "Variance",
                                    sourceKey: "variance",
                                    targetKey: "variance",
                                    differenceKey: "varianceDifference",
                                    format: true
                                },
                                {
                                    label: "Q1",
                                    sourceKey: "q1",
                                    targetKey: "q1",
                                    differenceKey: "q1Difference",
                                    format: true
                                },
                                {
                                    label: "Q3",
                                    sourceKey: "q3",
                                    targetKey: "q3",
                                    differenceKey: "q3Difference",
                                    format: true
                                },
                                {
                                    label: "IQR",
                                    sourceKey: "iqr",
                                    targetKey: "iqr",
                                    differenceKey: "iqrDifference",
                                    format: true
                                }
                            ]

                            delegate: Rectangle {
                                width: parent.width
                                height: 36

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: modelData.label

                                        color: "white"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            var value =
                                                    appController.analysisResult[
                                                        "sourceStatistics"
                                                    ][modelData.sourceKey]

                                            return modelData.format
                                                    ? formatNumber(value)
                                                    : value
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#AAB2C0"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            var value =
                                                    appController.analysisResult[
                                                        "targetStatistics"
                                                    ][modelData.targetKey]

                                            return modelData.format
                                                    ? formatNumber(value)
                                                    : value
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#AAB2C0"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            if (modelData.differenceKey.length === 0)
                                                return "-"

                                            return formatDifference(
                                                appController.analysisResult[
                                                    modelData.differenceKey
                                                ]
                                            )
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color:
                                            modelData.differenceKey.length > 0
                                            ? "#FFE29A"
                                            : "#7F899A"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // VISUALIZATION
            // =================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    text: "Visualization"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text:
                        "Create visualizations from the current working datasets. "
                        + "Histogram, Box Plot, Time Series, Distribution, "
                        + "Correlation Matrix and Dataset Comparison are available."
                    color: "#AAB2C0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                width: parent.width - 60
                height: 790
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                // =============================================
                // DATASET 1 VISUALIZATION
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 9

                        Text {
                            text: "Dataset 1 Visualization"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text { text: "Chart Type"; color: "#AAB2C0" }

                        ComboBox {
                            id: dataset1VisualizationType
                            width: parent.width
                            height: 40
                            model: [
                                "Histogram",
                                "Box Plot",
                                "Time Series",
                                "Distribution",
                                "Correlation Matrix"
                            ]
                            currentIndex: 0
                        }

                        Text {
                            visible:
                                dataset1VisualizationType.currentText !== "Time Series"
                                && dataset1VisualizationType.currentText !== "Correlation Matrix"
                            text: "Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1VisualizationColumn
                            width: parent.width
                            height: 40
                            visible:
                                dataset1VisualizationType.currentText !== "Time Series"
                                && dataset1VisualizationType.currentText !== "Correlation Matrix"
                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Text {
                            visible: dataset1VisualizationType.currentText === "Time Series"
                            text: "X / Time Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1TimeXColumn
                            width: parent.width
                            height: 40
                            visible: dataset1VisualizationType.currentText === "Time Series"
                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Text {
                            visible: dataset1VisualizationType.currentText === "Time Series"
                            text: "Y / Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1TimeYColumn
                            width: parent.width
                            height: 40
                            visible: dataset1VisualizationType.currentText === "Time Series"
                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Button {
                            width: parent.width
                            height: 42
                            text: "Generate Visualization"

                            enabled: {
                                if (appController.dataset1Name.length === 0)
                                    return false

                                if (dataset1VisualizationType.currentText === "Correlation Matrix")
                                    return true

                                if (dataset1VisualizationType.currentText === "Time Series")
                                    return dataset1TimeXColumn.currentIndex >= 0
                                            && dataset1TimeYColumn.currentIndex >= 0

                                return dataset1VisualizationColumn.currentIndex >= 0
                            }

                            onClicked: {
                                var type = dataset1VisualizationType.currentText
                                var result = ({})

                                if (type === "Histogram")
                                    result = appController.createDataset1Histogram(
                                                dataset1VisualizationColumn.currentText, 10)
                                else if (type === "Box Plot")
                                    result = appController.createDataset1BoxPlot(
                                                dataset1VisualizationColumn.currentText, 1.5)
                                else if (type === "Time Series")
                                    result = appController.createDataset1TimeSeries(
                                                dataset1TimeXColumn.currentText,
                                                dataset1TimeYColumn.currentText)
                                else if (type === "Distribution")
                                    result = appController.createDataset1Distribution(
                                                dataset1VisualizationColumn.currentText, 10)
                                else if (type === "Correlation Matrix")
                                    result = appController.createDataset1CorrelationMatrix()

                                if (!result["success"]) {
                                    errorDialog.text =
                                            result["errorMessage"] || appController.lastError
                                    errorDialog.open()
                                    return
                                }

                                dataset1VisualizationResult = result

                                if (type !== "Correlation Matrix")
                                    dataset1VisualizationCanvas.requestPaint()
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 430
                            radius: 8
                            color: "#171B24"
                            border.color: "#30394A"
                            border.width: 1

                            Canvas {
                                id: dataset1VisualizationCanvas
                                anchors.fill: parent
                                anchors.margins: 10

                                visible:
                                    dataset1VisualizationResult["success"]
                                    && dataset1VisualizationType.currentText !== "Correlation Matrix"

                                onPaint: {
                                    drawVisualization(
                                                dataset1VisualizationCanvas,
                                                getContext("2d"),
                                                dataset1VisualizationType.currentText,
                                                dataset1VisualizationResult)
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                visible:
                                    dataset1VisualizationResult["success"]
                                    && dataset1VisualizationType.currentText === "Correlation Matrix"

                                Text {
                                    text: "Correlation Matrix"
                                    color: "#9CCBFF"
                                    font.bold: true
                                }

                                Row {
                                    spacing: 4

                                    Repeater {
                                        model:
                                            dataset1VisualizationResult["columnNames"] || []

                                        delegate: Rectangle {
                                            width: 76
                                            height: 34
                                            color: "#262E3D"

                                            Text {
                                                anchors.centerIn: parent
                                                width: parent.width - 6
                                                text: modelData
                                                color: "#D7DCE5"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    columns:
                                        Number(dataset1VisualizationResult["columnCount"] || 1)

                                    spacing: 4

                                    Repeater {
                                        model:
                                            (dataset1VisualizationResult["values"] || []).length

                                        delegate: Rectangle {
                                            width: 76
                                            height: 54

                                            color:
                                                correlationCellColor(
                                                    dataset1VisualizationResult["values"][index]
                                                )

                                            Text {
                                                anchors.centerIn: parent
                                                text:
                                                    formatNumber(
                                                        dataset1VisualizationResult["values"][index]
                                                    )
                                                color: "white"
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !dataset1VisualizationResult["success"]
                                text: "Generate a chart to preview it here."
                                color: "#7F899A"
                            }
                        }

                        Text {
                            width: parent.width
                            visible: dataset1VisualizationResult["success"]

                            text: {
                                var type = dataset1VisualizationType.currentText

                                if (type === "Histogram")
                                    return "Valid values: "
                                            + dataset1VisualizationResult["validValueCount"]
                                            + " | Bins: "
                                            + dataset1VisualizationResult["binCount"]

                                if (type === "Box Plot")
                                    return "Median: "
                                            + formatNumber(dataset1VisualizationResult["median"])
                                            + " | Outliers: "
                                            + dataset1VisualizationResult["outlierCount"]

                                if (type === "Time Series")
                                    return "Points: "
                                            + dataset1VisualizationResult["pointCount"]

                                if (type === "Distribution")
                                    return "Valid values: "
                                            + dataset1VisualizationResult["validValueCount"]

                                return "Numeric columns: "
                                        + dataset1VisualizationResult["columnCount"]
                            }

                            color: "#AAB2C0"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // =============================================
                // DATASET 2 VISUALIZATION
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 9

                        Text {
                            text: "Dataset 2 Visualization"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text { text: "Chart Type"; color: "#AAB2C0" }

                        ComboBox {
                            id: dataset2VisualizationType
                            width: parent.width
                            height: 40
                            model: [
                                "Histogram",
                                "Box Plot",
                                "Time Series",
                                "Distribution",
                                "Correlation Matrix"
                            ]
                            currentIndex: 0
                        }

                        Text {
                            visible:
                                dataset2VisualizationType.currentText !== "Time Series"
                                && dataset2VisualizationType.currentText !== "Correlation Matrix"
                            text: "Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2VisualizationColumn
                            width: parent.width
                            height: 40
                            visible:
                                dataset2VisualizationType.currentText !== "Time Series"
                                && dataset2VisualizationType.currentText !== "Correlation Matrix"
                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Text {
                            visible: dataset2VisualizationType.currentText === "Time Series"
                            text: "X / Time Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2TimeXColumn
                            width: parent.width
                            height: 40
                            visible: dataset2VisualizationType.currentText === "Time Series"
                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Text {
                            visible: dataset2VisualizationType.currentText === "Time Series"
                            text: "Y / Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2TimeYColumn
                            width: parent.width
                            height: 40
                            visible: dataset2VisualizationType.currentText === "Time Series"
                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1
                        }

                        Button {
                            width: parent.width
                            height: 42
                            text: "Generate Visualization"

                            enabled: {
                                if (appController.dataset2Name.length === 0)
                                    return false

                                if (dataset2VisualizationType.currentText === "Correlation Matrix")
                                    return true

                                if (dataset2VisualizationType.currentText === "Time Series")
                                    return dataset2TimeXColumn.currentIndex >= 0
                                            && dataset2TimeYColumn.currentIndex >= 0

                                return dataset2VisualizationColumn.currentIndex >= 0
                            }

                            onClicked: {
                                var type = dataset2VisualizationType.currentText
                                var result = ({})

                                if (type === "Histogram")
                                    result = appController.createDataset2Histogram(
                                                dataset2VisualizationColumn.currentText, 10)
                                else if (type === "Box Plot")
                                    result = appController.createDataset2BoxPlot(
                                                dataset2VisualizationColumn.currentText, 1.5)
                                else if (type === "Time Series")
                                    result = appController.createDataset2TimeSeries(
                                                dataset2TimeXColumn.currentText,
                                                dataset2TimeYColumn.currentText)
                                else if (type === "Distribution")
                                    result = appController.createDataset2Distribution(
                                                dataset2VisualizationColumn.currentText, 10)
                                else if (type === "Correlation Matrix")
                                    result = appController.createDataset2CorrelationMatrix()

                                if (!result["success"]) {
                                    errorDialog.text =
                                            result["errorMessage"] || appController.lastError
                                    errorDialog.open()
                                    return
                                }

                                dataset2VisualizationResult = result

                                if (type !== "Correlation Matrix")
                                    dataset2VisualizationCanvas.requestPaint()
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 430
                            radius: 8
                            color: "#171B24"
                            border.color: "#30394A"
                            border.width: 1

                            Canvas {
                                id: dataset2VisualizationCanvas
                                anchors.fill: parent
                                anchors.margins: 10

                                visible:
                                    dataset2VisualizationResult["success"]
                                    && dataset2VisualizationType.currentText !== "Correlation Matrix"

                                onPaint: {
                                    drawVisualization(
                                                dataset2VisualizationCanvas,
                                                getContext("2d"),
                                                dataset2VisualizationType.currentText,
                                                dataset2VisualizationResult)
                                }
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                visible:
                                    dataset2VisualizationResult["success"]
                                    && dataset2VisualizationType.currentText === "Correlation Matrix"

                                Text {
                                    text: "Correlation Matrix"
                                    color: "#D2B4FF"
                                    font.bold: true
                                }

                                Row {
                                    spacing: 4

                                    Repeater {
                                        model:
                                            dataset2VisualizationResult["columnNames"] || []

                                        delegate: Rectangle {
                                            width: 76
                                            height: 34
                                            color: "#262E3D"

                                            Text {
                                                anchors.centerIn: parent
                                                width: parent.width - 6
                                                text: modelData
                                                color: "#D7DCE5"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    columns:
                                        Number(dataset2VisualizationResult["columnCount"] || 1)

                                    spacing: 4

                                    Repeater {
                                        model:
                                            (dataset2VisualizationResult["values"] || []).length

                                        delegate: Rectangle {
                                            width: 76
                                            height: 54

                                            color:
                                                correlationCellColor(
                                                    dataset2VisualizationResult["values"][index]
                                                )

                                            Text {
                                                anchors.centerIn: parent
                                                text:
                                                    formatNumber(
                                                        dataset2VisualizationResult["values"][index]
                                                    )
                                                color: "white"
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !dataset2VisualizationResult["success"]
                                text: "Generate a chart to preview it here."
                                color: "#7F899A"
                            }
                        }

                        Text {
                            width: parent.width
                            visible: dataset2VisualizationResult["success"]

                            text: {
                                var type = dataset2VisualizationType.currentText

                                if (type === "Histogram")
                                    return "Valid values: "
                                            + dataset2VisualizationResult["validValueCount"]
                                            + " | Bins: "
                                            + dataset2VisualizationResult["binCount"]

                                if (type === "Box Plot")
                                    return "Median: "
                                            + formatNumber(dataset2VisualizationResult["median"])
                                            + " | Outliers: "
                                            + dataset2VisualizationResult["outlierCount"]

                                if (type === "Time Series")
                                    return "Points: "
                                            + dataset2VisualizationResult["pointCount"]

                                if (type === "Distribution")
                                    return "Valid values: "
                                            + dataset2VisualizationResult["validValueCount"]

                                return "Numeric columns: "
                                        + dataset2VisualizationResult["columnCount"]
                            }

                            color: "#AAB2C0"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // =================================================
            // DATASET COMPARISON CHART
            // =================================================

            Rectangle {
                width: parent.width - 60
                height: 590
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 12
                color: "#1D2330"
                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: "Dataset Comparison Chart"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 6

                            Text {
                                text: "Dataset 1 Numeric Column"
                                color: "#9CCBFF"
                            }

                            ComboBox {
                                id: comparisonVisualizationSourceColumn
                                width: parent.width
                                height: 40
                                model: appController.dataset1ColumnModel
                                textRole: "name"
                                currentIndex: -1
                            }
                        }

                        Column {
                            width: (parent.width - 12) / 2
                            spacing: 6

                            Text {
                                text: "Dataset 2 Numeric Column"
                                color: "#D2B4FF"
                            }

                            ComboBox {
                                id: comparisonVisualizationTargetColumn
                                width: parent.width
                                height: 40
                                model: appController.dataset2ColumnModel
                                textRole: "name"
                                currentIndex: -1
                            }
                        }
                    }

                    Button {
                        width: 220
                        height: 42
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Generate Comparison Chart"

                        enabled:
                            comparisonVisualizationSourceColumn.currentIndex >= 0
                            && comparisonVisualizationTargetColumn.currentIndex >= 0

                        onClicked: {
                            var result =
                                    appController.createDatasetComparisonChart(
                                        comparisonVisualizationSourceColumn.currentText,
                                        comparisonVisualizationTargetColumn.currentText
                                    )

                            if (!result["success"]) {
                                errorDialog.text =
                                    result["errorMessage"] || appController.lastError
                                errorDialog.open()
                                return
                            }

                            comparisonVisualizationResult = result
                            comparisonVisualizationCanvas.requestPaint()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 390
                        radius: 8
                        color: "#171B24"
                        border.color: "#30394A"
                        border.width: 1

                        Canvas {
                            id: comparisonVisualizationCanvas
                            anchors.fill: parent
                            anchors.margins: 10
                            visible: comparisonVisualizationResult["success"]

                            onPaint: {
                                drawLineChart(
                                            comparisonVisualizationCanvas,
                                            getContext("2d"),
                                            comparisonVisualizationResult["indexes"] || [],
                                            comparisonVisualizationResult["sourceValues"] || [],
                                            comparisonVisualizationResult["targetValues"] || [])
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !comparisonVisualizationResult["success"]
                            text: "Select two numeric columns and generate the comparison chart."
                            color: "#7F899A"
                        }
                    }

                    Row {
                        spacing: 25
                        visible: comparisonVisualizationResult["success"]

                        Text {
                            text:
                                "Dataset 1: "
                                + (comparisonVisualizationResult["sourceColumnName"] || "-")
                            color: "#9CCBFF"
                            font.bold: true
                        }

                        Text {
                            text:
                                "Dataset 2: "
                                + (comparisonVisualizationResult["targetColumnName"] || "-")
                            color: "#D2B4FF"
                            font.bold: true
                        }

                        Text {
                            text:
                                "Paired Points: "
                                + (comparisonVisualizationResult["pointCount"] || 0)
                            color: "#AAB2C0"
                        }
                    }
                }
            }

            // =================================================
            // EXPORT
            // =================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 7

                Text {
                    text: "Export"
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text:
                        "Export the current working dataset. "
                        + "Cleaning changes are included, while the original dataset remains unchanged."
                    color: "#AAB2C0"
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                width: parent.width - 60
                height: 250
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: appController.dataset1Modified ? "#C792EA" : "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 36
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Dataset 1 Export"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:
                                appController.dataset1Name.length > 0
                                ? (
                                      appController.dataset1Modified
                                      ? "Working / cleaned dataset will be exported."
                                      : "Current working dataset will be exported."
                                  )
                                : "Load Dataset 1 first."
                            color:
                                appController.dataset1Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Button {
                                width: 130
                                height: 42
                                text: "Export CSV"
                                enabled: appController.dataset1Name.length > 0
                                onClicked: dataset1CsvExportDialog.open()
                            }

                            Button {
                                width: 130
                                height: 42
                                text: "Export JSON"
                                enabled: appController.dataset1Name.length > 0
                                onClicked: dataset1JsonExportDialog.open()
                            }

                            Button {
                                width: 130
                                height: 42
                                text: "Export Excel"
                                enabled: appController.dataset1Name.length > 0
                                onClicked: dataset1XlsxExportDialog.open()
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: appController.dataset1Name.length > 0
                            text:
                                "Rows: "
                                + appController.dataset1RowCount
                                + " | Columns: "
                                + appController.dataset1ColumnCount
                            color: "#7F899A"
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height
                    radius: 12
                    color: "#1D2330"
                    border.color: appController.dataset2Modified ? "#C792EA" : "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 36
                        spacing: 12

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Dataset 2 Export"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text:
                                appController.dataset2Name.length > 0
                                ? (
                                      appController.dataset2Modified
                                      ? "Working / cleaned dataset will be exported."
                                      : "Current working dataset will be exported."
                                  )
                                : "Load Dataset 2 first."
                            color:
                                appController.dataset2Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Button {
                                width: 130
                                height: 42
                                text: "Export CSV"
                                enabled: appController.dataset2Name.length > 0
                                onClicked: dataset2CsvExportDialog.open()
                            }

                            Button {
                                width: 130
                                height: 42
                                text: "Export JSON"
                                enabled: appController.dataset2Name.length > 0
                                onClicked: dataset2JsonExportDialog.open()
                            }

                            Button {
                                width: 130
                                height: 42
                                text: "Export Excel"
                                enabled: appController.dataset2Name.length > 0
                                onClicked: dataset2XlsxExportDialog.open()
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: appController.dataset2Name.length > 0
                            text:
                                "Rows: "
                                + appController.dataset2RowCount
                                + " | Columns: "
                                + appController.dataset2ColumnCount
                            color: "#7F899A"
                        }
                    }
                }
            }

            // =================================================
            // RAW DATA PARSING
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Raw Data Parsing"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text:
                        "Load parameter metadata and raw binary data, then decode the packet."

                    color: "#AAB2C0"

                    font.pixelSize: 14
                }
            }

            Row {
                width: parent.width - 60
                height: 200

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.rawMetadataLoaded
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Parameter Metadata"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.rawMetadataLoaded
                                ? "Metadata loaded successfully"
                                : "No metadata selected"

                            color:
                                appController.rawMetadataLoaded
                                ? "#9FE3B5"
                                : "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.rawMetadataLoaded

                            text:
                                appController.rawParameterDefinitionCount
                                + " parameter definitions"

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 190
                            height: 42

                            text:
                                appController.rawMetadataLoaded
                                ? "Change Metadata"
                                : "Select Metadata"

                            onClicked:
                                rawMetadataDialog.open()
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.rawDataLoaded
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Raw Data"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.rawDataLoaded
                                ? "Raw data loaded successfully"
                                : "No raw data selected"

                            color:
                                appController.rawDataLoaded
                                ? "#9FE3B5"
                                : "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.rawDataLoaded

                            text:
                                appController.rawDataByteCount
                                + " bytes"

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 190
                            height: 42

                            text:
                                appController.rawDataLoaded
                                ? "Change Raw Data"
                                : "Select Raw Data"

                            onClicked:
                                rawDataDialog.open()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 90

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Row {
                    anchors.centerIn: parent

                    spacing: 15

                    Button {
                        width: 190
                        height: 42

                        text: "Parse Raw Data"

                        enabled:
                            appController.rawMetadataLoaded
                            &&
                            appController.rawDataLoaded

                        onClicked: {
                            var success =
                                    appController.parseRawData()

                            if (!success) {
                                errorDialog.text =
                                        appController.lastError

                                errorDialog.open()
                            }
                        }
                    }

                    Button {
                        width: 150
                        height: 42

                        text: "Clear Results"

                        enabled:
                            appController.rawParseAvailable

                        onClicked:
                            appController.clearRawParse()
                    }

                    Text {
                        anchors.verticalCenter:
                            parent.verticalCenter

                        text:
                            appController.rawParseAvailable
                            ? "Parse completed"
                            : "Waiting for raw data"

                        color:
                            appController.rawParseAvailable
                            ? "#9FE3B5"
                            : "#AAB2C0"

                        font.bold: true
                    }
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 430

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 10

                    Text {
                        text: "Parsed Parameters"

                        color: "white"

                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 42

                        radius: 6

                        color: "#262E3D"

                        Row {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Parameter"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.20

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Value"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.15

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Type"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.15

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Unit"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Status"

                                color: "#D7DCE5"

                                font.bold: true
                            }
                        }
                    }

                    ListView {
                        id: parsedParameterList

                        width: parent.width
                        height: 330

                        clip: true

                        model:
                            appController.parameterModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 50

                            color:
                                index % 2 === 0
                                ? "#1D2330"
                                : "#202735"

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    width: parent.width * 0.25

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.dataName

                                    color: "white"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.20

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.displayValue

                                    color:
                                        model.valid
                                        ? "#9CCBFF"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.15

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.dataType

                                    color: "#AAB2C0"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.15

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.unit.length > 0
                                        ? model.unit
                                        : "-"

                                    color: "#AAB2C0"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.25

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.valid
                                        ? model.status
                                        : model.errorMessage

                                    color:
                                        model.valid
                                        ? "#9FE3B5"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            visible:
                                parsedParameterList.count === 0

                            text:
                                "Load metadata and raw data, then click Parse Raw Data."

                            color: "#7F899A"

                            font.pixelSize: 14
                        }
                    }
                }
            }

            // =================================================
            // RAW WARNINGS
            // =================================================

            Rectangle {
                width: parent.width - 60

                height:
                    appController.rawWarnings.length > 0
                    ? 110
                    : 0

                visible:
                    appController.rawWarnings.length > 0

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#332D1E"

                border.color: "#6E6035"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 8

                    Text {
                        text: "Metadata Warnings"

                        color: "#FFE29A"

                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text:
                            appController.rawWarnings.join("\n")

                        color: "#D7C98F"

                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item {
                width: 1
                height: 30
            }
        }
    }
}