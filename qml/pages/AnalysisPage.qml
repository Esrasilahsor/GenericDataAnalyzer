import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "../" as AppTheme
import "../components" as Components

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
    property bool sessionPromptHandled: false

    function checkSessionRestore() {
        if (page.sessionPromptHandled) return
        if (page.appController &&
            page.appController.sessionRestoreDecision === 0 &&
            page.appController.hasRestorableSession) {
            sessionRestoreDialog.showPrompt(
                qsTr("Restore Session"),
                qsTr("Would you like to restore the last session?"),
                qsTr("Previous analysis results, cleaning operations and visualization settings will be restored.")
            )
        }
    }

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
            return qsTr("Not loaded")

        return dataset === 1
                ? (page.appController.dataset1Name || qsTr("Not loaded"))
                : (page.appController.dataset2Name || qsTr("Not loaded"))
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

    function outlierParameterValue(dataset) {
        var result = page.outlierResult(dataset)
        if (result && result.parameter !== undefined && result.parameter !== null)
            return Number(result.parameter)
        return page.outlierParameter
    }

    function selectedColumn(dataset) {
        return dataset === 1
                ? page.dataset1Column
                : page.dataset2Column
    }

    function setAnalysisError(message) {
        page.analysisError = message || ""
        if (page.analysisError !== "" && page.mainWindow) {
            page.mainWindow.showAlert(
                qsTr("Operation / Analysis Notification"),
                page.analysisError,
                qsTr("A notification or warning occurred during the operation."),
                "warning"
            )
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
                qsTr("You must select a column before running statistical analysis.")
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

        var paramRaw = outlierParameterField ? outlierParameterField.text : String(page.outlierParameter)
        var cleaned = paramRaw.trim().replace(",", ".")
        var parameter = Number(cleaned)
        if (!isFinite(parameter) || parameter <= 0) {
            page.setAnalysisError(
                qsTr("Please enter a valid numeric parameter.")
            )
            return
        }

        page.outlierParameter = parameter
        page.setAnalysisError("")

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

        var hasMissing = (page.qualityNumber(dataset, "totalMissingValues") > 0 ||
                          page.qualityNumber(dataset, "columnsWithMissingValues") > 0) ? 1 : 0

        var hasDuplicates = page.qualityNumber(dataset, "duplicateRowCount") > 0 ? 1 : 0

        var hasConstants = page.qualityNumber(dataset, "constantColumnCount") > 0 ? 1 : 0

        var hasOutliers = 0
        if (page.outlierAvailable(dataset)) {
            hasOutliers = page.totalOutlierCount(dataset) > 0 ? 1 : 0
        } else {
            var qResult = page.qualityResult(dataset)
            if (qResult && (qResult.hasOutliers === true || Number(qResult.outlierCount || 0) > 0)) {
                hasOutliers = 1
            }
        }

        return hasMissing + hasDuplicates + hasConstants + hasOutliers
    }

    function qualityStatus(dataset) {
        if (!page.qualityAvailable(dataset))
            return qsTr("Pending analysis")

        return qualityProblemCount(dataset) === 0
                ? qsTr("✓ No issues detected")
                : qsTr("⚠ Review required")
    }

    function qualityStatusColor(dataset) {
        if (!page.qualityAvailable(dataset))
            return theme.textSecondary

        return page.qualityProblemCount(dataset) === 0
                ? theme.success
                : theme.warning
    }

    onVisibleChanged: {
        if (page.visible) {
            page.checkSessionRestore()
        }
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
        if (page.visible) {
            page.checkSessionRestore()
        }
    }

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onDataset1Changed() {
            page.sessionPromptHandled = false
            page.runQualityAnalysis(1)
        }

        function onDataset2Changed() {
            page.sessionPromptHandled = false
            page.runQualityAnalysis(2)
        }
    }

    ScrollView {
        id: pageScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: pageScrollView.availableWidth
            spacing: 18

            Item {
                Layout.preferredHeight: 8
            }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 2
                title: qsTr("Next step: Data Cleaning")
                subtitle: qsTr("Apply missing value imputation, duplicate removal, constant column drop and analyzed outlier actions in Data Cleaning.")
                buttonText: qsTr("Go to Data Cleaning →")
                buttonVisible: true
                buttonEnabled: page.qualityAvailable(1) || page.qualityAvailable(2)
                onButtonClicked: page.goToPage(3)
                secondaryButtonText: qsTr("Skip to Comparison →")
                secondaryButtonVisible: true
                onSecondaryButtonClicked: {
                    if (appController)
                        appController.skipCleaning()
                    page.goToPage(4)
                }
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
                                    text: qsTr("DATASET %1").arg(parent.parent.parent.dataset)
                                    color: theme.primary
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Label {
                                    text: page.loaded(parent.parent.parent.dataset)
                                          ? page.name(parent.parent.parent.dataset)
                                          : qsTr("No file loaded")
                                    color: theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.loaded(parent.parent.parent.dataset)
                                          ? qsTr("%1 records  •  %2 columns").arg(page.rows(parent.parent.parent.dataset)).arg(page.columns(parent.parent.parent.dataset))
                                          : qsTr("Waiting for dataset")
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
                        text: qsTr("Batch Data Quality & Outlier Check")
                        color: theme.text
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: qsTr("Data Quality + Outliers")
                        color: theme.primary
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Label {
                    text: qsTr("Inspect quality issues and outliers in both datasets on a single screen before cleaning.")
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
                            : (qualityCard.available ? Number(page.qualityValue(qualityCard.dataset, "outlierCount", 0)) : 0)

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
                                        text: qsTr("DATASET %1").arg(qualityCard.dataset)
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
                                            ? qsTr("PENDING")
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
                                        { title: qsTr("Missing values"), key: "missing" },
                                        { title: qsTr("Duplicates"), key: "duplicates" },
                                        { title: qsTr("Constant columns"), key: "constants" },
                                        { title: qsTr("Outliers"), key: "outliers" }
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
                                            text: qsTr("Column structure")
                                            color: theme.textSecondary
                                            font.pixelSize: 11
                                        }

                                        Label {
                                            text:
                                                qualityCard.available
                                                ? qualityCard.numeric
                                                  + qsTr(" numeric  •  ")
                                                  + qualityCard.textColumns
                                                  + qsTr(" text")
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
                                            text: qsTr("Missing columns")
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
                                    ? qsTr("Quality analysis not yet executed.")
                                    : qualityCard.outliers > 0
                                      ? qsTr("⚠ Outlier results ready; can be applied in Data Cleaning.")
                                      : qualityCard.constants > 0
                                        ? qsTr("⚠ Constant columns flagged for review.")
                                        : qualityCard.missing > 0
                                          ? qsTr("⚠ Missing values can be managed in Data Cleaning.")
                                          : qualityCard.duplicates > 0
                                            ? qsTr("⚠ Duplicate records can be managed in Data Cleaning.")
                                            : qsTr("✓ No issues detected in current quality checks.")
                                color: page.qualityStatusColor(qualityCard.dataset)
                                font.pixelSize: 11
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }
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
                    text: qsTr("Column-Level Quality Details")
                    color: theme.text
                    font.pixelSize: 18
                    font.bold: true
                }

                Label {
                    text: qsTr("Inspect data types, missing value count/percentage and unique counts per column.")
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
                                    text: qsTr("Dataset %1").arg(columnQualityCard.dataset)
                                    color: theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text:
                                        page.loaded(columnQualityCard.dataset)
                                        ? qsTr("%1 columns").arg(page.columns(columnQualityCard.dataset))
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
                                        text: qsTr("Column")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: qsTr("Type")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 75
                                    }

                                    Label {
                                        text: qsTr("Missing")
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 65
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Label {
                                        text: qsTr("Unique")
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
                                boundsBehavior: Flickable.StopAtBounds
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
                text: qsTr("Column Statistics")
                color: theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Label {
                Layout.leftMargin: 28
                text: qsTr("Select a column from each dataset to compare their descriptive statistics simultaneously.")
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
                                        text: qsTr("DATASET %1").arg(statisticsCard.dataset)
                                        color: theme.primary
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    Label {
                                        text: page.loaded(statisticsCard.dataset)
                                              ? page.name(statisticsCard.dataset)
                                              : qsTr("No file loaded")
                                        color: theme.text
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }
                                }

                                Label {
                                    text: page.edaAvailable(statisticsCard.dataset)
                                          ? qsTr("✓ Analyzed")
                                          : qsTr("Pending analysis")
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
                                    id: viewStatsBtn
                                    Layout.preferredWidth: 145
                                    Layout.preferredHeight: 38

                                    text: qsTr("View Statistics")
                                    enabled: statisticsCard.selectedColumn !== ""

                                    property bool clickFeedback: false
                                    Timer {
                                        id: viewStatsTimer
                                        interval: 450
                                        onTriggered: viewStatsBtn.clickFeedback = false
                                    }

                                    onClicked: {
                                        clickFeedback = true
                                        viewStatsTimer.restart()
                                        page.analyzeEda(statisticsCard.dataset)
                                    }

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
                                        border.color: viewStatsBtn.clickFeedback ? theme.success : "transparent"
                                        border.width: 1
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
                                            { title: qsTr("Count"), key: "count" },
                                            { title: qsTr("Mean"), key: "mean" },
                                            { title: qsTr("Median"), key: "median" },
                                            { title: qsTr("Min"), key: "minimum" },
                                            { title: qsTr("Max"), key: "maximum" },
                                            { title: qsTr("Std. Dev."), key: "standardDeviation" },
                                            { title: qsTr("Q1"), key: "q1" },
                                            { title: qsTr("Q3"), key: "q3" },
                                            { title: qsTr("IQR"), key: "iqr" },
                                            { title: qsTr("Range"), key: "range" }
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
                text: qsTr("Outlier Analysis")
                color: theme.text
                font.pixelSize: 18
                font.bold: true
            }

            Label {
                Layout.leftMargin: 28
                text: qsTr("The selected method is applied to all eligible numeric columns. Results are passed to the Data Cleaning page.")
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
                                text: qsTr("Dataset")
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            ComboBox {
                                id: outlierDatasetCombo
                                Layout.fillWidth: true
                                model: [qsTr("Dataset 1"), qsTr("Dataset 2")]
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
                                text: qsTr("Method")
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            ComboBox {
                                id: outlierMethodComboBox
                                Layout.fillWidth: true
                                model: ["IQR", "Z-Score"]
                                currentIndex: page.outlierMethod === "Z-Score" ? 1 : 0

                                onActivated: {
                                    page.outlierMethod = currentText
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: qsTr("Parameter")
                                color: theme.textSecondary
                                font.pixelSize: 11
                            }

                            TextField {
                                id: outlierParameterField
                                Layout.fillWidth: true
                                text: page.outlierParameter > 0 ? page.outlierParameter.toString() : "1.5"

                                inputMethodHints: Qt.ImhFormattedNumbersOnly

                                validator: DoubleValidator {
                                    bottom: 0.01
                                    top: 100.0
                                    decimals: 4
                                    notation: DoubleValidator.StandardNotation
                                }

                                onTextChanged: {
                                    var cleaned = text.trim().replace(",", ".")
                                    var value = Number(cleaned)
                                    if (isFinite(value) && value > 0)
                                        page.outlierParameter = value
                                }

                                onAccepted: {
                                    if (analyzeOutlierBtn.enabled)
                                        analyzeOutlierBtn.clicked()
                                }
                            }
                        }

                        Button {
                            id: analyzeOutlierBtn
                            Layout.preferredWidth: 135
                            Layout.preferredHeight: 38
                            text: qsTr("Analyze")
                            enabled:
                                page.loaded(page.outlierDataset) &&
                                Number(String(outlierParameterField.text).trim().replace(",", ".")) > 0

                            property bool clickFeedback: false
                            Timer {
                                id: analyzeOutlierTimer
                                interval: 450
                                onTriggered: analyzeOutlierBtn.clickFeedback = false
                            }

                            onClicked: {
                                clickFeedback = true
                                analyzeOutlierTimer.restart()
                                page.analyzeOutlier()
                            }

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
                                border.color: analyzeOutlierBtn.clickFeedback ? theme.success : "transparent"
                                border.width: 1
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
                                    text: qsTr("Analyzed numeric columns")
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
                                          ? qsTr("All columns scanned")
                                          : qsTr("No analysis yet")
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
                                    text: qsTr("Total outliers")
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
                                          : qsTr("Awaiting result")
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
                                    text: qsTr("Rule applied")
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                Label {
                                    text: page.outlierAvailable(page.outlierDataset)
                                          ? (outlierMethodText(page.outlierDataset)
                                             + " • "
                                             + Number(outlierParameterValue(page.outlierDataset)).toFixed(3))
                                          : "—"
                                    color: theme.primary
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Label {
                                    text: (page.outlierAvailable(page.outlierDataset)
                                           ? outlierMethodText(page.outlierDataset)
                                           : page.outlierMethod) === "IQR"
                                          ? "Q1 − k × IQR  /  Q3 + k × IQR"
                                          : "|x − mean| / std. dev. > threshold"
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
                        text: qsTr("Column-level results")
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
                                text: qsTr("%1 outliers").arg(modelData.outlierCount || 0)
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

            Item {
                Layout.preferredHeight: 24
            }
        }
    }

    Components.SessionRestoreDialog {
        id: sessionRestoreDialog
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - height) / 2)

        onRestoreClicked: {
            page.sessionPromptHandled = true
            if (page.appController) {
                page.appController.applyGlobalRestoreDecision(true)
            }
        }

        onStartFreshClicked: {
            page.sessionPromptHandled = true
            if (page.appController) {
                page.appController.applyGlobalRestoreDecision(false)
            }
        }
    }
}
