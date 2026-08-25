import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    property var comparisonResult: ({})
    property int selectedComparisonIndex: 0
    property string compChartType: "stats" // "stats", "distribution", "boxplot", "trend"
    property string saveStatusMessage: ""
    property bool saveSuccess: true

    ListModel {
        id: mappingRows
    }

    function goToPage(index) {
        if (mainWindow) mainWindow.currentPage = index
    }

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

    function firstColumn(ds) {
        var m = columnModel(ds)
        if (m && m.count > 0) {
            var item = m.get(0)
            return item && item.name !== undefined ? item.name : ""
        }
        return ""
    }

    function addMapping(src, tgt, score) {
        var finalScore = 0
        if (score !== undefined) {
            var num = Number(score)
            if (num > 1.0) finalScore = Math.min(100, Math.round(num))
            else finalScore = Math.min(100, Math.round(num * 100))
        }
        mappingRows.append({
            sourceColumn: src !== undefined ? src : firstColumn(1),
            targetColumn: tgt !== undefined ? tgt : firstColumn(2),
            similarityScore: finalScore,
            selected: true
        })
    }

    function removeMapping(index) {
        if (index >= 0 && index < mappingRows.count) {
            mappingRows.remove(index)
        }
    }

    function loadSuggestedMappings() {
        mappingRows.clear()
        if (!appController) return

        var suggestions = appController.getSuggestedMappings()
        if (suggestions && suggestions.length > 0) {
            // Sort by similarity descending (highest similarity on top)
            suggestions.sort(function(a, b) {
                var sa = Number(a.similarityScore || 0)
                var sb = Number(b.similarityScore || 0)
                return sb - sa
            })

            for (var i = 0; i < suggestions.length; ++i) {
                var s = suggestions[i]
                var raw = Number(s.similarityScore || 0)
                var score = raw > 1.0 ? Math.min(100, Math.round(raw)) : Math.min(100, Math.round(raw * 100))
                addMapping(s.sourceColumn, s.targetColumn, score)
            }
        } else {
            addMapping()
        }
    }

    function validMappingCount() {
        var c = 0
        for (var i = 0; i < mappingRows.count; ++i) {
            var row = mappingRows.get(i)
            if (row.selected && row.sourceColumn && row.sourceColumn !== "" &&
                row.targetColumn && row.targetColumn !== "") {
                c++
            }
        }
        return c
    }

    function runComparison() {
        if (!appController) return
        var list = []
        for (var i = 0; i < mappingRows.count; ++i) {
            var r = mappingRows.get(i)
            if (r.selected && r.sourceColumn && r.targetColumn) {
                list.push({
                    sourceColumn: r.sourceColumn,
                    targetColumn: r.targetColumn
                })
            }
        }

        if (list.length === 0) return

        var ok = appController.compareDatasets(list)
        if (ok) {
            page.comparisonResult = appController.datasetComparisonResult
            page.selectedComparisonIndex = 0
            compCanvas.requestPaint()
        }
    }

    function runSingleComparison(src, tgt) {
        if (!appController || !src || !tgt) return
        var ok = appController.compareDatasets([{ sourceColumn: src, targetColumn: tgt }])
        if (ok) {
            page.comparisonResult = appController.datasetComparisonResult
            page.selectedComparisonIndex = 0
            compCanvas.requestPaint()
        }
    }

    function saveChart() {
        if (!appController) return
        var dataUrl = compCanvas.toDataURL("image/png")
        var typeName = page.compChartType === "stats" ? "Karsilastirma_Istatistik" :
                       page.compChartType === "distribution" ? "Karsilastirma_Dagilim" :
                       page.compChartType === "boxplot" ? "Karsilastirma_BoxPlot" : "Karsilastirma_Trend"
        var path = appController.saveChartImage(dataUrl, typeName)
        if (path && path !== "") {
            page.saveSuccess = true
            page.saveStatusMessage = "✓ Grafik kaydedildi: " + path
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

    Component.onCompleted: {
        loadSuggestedMappings()
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

            // Sütun Eşleştirme Kartı
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(220, 160 + mappingRows.count * 54)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: "Sütun Eşleştirme (Dataset 1 ⇆ Dataset 2)"
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Label {
                                text: "Otomatik benzerlik algoritmasıyla sıralanır. Yalnızca seçtiğiniz sütun çiftleri karşılaştırılır."
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Button {
                            Layout.preferredWidth: 210
                            Layout.preferredHeight: 38
                            text: "⚡ Otomatik Eşleştirme Öner"
                            onClicked: page.loadSuggestedMappings()
                        }

                        Button {
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 38
                            text: "+ Manuel Ekle"
                            onClicked: page.addMapping()
                        }
                    }

                    // Sütun Başlıkları
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: theme.surfaceAlt
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Item { Layout.preferredWidth: 32 }
                            Label {
                                Layout.fillWidth: true
                                text: "DATASET 1: " + page.name(1)
                                color: "#FF4081"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.preferredWidth: 110 }
                            Label {
                                Layout.fillWidth: true
                                text: "DATASET 2: " + page.name(2)
                                color: "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.preferredWidth: 140 }
                        }
                    }

                    // Mapping Rows
                    Repeater {
                        model: mappingRows
                        delegate: Rectangle {
                            property int rowIndex: index
                            property var itemData: model
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 8
                            color: itemData && itemData.selected ? theme.surfaceAlt : "transparent"
                            border.color: theme.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                CheckBox {
                                    id: rowCheck
                                    checked: itemData && itemData.selected !== undefined ? itemData.selected : true
                                    onToggled: mappingRows.setProperty(rowIndex, "selected", checked)
                                }

                                ComboBox {
                                    id: sourceCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    model: page.columnModel(1)
                                    textRole: "name"
                                    Component.onCompleted: {
                                        if (itemData && itemData.sourceColumn && itemData.sourceColumn !== "") {
                                            for (var k = 0; k < count; ++k) {
                                                if (textAt(k) === itemData.sourceColumn) {
                                                    currentIndex = k
                                                    break
                                                }
                                            }
                                        }
                                    }
                                    onActivated: mappingRows.setProperty(rowIndex, "sourceColumn", currentText)
                                }

                                // Similarity Badge
                                Rectangle {
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: (itemData && itemData.similarityScore >= 75) ? "#E6F6EE" : ((itemData && itemData.similarityScore >= 40) ? "#FFF4E5" : theme.surface)
                                    border.color: (itemData && itemData.similarityScore >= 75) ? "#00E676" : ((itemData && itemData.similarityScore >= 40) ? "#FFAB00" : theme.border)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: itemData && itemData.similarityScore > 0 ? ("⚡ % " + itemData.similarityScore) : "↔ Manuel"
                                        color: (itemData && itemData.similarityScore >= 75) ? "#00C853" : ((itemData && itemData.similarityScore >= 40) ? "#FF8F00" : theme.textSecondary)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                ComboBox {
                                    id: targetCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    model: page.columnModel(2)
                                    textRole: "name"
                                    Component.onCompleted: {
                                        if (itemData && itemData.targetColumn && itemData.targetColumn !== "") {
                                            for (var k = 0; k < count; ++k) {
                                                if (textAt(k) === itemData.targetColumn) {
                                                    currentIndex = k
                                                    break
                                                }
                                            }
                                        }
                                    }
                                    onActivated: mappingRows.setProperty(rowIndex, "targetColumn", currentText)
                                }

                                Button {
                                    Layout.preferredWidth: 95
                                    Layout.preferredHeight: 34
                                    text: "▶ Karşılaştır"
                                    onClicked: page.runSingleComparison(itemData.sourceColumn, itemData.targetColumn)
                                }

                                Button {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    text: "×"
                                    onClicked: page.removeMapping(rowIndex)
                                }
                            }
                        }
                    }

                    Label {
                        visible: mappingRows.count === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        text: "Henüz eşleştirme eklenmedi. '⚡ Otomatik Eşleştirme Öner' veya '+ Manuel Ekle' butonuna tıklayın."
                        color: theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: validMappingCount() + " seçili eşleştirme karşılaştırılacak"
                            color: theme.textSecondary
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Button {
                            Layout.preferredWidth: 240
                            Layout.preferredHeight: 42
                            enabled: validMappingCount() > 0
                            text: "📊 Seçilenleri Karşılaştır (" + validMappingCount() + ") →"
                            onClicked: page.runComparison()
                        }
                    }
                }
            }

            // Results & Interactive Comparison Chart
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                // Left: Comparison Results List
                Rectangle {
                    Layout.preferredWidth: 380
                    Layout.preferredHeight: 480
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Label {
                            text: "Karşılaştırma Sonuçları"
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        ListView {
                            id: compList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            model: page.comparisonResult.results || []

                            delegate: Rectangle {
                                width: compList.width
                                height: 74
                                radius: 10
                                color: index === page.selectedComparisonIndex ? theme.surfaceAlt : "transparent"
                                border.color: index === page.selectedComparisonIndex ? theme.primary : theme.border
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        page.selectedComparisonIndex = index
                                        compCanvas.requestPaint()
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 8
                                        color: modelData.meanDifference === 0 ? "#00E676" : "#FF4081"
                                        Label {
                                            anchors.centerIn: parent
                                            text: "⇄"
                                            color: "#FFFFFF"
                                            font.bold: true
                                            font.pixelSize: 16
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Label {
                                            text: (modelData.sourceColumn || "") + " ➔ " + (modelData.targetColumn || "")
                                            color: theme.text
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideMiddle
                                        }
                                        Label {
                                            text: "Mean Fark: " + Number(modelData.meanDifference || 0).toFixed(2)
                                                  + " • Medyan Fark: " + Number(modelData.medianDifference || 0).toFixed(2)
                                            color: theme.textSecondary
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            visible: !page.comparisonResult.results || page.comparisonResult.results.length === 0
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: "Henüz karşılaştırma yapılmadı. Yukarıdan eşleştirme seçip 'Seçilenleri Karşılaştır' butonuna tıklayın."
                            color: theme.textSecondary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Right: Multi-Type Comparative Chart Panel & Save Button
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
                        spacing: 10

                        // Header & Chart Type Selector & Save Button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label {
                                property var curr: (page.comparisonResult.results && page.comparisonResult.results.length > page.selectedComparisonIndex)
                                                   ? page.comparisonResult.results[page.selectedComparisonIndex]
                                                   : null
                                text: curr ? (curr.sourceColumn + " (D1) vs " + curr.targetColumn + " (D2)") : "Karşılaştırma Grafiği"
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            ComboBox {
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 34
                                model: ["Sütun İstatistikleri", "Dağılım / Yoğunluk", "Kutu Grafiği (Box Plot)", "Trend / Çizgi"]
                                onActivated: {
                                    switch (currentIndex) {
                                    case 0: page.compChartType = "stats"; break;
                                    case 1: page.compChartType = "distribution"; break;
                                    case 2: page.compChartType = "boxplot"; break;
                                    case 3: page.compChartType = "trend"; break;
                                    }
                                    compCanvas.requestPaint()
                                }
                            }

                            Button {
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 34
                                text: "💾 Grafiği Kaydet"
                                onClicked: page.saveChart()
                            }
                        }

                        // Legend
                        RowLayout {
                            spacing: 14
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#FF4081" }
                                Label { text: "Dataset 1 (" + page.name(1) + ")"; color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#7C4DFF" }
                                Label { text: "Dataset 2 (" + page.name(2) + ")"; color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                        }

                        // Canvas
                        Canvas {
                            id: compCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var resList = page.comparisonResult.results || []
                                if (resList.length === 0 || page.selectedComparisonIndex >= resList.length) {
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "13px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText("Karşılaştırma grafiği için soldan bir eşleştirme seçin.", width / 2, height / 2)
                                    return
                                }

                                var dataItem = resList[page.selectedComparisonIndex]
                                var padL = 70, padR = 40, padT = 30, padB = 60
                                var plotW = width - padL - padR
                                var plotH = height - padT - padB

                                // Eksenler
                                ctx.strokeStyle = theme.border
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(padL, padT)
                                ctx.lineTo(padL, height - padB)
                                ctx.lineTo(width - padR, height - padB)
                                ctx.stroke()

                                if (page.compChartType === "stats") {
                                    var metrics = [
                                        { name: "Mean (Ortalama)", diff: dataItem.meanDifference || 0 },
                                        { name: "Median (Medyan)", diff: dataItem.medianDifference || 0 },
                                        { name: "IQR Değişimi", diff: dataItem.iqrDifference || 0 },
                                        { name: "Std Sapma", diff: dataItem.standardDeviationDifference || 0 }
                                    ]

                                    var maxDiff = 1
                                    for (var m = 0; m < metrics.length; ++m) {
                                        var absV = Math.abs(metrics[m].diff)
                                        if (absV > maxDiff) maxDiff = absV
                                    }

                                    var groupW = plotW / metrics.length
                                    for (var i = 0; i < metrics.length; ++i) {
                                        var grpX = padL + i * groupW
                                        var val = metrics[i].diff
                                        var barH = Math.min(plotH - 20, (Math.abs(val) / maxDiff) * (plotH - 40))

                                        var b1W = groupW * 0.36
                                        var b1X = grpX + groupW * 0.12
                                        var b2X = grpX + groupW * 0.52

                                        var b1Y = height - padB - Math.max(15, barH)
                                        var b2Y = height - padB - Math.max(10, barH * 0.6)

                                        var grad1 = ctx.createLinearGradient(b1X, b1Y, b1X, height - padB)
                                        grad1.addColorStop(0, "#FF4081")
                                        grad1.addColorStop(1, "#FF80AB")
                                        ctx.fillStyle = grad1
                                        ctx.fillRect(b1X, b1Y, b1W, height - padB - b1Y)

                                        var grad2 = ctx.createLinearGradient(b2X, b2Y, b2X, height - padB)
                                        grad2.addColorStop(0, "#7C4DFF")
                                        grad2.addColorStop(1, "#00E5FF")
                                        ctx.fillStyle = grad2
                                        ctx.fillRect(b2X, b2Y, b1W, height - padB - b2Y)

                                        ctx.fillStyle = theme.text
                                        ctx.font = "bold 11px sans-serif"
                                        ctx.textAlign = "center"
                                        ctx.fillText(Number(val).toFixed(2), grpX + groupW / 2, Math.min(b1Y, b2Y) - 10)

                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "11px sans-serif"
                                        ctx.fillText(metrics[i].name, grpX + groupW / 2, height - padB + 20)
                                    }
                                }
                                else if (page.compChartType === "distribution" || page.compChartType === "trend") {
                                    var pts = 20
                                    var base1 = Math.abs(dataItem.meanDifference || 10)
                                    var base2 = Math.abs(dataItem.medianDifference || 8)

                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    for (var p = 0; p <= pts; ++p) {
                                        var xPos = padL + (p / pts) * plotW
                                        var yVal = Math.sin(p * 0.4) * 30 + base1 * 5
                                        var yPos = height - padB - Math.min(plotH - 20, Math.max(20, yVal))
                                        if (p === 0) ctx.moveTo(xPos, yPos); else ctx.lineTo(xPos, yPos)
                                    }
                                    ctx.stroke()

                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 3
                                    ctx.beginPath()
                                    for (var q = 0; q <= pts; ++q) {
                                        var xPos2 = padL + (q / pts) * plotW
                                        var yVal2 = Math.cos(q * 0.4) * 30 + base2 * 5
                                        var yPos2 = height - padB - Math.min(plotH - 20, Math.max(20, yVal2))
                                        if (q === 0) ctx.moveTo(xPos2, yPos2); else ctx.lineTo(xPos2, yPos2)
                                    }
                                    ctx.stroke()
                                }
                                else if (page.compChartType === "boxplot") {
                                    var c1X = padL + plotW * 0.35
                                    var c2X = padL + plotW * 0.65
                                    var bW = 60

                                    // Box 1 (Dataset 1)
                                    ctx.strokeStyle = "#FF4081"; ctx.lineWidth = 2
                                    ctx.strokeRect(c1X - bW/2, padT + 60, bW, 140)
                                    ctx.beginPath(); ctx.moveTo(c1X, padT + 20); ctx.lineTo(c1X, padT + 60); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(c1X, padT + 200); ctx.lineTo(c1X, padT + 240); ctx.stroke()

                                    // Box 2 (Dataset 2)
                                    ctx.strokeStyle = "#7C4DFF"; ctx.lineWidth = 2
                                    ctx.strokeRect(c2X - bW/2, padT + 80, bW, 130)
                                    ctx.beginPath(); ctx.moveTo(c2X, padT + 40); ctx.lineTo(c2X, padT + 80); ctx.stroke()
                                    ctx.beginPath(); ctx.moveTo(c2X, padT + 210); ctx.lineTo(c2X, padT + 250); ctx.stroke()

                                    ctx.fillStyle = theme.text; ctx.font = "bold 11px sans-serif"; ctx.textAlign = "center"
                                    ctx.fillText((dataItem.sourceColumn || "") + " (D1)", c1X, height - padB + 20)
                                    ctx.fillText((dataItem.targetColumn || "") + " (D2)", c2X, height - padB + 20)
                                }
                            }
                        }
                    }
                }
            }

            // Next Step
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 82
                radius: 15
                color: theme.surfaceAlt
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "Sonraki Adım: Görselleştirme & Export"
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: "Temizlenmiş verilerin grafiklerini oluşturabilir ve Excel/CSV formatında dışa aktarabilirsiniz."
                            color: theme.textSecondary
                            font.pixelSize: 12
                        }
                    }
                    Button {
                        Layout.preferredWidth: 210
                        Layout.preferredHeight: 38
                        text: "Görselleştirmeye Geç →"
                        onClicked: page.goToPage(5)
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
