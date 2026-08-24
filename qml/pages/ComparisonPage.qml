import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    ListModel { id: mappingRows }
    property var comparisonResult: appController ? appController.datasetComparisonResult : ({})
    property bool comparisonAvailable: appController ? appController.datasetComparisonAvailable : false
    property int selectedComparisonIndex: 0

    function goToPage(index) {
        if (mainWindow) mainWindow.currentPage = index
    }

    function columnModel(ds) {
        return ds === 1 ? (appController ? appController.dataset1ColumnModel : null)
                        : (appController ? appController.dataset2ColumnModel : null)
    }

    function addMapping() {
        mappingRows.append({
            sourceColumn: "",
            targetColumn: "",
            similarityScore: 0
        })
    }

    function removeMapping(i) {
        if (i >= 0 && i < mappingRows.count)
            mappingRows.remove(i)
    }

    function loadSuggestedMappings() {
        if (!appController) return
        appController.generateMappings()
        mappingRows.clear()
        var list = appController.getSuggestedMappings()
        if (list && list.length > 0) {
            for (var i = 0; i < list.length; ++i) {
                mappingRows.append({
                    sourceColumn: list[i].sourceColumn || "",
                    targetColumn: list[i].targetColumn || "",
                    similarityScore: Math.round(Number(list[i].similarityScore || 0))
                })
            }
        } else {
            addMapping()
        }
    }

    function validMappingCount() {
        var c = 0
        for (var i = 0; i < mappingRows.count; ++i) {
            var m = mappingRows.get(i)
            if (m.sourceColumn !== "" && m.targetColumn !== "")
                ++c
        }
        return c
    }

    function runComparison() {
        if (!appController || validMappingCount() === 0) return

        var list = []
        for (var i = 0; i < mappingRows.count; ++i) {
            var m = mappingRows.get(i)
            if (m.sourceColumn !== "" && m.targetColumn !== "")
                list.push({
                    sourceColumn: m.sourceColumn,
                    targetColumn: m.targetColumn
                })
        }

        appController.compareDatasets(list)
    }

    Connections {
        target: appController
        ignoreUnknownSignals: true
        function onDatasetComparisonChanged() {
            page.comparisonResult = appController ? appController.datasetComparisonResult : ({})
            page.comparisonAvailable = appController ? appController.datasetComparisonAvailable : false
            page.selectedComparisonIndex = 0
            if (compCanvas) compCanvas.requestPaint()
        }
        function onDataset1Changed() { mappingRows.clear() }
        function onDataset2Changed() { mappingRows.clear() }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            Item {
                Layout.preferredHeight: 8
            }

            // Dataset header cards
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2
                    delegate: Rectangle {
                        property int ds: index + 1
                        Layout.fillWidth: true
                        Layout.preferredHeight: 82
                        radius: 14
                        color: theme.surface
                        border.color: theme.border
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 3
                            Label {
                                text: "DATASET " + parent.parent.ds
                                color: parent.parent.ds === 1 ? "#FF4081" : "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Label {
                                text: parent.parent.ds === 1
                                      ? (appController ? appController.dataset1Name : "")
                                      : (appController ? appController.dataset2Name : "")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                            Label {
                                text: parent.parent.ds === 1
                                      ? (appController ? appController.dataset1RowCount + " satır • " + appController.dataset1ColumnCount + " sütun" : "")
                                      : (appController ? appController.dataset2RowCount + " satır • " + appController.dataset2ColumnCount + " sütun" : "")
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            // Mapping editor
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(260, 190 + mappingRows.count * 80)
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
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                text: "Sütun Eşleştirmeleri"
                                color: theme.text
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Label {
                                text: "Otomatik benzerlik algoritmasıyla veya manuel olarak sütunları eşleştirip karşılaştırabilirsiniz."
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
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 38
                            text: "+ Manuel Ekle"
                            onClicked: page.addMapping()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 9
                        color: theme.surfaceAlt
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            Label {
                                Layout.fillWidth: true
                                text: "DATASET 1 SÜTUNU"
                                color: "#FF4081"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.preferredWidth: 130 }
                            Label {
                                Layout.fillWidth: true
                                text: "DATASET 2 SÜTUNU"
                                color: "#7C4DFF"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.preferredWidth: 40 }
                        }
                    }

                    Repeater {
                        model: mappingRows
                        delegate: RowLayout {
                            property int rowIndex: index
                            property var itemData: model
                            Layout.fillWidth: true
                            spacing: 10

                            ComboBox {
                                id: sourceCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                model: page.columnModel(1)
                                textRole: "name"
                                Component.onCompleted: {
                                    if (itemData.sourceColumn && itemData.sourceColumn !== "") {
                                        for (var k = 0; k < count; ++k) {
                                            if (textAt(k) === itemData.sourceColumn) {
                                                currentIndex = k
                                                break
                                            }
                                        }
                                    }
                                }
                                onActivated:
                                    mappingRows.setProperty(rowIndex, "sourceColumn", currentText)
                            }

                            // Similarity Badge
                            Rectangle {
                                Layout.preferredWidth: 130
                                Layout.preferredHeight: 32
                                radius: 16
                                color: itemData.similarityScore > 75 ? "#E6F6EE" : (itemData.similarityScore > 40 ? "#FFF4E5" : theme.surfaceAlt)
                                border.color: itemData.similarityScore > 75 ? "#00E676" : (itemData.similarityScore > 40 ? "#FFAB00" : theme.border)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Label {
                                        text: itemData.similarityScore > 0 ? "⚡ %" + itemData.similarityScore : "↔"
                                        color: itemData.similarityScore > 75 ? "#00C853" : (itemData.similarityScore > 40 ? "#FF8F00" : theme.primary)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Label {
                                        visible: itemData.similarityScore > 0
                                        text: "Eşleşme"
                                        color: theme.textSecondary
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            ComboBox {
                                id: targetCombo
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                model: page.columnModel(2)
                                textRole: "name"
                                Component.onCompleted: {
                                    if (itemData.targetColumn && itemData.targetColumn !== "") {
                                        for (var k = 0; k < count; ++k) {
                                            if (textAt(k) === itemData.targetColumn) {
                                                currentIndex = k
                                                break
                                            }
                                        }
                                    }
                                }
                                onActivated:
                                    mappingRows.setProperty(rowIndex, "targetColumn", currentText)
                            }

                            Button {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                text: "×"
                                onClicked: page.removeMapping(rowIndex)
                            }
                        }
                    }

                    Label {
                        visible: mappingRows.count === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        text: "Henüz eşleştirme yok.
'⚡ Otomatik Eşleştirme Öner' butonuna tıklayarak otomatik benzerlikleri bulabilir veya '+ Manuel Ekle' ile seçebilirsiniz."
                        color: theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: validMappingCount() + " geçerli eşleştirme"
                            color: theme.textSecondary
                            font.pixelSize: 12
                        }
                        Button {
                            Layout.preferredWidth: 220
                            Layout.preferredHeight: 42
                            enabled: validMappingCount() > 0
                            text: "📊 Karşılaştırmayı Başlat →"
                            onClicked: page.runComparison()
                        }
                    }
                }
            }

            // Dataset-level summary cards
            Rectangle {
                visible: page.comparisonAvailable
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 140
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    columns: 4
                    columnSpacing: 12
                    rowSpacing: 10

                    Repeater {
                        model: [
                            { t: "Karşılaştırılan Alan", k: "matchedColumnCount", c: "#FF4081" },
                            { t: "Karşılaştırılan Kayıt", k: "comparedRecordCount", c: "#7C4DFF" },
                            { t: "Fark Bulunan Kayıt", k: "differentRecordCount", c: "#FF6E40" },
                            { t: "Fark Oranı", k: "differencePercentage", c: "#00E5FF" }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 88
                            radius: 10
                            color: theme.surfaceAlt
                            border.color: theme.border
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 3
                                Label {
                                    text: modelData.t
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }
                                Label {
                                    text: modelData.k === "differencePercentage"
                                          ? Number(page.comparisonResult[modelData.k] || 0).toFixed(2) + "%"
                                          : String(page.comparisonResult[modelData.k] || 0)
                                    color: modelData.c
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            // Per-pair results + Integrated Comparison Chart
            RowLayout {
                visible: page.comparisonAvailable
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                // Left: Pair Selection List
                Rectangle {
                    Layout.preferredWidth: 420
                    Layout.preferredHeight: 460
                    radius: 16
                    color: theme.surface
                    border.color: theme.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Label {
                            text: "Eşleştirme Listesi"
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ColumnLayout {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: page.comparisonResult.results || []
                                    delegate: Rectangle {
                                        property int rIdx: index
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 94
                                        radius: 10
                                        color: page.selectedComparisonIndex === rIdx
                                               ? (theme.darkMode ? "#2D1E3A" : "#F8EBF7")
                                               : theme.surfaceAlt
                                        border.color: page.selectedComparisonIndex === rIdx
                                                      ? "#FF4081"
                                                      : theme.border
                                        border.width: page.selectedComparisonIndex === rIdx ? 2 : 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                page.selectedComparisonIndex = rIdx
                                                compCanvas.requestPaint()
                                            }
                                        }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Label {
                                                    text: modelData.sourceColumn + " ↔ " + modelData.targetColumn
                                                    color: theme.text
                                                    font.pixelSize: 13
                                                    font.bold: true
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideMiddle
                                                }
                                                Rectangle {
                                                    Layout.preferredHeight: 20
                                                    Layout.preferredWidth: 60
                                                    radius: 10
                                                    color: "#FF4081"
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: "%" + Number(modelData.differencePercentage || 0).toFixed(1) + " F"
                                                        color: "#FFFFFF"
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            Label {
                                                text: "Ortak: " + modelData.comparedRecords + " • Fark: " + modelData.differentRecords
                                                color: theme.textSecondary
                                                font.pixelSize: 11
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
                        }
                    }
                }

                // Right: Integrated Comparative Chart ("Kız Neşesi / Canlı Renkler")
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 460
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
                            spacing: 8

                            Label {
                                property var curr: (page.comparisonResult.results && page.comparisonResult.results.length > page.selectedComparisonIndex)
                                                   ? page.comparisonResult.results[page.selectedComparisonIndex]
                                                   : null
                                text: curr ? "Karşılaştırma Grafiği: " + curr.sourceColumn + " (D1) vs " + curr.targetColumn + " (D2)" : "Karşılaştırma Grafiği"
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            // Legend pills
                            RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 12; height: 12; radius: 6; color: "#FF4081"
                                }
                                Label { text: "Dataset 1"; color: theme.text; font.pixelSize: 11; font.bold: true }

                                Rectangle {
                                    width: 12; height: 12; radius: 6; color: "#7C4DFF"
                                }
                                Label { text: "Dataset 2"; color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                        }

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

                                // Metrics to compare
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

                                    // Gradient 1: Vibrant Sunset Magenta/Pink (#FF4081 -> #FF80AB)
                                    var grad1 = ctx.createLinearGradient(b1X, b1Y, b1X, height - padB)
                                    grad1.addColorStop(0, "#FF4081")
                                    grad1.addColorStop(1, "#FF80AB")
                                    ctx.fillStyle = grad1
                                    ctx.fillRect(b1X, b1Y, b1W, height - padB - b1Y)

                                    // Gradient 2: Vibrant Purple/Cyan (#7C4DFF -> #00E5FF)
                                    var grad2 = ctx.createLinearGradient(b2X, b2Y, b2X, height - padB)
                                    grad2.addColorStop(0, "#7C4DFF")
                                    grad2.addColorStop(1, "#00E5FF")
                                    ctx.fillStyle = grad2
                                    ctx.fillRect(b2X, b2Y, b1W, height - padB - b2Y)

                                    // Değer etiketleri
                                    ctx.fillStyle = theme.text
                                    ctx.font = "bold 11px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText(Number(val).toFixed(2), grpX + groupW / 2, Math.min(b1Y, b2Y) - 10)

                                    // Grup Etiketi
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "11px sans-serif"
                                    ctx.fillText(metrics[i].name, grpX + groupW / 2, height - padB + 20)
                                }
                            }
                        }
                    }
                }
            }

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
