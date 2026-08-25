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

    property int activeDataset: 1
    property string chartType: "histogram" // histogram, boxplot, timeseries, distribution, correlation, comparison
    property bool isDualMode: false

    property string selectedCol1: ""
    property string selectedCol2: ""
    property int binCount: 10
    property double boxPlotMultiplier: 1.5

    property var chartData1: ({})
    property var chartData2: ({})

    property string exportFormat: "xlsx"
    property string saveStatusMessage: ""
    property bool saveSuccess: true

    function isLoaded(ds) {
        if (!appController) return false
        return ds === 1 ? (appController.dataset1Name !== "") : (appController.dataset2Name !== "")
    }

    function name(ds) {
        if (!appController) return "Dataset " + ds
        var n = ds === 1 ? appController.dataset1Name : appController.dataset2Name
        return n && n !== "" ? n : "Dataset " + ds
    }

    function columnModel(ds) {
        if (!appController) return null
        return ds === 1 ? appController.dataset1ColumnModel : appController.dataset2ColumnModel
    }

    function generateChart() {
        if (!appController) return

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
        else if (page.chartType === "timeseries") {
            if (page.isDualMode) {
                page.chartData1 = appController.createDataset1TimeSeries(page.selectedCol1, page.selectedCol2)
                page.chartData2 = appController.createDataset2TimeSeries(page.selectedCol1, page.selectedCol2)
            } else {
                if (page.activeDataset === 1)
                    page.chartData1 = appController.createDataset1TimeSeries(page.selectedCol1, page.selectedCol2)
                else
                    page.chartData1 = appController.createDataset2TimeSeries(page.selectedCol1, page.selectedCol2)
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
            page.chartData1 = appController.createDatasetComparisonChart(page.selectedCol1, page.selectedCol2)
        }

        chartCanvas1.requestPaint()
        if (chartCanvas2) chartCanvas2.requestPaint()
    }

    function saveChart(canvasObj, prefix) {
        if (!appController || !canvasObj) return
        var dataUrl = canvasObj.toDataURL("image/png")
        var path = appController.saveChartImage(dataUrl, prefix)
        if (path && path !== "") {
            page.saveSuccess = true
            page.saveStatusMessage = "✓ Grafik başarıyla kaydedildi: " + path
        } else {
            page.saveSuccess = false
            page.saveStatusMessage = "✕ Grafik kaydedilemedi: " + (appController.lastError || "Hata")
        }
        statusTimer.restart()
    }

    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: page.saveStatusMessage = ""
    }

    // Export Dialog
    FileDialog {
        id: exportDialog
        title: "Temizlenmiş Veri Setini Dışa Aktar"
        selectExisting: false
        folder: appController && appController.dataDirectory !== "" ? ("file:///" + String(appController.dataDirectory).replace(/\\/g, "/")) : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"
        nameFilters: page.exportFormat === "xlsx" ? ["Excel Dosyası (*.xlsx)"] :
                     page.exportFormat === "csv" ? ["CSV Dosyası (*.csv)"] : ["JSON Dosyası (*.json)"]
        onAccepted: {
            var path = String(fileUrl).replace("file:///", "")
            var ok = false
            if (page.exportFormat === "xlsx") {
                ok = page.activeDataset === 1 ? appController.exportDataset1ToXlsx(path) : appController.exportDataset2ToXlsx(path)
            } else if (page.exportFormat === "csv") {
                ok = page.activeDataset === 1 ? appController.exportDataset1ToCsv(path) : appController.exportDataset2ToCsv(path)
            } else if (page.exportFormat === "json") {
                ok = page.activeDataset === 1 ? appController.exportDataset1ToJson(path) : appController.exportDataset2ToJson(path)
            }

            if (ok) {
                page.saveSuccess = true
                page.saveStatusMessage = "✓ Dataset " + page.activeDataset + " başarıyla dışa aktarıldı: " + path
            } else {
                page.saveSuccess = false
                page.saveStatusMessage = "✕ Dışa aktarma hatası: " + (appController.lastError || "Hata")
            }
            statusTimer.restart()
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
                                Layout.preferredWidth: 120
                                text: "📊 Tekli Grafik"
                                highlighted: !page.isDualMode
                                onClicked: {
                                    page.isDualMode = false
                                    chartCanvas1.requestPaint()
                                }
                            }
                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 160
                                text: "⇆ Yan Yana Çift Grafik"
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
                            visible: !page.isDualMode
                            spacing: 6
                            Label { text: "• Veri Seti:"; color: theme.text; font.pixelSize: 12; font.bold: true }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 110
                                text: "Dataset 1"
                                enabled: page.isLoaded(1)
                                highlighted: page.activeDataset === 1
                                onClicked: {
                                    page.activeDataset = 1
                                    page.chartData1 = ({})
                                    chartCanvas1.requestPaint()
                                }
                            }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 110
                                text: "Dataset 2"
                                enabled: page.isLoaded(2)
                                highlighted: page.activeDataset === 2
                                onClicked: {
                                    page.activeDataset = 2
                                    page.chartData1 = ({})
                                    chartCanvas1.requestPaint()
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 8
                            Label { text: "Temizlenmiş Veriyi Aktar:"; color: theme.textSecondary; font.pixelSize: 12 }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 115
                                text: "📥 Excel (.xlsx)"
                                enabled: page.isLoaded(page.activeDataset)
                                onClicked: {
                                    page.exportFormat = "xlsx"
                                    exportDialog.open()
                                }
                            }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 105
                                text: "📥 CSV (.csv)"
                                enabled: page.isLoaded(page.activeDataset)
                                onClicked: {
                                    page.exportFormat = "csv"
                                    exportDialog.open()
                                }
                            }

                            Button {
                                Layout.preferredHeight: 34
                                Layout.preferredWidth: 105
                                text: "📥 JSON (.json)"
                                enabled: page.isLoaded(page.activeDataset)
                                onClicked: {
                                    page.exportFormat = "json"
                                    exportDialog.open()
                                }
                            }
                        }
                    }

                    // Row 2: Selectors & Draw Button
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Label { text: "Grafik Türü"; color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                id: typeCombo
                                Layout.preferredWidth: 200
                                Layout.preferredHeight: 36
                                model: ["Histogram (Frekans)", "Kutu Grafiği (Box Plot)", "Çizgi Grafiği (Line)", "Dağılım (Distribution)", "Korelasyon Matrisi (Heatmap)", "İki Veri Seti Karşılaştırma"]
                                onActivated: {
                                    switch (currentIndex) {
                                    case 0: page.chartType = "histogram"; break;
                                    case 1: page.chartType = "boxplot"; break;
                                    case 2: page.chartType = "timeseries"; break;
                                    case 3: page.chartType = "distribution"; break;
                                    case 4: page.chartType = "correlation"; break;
                                    case 5: page.chartType = "comparison"; break;
                                    }
                                    page.chartData1 = ({})
                                    page.chartData2 = ({})
                                    chartCanvas1.requestPaint()
                                    if (chartCanvas2) chartCanvas2.requestPaint()
                                }
                            }
                        }

                        // Column 1
                        ColumnLayout {
                            visible: page.chartType !== "correlation"
                            spacing: 2
                            Label {
                                text: page.isDualMode ? "Dataset 1 Sütunu" : (page.chartType === "timeseries" ? "X Ekseni Sütunu" : (page.chartType === "comparison" ? "Dataset 1 Sütunu" : "Analiz Sütunu"))
                                color: page.isDualMode ? "#FF4081" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: col1Combo
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 36
                                model: page.isDualMode ? page.columnModel(1) : (page.chartType === "comparison" ? page.columnModel(1) : page.columnModel(page.activeDataset))
                                textRole: "name"
                                onActivated: page.selectedCol1 = currentText
                                Component.onCompleted: {
                                    if (count > 0) page.selectedCol1 = textAt(0)
                                }
                            }
                        }

                        // Column 2
                        ColumnLayout {
                            visible: (page.isDualMode || page.chartType === "timeseries" || page.chartType === "comparison") && page.chartType !== "correlation"
                            spacing: 2
                            Label {
                                text: page.isDualMode ? "Dataset 2 Sütunu" : (page.chartType === "comparison" ? "Dataset 2 Sütunu" : "Y Ekseni Sütunu")
                                color: page.isDualMode ? "#7C4DFF" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: col2Combo
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 36
                                model: page.isDualMode ? page.columnModel(2) : (page.chartType === "comparison" ? page.columnModel(2) : page.columnModel(page.activeDataset))
                                textRole: "name"
                                onActivated: page.selectedCol2 = currentText
                                Component.onCompleted: {
                                    if (count > 0) page.selectedCol2 = textAt(0)
                                }
                            }
                        }

                        // Parameters
                        ColumnLayout {
                            visible: page.chartType === "histogram" || page.chartType === "distribution"
                            spacing: 2
                            Label { text: "Grup (Bin) Sayısı"; color: theme.textSecondary; font.pixelSize: 11 }
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
                            Label { text: "IQR Çarpanı"; color: theme.textSecondary; font.pixelSize: 11 }
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
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 38
                            text: "📊 Grafiği Çiz"
                            onClicked: page.generateChart()
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

                // Panel 1 (Dataset 1 or Active Dataset)
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
                                text: page.isDualMode ? "Dataset 1: " + page.name(1) : (page.name(page.activeDataset) + " Grafiği")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 30
                                text: "💾 Grafiği Kaydet"
                                onClicked: page.saveChart(chartCanvas1, page.chartType + "_D1")
                            }
                        }

                        Canvas {
                            id: chartCanvas1
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                if (!page.chartData1 || !page.chartData1.success) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "13px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Grafik görüntülemek için yukarıdan parametre seçip 'Grafiği Çiz' butonuna tıklayın.", width / 2, height / 2)
                                    return
                                }

                                var padL = 55, padR = 25, padT = 30, padB = 45
                                var plotW = width - padL - padR
                                var plotH = height - padT - padB

                                if (page.chartType === "correlation" && page.chartData1.columnNames) {
                                    // Correlation Heatmap
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

                                            // Color map: -1.0 (#2979FF) -> 0.0 (#374151) -> +1.0 (#FF4081)
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
                                        // Row label
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "9px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(cols[r], startX - 6, startY + r * cellH + cellH / 2 + 3)
                                    }
                                    return
                                }

                                // Eksenler
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
                                        var bH = (freqs[j] / maxF) * (plotH - 20)
                                        var bX = padL + j * bW + 4
                                        var bY = height - padB - bH

                                        var grad = ctx.createLinearGradient(bX, bY, bX, height - padB)
                                        grad.addColorStop(0, "#FF4081")
                                        grad.addColorStop(1, "#FF80AB")
                                        ctx.fillStyle = grad
                                        ctx.fillRect(bX, bY, bW - 8, bH)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "bold 11px sans-serif"
                                        ctx.textAlign = "center"
                                        if (freqs[j] > 0) ctx.fillText(String(freqs[j]), bX + (bW - 8) / 2, bY - 6)

                                        if (low.length > j) {
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.fillText(Number(low[j]).toFixed(1), bX + (bW - 8) / 2, height - padB + 15)
                                        }
                                    }
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
                                    ctx.fillText("Medyan: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY(min))
                                }
                                else if ((page.chartType === "timeseries" || page.chartType === "distribution" || page.chartType === "comparison") && page.chartData1.pointCount > 0) {
                                    var pts = page.chartData1.pointCount
                                    var xVals = page.chartData1.xValues || page.chartData1.indexes || []
                                    var yVals = page.chartData1.yValues || page.chartData1.sourceValues || []
                                    var minY = 0, maxY = 1
                                    for (var p = 0; p < yVals.length; ++p) {
                                        if (yVals[p] < minY) minY = yVals[p]
                                        if (yVals[p] > maxY) maxY = yVals[p]
                                    }
                                    var rngY = (maxY - minY) === 0 ? 1 : (maxY - minY)

                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    for (var k = 0; k < pts; ++k) {
                                        var xP = padL + (k / Math.max(1, pts - 1)) * plotW
                                        var yP = (height - padB) - ((yVals[k] - minY) / rngY) * (plotH - 20)
                                        if (k === 0) ctx.moveTo(xP, yP); else ctx.lineTo(xP, yP)
                                    }
                                    ctx.stroke()
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
                                text: "Dataset 2: " + page.name(2)
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 30
                                text: "💾 Grafiği Kaydet"
                                onClicked: page.saveChart(chartCanvas2, page.chartType + "_D2")
                            }
                        }

                        Canvas {
                            id: chartCanvas2
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                if (!page.chartData2 || !page.chartData2.success) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Dataset 2 grafiği için 'Grafiği Çiz' butonuna tıklayın.", width / 2, height / 2)
                                    return
                                }

                                var padL = 55, padR = 25, padT = 30, padB = 45
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

                                // Eksenler
                                ctx.strokeStyle = theme.border
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(padL, padT)
                                ctx.lineTo(padL, height - padB)
                                ctx.lineTo(width - padR, height - padB)
                                ctx.stroke()

                                if (page.chartType === "histogram" && page.chartData2.frequencies) {
                                    var freqs = page.chartData2.frequencies
                                    var maxF = 1
                                    for (var i = 0; i < freqs.length; ++i) if (freqs[i] > maxF) maxF = freqs[i]
                                    var bW = plotW / freqs.length
                                    var low = page.chartData2.binLowerBounds || []

                                    for (var j = 0; j < freqs.length; ++j) {
                                        var bH = (freqs[j] / maxF) * (plotH - 20)
                                        var bX = padL + j * bW + 4
                                        var bY = height - padB - bH

                                        var grad = ctx.createLinearGradient(bX, bY, bX, height - padB)
                                        grad.addColorStop(0, "#7C4DFF")
                                        grad.addColorStop(1, "#00E5FF")
                                        ctx.fillStyle = grad
                                        ctx.fillRect(bX, bY, bW - 8, bH)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "bold 11px sans-serif"
                                        ctx.textAlign = "center"
                                        if (freqs[j] > 0) ctx.fillText(String(freqs[j]), bX + (bW - 8) / 2, bY - 6)

                                        if (low.length > j) {
                                            ctx.fillStyle = theme.textSecondary
                                            ctx.font = "10px sans-serif"
                                            ctx.fillText(Number(low[j]).toFixed(1), bX + (bW - 8) / 2, height - padB + 15)
                                        }
                                    }
                                }
                                else if (page.chartType === "boxplot" && page.chartData2.minimum !== undefined) {
                                    var min = page.chartData2.minimum, max = page.chartData2.maximum
                                    var q1 = page.chartData2.q1, med = page.chartData2.median, q3 = page.chartData2.q3
                                    var lW = page.chartData2.lowerWhisker !== undefined ? page.chartData2.lowerWhisker : min
                                    var uW = page.chartData2.upperWhisker !== undefined ? page.chartData2.upperWhisker : max
                                    var rng = (max - min) === 0 ? 1 : (max - min)
                                    function toY2(v) { return (height - padB) - ((v - min) / rng) * (plotH - 40) - 20 }

                                    var cX = width / 2, boxW = 90
                                    ctx.strokeStyle = "#7C4DFF"; ctx.lineWidth = 2
                                    ctx.beginPath()
                                    ctx.moveTo(cX, toY2(lW)); ctx.lineTo(cX, toY2(uW))
                                    ctx.moveTo(cX - 20, toY2(lW)); ctx.lineTo(cX + 20, toY2(lW))
                                    ctx.moveTo(cX - 20, toY2(uW)); ctx.lineTo(cX + 20, toY2(uW))
                                    ctx.stroke()

                                    var yQ3 = toY2(q3), yQ1 = toY2(q1)
                                    var gradB = ctx.createLinearGradient(cX - boxW/2, yQ3, cX + boxW/2, yQ1)
                                    gradB.addColorStop(0, "#7C4DFF")
                                    gradB.addColorStop(1, "#00E5FF")
                                    ctx.fillStyle = gradB
                                    ctx.fillRect(cX - boxW / 2, yQ3, boxW, yQ1 - yQ3)
                                    ctx.strokeStyle = "#512DA8"
                                    ctx.strokeRect(cX - boxW / 2, yQ3, boxW, yQ1 - yQ3)

                                    ctx.strokeStyle = "#FFD600"; ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(cX - boxW / 2, toY2(med)); ctx.lineTo(cX + boxW / 2, toY2(med))
                                    ctx.stroke()

                                    ctx.fillStyle = theme.text; ctx.font = "bold 10px sans-serif"; ctx.textAlign = "left"
                                    ctx.fillText("Max: " + Number(max).toFixed(1), cX + boxW / 2 + 10, toY2(max))
                                    ctx.fillText("Medyan: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY2(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY2(min))
                                }
                                else if ((page.chartType === "timeseries" || page.chartType === "distribution" || page.chartType === "comparison") && page.chartData2.pointCount > 0) {
                                    var pts2 = page.chartData2.pointCount
                                    var xVals2 = page.chartData2.xValues || page.chartData2.indexes || []
                                    var yVals2 = page.chartData2.yValues || page.chartData2.targetValues || []
                                    var minY2 = 0, maxY2 = 1
                                    for (var p2 = 0; p2 < yVals2.length; ++p2) {
                                        if (yVals2[p2] < minY2) minY2 = yVals2[p2]
                                        if (yVals2[p2] > maxY2) maxY2 = yVals2[p2]
                                    }
                                    var rngY2 = (maxY2 - minY2) === 0 ? 1 : (maxY2 - minY2)

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    for (var k2 = 0; k2 < pts2; ++k2) {
                                        var xP2 = padL + (k2 / Math.max(1, pts2 - 1)) * plotW
                                        var yP2 = (height - padB) - ((yVals2[k2] - minY2) / rngY2) * (plotH - 20)
                                        if (k2 === 0) ctx.moveTo(xP2, yP2); else ctx.lineTo(xP2, yP2)
                                    }
                                    ctx.stroke()
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
