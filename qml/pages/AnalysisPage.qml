import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../" as AppTheme

Item {
    id: page

    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    property string dataset1Column: ""
    property string dataset2Column: ""

    property int outlierDataset: 1
    property string outlierMethod: "IQR"
    property double outlierParameter: 1.5

    property string analysisError: ""

    function goToPage(index) {
        if (page.mainWindow)
            page.mainWindow.currentPage = index
    }

    function loaded(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1Name !== ""
                : page.appController.dataset2Name !== ""
    }

    function name(dataset) {
        if (!page.appController)
            return "Yüklenmedi"

        return dataset === 1
                ? page.appController.dataset1Name
                : page.appController.dataset2Name
    }

    function rows(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1RowCount
                : page.appController.dataset2RowCount
    }

    function columns(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1ColumnCount
                : page.appController.dataset2ColumnCount
    }

    function columnModel(dataset) {
        if (!page.appController)
            return null

        return dataset === 1
                ? page.appController.dataset1ColumnModel
                : page.appController.dataset2ColumnModel
    }

    function edaAvailable(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1EdaAvailable
                : page.appController.dataset2EdaAvailable
    }

    function edaResult(dataset) {
        if (!page.appController)
            return {}

        return dataset === 1
                ? page.appController.dataset1EdaResult
                : page.appController.dataset2EdaResult
    }

    function outlierAvailable(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1OutlierAvailable
                : page.appController.dataset2OutlierAvailable
    }

    function outlierResult(dataset) {
        if (!page.appController)
            return {}

        return dataset === 1
                ? page.appController.dataset1OutlierResult
                : page.appController.dataset2OutlierResult
    }

    function outlierMethodText(dataset) {
        var result = page.outlierResult(dataset)
        if (result && result.method)
            return String(result.method)
        return page.outlierMethod
    }

    function selectedColumn(dataset) {
        return dataset === 1
                ? page.dataset1Column
                : page.dataset2Column
    }

    function setAnalysisError(message) {
        page.analysisError = message || ""
        if (page.analysisError !== "") {
            errorPopup.open()
        }
    }

    function runQualityAnalysis(dataset) {
        if (!page.appController || !page.loaded(dataset))
            return

        if (dataset === 1)
            page.appController.analyzeDataset1Quality()
        else
            page.appController.analyzeDataset2Quality()
    }

    function statValue(dataset, key) {
        var result = page.edaResult(dataset)
        var value = result[key]

        if (value === undefined || value === null)
            return "—"

        if (key === "count")
            return String(value)

        return Number(value).toFixed(3)
    }

    function analyzeEda(dataset) {
        if (!page.appController)
            return

        var column = page.selectedColumn(dataset)

        if (column === "") {
            page.setAnalysisError(
                "İstatistik analizi için önce bir sütun seçmelisiniz."
            )
            return
        }

        page.setAnalysisError("")

        if (dataset === 1)
            page.appController.analyzeDataset1Eda(column)
        else
            page.appController.analyzeDataset2Eda(column)
    }

    function analyzeOutlier() {
        if (!page.appController)
            return

        var parameter = Number(page.outlierParameter)
        if (!isFinite(parameter) || parameter <= 0)
            return

        if (page.outlierDataset === 1) {
            if (typeof page.appController.analyzeDataset1OutliersAllColumns === "function") {
                page.appController.analyzeDataset1OutliersAllColumns(
                    page.outlierMethod,
                    parameter
                )
            }
        } else {
            if (typeof page.appController.analyzeDataset2OutliersAllColumns === "function") {
                page.appController.analyzeDataset2OutliersAllColumns(
                    page.outlierMethod,
                    parameter
                )
            }
        }
    }

    function outlierColumns(dataset) {
        var result = page.outlierResult(dataset)
        if (!result || result.columns === undefined || result.columns === null)
            return []
        return result.columns
    }

    function outlierColumnCount(dataset) {
        return outlierColumns(dataset).length
    }

    function totalOutlierCount(dataset) {
        var result = page.outlierResult(dataset)
        if (!result)
            return 0
        return Number(result.outlierCount || 0)
    }

    function totalOutlierPercentage(dataset) {
        var result = page.outlierResult(dataset)
        if (!result)
            return 0
        return Number(result.outlierPercentage || 0)
    }

    function qualityAvailable(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1QualityAvailable
                : page.appController.dataset2QualityAvailable
    }

    function qualityResult(dataset) {
        if (!page.appController)
            return {}

        return dataset === 1
                ? page.appController.dataset1QualityResult
                : page.appController.dataset2QualityResult
    }

    function qualityValue(dataset, key, fallback) {
        var result = page.qualityResult(dataset)

        if (!result)
            return fallback

        var value = result[key]

        return value === undefined || value === null
                ? fallback
                : value
    }

    function qualityNumber(dataset, key) {
        return Number(page.qualityValue(dataset, key, 0))
    }

    function qualityList(dataset, key) {
        var value = page.qualityValue(dataset, key, [])

        if (!value || typeof value.length === "undefined")
            return []

        return value
    }

    function qualityProblemCount(dataset) {
        if (!page.qualityAvailable(dataset))
            return 0

        var missing =
            page.qualityNumber(dataset, "totalMissingValues")

        var duplicates =
            page.qualityNumber(dataset, "duplicateRowCount")

        var constants =
            page.qualityNumber(dataset, "constantColumnCount")

        var outliers =
            page.outlierAvailable(dataset)
            ? page.totalOutlierCount(dataset)
            : 0

        return missing + duplicates + constants + outliers
    }

    function qualityStatus(dataset) {
        if (!page.qualityAvailable(dataset))
            return "Analiz bekliyor"

        var missing =
            page.qualityNumber(dataset, "totalMissingValues")

        var duplicates =
            page.qualityNumber(dataset, "duplicateRowCount")

        var constants =
            page.qualityNumber(dataset, "constantColumnCount")

        var outliers =
            page.outlierAvailable(dataset)
            ? page.totalOutlierCount(dataset)
            : 0

        return (missing === 0 &&
                duplicates === 0 &&
                constants === 0 &&
                outliers === 0)
                ? "✓ Sorun tespit edilmedi"
                : "⚠ İnceleme gerekli"
    }

    function qualityStatusColor(dataset) {
        if (!page.qualityAvailable(dataset))
            return theme.textSecondary

        return page.qualityProblemCount(dataset) === 0
                ? theme.success
                : theme.warning
    }

    onAppControllerChanged: {
        if (page.appController) {
            if (page.loaded(1) && !page.qualityAvailable(1))
                page.runQualityAnalysis(1)
            if (page.loaded(2) && !page.qualityAvailable(2))
                page.runQualityAnalysis(2)
        }
    }

    Component.onCompleted: {
        if (page.appController) {
            if (page.loaded(1) && !page.qualityAvailable(1))
                page.runQualityAnalysis(1)
            if (page.loaded(2) && !page.qualityAvailable(2))
                page.runQualityAnalysis(2)
        }
    }

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onDataset1Changed() {
            page.runQualityAnalysis(1)
        }

        function onDataset2Changed() {
            page.runQualityAnalysis(2)
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 18

            Item {
                Layout.preferredHeight: 8
            }

            // =================================================
            // DATASET SUMMARY
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        property int dataset: index + 1

                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        radius: 14
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 12
                                color: page.loaded(parent.parent.dataset)
                                       ? theme.primary
                                       : theme.surfaceAlt

                                Label {
                                    anchors.centerIn: parent
                                    text: "D" + parent.parent.parent.dataset
                                    color: page.loaded(parent.parent.parent.dataset)
                                           ? "#FFFFFF"
                                           : theme.textSecondary
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: "DATASET " + parent.parent.parent.dataset
                                    color: theme.primary
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Label {
                                    text: page.loaded(parent.parent.parent.dataset)
                                          ? page.name(parent.parent.parent.dataset)
                                          : "Dosya yüklenmedi"
                                    color: theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.loaded(parent.parent.parent.dataset)
                                          ? page.rows(parent.parent.parent.dataset)
                                            + " satır  •  "
                                            + page.columns(parent.parent.parent.dataset)
                                            + " sütun"
                                          : "Veri seti bekleniyor"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }



            // =================================================
            // TOPLU VERİ KONTROLÜ
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Toplu Veri Kontrolü"
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Veri Kalitesi + Outlier"
                        color: theme.primary
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Label {
                    text: "Temizleme yapmadan önce iki veri setindeki kalite problemlerini tek ekranda kontrol edin."
                    color: theme.textSecondary
                    font.pixelSize: 12
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
                        id: qualityCard

                        property int dataset: index + 1
                        property bool available:
                            page.qualityAvailable(qualityCard.dataset)

                        property int missing:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "totalMissingValues"
                            )

                        property int missingColumns:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "columnsWithMissingValues"
                            )

                        property int duplicates:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "duplicateRowCount"
                            )

                        property int constants:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "constantColumnCount"
                            )

                        property int numeric:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "numericColumnCount"
                            )

                        property int textColumns:
                            page.qualityNumber(
                                qualityCard.dataset,
                                "nonNumericColumnCount"
                            )

                        property int outliers:
                            page.outlierAvailable(qualityCard.dataset)
                            ? page.totalOutlierCount(qualityCard.dataset)
                            : 0

                        Layout.fillWidth: true
                        Layout.preferredHeight: 265

                        radius: 16
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

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
                                        text: "DATASET " + qualityCard.dataset
                                        color: theme.primary
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Label {
                                        text: page.name(qualityCard.dataset)
                                        color: theme.text
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 140
                                    Layout.preferredHeight: 30
                                    radius: 9
                                    color:
                                        !qualityCard.available
                                        ? theme.surfaceAlt
                                        : page.qualityProblemCount(
                                            qualityCard.dataset
                                          ) === 0
                                          ? theme.success
                                          : theme.warning

                                    Label {
                                        anchors.centerIn: parent
                                        text:
                                            !qualityCard.available
                                            ? "BEKLENİYOR"
                                            : page.qualityStatus(
                                                qualityCard.dataset
                                              )
                                        color:
                                            qualityCard.available
                                            ? "#FFFFFF"
                                            : theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            // Ana kalite metrikleri
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: [
                                        { title: "Eksik değer", key: "missing" },
                                        { title: "Duplicate", key: "duplicates" },
                                        { title: "Sabit sütun", key: "constants" },
                                        { title: "Outlier", key: "outliers" }
                                    ]

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 64
                                        radius: 9
                                        color: theme.surfaceAlt
                                        border.width: 1
                                        border.color: theme.border

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 2

                                            Label {
                                                text: modelData.title
                                                color: theme.textSecondary
                                                font.pixelSize: 11
                                            }

                                            Label {
                                                text:
                                                    !qualityCard.available
                                                    ? "—"
                                                    : modelData.key === "missing"
                                                      ? String(
                                                          qualityCard.missing
                                                        )
                                                      : modelData.key === "duplicates"
                                                        ? String(
                                                            qualityCard.duplicates
                                                          )
                                                        : modelData.key === "constants"
                                                          ? String(
                                                              qualityCard.constants
                                                            )
                                                          : page.outlierAvailable(
                                                              qualityCard.dataset
                                                            )
                                                            ? String(
                                                                qualityCard.outliers
                                                              )
                                                            : "—"
                                                color:
                                                    modelData.key === "outliers" &&
                                                    qualityCard.outliers > 0
                                                    ? theme.warning
                                                    : ((modelData.key === "missing" &&
                                                        qualityCard.missing > 0) ||
                                                       (modelData.key === "duplicates" &&
                                                        qualityCard.duplicates > 0) ||
                                                       (modelData.key === "constants" &&
                                                        qualityCard.constants > 0))
                                                      ? theme.warning
                                                      : theme.text
                                                font.pixelSize: 16
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            // Veri yapısı
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 58
                                radius: 9
                                color: theme.surfaceAlt
                                border.width: 1
                                border.color: theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Label {
                                            text: "Sütun yapısı"
                                            color: theme.textSecondary
                                            font.pixelSize: 11
                                        }

                                        Label {
                                            text:
                                                qualityCard.available
                                                ? qualityCard.numeric
                                                  + " sayısal  •  "
                                                  + qualityCard.textColumns
                                                  + " metinsel"
                                                : "—"
                                            color: theme.text
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        color: theme.border
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 120
                                        spacing: 1

                                        Label {
                                            text: "Eksik sütun"
                                            color: theme.textSecondary
                                            font.pixelSize: 11
                                        }

                                        Label {
                                            text:
                                                qualityCard.available
                                                ? String(qualityCard.missingColumns)
                                                : "—"
                                            color:
                                                qualityCard.missingColumns > 0
                                                ? theme.warning
                                                : theme.text
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text:
                                    !qualityCard.available
                                    ? "Kalite analizi henüz çalıştırılmadı."
                                    : qualityCard.outliers > 0
                                      ? "⚠ Outlier sonucu hazır; Veri Temizleme sayfasına aktarılabilir."
                                      : qualityCard.constants > 0
                                        ? "⚠ Sabit sütunlar inceleme için işaretlendi."
                                        : qualityCard.missing > 0
                                          ? "⚠ Eksik değerler temizleme aşamasında yönetilebilir."
                                          : qualityCard.duplicates > 0
                                            ? "⚠ Duplicate kayıtlar temizleme aşamasında yönetilebilir."
                                            : "✓ Bu dataset için mevcut kalite kontrollerinde sorun bulunmadı."
                                color: page.qualityStatusColor(qualityCard.dataset)
                                font.pixelSize: 11
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // Toplu kontrol sonrası temizleme
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 74
                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Label {
                        text: "🧹"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "Kontrolden sonra temizleme"
                            color: theme.text
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Label {
                            text: "Eksik değer, duplicate, sabit sütun ve analiz edilmiş outlier sonuçları Veri Temizleme sayfasında seçerek uygulayabilirsiniz."
                            color: theme.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 38
                        text: "Veri Temizlemeye Git →"

                        enabled:
                            page.qualityAvailable(1) ||
                            page.qualityAvailable(2)

                        onClicked: page.goToPage(3)

                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled
                                   ? "#FFFFFF"
                                   : theme.textSecondary
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: parent.enabled
                                   ? theme.primary
                                   : theme.border
                        }
                    }
                }
            }

            // =================================================
            // SÜTUN KALİTESİ DETAYI
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 4

                Label {
                    text: "Sütun Bazında Kalite Detayı"
                    color: theme.text
                    font.pixelSize: 18
                    font.bold: true
                }

                Label {
                    text: "Her sütunun veri tipi, eksik değer sayısı/yüzdesi ve benzersiz değer sayısı burada görünür."
                    color: theme.textSecondary
                    font.pixelSize: 12
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
                        id: columnQualityCard

                        property int dataset: index + 1

                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        radius: 16
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: "Dataset " + columnQualityCard.dataset
                                    color: theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text:
                                        page.loaded(columnQualityCard.dataset)
                                        ? page.columns(columnQualityCard.dataset)
                                          + " sütun"
                                        : "—"
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 7
                                color: theme.surfaceAlt

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8

                                    Label {
                                        text: "Sütun"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: "Tip"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 75
                                    }

                                    Label {
                                        text: "Eksik"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Label {
                                        text: "Unique"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 60
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 5
                                model: page.columnModel(
                                    columnQualityCard.dataset
                                )

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 34
                                    radius: 7
                                    color:
                                        model.missingCount > 0
                                        ? theme.surfaceAlt
                                        : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 7
                                        spacing: 6

                                        Label {
                                            text: model.name || "—"
                                            color: theme.text
                                            font.pixelSize: 12
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }

                                        Label {
                                            text: model.dataType || "Unknown"
                                            color: theme.textSecondary
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 75
                                        }

                                        Label {
                                            text:
                                                String(model.missingCount || 0)
                                                + " ("
                                                + Number(
                                                    model.missingPercentage || 0
                                                  ).toFixed(1)
                                                + "%)"
                                            color:
                                                Number(model.missingCount || 0) > 0
                                                ? theme.warning
                                                : theme.textSecondary
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 65
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Label {
                                            text: String(model.uniqueCount || 0)
                                            color: theme.text
                                            font.pixelSize: 11
                                            Layout.preferredWidth: 60
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // SIDE-BY-SIDE STATISTICS
            // =================================================

            Label {
                Layout.leftMargin: 28
                text: "Sütun İstatistikleri"
                color: theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Label {
                Layout.leftMargin: 28
                text: "Her veri setinden bir sütun seçerek istatistikleri aynı anda karşılaştırabilirsiniz."
                color: theme.textSecondary
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        id: statisticsCard

                        property int dataset: index + 1
                        property string selectedColumn:
                            dataset === 1
                            ? page.dataset1Column
                            : page.dataset2Column

                        Layout.fillWidth: true
                        Layout.preferredHeight: 430

                        radius: 16
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

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
                                        text: "DATASET " + statisticsCard.dataset
                                        color: theme.primary
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Label {
                                        text: page.loaded(statisticsCard.dataset)
                                              ? page.name(statisticsCard.dataset)
                                              : "Dosya yüklenmedi"
                                        color: theme.text
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                Label {
                                    text: page.edaAvailable(statisticsCard.dataset)
                                          ? "✓ Analiz edildi"
                                          : "Analiz bekliyor"
                                    color: page.edaAvailable(statisticsCard.dataset)
                                           ? theme.success
                                           : theme.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                ComboBox {
                                    id: statisticsColumnCombo

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38

                                    model: page.columnModel(statisticsCard.dataset)
                                    textRole: "name"
                                    enabled: page.loaded(statisticsCard.dataset)

                                    onActivated: {
                                        if (statisticsCard.dataset === 1)
                                            page.dataset1Column = currentText
                                        else
                                            page.dataset2Column = currentText
                                    }
                                }

                                Button {
                                    Layout.preferredWidth: 145
                                    Layout.preferredHeight: 38

                                    text: "İstatistikleri Gör"
                                    enabled: statisticsCard.selectedColumn !== ""

                                    onClicked:
                                        page.analyzeEda(statisticsCard.dataset)

                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.enabled ? "#FFFFFF" : theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        radius: 8
                                        color: parent.enabled
                                               ? theme.primary
                                               : theme.border
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 11
                                color: theme.surfaceAlt
                                border.width: 1
                                border.color: theme.border

                                GridLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    columns: 2
                                    columnSpacing: 10
                                    rowSpacing: 8

                                    Repeater {
                                        model: [
                                            { title: "Count", key: "count" },
                                            { title: "Mean", key: "mean" },
                                            { title: "Median", key: "median" },
                                            { title: "Min", key: "minimum" },
                                            { title: "Max", key: "maximum" },
                                            { title: "Std. Dev.", key: "standardDeviation" },
                                            { title: "Q1", key: "q1" },
                                            { title: "Q3", key: "q3" },
                                            { title: "IQR", key: "iqr" },
                                            { title: "Range", key: "range" }
                                        ]

                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 56
                                            radius: 8
                                            color: theme.surface
                                            border.width: 1
                                            border.color: theme.border

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 2

                                                Label {
                                                    text: modelData.title
                                                    color: theme.textSecondary
                                                    font.pixelSize: 11
                                                }

                                                Label {
                                                    text: page.edaAvailable(statisticsCard.dataset)
                                                          ? page.statValue(
                                                                statisticsCard.dataset,
                                                                modelData.key
                                                            )
                                                          : "—"
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
                    }
                }
            }

            // =================================================
            // OUTLIER ANALYSIS
            // =================================================

            Label {
                Layout.leftMargin: 28
                text: "Aykırı Değer Analizi"
                color: theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Label {
                Layout.leftMargin: 28
                text: "Seçilen yöntem, veri setindeki tüm uygun sayısal sütunlara uygulanır. Sonuçlar Veri Temizleme sayfasına aktarılır."
                color: theme.textSecondary
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 255

                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.preferredWidth: 150
                            spacing: 4

                            Label {
                                text: "Veri seti"
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            ComboBox {
                                id: outlierDatasetCombo
                                Layout.fillWidth: true
                                model: ["Dataset 1", "Dataset 2"]
                                currentIndex: page.outlierDataset - 1

                                onActivated: {
                                    page.outlierDataset = currentIndex + 1
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 150
                            spacing: 4

                            Label {
                                text: "Yöntem"
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            ComboBox {
                                id: methodCombo
                                Layout.fillWidth: true
                                model: ["IQR", "Z-Score"]

                                onActivated: {
                                    page.outlierMethod = currentText
                                    page.outlierParameter =
                                        currentText === "IQR" ? 1.5 : 3.0
                                    parameterField.text =
                                        page.outlierParameter.toString()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text:
                                    page.outlierMethod === "IQR"
                                    ? "IQR katsayısı"
                                    : "Z-Score eşiği"
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            TextField {
                                id: parameterField
                                Layout.fillWidth: true
                                text: page.outlierMethod === "IQR"
                                      ? "1.5"
                                      : "3.0"

                                inputMethodHints: Qt.ImhFormattedNumbersOnly

                                validator: DoubleValidator {
                                    bottom: 0.01
                                    top: 1000.0
                                    decimals: 6
                                    notation: DoubleValidator.StandardNotation
                                }

                                onEditingFinished: {
                                    var value = Number(text)
                                    if (isFinite(value) && value > 0)
                                        page.outlierParameter = value
                                }
                            }
                        }

                        Button {
                            Layout.preferredWidth: 135
                            Layout.preferredHeight: 38
                            text: "Analiz Et"
                            enabled:
                                page.loaded(page.outlierDataset) &&
                                Number(page.outlierParameter) > 0

                            onClicked: page.analyzeOutlier()

                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "#FFFFFF" : theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 8
                                color: parent.enabled
                                       ? theme.primary
                                       : theme.border
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 11
                        color: theme.surfaceAlt

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Label {
                                    text: "Analiz edilen sayısal sütun"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                Label {
                                    text: page.outlierAvailable(page.outlierDataset)
                                          ? String(page.outlierResult(
                                                page.outlierDataset
                                            ).numericColumnCount || 0)
                                          : "—"
                                    color: theme.text
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                Label {
                                    text: page.outlierAvailable(page.outlierDataset)
                                          ? "Sütunların tamamı tarandı"
                                          : "Henüz analiz yapılmadı"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                color: theme.border
                            }

                            ColumnLayout {
                                Layout.preferredWidth: 160
                                spacing: 3

                                Label {
                                    text: "Toplam aykırı değer"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                Label {
                                    text: page.outlierAvailable(page.outlierDataset)
                                          ? String(totalOutlierCount(
                                                page.outlierDataset
                                            ))
                                          : "—"
                                    color: page.outlierAvailable(page.outlierDataset)
                                           && totalOutlierCount(page.outlierDataset) > 0
                                           ? theme.warning
                                           : theme.text
                                    font.pixelSize: 22
                                    font.bold: true
                                }

                                Label {
                                    text: page.outlierAvailable(page.outlierDataset)
                                          ? totalOutlierPercentage(
                                                page.outlierDataset
                                            ).toFixed(2) + "%"
                                          : "Sonuç bekleniyor"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.fillHeight: true
                                color: theme.border
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Label {
                                    text: "Kullanılan kural"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                Label {
                                    text: outlierMethodText(page.outlierDataset)
                                          + " • "
                                          + Number(page.outlierParameter).toFixed(3)
                                    color: theme.primary
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Label {
                                    text: page.outlierMethod === "IQR"
                                          ? "Q1 − katsayı × IQR  /  Q3 + katsayı × IQR"
                                          : "|x − mean| / std. dev. > eşik"
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: page.outlierAvailable(page.outlierDataset)
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight:
                    Math.max(75, 60 + outlierColumnCount(page.outlierDataset) * 34)

                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Label {
                        text: "Sütun bazında sonuçlar"
                        color: theme.text
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Repeater {
                        model: page.outlierColumns(page.outlierDataset)

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                Layout.fillWidth: true
                                text: modelData.columnName || "—"
                                color: theme.text
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideMiddle
                            }

                            Label {
                                text: String(modelData.outlierCount || 0)
                                      + " aykırı"
                                color: Number(modelData.outlierCount || 0) > 0
                                       ? theme.warning
                                       : theme.success
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label {
                                Layout.preferredWidth: 70
                                text: Number(
                                    modelData.outlierPercentage || 0
                                ).toFixed(2) + "%"
                                color: theme.textSecondary
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // =================================================
            // NEXT STEP
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 80

                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "Sonraki adım: Veri Temizleme"
                            color: theme.text
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Label {
                            text: "Eksik değer, duplicate ve bu analizde bulunan tüm aykırı değerleri Veri Temizleme sayfasında seçip tek seferde uygulayın."
                            color: theme.textSecondary
                            font.pixelSize: 11
                        }
                    }

                    Button {
                        Layout.preferredWidth: 165
                        Layout.preferredHeight: 38
                        text: "Veri Temizlemeye Git →"

                        onClicked: page.goToPage(3)

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: theme.primary
                        }
                    }

                    Button {
                        Layout.preferredWidth: 185
                        Layout.preferredHeight: 38
                        text: "Temizlemeyi Atla (Karşılaştır) →"

                        onClicked: {
                            if (appController)
                                appController.skipCleaning()
                            page.goToPage(4)
                        }

                        contentItem: Text {
                            text: parent.text
                            color: theme.text
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: theme.surfaceAlt
                            border.width: 1
                            border.color: theme.border
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }
}
