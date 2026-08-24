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
        return ds === 1 ? appController.dataset1QualityResult
                        : appController.dataset2QualityResult
    }
    function name(ds) {
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

    function rebuild(ds) {
        var m = ds === 1 ? dataset1Problems : dataset2Problems
        m.clear()
        if (!available(ds)) return

        var missing = arr(ds, "columnsWithMissing")
        for (var i = 0; i < missing.length; ++i) {
            m.append({
                type: "missing",
                title: String(missing[i]),
                description: "Bu sütunda eksik değer bulunuyor.",
                action: "Atla"
            })
        }

        if (missing.length > 0) {
            m.append({
                type: "missingRows",
                title: "Eksik değer içeren satırlar",
                description: "Eksik değer bulunan tüm kayıtları kaldırır.",
                action: "Atla"
            })
        }

        if (n(ds, "duplicateRowCount") > 0)
            m.append({
                type: "duplicate",
                title: "Tekrarlanan kayıtlar",
                description: n(ds, "duplicateRowCount") + " duplicate kayıt tespit edildi.",
                action: "Atla"
            })

        var constants = arr(ds, "constantColumns")
        for (var j = 0; j < constants.length; ++j)
            m.append({
                type: "constant",
                title: String(constants[j]),
                description: "Sütunda tek bir benzersiz değer bulunuyor.",
                action: "Atla"
            })

        // Veri Analizi sayfasında tüm sayısal sütunlara uygulanan
        // Outlier sonucunu doğrudan temizleme kuyruğuna aktar.
        var outAvailable = ds === 1
            ? appController.dataset1OutlierAvailable
            : appController.dataset2OutlierAvailable

        if (outAvailable) {
            var out = ds === 1
                ? appController.dataset1OutlierResult
                : appController.dataset2OutlierResult

            var outColumns =
                out && out.columns !== undefined && out.columns !== null
                ? out.columns
                : []

            var outMethod = String(out.method || "IQR")
            var outParameter = Number(
                out.parameter ||
                (outMethod === "IQR" ? 1.5 : 3.0)
            )

            for (var k = 0; k < outColumns.length; ++k) {
                var outColumn = outColumns[k]
                var outCount = Number(outColumn.outlierCount || 0)

                if (outCount <= 0)
                    continue

                m.append({
                    type: "outlier",
                    title: String(outColumn.columnName || "Sayısal sütun"),
                    description:
                        outCount
                        + " aykırı değer bulundu • "
                        + Number(
                            outColumn.outlierPercentage || 0
                        ).toFixed(2)
                        + "% • "
                        + outMethod
                        + " ("
                        + outParameter
                        + ")",
                    action: "Atla",
                    method: outMethod,
                    parameter: outParameter,
                    outlierCount: outCount
                })
            }
        }
    }

    function rebuildAll() {
        applied = false
        rebuild(1)
        rebuild(2)
    }

    function problemCount() {
        return dataset1Problems.count + dataset2Problems.count
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

        // 1. Snapshot actions so mid-loop updates do not mutate iteration
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

        if (ds1Affected && appController.dataset1Name !== "") appController.analyzeDataset1Quality()
        if (ds2Affected && appController.dataset2Name !== "") appController.analyzeDataset2Quality()

        applying = false
        applied = true
        rebuild(1)
        rebuild(2)
    }

    function restore(ds) {
        var ok = ds === 1 ? appController.restoreDataset1()
                           : appController.restoreDataset2()
        if (ok) {
            log("↶ Dataset " + ds + " orijinal çalışma verisine döndürüldü.", true)
            if (ds === 1) appController.analyzeDataset1Quality()
            else appController.analyzeDataset2Quality()
            applied = false
            rebuildAll()
        }
    }

    onAppControllerChanged: rebuildAll()

    Component.onCompleted: rebuildAll()

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onDataset1QualityChanged() {
            if (!page.applying)
                page.rebuildAll()
        }

        function onDataset2QualityChanged() {
            if (!page.applying)
                page.rebuildAll()
        }

        function onDataset1OutlierChanged() {
            if (!page.applying)
                page.rebuildAll()
        }

        function onDataset2OutlierChanged() {
            if (!page.applying)
                page.rebuildAll()
        }

        function onDataset1Changed() {
            if (!page.applying)
                page.rebuildAll()
        }

        function onDataset2Changed() {
            if (!page.applying)
                page.rebuildAll()
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 12

                Button {
                    Layout.preferredWidth: 190
                    Layout.preferredHeight: 36
                    text: "← Veri Analizine Dön"
                    onClicked: page.goToPage(2)
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 90
                radius: 16
                color: theme.surfaceAlt
                border.color: applied ? theme.success : theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 13
                        color: applied ? theme.success : theme.warning

                        Label {
                            anchors.centerIn: parent
                            text: applied ? "✓" : String(problemCount())
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Label {
                            text: applied ? "Temizleme tamamlandı"
                                  : problemCount() + " temizleme adımı hazır"
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Label {
                            text: selectedCount() + " işlem seçildi • Orijinal veri korunur, yalnızca çalışma kopyası değişir."
                            color: theme.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Label {
                        text: selectedCount() + " seçili"
                        color: theme.primary
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }

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
                                        color: theme.primary
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
                                    text: available(card.ds) ? "Analiz edildi" : "Analiz bekleniyor"
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
                                            color: itemData.type === "outlier"
                                                   ? theme.warning
                                                   : theme.primary
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
                                            Layout.preferredWidth: 155
                                            Layout.preferredHeight: 36
                                            model: itemData.type === "missing"
                                                   ? ["Atla", "Mean", "Median", "Mode", "Satırları kaldır"]
                                                   : itemData.type === "missingRows"
                                                     ? ["Atla", "Satırları kaldır"]
                                                     : itemData.type === "duplicate"
                                                       ? ["Atla", "Kayıtları kaldır"]
                                                       : itemData.type === "outlier"
                                                         ? ["Atla", "Aykırıları kaldır"]
                                                         : ["Atla"]
                                            currentIndex: Math.max(0, model.indexOf(itemData.action))
                                            onActivated: {
                                                var a = currentText
                                                card.problems.setProperty(index, "action", a)
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
                                      ? "✓ Bu veri setinde temizlenecek problem yok."
                                      : "Önce Veri Kalitesi ve gerekiyorsa Outlier Analizi çalıştırın."
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
                            text: "Seçimler tek seferde uygulanır. Uygulama sonrasında kalite analizi yeniden hesaplanır."
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

            Rectangle {
                visible: logModel.count > 0
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 64 + logModel.count * 34
                radius: 15
                color: theme.surface
                border.color: theme.border
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    Label {
                        text: "İşlem Geçmişi"
                        color: theme.text
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Repeater {
                        model: logModel
                        delegate: Label {
                            Layout.fillWidth: true
                            text: model.message
                            color: model.success ? theme.success : theme.error
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

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
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { text: "Sonraki adım"; color: theme.textSecondary; font.pixelSize: 11 }
                        Label { text: "Sütun Eşleştirme / Karşılaştırma"; color: theme.text; font.pixelSize: 14; font.bold: true }
                        Label { text: "Temizlenmiş çalışma verisini eşleştirip datasetleri karşılaştırabilirsiniz."; color: theme.textSecondary; font.pixelSize: 11 }
                    }
                    Button {
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 40
                        enabled: applied || problemCount() === 0
                        text: "Eşleştirmeye Geç →"
                        onClicked: page.goToPage(4)
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
