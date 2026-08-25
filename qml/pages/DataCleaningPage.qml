import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow
    property bool applying: false
    property bool applied: false

    ListModel { id: dataset1Problems }
    ListModel { id: dataset2Problems }
    ListModel { id: logModel }

    function goToPage(index) {
        if (mainWindow) mainWindow.currentPage = index
    }

    function available(ds) {
        return appController && (ds === 1
            ? appController.dataset1QualityAvailable
            : appController.dataset2QualityAvailable)
    }
    function quality(ds) {
        return ds === 1 ? (appController ? appController.dataset1QualityResult : ({}))
                        : (appController ? appController.dataset2QualityResult : ({}))
    }
    function name(ds) {
        if (!appController) return "Dataset " + ds
        var n = ds === 1 ? appController.dataset1Name : appController.dataset2Name
        return n && n !== "" ? n : "Dataset " + ds
    }
    function n(ds, key) {
        var r = quality(ds)
        return r[key] === undefined ? 0 : Number(r[key])
    }
    function arr(ds, key) {
        var r = quality(ds)
        return r[key] === undefined || r[key] === null ? [] : r[key]
    }

    function isColumnNumeric(ds, colName) {
        if (!appController) return false
        var colModel = ds === 1 ? appController.dataset1ColumnModel : appController.dataset2ColumnModel
        if (!colModel) return false
        for (var i = 0; i < colModel.count; ++i) {
            var c = colModel.get(i)
            if (c.name === colName) {
                return c.type === "int" || c.type === "double" || c.type === "float" || c.type === "number" || c.isNumeric === true
            }
        }
        return false
    }

    function rebuild(ds) {
        var m = ds === 1 ? dataset1Problems : dataset2Problems
        m.clear()
        if (!appController) return

        if (ds === 1 && appController.dataset1Name !== "") {
            if (!appController.dataset1QualityAvailable) appController.analyzeDataset1Quality()
            if (!appController.dataset1OutlierAvailable) appController.analyzeDataset1OutliersAllColumns("IQR", 1.5)
        } else if (ds === 2 && appController.dataset2Name !== "") {
            if (!appController.dataset2QualityAvailable) appController.analyzeDataset2Quality()
            if (!appController.dataset2OutlierAvailable) appController.analyzeDataset2OutliersAllColumns("IQR", 1.5)
        }

        if (!available(ds)) return

        // 1. Missing columns
        var missing = arr(ds, "columnsWithMissing")
        for (var i = 0; i < missing.length; ++i) {
            var col = String(missing[i])
            var isNum = isColumnNumeric(ds, col)
            m.append({
                type: "missing",
                title: col,
                isNumeric: isNum,
                description: isNum ? "Sayısal sütunda eksik değerler mevcut." : "Metinsel sütunda eksik değerler mevcut.",
                action: "Atla"
            })
        }

        // 2. Missing rows bulk
        if (missing.length > 0) {
            m.append({
                type: "missingRows",
                title: "Eksik değer içeren satırlar",
                isNumeric: false,
                description: "Eksik değer bulunan tüm kayıtları veri setinden kaldırır.",
                action: "Atla"
            })
        }

        // 3. Duplicate rows
        if (n(ds, "duplicateRowCount") > 0) {
            m.append({
                type: "duplicate",
                title: "Tekrarlanan kayıtlar",
                isNumeric: false,
                description: n(ds, "duplicateRowCount") + " adet tekrar eden kayıt tespit edildi.",
                action: "Atla"
            })
        }

        // 4. Constant columns
        var constants = arr(ds, "constantColumns")
        for (var j = 0; j < constants.length; ++j) {
            m.append({
                type: "constant",
                title: String(constants[j]),
                isNumeric: false,
                description: "Sütunda yalnızca tek bir sabit değer bulunuyor.",
                action: "Atla"
            })
        }

        // 5. Outliers
        var outAvailable = ds === 1
            ? appController.dataset1OutlierAvailable
            : appController.dataset2OutlierAvailable

        if (outAvailable) {
            var out = ds === 1
                ? appController.dataset1OutlierResult
                : appController.dataset2OutlierResult

            var outColumns = out && out.columns ? out.columns : []
            var outMethod = String(out.method || "IQR")
            var outParameter = Number(out.parameter || (outMethod === "IQR" ? 1.5 : 3.0))

            for (var k = 0; k < outColumns.length; ++k) {
                var outCol = outColumns[k]
                var outCount = Number(outCol.outlierCount || 0)
                if (outCount > 0) {
                    m.append({
                        type: "outlier",
                        title: String(outCol.columnName || "Sayısal Sütun"),
                        isNumeric: true,
                        description: outCount + " aykırı değer bulundu • %" + Number(outCol.outlierPercentage || 0).toFixed(2) + " (" + outMethod + ")",
                        action: "Atla",
                        method: outMethod,
                        parameter: outParameter
                    })
                }
            }
        }
    }

    function rebuildAll() {
        applied = false
        rebuild(1)
        rebuild(2)
    }

    function selectedCount() {
        var c = 0
        for (var i = 0; i < dataset1Problems.count; ++i)
            if (dataset1Problems.get(i).action !== "Atla") ++c
        for (var j = 0; j < dataset2Problems.count; ++j)
            if (dataset2Problems.get(j).action !== "Atla") ++c
        return c
    }

    function log(text, success) {
        logModel.append({ message: text, success: success })
    }

    function applyAll() {
        if (!appController || applying) return
        var totalSelected = selectedCount()
        if (totalSelected === 0) return

        applying = true
        logModel.clear()

        // 1. Snapshot all actions
        var actionsToRun = []
        for (var i = 0; i < dataset1Problems.count; ++i) {
            var item1 = dataset1Problems.get(i)
            if (item1.action !== "Atla") {
                actionsToRun.push({
                    ds: 1,
                    type: item1.type,
                    title: item1.title,
                    action: item1.action,
                    method: item1.method,
                    parameter: item1.parameter
                })
            }
        }
        for (var j = 0; j < dataset2Problems.count; ++j) {
            var item2 = dataset2Problems.get(j)
            if (item2.action !== "Atla") {
                actionsToRun.push({
                    ds: 2,
                    type: item2.type,
                    title: item2.title,
                    action: item2.action,
                    method: item2.method,
                    parameter: item2.parameter
                })
            }
        }

        var ds1Affected = false
        var ds2Affected = false

        // 2. Execute each action sequentially
        for (var k = 0; k < actionsToRun.length; ++k) {
            var act = actionsToRun[k]
            if (act.ds === 1) ds1Affected = true
            else if (act.ds === 2) ds2Affected = true

            var ok = false
            if (act.type === "missing") {
                if (act.action === "Mean")
                    ok = act.ds === 1 ? appController.fillDataset1MissingWithMean(act.title) : appController.fillDataset2MissingWithMean(act.title)
                else if (act.action === "Median")
                    ok = act.ds === 1 ? appController.fillDataset1MissingWithMedian(act.title) : appController.fillDataset2MissingWithMedian(act.title)
                else if (act.action === "Mode")
                    ok = act.ds === 1 ? appController.fillDataset1MissingWithMode(act.title) : appController.fillDataset2MissingWithMode(act.title)
                else if (act.action === "Satırları kaldır")
                    ok = act.ds === 1 ? appController.removeDataset1MissingRows() : appController.removeDataset2MissingRows()
            } else if (act.type === "missingRows") {
                ok = act.ds === 1 ? appController.removeDataset1MissingRows() : appController.removeDataset2MissingRows()
            } else if (act.type === "duplicate") {
                ok = act.ds === 1 ? appController.removeDataset1Duplicates() : appController.removeDataset2Duplicates()
            } else if (act.type === "constant") {
                ok = act.ds === 1 ? appController.removeDataset1Column(act.title) : appController.removeDataset2Column(act.title)
            } else if (act.type === "outlier") {
                var outMethod = String(act.method || "IQR")
                var outParam = Number(act.parameter || (outMethod === "IQR" ? 1.5 : 3.0))
                ok = act.ds === 1
                    ? appController.applyDataset1OutlierAction(act.title, outMethod, "Remove", outParam)
                    : appController.applyDataset2OutlierAction(act.title, outMethod, "Remove", outParam)
            }

            var detail = act.type === "outlier" ? " (" + String(act.method || "IQR") + ")" : ""
            log((ok ? "✓ " : "✕ ") + "Dataset " + act.ds + " • " + act.title + " → " + act.action + detail, ok)
        }

        // 3. Refresh quality & outlier analysis
        if (ds1Affected && appController.dataset1Name !== "") {
            appController.analyzeDataset1Quality()
            appController.analyzeDataset1OutliersAllColumns("IQR", 1.5)
        }
        if (ds2Affected && appController.dataset2Name !== "") {
            appController.analyzeDataset2Quality()
            appController.analyzeDataset2OutliersAllColumns("IQR", 1.5)
        }

        applying = false
        applied = true
        rebuild(1)
        rebuild(2)
    }

    function restore(ds) {
        if (!appController) return
        var ok = ds === 1 ? appController.restoreDataset1() : appController.restoreDataset2()
        if (ok) {
            log("↶ Dataset " + ds + " orijinal çalışma verisine döndürüldü.", true)
            if (ds === 1) {
                appController.analyzeDataset1Quality()
                appController.analyzeDataset1OutliersAllColumns("IQR", 1.5)
            } else {
                appController.analyzeDataset2Quality()
                appController.analyzeDataset2OutliersAllColumns("IQR", 1.5)
            }
            applied = false
            rebuildAll()
        }
    }

    Component.onCompleted: {
        if (appController) {
            if (appController.dataset1Name !== "") {
                appController.analyzeDataset1Quality()
                appController.analyzeDataset1OutliersAllColumns("IQR", 1.5)
            }
            if (appController.dataset2Name !== "") {
                appController.analyzeDataset2Quality()
                appController.analyzeDataset2OutliersAllColumns("IQR", 1.5)
            }
        }
        rebuildAll()
    }

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onDataset1QualityChanged() { if (!page.applying) page.rebuildAll() }
        function onDataset2QualityChanged() { if (!page.applying) page.rebuildAll() }
        function onDataset1OutlierChanged() { if (!page.applying) page.rebuildAll() }
        function onDataset2OutlierChanged() { if (!page.applying) page.rebuildAll() }
        function onDataset1Changed() { if (!page.applying) page.rebuildAll() }
        function onDataset2Changed() { if (!page.applying) page.rebuildAll() }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // Dataset Cards
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2
                    delegate: Rectangle {
                        id: card
                        property int ds: index + 1
                        property var problems: ds === 1 ? dataset1Problems : dataset2Problems
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(260, 200 + problems.count * 80)
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
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Label {
                                        text: "DATASET " + card.ds
                                        color: card.ds === 1 ? "#FF4081" : "#7C4DFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Label {
                                        text: page.name(card.ds)
                                        color: theme.text
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideMiddle
                                    }
                                }
                                Label {
                                    text: available(card.ds) ? "✓ Analiz Edildi" : "Analiz Bekleniyor"
                                    color: available(card.ds) ? theme.success : theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: card.problems
                                delegate: Rectangle {
                                    property var itemData: model
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 70
                                    radius: 10
                                    color: theme.surfaceAlt
                                    border.color: theme.border
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            radius: 9
                                            color: itemData.type === "outlier" ? "#FF6E40" : (itemData.type === "missing" ? "#FF4081" : theme.primary)
                                            Label {
                                                anchors.centerIn: parent
                                                text: itemData.type === "missing" ? "!" :
                                                      itemData.type === "duplicate" ? "⧉" :
                                                      itemData.type === "outlier" ? "△" : "C"
                                                color: "#FFFFFF"
                                                font.bold: true
                                                font.pixelSize: 13
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Label {
                                                text: itemData.title
                                                color: theme.text
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideMiddle
                                            }
                                            Label {
                                                text: itemData.description
                                                color: theme.textSecondary
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        ComboBox {
                                            id: actionCombo
                                            Layout.preferredWidth: 165
                                            Layout.preferredHeight: 36
                                            model: itemData.type === "missing"
                                                   ? (itemData.isNumeric ? ["Atla", "Mean", "Median", "Mode", "Satırları kaldır"] : ["Atla", "Mode", "Satırları kaldır"])
                                                   : itemData.type === "missingRows"
                                                     ? ["Atla", "Satırları kaldır"]
                                                     : itemData.type === "duplicate"
                                                       ? ["Atla", "Kayıtları kaldır"]
                                                       : itemData.type === "constant"
                                                         ? ["Atla", "Sütunu kaldır"]
                                                         : itemData.type === "outlier"
                                                           ? ["Atla", "Aykırıları kaldır"]
                                                           : ["Atla"]
                                            currentIndex: Math.max(0, model.indexOf(itemData.action))
                                            onActivated: {
                                                var a = currentText
                                                if (index >= 0 && index < card.problems.count) {
                                                    card.problems.setProperty(index, "action", a)
                                                }
                                                page.applied = false
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                visible: card.problems.count === 0
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: available(card.ds)
                                      ? "✓ Bu veri setinde temizlenecek problem bulunmuyor."
                                      : "Önce Veri Kalitesi analizi çalıştırın."
                                color: available(card.ds) ? theme.success : theme.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Button {
                                    Layout.preferredWidth: 140
                                    Layout.preferredHeight: 34
                                    text: "↶ Orijinale Dön"
                                    onClicked: page.restore(card.ds)
                                }
                            }
                        }
                    }
                }
            }

            // Apply Panel
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 84
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
                            text: selectedCount() + " işlem seçildi"
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: "Seçilen bütün işlemler arka yüzde çalışma kopyasına sırayla ve güvenle uygulanır."
                            color: theme.textSecondary
                            font.pixelSize: 11
                        }
                    }
                    Button {
                        Layout.preferredWidth: 230
                        Layout.preferredHeight: 42
                        enabled: !applying && !applied && selectedCount() > 0
                        text: applying ? "Uygulanıyor..." : (applied ? "✓ Temizleme Tamamlandı" : "✓ Seçilen İşlemleri Uygula")
                        onClicked: page.applyAll()
                    }
                }
            }

            // Log Console Panel
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: Math.max(140, 70 + logModel.count * 28)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: "Temizleme Günlüğü (Log)"
                        color: theme.text
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Repeater {
                        model: logModel
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Label {
                                text: model.message
                                color: model.success ? theme.success : theme.error
                                font.pixelSize: 12
                                font.family: "Consolas, monospace"
                            }
                        }
                    }

                    Label {
                        visible: logModel.count === 0
                        text: "Henüz bir işlem uygulanmadı."
                        color: theme.textSecondary
                        font.pixelSize: 12
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
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 38
                        text: "Karşılaştırmaya Geç →"
                        onClicked: page.goToPage(4)
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
