import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    property int activeDs: 1 // 1 for Dataset 1, 2 for Dataset 2
    property string outlierMethod: "IQR"
    property double outlierParam: 1.5
    property string bulkMissingAction: "Mean (Ortalama)"
    property string bulkOutlierAction: "Aykırıları kaldır"

    ListModel { id: missingModel }
    ListModel { id: duplicateModel }
    ListModel { id: outlierModel }
    ListModel { id: constantModel }
    ListModel { id: logModel }

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

    function quality(ds) {
        return ds === 1 ? (appController ? appController.dataset1QualityResult : ({}))
                        : (appController ? appController.dataset2QualityResult : ({}))
    }

    function isColumnNumeric(ds, colName) {
        if (!appController) return false
        var colModel = ds === 1 ? appController.dataset1ColumnModel : appController.dataset2ColumnModel
        if (!colModel) return false
        return colModel.isColumnNumeric(colName)
    }

    function log(msg, ok) {
        var time = Qt.formatTime(new Date(), "hh:mm:ss")
        logModel.insert(0, { message: "[" + time + "] " + (ok ? "✓ " : "✕ ") + msg, success: ok })
    }

    function refreshAnalysis() {
        if (!appController) return
        var ds = page.activeDs
        if (page.isLoaded(ds)) {
            if (ds === 1) {
                appController.analyzeDataset1Quality()
                appController.analyzeDataset1OutliersAllColumns(page.outlierMethod, page.outlierParam)
            } else {
                appController.analyzeDataset2Quality()
                appController.analyzeDataset2OutliersAllColumns(page.outlierMethod, page.outlierParam)
            }
        }
        rebuildLists()
    }

    function rebuildLists() {
        missingModel.clear()
        duplicateModel.clear()
        outlierModel.clear()
        constantModel.clear()

        if (!appController || !page.isLoaded(page.activeDs)) return

        var ds = page.activeDs
        var q = quality(ds)

        // 1. Missing columns & rows
        var missingCols = q.columnsWithMissing || []
        for (var i = 0; i < missingCols.length; ++i) {
            var col = String(missingCols[i])
            var isNum = isColumnNumeric(ds, col)
            missingModel.append({
                columnName: col,
                isNumeric: isNum,
                action: isNum ? "Mean (Ortalama)" : "Mode (Mod)"
            })
        }

        // Missing rows summary
        if (missingCols.length > 0) {
            missingModel.append({
                columnName: "Tüm Eksik Değerli Satırlar",
                isNumeric: false,
                action: "Satırları kaldır"
            })
        }

        // 2. Duplicate rows
        var dupCount = Number(q.duplicateRowCount || 0)
        if (dupCount > 0) {
            duplicateModel.append({
                title: "Tekrarlanan Kayıtlar (" + dupCount + " adet)",
                count: dupCount
            })
        }

        // 3. Constant columns
        var consts = q.constantColumns || []
        for (var j = 0; j < consts.length; ++j) {
            constantModel.append({
                columnName: String(consts[j])
            })
        }

        // 4. Outliers
        var out = ds === 1 ? appController.dataset1OutlierResult : appController.dataset2OutlierResult
        var outCols = out && out.columns ? out.columns : []
        for (var k = 0; k < outCols.length; ++k) {
            var oc = outCols[k]
            var outCount = Number(oc.outlierCount || 0)
            if (outCount > 0) {
                outlierModel.append({
                    columnName: String(oc.columnName),
                    outlierCount: outCount,
                    percentage: Number(oc.outlierPercentage || 0).toFixed(2),
                    action: "Aykırıları kaldır"
                })
            }
        }
    }

    // --- Actions ---

    function applySingleMissing(index) {
        if (index < 0 || index >= missingModel.count) return
        var item = missingModel.get(index)
        if (!item) return
        var ds = page.activeDs
        var ok = false
        var act = String(item.action || "")

        if (item.columnName === "Tüm Eksik Değerli Satırlar" || act.indexOf("Satır") !== -1 || act === "Sil") {
            ok = ds === 1 ? appController.removeDataset1MissingRows() : appController.removeDataset2MissingRows()
            log("Dataset " + ds + " • Eksik Değerli Satırlar kaldırıldı.", ok)
        } else if (act.indexOf("Mean") !== -1 || act.indexOf("Ortalama") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMean(item.columnName) : appController.fillDataset2MissingWithMean(item.columnName)
            log("Dataset " + ds + " • " + item.columnName + " ortalama (Mean) ile dolduruldu.", ok)
        } else if (act.indexOf("Median") !== -1 || act.indexOf("Medyan") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMedian(item.columnName) : appController.fillDataset2MissingWithMedian(item.columnName)
            log("Dataset " + ds + " • " + item.columnName + " medyan ile dolduruldu.", ok)
        } else if (act.indexOf("Mode") !== -1 || act.indexOf("Mod") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMode(item.columnName) : appController.fillDataset2MissingWithMode(item.columnName)
            log("Dataset " + ds + " • " + item.columnName + " mod ile dolduruldu.", ok)
        } else if (act === "Atla") {
            log("Dataset " + ds + " • " + item.columnName + " atlandı.", true)
        }

        refreshAnalysis()
    }

    function applyBulkMissing() {
        var ds = page.activeDs
        var act = page.bulkMissingAction
        if (act.indexOf("Satır") !== -1 || act === "Sil") {
            var ok = ds === 1 ? appController.removeDataset1MissingRows() : appController.removeDataset2MissingRows()
            log("Dataset " + ds + " • Tüm eksik değerli satırlar kaldırıldı.", ok)
        } else {
            var q = quality(ds)
            var missingCols = q.columnsWithMissing || []
            for (var i = 0; i < missingCols.length; ++i) {
                var col = String(missingCols[i])
                var isNum = isColumnNumeric(ds, col)
                if ((act.indexOf("Mean") !== -1 || act.indexOf("Ortalama") !== -1) && isNum) {
                    if (ds === 1) appController.fillDataset1MissingWithMean(col); else appController.fillDataset2MissingWithMean(col)
                } else if ((act.indexOf("Median") !== -1 || act.indexOf("Medyan") !== -1) && isNum) {
                    if (ds === 1) appController.fillDataset1MissingWithMedian(col); else appController.fillDataset2MissingWithMedian(col)
                } else if (act.indexOf("Mode") !== -1 || act.indexOf("Mod") !== -1) {
                    if (ds === 1) appController.fillDataset1MissingWithMode(col); else appController.fillDataset2MissingWithMode(col)
                }
            }
            log("Dataset " + ds + " • Tüm eksik sütunlar '" + act + "' ile dolduruldu.", true)
        }
        refreshAnalysis()
    }

    function applyRemoveDuplicates() {
        var ds = page.activeDs
        var ok = ds === 1 ? appController.removeDataset1Duplicates() : appController.removeDataset2Duplicates()
        log("Dataset " + ds + " • Tekrarlanan kayıtlar kaldırıldı.", ok)
        refreshAnalysis()
    }

    function mapOutlierAction(actionName) {
        if (actionName.indexOf("Mean") !== -1 || actionName.indexOf("Ortalama") !== -1) return "Mean"
        if (actionName.indexOf("Median") !== -1 || actionName.indexOf("Medyan") !== -1) return "Median"
        if (actionName.indexOf("Mode") !== -1 || actionName.indexOf("Mod") !== -1) return "Mode"
        if (actionName.indexOf("Cap") !== -1 || actionName.indexOf("Sınırla") !== -1) return "Cap"
        return "Remove"
    }

    function applySingleOutlier(index) {
        if (index < 0 || index >= outlierModel.count) return
        var item = outlierModel.get(index)
        if (!item) return
        var ds = page.activeDs
        var backendAction = mapOutlierAction(item.action)

        var ok = ds === 1
            ? appController.applyDataset1OutlierAction(item.columnName, page.outlierMethod, backendAction, page.outlierParam)
            : appController.applyDataset2OutlierAction(item.columnName, page.outlierMethod, backendAction, page.outlierParam)

        log("Dataset " + ds + " • " + item.columnName + " (" + item.action + " - " + page.outlierMethod + ").", ok)
        refreshAnalysis()
    }

    function applyBulkOutliers() {
        var ds = page.activeDs
        var total = outlierModel.count
        var successCount = 0
        var backendAction = mapOutlierAction(page.bulkOutlierAction)

        for (var i = 0; i < outlierModel.count; ++i) {
            var rowItem = outlierModel.get(i)
            if (!rowItem) continue
            var col = rowItem.columnName
            var ok = ds === 1
                ? appController.applyDataset1OutlierAction(col, page.outlierMethod, backendAction, page.outlierParam)
                : appController.applyDataset2OutlierAction(col, page.outlierMethod, backendAction, page.outlierParam)
            if (ok) successCount++
        }

        log("Dataset " + ds + " • " + successCount + "/" + total + " sütunun aykırı değerleri '" + page.bulkOutlierAction + "' ile temizlendi.", successCount > 0)
        refreshAnalysis()
    }

    function applyRemoveConstant(colName) {
        var ds = page.activeDs
        var ok = ds === 1 ? appController.removeDataset1Column(colName) : appController.removeDataset2Column(colName)
        log("Dataset " + ds + " • Sabit sütun '" + colName + "' kaldırıldı.", ok)
        refreshAnalysis()
    }

    function restoreDataset() {
        var ds = page.activeDs
        var ok = ds === 1 ? appController.restoreDataset1() : appController.restoreDataset2()
        if (ok) {
            log("↶ Dataset " + ds + " orijinal haline sıfırlandı.", true)
            refreshAnalysis()
        }
    }

    Component.onCompleted: {
        refreshAnalysis()
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // Dataset Selector & Restore Row
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 70
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Label {
                        text: "Aktif Veri Seti:"
                        color: theme.text
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Button {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        text: "Dataset 1: " + page.name(1)
                        highlighted: page.activeDs === 1
                        enabled: page.isLoaded(1)
                        onClicked: {
                            page.activeDs = 1
                            page.refreshAnalysis()
                        }
                    }

                    Button {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        text: "Dataset 2: " + page.name(2)
                        highlighted: page.activeDs === 2
                        enabled: page.isLoaded(2)
                        onClicked: {
                            page.activeDs = 2
                            page.refreshAnalysis()
                        }
                    }

                    Rectangle {
                        property bool isMod: page.activeDs === 1
                            ? (page.appController && page.appController.dataset1Modified)
                            : (page.appController && page.appController.dataset2Modified)
                        visible: isMod
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: 100
                        radius: 14
                        color: "#E6F6EE"
                        border.width: 1
                        border.color: theme.success

                        Label {
                            anchors.centerIn: parent
                            text: "✓ Temizlendi"
                            color: theme.success
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 38
                        text: "↶ Orijinale Sıfırla"
                        onClicked: page.restoreDataset()
                    }
                }
            }

            // Category 1: Missing Values & Duplicates
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(140, 95 + (missingModel.count + duplicateModel.count) * 58)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Label {
                            text: "🧩 Eksik Değerler & Tekrarlanan Kayıtlar"
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }

                        ComboBox {
                            visible: missingModel.count > 0
                            Layout.preferredWidth: 190
                            Layout.preferredHeight: 34
                            model: ["Mean (Ortalama)", "Median (Medyan)", "Mode (Mod)", "Satırları kaldır (Sil)"]
                            onActivated: page.bulkMissingAction = currentText
                        }

                        Button {
                            visible: missingModel.count > 0
                            Layout.preferredWidth: 190
                            Layout.preferredHeight: 34
                            text: "⚡ Tüm Eksikleri Uygula"
                            onClicked: page.applyBulkMissing()
                        }
                    }

                    // Duplicates
                    Repeater {
                        model: duplicateModel
                        delegate: Rectangle {
                            property string rowTitle: (model && model.title !== undefined) ? model.title : ""
                            visible: rowTitle !== ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: "⧉ " + rowTitle
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                }
                                Button {
                                    Layout.preferredWidth: 140
                                    Layout.preferredHeight: 32
                                    text: "Kayıtları Kaldır"
                                    onClicked: page.applyRemoveDuplicates()
                                }
                            }
                        }
                    }

                    // Missing Columns
                    Repeater {
                        model: missingModel
                        delegate: Rectangle {
                            property int rowIndex: index
                            property string colName: (model && model.columnName !== undefined) ? model.columnName : ""
                            property bool isNum: (model && model.isNumeric !== undefined) ? model.isNumeric : false
                            property string actName: (model && model.action !== undefined) ? model.action : "Mean (Ortalama)"
                            visible: colName !== ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: "! " + colName
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }

                                ComboBox {
                                    id: missingCombo
                                    visible: colName !== "Tüm Eksik Değerli Satırlar"
                                    Layout.preferredWidth: 175
                                    Layout.preferredHeight: 34
                                    model: isNum
                                           ? ["Mean (Ortalama)", "Median (Medyan)", "Mode (Mod)", "Satırları kaldır", "Atla"]
                                           : ["Mode (Mod)", "Satırları kaldır", "Atla"]
                                    currentIndex: Math.max(0, model.indexOf(actName))
                                    onActivated: {
                                        if (rowIndex >= 0 && rowIndex < missingModel.count) {
                                            missingModel.setProperty(rowIndex, "action", currentText)
                                        }
                                    }
                                }

                                Button {
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 34
                                    text: "▶ Uygula"
                                    onClicked: page.applySingleMissing(rowIndex)
                                }
                            }
                        }
                    }

                    Label {
                        visible: missingModel.count === 0 && duplicateModel.count === 0
                        text: "✓ Bu veri setinde eksik değer veya tekrarlanan kayıt bulunmuyor."
                        color: theme.success
                        font.pixelSize: 12
                    }
                }
            }

            // Category 2: Outliers (Aykırı Değerler)
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(160, 110 + outlierModel.count * 58)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Label {
                            text: "⚡ Aykırı Değerler (Outliers)"
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label { text: "Yöntem:"; color: theme.textSecondary; font.pixelSize: 11 }
                        ComboBox {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 32
                            model: ["IQR (1.5)", "IQR (3.0)", "Z-Score (3.0)"]
                            onActivated: {
                                if (currentIndex === 0) { page.outlierMethod = "IQR"; page.outlierParam = 1.5 }
                                else if (currentIndex === 1) { page.outlierMethod = "IQR"; page.outlierParam = 3.0 }
                                else if (currentIndex === 2) { page.outlierMethod = "Z-Score"; page.outlierParam = 3.0 }
                                page.refreshAnalysis()
                            }
                        }

                        ComboBox {
                            visible: outlierModel.count > 0
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 32
                            model: ["Aykırıları kaldır", "Mean (Ortalama)", "Median (Medyan)", "Mode (Mod)", "Sınırla (Cap)"]
                            onActivated: page.bulkOutlierAction = currentText
                        }

                        Button {
                            visible: outlierModel.count > 0
                            Layout.preferredWidth: 190
                            Layout.preferredHeight: 34
                            text: "⚡ Tüm Aykırıları Uygula"
                            onClicked: page.applyBulkOutliers()
                        }
                    }

                    Repeater {
                        model: outlierModel
                        delegate: Rectangle {
                            property int outIndex: index
                            property string outColName: (model && model.columnName !== undefined) ? model.columnName : ""
                            property string outCountStr: (model && model.outlierCount !== undefined) ? String(model.outlierCount) : "0"
                            property string outPctStr: (model && model.percentage !== undefined) ? String(model.percentage) : "0"
                            property string outActionStr: (model && model.action !== undefined) ? model.action : "Aykırıları kaldır"
                            visible: outColName !== ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: "△ " + outColName
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.preferredWidth: 190
                                    elide: Text.ElideMiddle
                                }

                                Label {
                                    text: outCountStr + " aykırı değer (% " + outPctStr + ")"
                                    color: "#FF6E40"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }

                                ComboBox {
                                    id: outlierActionCombo
                                    Layout.preferredWidth: 175
                                    Layout.preferredHeight: 34
                                    model: ["Aykırıları kaldır", "Mean (Ortalama)", "Median (Medyan)", "Mode (Mod)", "Sınırla (Cap)"]
                                    currentIndex: Math.max(0, model.indexOf(outActionStr))
                                    onActivated: {
                                        if (outIndex >= 0 && outIndex < outlierModel.count) {
                                            outlierModel.setProperty(outIndex, "action", currentText)
                                        }
                                    }
                                }

                                Button {
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 34
                                    text: "▶ Uygula"
                                    onClicked: page.applySingleOutlier(outIndex)
                                }
                            }
                        }
                    }

                    Label {
                        visible: outlierModel.count === 0
                        text: "✓ Bu veri setinde (" + page.outlierMethod + ") yöntemiyle belirlenen aykırı değer bulunmuyor."
                        color: theme.success
                        font.pixelSize: 12
                    }
                }
            }

            // Category 3: Constant Columns
            Rectangle {
                visible: constantModel.count > 0
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(120, 80 + constantModel.count * 52)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Label {
                        text: "🗑️ Sabit Değerli Sütunlar"
                        color: theme.text
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Repeater {
                        model: constantModel
                        delegate: Rectangle {
                            property string constCol: (model && model.columnName !== undefined) ? model.columnName : ""
                            visible: constCol !== ""
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: "C • " + constCol + " (Tek bir sabit değer içeriyor)"
                                    color: theme.text
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                                Button {
                                    Layout.preferredWidth: 130
                                    Layout.preferredHeight: 32
                                    text: "Sütunu Kaldır"
                                    onClicked: page.applyRemoveConstant(constCol)
                                }
                            }
                        }
                    }
                }
            }

            // Live Log Console (ScrollView with full history)
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 200
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
                        Label {
                            text: "Canlı Temizleme Günlüğü (Log)"
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 28
                            text: "Temizle"
                            onClicked: logModel.clear()
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: logView
                            model: logModel
                            spacing: 4
                            delegate: RowLayout {
                                width: logView.width
                                spacing: 8
                                Label {
                                    text: (model && model.message !== undefined) ? model.message : ""
                                    color: (model && model.success) ? theme.success : theme.error
                                    font.pixelSize: 12
                                    font.family: "Consolas, monospace"
                                }
                            }
                        }
                    }

                    Label {
                        visible: logModel.count === 0
                        text: "Henüz bir temizleme işlemi uygulanmadı."
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }
                }
            }

            // Next Step Card
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 80
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
                            text: "Sonraki Adım: Karşılaştırma veya Görselleştirme"
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: "Temizlenen verileri karşılaştırabilir veya görselleştirme sayfasında grafiklerini çıkarabilirsiniz."
                            color: theme.textSecondary
                            font.pixelSize: 12
                        }
                    }
                    Button {
                        Layout.preferredWidth: 180
                        Layout.preferredHeight: 38
                        text: "Karşılaştırmaya Geç →"
                        onClicked: {
                            if (appController)
                                appController.setCleaningCompleted(true)
                            page.goToPage(4)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
