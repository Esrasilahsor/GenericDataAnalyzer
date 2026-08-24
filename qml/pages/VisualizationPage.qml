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

    property bool isDualMode: false
    property int activeDataset: 1
    property string chartType: "histogram"
    property string selectedCol1: ""
    property string selectedCol2: ""
    property int binCount: 10
    property double boxPlotMultiplier: 1.5

    // Chart Data
    property var chartData1: ({})
    property var chartData2: ({})
    property string statusMessage: ""
    property bool statusSuccess: true

    property string exportFormat: "xlsx"

    function goToPage(index) {
        if (page.mainWindow)
            page.mainWindow.currentPage = index
    }

    function isLoaded(ds) {
        if (!page.appController) return false
        return ds === 1
            ? page.appController.dataset1Name !== ""
            : page.appController.dataset2Name !== ""
    }

    function datasetName(ds) {
        if (!page.appController) return "Dataset " + ds
        var n = ds === 1 ? page.appController.dataset1Name : page.appController.dataset2Name
        return n && n !== "" ? n : "Dataset " + ds
    }

    function columnModel(ds) {
        if (!page.appController) return null
        return ds === 1 ? page.appController.dataset1ColumnModel : page.appController.dataset2ColumnModel
    }

    function generateChart1() {
        if (!page.appController || page.selectedCol1 === "") return
        if (page.chartType === "histogram") {
            var r = page.appController.createDataset1Histogram(page.selectedCol1, page.binCount)
            if (r && r.success) { page.chartData1 = r; chartCanvas1.requestPaint(); }
        } else if (page.chartType === "boxplot") {
            var rb = page.appController.createDataset1BoxPlot(page.selectedCol1, page.boxPlotMultiplier)
            if (rb && rb.success) { page.chartData1 = rb; chartCanvas1.requestPaint(); }
        } else if (page.chartType === "distribution") {
            var rd = page.appController.createDataset1Distribution(page.selectedCol1, page.binCount)
            if (rd && rd.success) { page.chartData1 = rd; chartCanvas1.requestPaint(); }
        }
    }

    function generateChart2() {
        if (!page.appController || page.selectedCol2 === "") return
        if (page.chartType === "histogram") {
            var r = page.appController.createDataset2Histogram(page.selectedCol2, page.binCount)
            if (r && r.success) { page.chartData2 = r; if (chartCanvas2) chartCanvas2.requestPaint(); }
        } else if (page.chartType === "boxplot") {
            var rb = page.appController.createDataset2BoxPlot(page.selectedCol2, page.boxPlotMultiplier)
            if (rb && rb.success) { page.chartData2 = rb; if (chartCanvas2) chartCanvas2.requestPaint(); }
        } else if (page.chartType === "distribution") {
            var rd = page.appController.createDataset2Distribution(page.selectedCol2, page.binCount)
            if (rd && rd.success) { page.chartData2 = rd; if (chartCanvas2) chartCanvas2.requestPaint(); }
        }
    }

    function generateChart() {
        if (!page.appController) return
        page.statusMessage = ""

        if (page.isDualMode) {
            if (page.selectedCol1 === "" || page.selectedCol2 === "") {
                page.showStatus("Lütfen her iki veri seti için de sütun seçin.", false)
                return
            }
            generateChart1()
            generateChart2()
            page.showStatus("Yan yana grafikler başarıyla oluşturuldu.", true)
            return
        }

        if (page.chartType === "histogram") {
            if (page.selectedCol1 === "") {
                page.showStatus("Lütfen bir sütun seçin.", false)
                return
            }
            var resHist = page.activeDataset === 1
                ? page.appController.createDataset1Histogram(page.selectedCol1, page.binCount)
                : page.appController.createDataset2Histogram(page.selectedCol1, page.binCount)

            if (resHist && resHist.success) {
                page.chartData1 = resHist
                chartCanvas1.requestPaint()
                page.showStatus("Histogram başarıyla üretildi.", true)
            } else {
                page.showStatus((resHist && resHist.errorMessage) || "Grafik oluşturulamadı. Sütun sayısal olmalıdır.", false)
            }
        }
        else if (page.chartType === "boxplot") {
            if (page.selectedCol1 === "") {
                page.showStatus("Lütfen bir sütun seçin.", false)
                return
            }
            var resBox = page.activeDataset === 1
                ? page.appController.createDataset1BoxPlot(page.selectedCol1, page.boxPlotMultiplier)
                : page.appController.createDataset2BoxPlot(page.selectedCol1, page.boxPlotMultiplier)

            if (resBox && resBox.success) {
                page.chartData1 = resBox
                chartCanvas1.requestPaint()
                page.showStatus("Kutu Grafiği (Box Plot) başarıyla üretildi.", true)
            } else {
                page.showStatus((resBox && resBox.errorMessage) || "Grafik oluşturulamadı.", false)
            }
        }
        else if (page.chartType === "timeseries") {
            if (page.selectedCol1 === "" || page.selectedCol2 === "") {
                page.showStatus("Lütfen X ve Y ekseni için iki sütun seçin.", false)
                return
            }
            var resLine = page.activeDataset === 1
                ? page.appController.createDataset1TimeSeries(page.selectedCol1, page.selectedCol2)
                : page.appController.createDataset2TimeSeries(page.selectedCol1, page.selectedCol2)

            if (resLine && resLine.success) {
                page.chartData1 = resLine
                chartCanvas1.requestPaint()
                page.showStatus("Çizgi Grafiği başarıyla üretildi.", true)
            } else {
                page.showStatus((resLine && resLine.errorMessage) || "Grafik oluşturulamadı.", false)
            }
        }
        else if (page.chartType === "distribution") {
            if (page.selectedCol1 === "") {
                page.showStatus("Lütfen bir sütun seçin.", false)
                return
            }
            var resDist = page.activeDataset === 1
                ? page.appController.createDataset1Distribution(page.selectedCol1, page.binCount)
                : page.appController.createDataset2Distribution(page.selectedCol1, page.binCount)

            if (resDist && resDist.success) {
                page.chartData1 = resDist
                chartCanvas1.requestPaint()
                page.showStatus("Dağılım grafiği başarıyla üretildi.", true)
            } else {
                page.showStatus((resDist && resDist.errorMessage) || "Grafik oluşturulamadı.", false)
            }
        }
    }

    function showStatus(msg, ok) {
        page.statusMessage = msg
        page.statusSuccess = ok
    }

    function doExport(path) {
        if (!page.appController) return
        var ok = false
        if (page.exportFormat === "xlsx") {
            ok = page.activeDataset === 1
                ? page.appController.exportDataset1ToXlsx(path)
                : page.appController.exportDataset2ToXlsx(path)
        } else if (page.exportFormat === "csv") {
            ok = page.activeDataset === 1
                ? page.appController.exportDataset1ToCsv(path)
                : page.appController.exportDataset2ToCsv(path)
        } else if (page.exportFormat === "json") {
            ok = page.activeDataset === 1
                ? page.appController.exportDataset1ToJson(path)
                : page.appController.exportDataset2ToJson(path)
        }

        if (ok) {
            page.showStatus("Dataset " + page.activeDataset + " başarıyla dışa aktarıldı: " + path, true)
            exportFeedbackPopup.open()
        } else {
            page.showStatus("Dışa aktarma başarısız oldu: " + (page.appController.lastError || "Bilinmeyen hata"), false)
            exportFeedbackPopup.open()
        }
    }

    FileDialog {
        id: exportDialog
        title: "Temizlenmiş Veriyi Dışa Aktar"
        selectExisting: false
        folder: page.appController && page.appController.dataDirectory !== ""
                ? ("file:///" + page.appController.dataDirectory.replace(/\\/g, "/"))
                : "file:///C:/Users/aybuk/Desktop/GenericDataAnalyzer/data"
        nameFilters: page.exportFormat === "xlsx"
                     ? ["Excel Dosyaları (*.xlsx)"]
                     : (page.exportFormat === "csv" ? ["CSV Dosyaları (*.csv)"] : ["JSON Dosyaları (*.json)"])
        onAccepted: {
            page.doExport(fileUrl.toString())
        }
    }

    Popup {
        id: exportFeedbackPopup
        anchors.centerIn: parent
        width: Math.min(440, page.width - 40)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0

        background: Rectangle {
            radius: 16
            color: theme.surface
            border.width: 1
            border.color: theme.border
        }

        contentItem: ColumnLayout {
            spacing: 16
            anchors.margins: 20

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: page.statusSuccess ? "#E6F6EE" : "#FFF4E5"
                    Label {
                        anchors.centerIn: parent
                        text: page.statusSuccess ? "✓" : "✕"
                        color: page.statusSuccess ? "#00E676" : "#FF5722"
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: page.statusSuccess ? "Dışa Aktarma Başarılı" : "Dışa Aktarma Hatası"
                        color: theme.text
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Label {
                        text: page.statusMessage
                        color: theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 36
                    text: "Tamam"
                    onClicked: exportFeedbackPopup.close()
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            Item { Layout.preferredHeight: 6 }

            // =================================================
            // KONTROL PANELİ: MOD, DATASET & GRAFİK TÜRÜ SEÇİMİ
            // =================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 180
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Mod Seçimi (Tekli vs Yan Yana Çift Grafik)
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

                        // Veri Seti Seçimi (Tekli modda)
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

                        // Dışa Aktarma Butonları
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

                    // Sütun ve Grafik Tipi Seçimi
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            Label { text: "Grafik Türü"; color: theme.textSecondary; font.pixelSize: 11 }
                            ComboBox {
                                id: typeCombo
                                Layout.preferredWidth: 170
                                Layout.preferredHeight: 36
                                model: ["Histogram (Frekans)", "Kutu Grafiği (Box Plot)", "Çizgi Grafiği (Line)", "Dağılım (Distribution)"]
                                onActivated: {
                                    switch (currentIndex) {
                                    case 0: page.chartType = "histogram"; break;
                                    case 1: page.chartType = "boxplot"; break;
                                    case 2: page.chartType = "timeseries"; break;
                                    case 3: page.chartType = "distribution"; break;
                                    }
                                    page.chartData1 = ({})
                                    page.chartData2 = ({})
                                    chartCanvas1.requestPaint()
                                    if (chartCanvas2) chartCanvas2.requestPaint()
                                }
                            }
                        }

                        // Sütun 1
                        ColumnLayout {
                            spacing: 2
                            Label {
                                text: page.isDualMode ? "Dataset 1 Sütunu" : (page.chartType === "timeseries" ? "X Ekseni Sütunu" : "Analiz Sütunu")
                                color: page.isDualMode ? "#FF4081" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: col1Combo
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 36
                                model: page.isDualMode ? page.columnModel(1) : page.columnModel(page.activeDataset)
                                textRole: "name"
                                onActivated: page.selectedCol1 = currentText
                                Component.onCompleted: {
                                    if (count > 0) page.selectedCol1 = textAt(0)
                                }
                            }
                        }

                        // Sütun 2
                        ColumnLayout {
                            visible: page.isDualMode || page.chartType === "timeseries"
                            spacing: 2
                            Label {
                                text: page.isDualMode ? "Dataset 2 Sütunu" : "Y Ekseni Sütunu"
                                color: page.isDualMode ? "#7C4DFF" : theme.textSecondary
                                font.pixelSize: 11
                                font.bold: page.isDualMode
                            }
                            ComboBox {
                                id: col2Combo
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 36
                                model: page.isDualMode ? page.columnModel(2) : page.columnModel(page.activeDataset)
                                textRole: "name"
                                onActivated: page.selectedCol2 = currentText
                                Component.onCompleted: {
                                    if (count > 0) page.selectedCol2 = textAt(0)
                                }
                            }
                        }

                        // Parametreler
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

            // =================================================
            // GRAFİK ALANI: TEKLİ VEYA YAN YANA ÇİFT GRAFİK
            // =================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                // Panel 1 (Dataset 1 veya Tekli Grafik)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 480
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
                            Rectangle { width: 10; height: 10; radius: 5; color: "#FF4081" }
                            Label {
                                text: page.isDualMode
                                      ? "DATASET 1 • " + page.selectedCol1
                                      : page.chartType.toUpperCase() + " • " + page.datasetName(page.activeDataset) + (page.selectedCol1 !== "" ? " (" + page.selectedCol1 + ")" : "")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: page.chartData1.success ? "✓ Güncel" : "Bekleniyor"
                                color: page.chartData1.success ? "#00E676" : theme.textSecondary
                                font.pixelSize: 11
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
                                    ctx.font = "12px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Grafiği çizmek için sütun seçip 'Grafiği Çiz' butonuna tıklayın.", width / 2, height / 2)
                                    return
                                }

                                var padL = 55, padR = 25, padT = 30, padB = 45
                                var plotW = width - padL - padR
                                var plotH = height - padT - padB

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

                                        // Canlı Renk Gradyanı: Pink to Rose Sunset (#FF4081 -> #FF80AB)
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
                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2
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

                                    ctx.strokeStyle = "#FFD600"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(cX - boxW / 2, toY(med)); ctx.lineTo(cX + boxW / 2, toY(med))
                                    ctx.stroke()

                                    ctx.fillStyle = theme.text
                                    ctx.font = "bold 10px sans-serif"
                                    ctx.textAlign = "left"
                                    ctx.fillText("Max: " + Number(max).toFixed(1), cX + boxW / 2 + 10, toY(max))
                                    ctx.fillText("Medyan: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY(min))
                                }
                                else if (page.chartType === "distribution" && page.chartData1.centers) {
                                    var cents = page.chartData1.centers
                                    var rels = page.chartData1.relativeFrequencies
                                    var maxR = 0.01
                                    for (var d = 0; d < rels.length; ++d) if (rels[d] > maxR) maxR = rels[d]
                                    var bW2 = plotW / cents.length
                                    for (var r = 0; r < cents.length; ++r) {
                                        var brH = (rels[r] / maxR) * (plotH - 20)
                                        var brX = padL + r * bW2 + 4
                                        var brY = height - padB - brH

                                        var gradD = ctx.createLinearGradient(brX, brY, brX, height - padB)
                                        gradD.addColorStop(0, "#FF6E40")
                                        gradD.addColorStop(1, "#FFD600")
                                        ctx.fillStyle = gradD
                                        ctx.fillRect(brX, brY, bW2 - 8, brH)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "9px sans-serif"
                                        ctx.textAlign = "center"
                                        ctx.fillText((Number(rels[r]) * 100).toFixed(0) + "%", brX + (bW2 - 8) / 2, brY - 4)
                                    }
                                }
                                else if (page.chartType === "timeseries" && page.chartData1.xValues) {
                                    var xs = page.chartData1.xValues, ys = page.chartData1.yValues
                                    if (xs.length > 0) {
                                        var minX = xs[0], maxX = xs[0], minY = ys[0], maxY = ys[0]
                                        for (var k = 0; k < xs.length; ++k) {
                                            if (xs[k] < minX) minX = xs[k]; if (xs[k] > maxX) maxX = xs[k]
                                            if (ys[k] < minY) minY = ys[k]; if (ys[k] > maxY) maxY = ys[k]
                                        }
                                        var rngX = (maxX - minX) === 0 ? 1 : (maxX - minX)
                                        var rngY = (maxY - minY) === 0 ? 1 : (maxY - minY)

                                        ctx.strokeStyle = "#FF4081"
                                        ctx.lineWidth = 3
                                        ctx.beginPath()
                                        for (var p = 0; p < xs.length; ++p) {
                                            var ptX = padL + ((xs[p] - minX) / rngX) * plotW
                                            var ptY = (height - padB) - ((ys[p] - minY) / rngY) * plotH
                                            if (p === 0) ctx.moveTo(ptX, ptY); else ctx.lineTo(ptX, ptY)
                                        }
                                        ctx.stroke()
                                    }
                                }
                            }
                        }
                    }
                }

                // Panel 2 (Sadece Dual Mode'da Dataset 2 Grafiği)
                Rectangle {
                    visible: page.isDualMode
                    Layout.fillWidth: true
                    Layout.preferredHeight: 480
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
                            Rectangle { width: 10; height: 10; radius: 5; color: "#7C4DFF" }
                            Label {
                                text: "DATASET 2 • " + page.selectedCol2
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: page.chartData2.success ? "✓ Güncel" : "Bekleniyor"
                                color: page.chartData2.success ? "#00E676" : theme.textSecondary
                                font.pixelSize: 11
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

                                        // Canlı Renk Gradyanı: Purple to Cyan (#7C4DFF -> #00E5FF)
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
                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2
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

                                    ctx.strokeStyle = "#FFD600"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    ctx.moveTo(cX - boxW / 2, toY2(med)); ctx.lineTo(cX + boxW / 2, toY2(med))
                                    ctx.stroke()

                                    ctx.fillStyle = theme.text
                                    ctx.font = "bold 10px sans-serif"
                                    ctx.textAlign = "left"
                                    ctx.fillText("Max: " + Number(max).toFixed(1), cX + boxW / 2 + 10, toY2(max))
                                    ctx.fillText("Medyan: " + Number(med).toFixed(1), cX + boxW / 2 + 10, toY2(med))
                                    ctx.fillText("Min: " + Number(min).toFixed(1), cX + boxW / 2 + 10, toY2(min))
                                }
                            }
                        }
                    }
                }

                // İstatistik ve Metrikler Paneli (Tekli Modda)
                Rectangle {
                    visible: !page.isDualMode
                    Layout.preferredWidth: 320
                    Layout.preferredHeight: 480
                    radius: 16
                    color: theme.surfaceAlt
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        Label {
                            text: "Grafik Özeti"
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: theme.border
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8

                            Repeater {
                                model: page.chartType === "histogram" ? [
                                    { k: "Geçerli Değer", v: String(page.chartData1.validValueCount || "—") },
                                    { k: "Bin Sayısı", v: String(page.chartData1.binCount || "—") },
                                    { k: "Bin Genişliği", v: Number(page.chartData1.binWidth || 0).toFixed(3) },
                                    { k: "Minimum", v: Number(page.chartData1.minimum || 0).toFixed(3) },
                                    { k: "Maximum", v: Number(page.chartData1.maximum || 0).toFixed(3) }
                                ] : (page.chartType === "boxplot" ? [
                                    { k: "Geçerli Değer", v: String(page.chartData1.validValueCount || "—") },
                                    { k: "Minimum", v: Number(page.chartData1.minimum || 0).toFixed(3) },
                                    { k: "Q1 (1. Çeyrek)", v: Number(page.chartData1.q1 || 0).toFixed(3) },
                                    { k: "Medyan (Q2)", v: Number(page.chartData1.median || 0).toFixed(3) },
                                    { k: "Q3 (3. Çeyrek)", v: Number(page.chartData1.q3 || 0).toFixed(3) },
                                    { k: "Maximum", v: Number(page.chartData1.maximum || 0).toFixed(3) },
                                    { k: "IQR", v: Number(page.chartData1.iqr || 0).toFixed(3) },
                                    { k: "Aykırı Değer Sayısı", v: String(page.chartData1.outlierCount || 0) }
                                ] : [
                                    { k: "Geçerli Nokta", v: String(page.chartData1.validValueCount || page.chartData1.pointCount || "—") },
                                    { k: "Grafik Türü", v: page.chartType.toUpperCase() }
                                ])

                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: modelData.k
                                        color: theme.textSecondary
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: modelData.v
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
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
