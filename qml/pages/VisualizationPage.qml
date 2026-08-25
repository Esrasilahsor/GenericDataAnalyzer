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
    property bool isRendering: false

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
        if (page.chartType !== "correlation" && (page.selectedCol1 === "" || page.selectedCol1 === "-- Sütun Seçiniz --")) {
            page.saveSuccess = false
            page.saveStatusMessage = "Lütfen çizmek istediğiniz sütunu seçin."
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
                        text: "⏳ Grafik hesaplanıyor ve çiziliyor, lütfen bekleyin..."
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
                            visible: !page.isDualMode && page.chartType !== "comparison"
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
                                    page.selectedCol1 = ""
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
                                    page.selectedCol1 = ""
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
                                Layout.preferredWidth: 205
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
                                text: (page.isDualMode || page.chartType === "comparison") ? "Dataset 1 Sütunu" : (page.chartType === "timeseries" ? "Çizgi Sütunu" : "Analiz Sütunu")
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
                                displayText: page.selectedCol1 !== "" ? page.selectedCol1 : "-- Sütun Seçiniz --"
                                onActivated: page.selectedCol1 = currentText
                            }
                        }

                        // Column 2
                        ColumnLayout {
                            visible: (page.isDualMode || page.chartType === "comparison") && page.chartType !== "correlation"
                            spacing: 2
                            Label {
                                text: "Dataset 2 Sütunu"
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
                                displayText: page.selectedCol2 !== "" ? page.selectedCol2 : "-- Sütun Seçiniz --"
                                onActivated: page.selectedCol2 = currentText
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
                            text: page.isRendering ? "⏳ Çiziliyor..." : "📊 Grafiği Çiz"
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
                                      ? "İki Veri Seti Karşılaştırma Grafiği (D1: " + page.name(1) + " vs D2: " + page.name(2) + ")"
                                      : (page.isDualMode ? "Dataset 1: " + page.name(1) + (page.selectedCol1 !== "" ? " (" + page.selectedCol1 + ")" : "") : page.name(page.activeDataset) + (page.selectedCol1 !== "" ? " (" + page.selectedCol1 + ")" : "") + " Grafiği")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideMiddle
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 30
                                text: "💾 Grafiği Kaydet"
                                onClicked: page.saveChart(chartCanvas1, page.chartType + "_D1")
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

                        Canvas {
                            id: chartCanvas1
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                if (page.chartType !== "correlation" && (page.selectedCol1 === "" || page.selectedCol1 === "-- Sütun Seçiniz --")) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "13px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Lütfen yukarıdan bir sütun seçip 'Grafiği Çiz' butonuna tıklayın.", width / 2, height / 2)
                                    return
                                }

                                if (!page.chartData1 || !page.chartData1.success) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "13px sans-serif"
                                    ctx.textAlign = "center"
                                    var errMsg = (page.chartData1 && page.chartData1.errorMessage) ? ("Hata: " + page.chartData1.errorMessage) : "Grafik görüntülemek için yukarıdan parametre seçip 'Grafiği Çiz' butonuna tıklayın."
                                    ctx.fillText(errMsg, width / 2, height / 2)
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
                                    ctx.fillText("Medyan: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY(min))
                                }
                                else if (page.chartType === "timeseries" && page.chartData1.pointCount > 0) {
                                    var pts = page.chartData1.pointCount
                                    var yVals = page.chartData1.yValues || []
                                    var minY = 999999, maxY = -999999
                                    for (var p = 0; p < yVals.length; ++p) {
                                        if (yVals[p] < minY) minY = yVals[p]
                                        if (yVals[p] > maxY) maxY = yVals[p]
                                    }
                                    if (minY === 999999) { minY = 0; maxY = 1; }
                                    var rngY = (maxY - minY) === 0 ? 1 : (maxY - minY)

                                    var step = Math.max(1, Math.floor(pts / 1000))
                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2
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
                                text: "Dataset 2: " + page.name(2) + (page.selectedCol2 !== "" ? " (" + page.selectedCol2 + ")" : "")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideMiddle
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

                                if (page.chartType !== "correlation" && (page.selectedCol2 === "" || page.selectedCol2 === "-- Sütun Seçiniz --")) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Lütfen Dataset 2 için bir sütun seçip 'Grafiği Çiz' butonuna tıklayın.", width / 2, height / 2)
                                    return
                                }

                                if (!page.chartData2 || !page.chartData2.success) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    var errMsg2 = (page.chartData2 && page.chartData2.errorMessage) ? ("Hata: " + page.chartData2.errorMessage) : "Dataset 2 grafiği için 'Grafiği Çiz' butonuna tıklayın."
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
                                else if (page.chartType === "timeseries" && page.chartData2.pointCount > 0) {
                                    var pts2 = page.chartData2.pointCount
                                    var yVals2 = page.chartData2.yValues || []
                                    var minY2 = 999999, maxY2 = -999999
                                    for (var p2 = 0; p2 < yVals2.length; ++p2) {
                                        if (yVals2[p2] < minY2) minY2 = yVals2[p2]
                                        if (yVals2[p2] > maxY2) maxY2 = yVals2[p2]
                                    }
                                    if (minY2 === 999999) { minY2 = 0; maxY2 = 1; }
                                    var rngY2 = (maxY2 - minY2) === 0 ? 1 : (maxY2 - minY2)
                                    var step2 = Math.max(1, Math.floor(pts2 / 1000))

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2
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
