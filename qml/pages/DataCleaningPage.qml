import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme
import "../components" as Components

Item {
    id: page
    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    property int activeDs: 1 // 1 for Dataset 1, 2 for Dataset 2
    property string outlierMethod: "IQR"
    property double outlierParam: 1.5
    property string bulkMissingAction: "Mean (Average)"
    property string bulkOutlierAction: "Remove Outliers"

    property int activeCleaningDs: 0
    property string activeCleaningOp: ""
    property string activeOutlierCol: ""
    property string activeMissingCol: ""

    function checkSessionRestore() {
        if (!page.appController) return
        if (page.appController.sessionRestoreDecision === 1) {
            if (page.appController.hasRestorableCleaningSession) {
                page.appController.restoreCleaningSession()
                page.refreshAnalysis()
            }
        }
    }

    ListModel { id: missingModel }
    ListModel { id: duplicateModel }
    ListModel { id: outlierModel }
    ListModel { id: constantModel }
    ListModel { id: logModel }

    function goToPage(index) {
        if (mainWindow) {
            if (mainWindow.navigateToPage)
                mainWindow.navigateToPage(index)
            else
                mainWindow.currentPage = index
        }
    }

    function isLoaded(ds) {
        if (!appController) return false
        return ds === 1 ? (appController.dataset1Name !== "") : (appController.dataset2Name !== "")
    }

    function name(ds) {
        if (!appController) return qsTr("Dataset %1").arg(ds)
        var n = ds === 1 ? appController.dataset1Name : appController.dataset2Name
        return n && n !== "" ? n : qsTr("Dataset %1").arg(ds)
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
                action: isNum ? "Mean (Average)" : "Mode"
            })
        }

        // 2. Duplicate rows
        var dupCount = Number(q.duplicateRowCount || 0)
        if (dupCount > 0) {
            duplicateModel.append({
                title: qsTr("Duplicate Records (%1 count)").arg(dupCount),
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
        var isOutlierAvail = ds === 1
            ? (appController && appController.dataset1OutlierAvailable)
            : (appController && appController.dataset2OutlierAvailable)
        var out = ds === 1 ? appController.dataset1OutlierResult : appController.dataset2OutlierResult
        var outCols = (isOutlierAvail && out && out.columns) ? out.columns : []
        for (var k = 0; k < outCols.length; ++k) {
            var oc = outCols[k]
            var outCount = Number(oc.outlierCount || 0)
            if (outCount > 0) {
                outlierModel.append({
                    columnName: String(oc.columnName),
                    outlierCount: outCount,
                    percentage: Number(oc.outlierPercentage || 0).toFixed(2),
                    action: "Remove Outliers"
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

        page.activeCleaningDs = ds
        page.activeCleaningOp = "single_missing"
        page.activeMissingCol = item.columnName

        if (act === "Drop Rows" || act === "Satırları Sil" || act === "Drop Missing Rows") {
            ok = ds === 1 ? appController.removeDataset1MissingRows() : appController.removeDataset2MissingRows()
            log(qsTr("Dataset %1 • Rows with missing values dropped.").arg(ds), ok)
        } else if (act === "Drop Column" || act === "Sütunu Sil" || act === "Remove Column" || act === "Delete Column") {
            ok = ds === 1 ? appController.removeDataset1Column(item.columnName) : appController.removeDataset2Column(item.columnName)
            log(qsTr("Dataset %1 • Column '%2' removed.").arg(ds).arg(item.columnName), ok)
        } else if (act.indexOf("Mean") !== -1 || act.indexOf("Ortalama") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMean(item.columnName) : appController.fillDataset2MissingWithMean(item.columnName)
            log(qsTr("Dataset %1 • %2 filled with mean (Average).").arg(ds).arg(item.columnName), ok)
        } else if (act.indexOf("Median") !== -1 || act.indexOf("Medyan") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMedian(item.columnName) : appController.fillDataset2MissingWithMedian(item.columnName)
            log(qsTr("Dataset %1 • %2 filled with median.").arg(ds).arg(item.columnName), ok)
        } else if (act.indexOf("Mode") !== -1 || act.indexOf("Mod") !== -1) {
            ok = ds === 1 ? appController.fillDataset1MissingWithMode(item.columnName) : appController.fillDataset2MissingWithMode(item.columnName)
            log(qsTr("Dataset %1 • %2 filled with mode.").arg(ds).arg(item.columnName), ok)
        } else if (act.indexOf("Skip") !== -1 || act === "Atla") {
            log(qsTr("Dataset %1 • %2 skipped.").arg(ds).arg(item.columnName), true)
        }

        if (!ok) {
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeMissingCol = ""
        }
    }

    function applyBulkMissing() {
        var ds = page.activeDs
        var act = page.bulkMissingAction
        var q = quality(ds)
        var missingCols = q.columnsWithMissing || []
        var numericFlags = []
        for (var i = 0; i < missingCols.length; ++i) {
            numericFlags.push(isColumnNumeric(ds, String(missingCols[i])))
        }
        page.activeCleaningDs = ds
        page.activeCleaningOp = "missing"
        var ok = appController.applyBulkMissingCleaning(ds, act, missingCols, numericFlags)
        if (ok) {
            log(qsTr("Dataset %1 • Bulk missing cleaning running in background...").arg(ds), true)
        } else {
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            log(qsTr("✕ Bulk cleaning error: %1").arg(appController.lastError || qsTr("Error")), false)
        }
    }

    function applyRemoveDuplicates() {
        var ds = page.activeDs
        page.activeCleaningDs = ds
        page.activeCleaningOp = "duplicates"
        var ok = ds === 1 ? appController.removeDataset1Duplicates() : appController.removeDataset2Duplicates()
        if (ok) {
            log(qsTr("Dataset %1 • Duplicate removal running in background...").arg(ds), true)
        } else {
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
        }
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

        var cleaned = outlierParameterField ? outlierParameterField.text.trim().replace(",", ".") : ""
        var val = Number(cleaned)
        if (isFinite(val) && val > 0) {
            page.outlierParam = val
        }

        var backendAction = mapOutlierAction(item.action)

        page.activeCleaningDs = ds
        page.activeCleaningOp = "single_outlier"
        page.activeOutlierCol = item.columnName

        var ok = ds === 1
            ? appController.applyDataset1OutlierAction(item.columnName, page.outlierMethod, backendAction, page.outlierParam)
            : appController.applyDataset2OutlierAction(item.columnName, page.outlierMethod, backendAction, page.outlierParam)

        if (ok) {
            log(qsTr("Dataset %1 • %2 (%3 - %4) running in background...").arg(ds).arg(item.columnName).arg(item.action).arg(page.outlierMethod), true)
        } else {
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeOutlierCol = ""
        }
    }

    function applyBulkOutliers() {
        var ds = page.activeDs

        var cleaned = outlierParameterField ? outlierParameterField.text.trim().replace(",", ".") : ""
        var val = Number(cleaned)
        if (isFinite(val) && val > 0) {
            page.outlierParam = val
        }

        var backendAction = mapOutlierAction(page.bulkOutlierAction)
        var cols = []
        for (var i = 0; i < outlierModel.count; ++i) {
            var rowItem = outlierModel.get(i)
            if (rowItem && rowItem.columnName) {
                cols.push(rowItem.columnName)
            }
        }

        page.activeCleaningDs = ds
        page.activeCleaningOp = "outliers"
        var ok = appController.applyBulkOutlierCleaning(ds, page.outlierMethod, backendAction, page.outlierParam, cols)
        if (ok) {
            log(qsTr("Dataset %1 • Bulk outlier cleaning running in background...").arg(ds), true)
        } else {
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
        }
    }

    function applyRemoveConstant(colName) {
        var ds = page.activeDs
        var ok = ds === 1 ? appController.removeDataset1Column(colName) : appController.removeDataset2Column(colName)
        if (ok) {
            log(qsTr("Dataset %1 • Column '%2' removed.").arg(ds).arg(colName), true)
        }
    }

    function hasMissingCleaning(ds) {
        if (!appController) return false
        return ds === 1 ? appController.dataset1HasMissingCleaning : appController.dataset2HasMissingCleaning
    }

    function hasOutlierCleaning(ds) {
        if (!appController) return false
        return ds === 1 ? appController.dataset1HasOutlierCleaning : appController.dataset2HasOutlierCleaning
    }

    function applyResetMissing() {
        var ds = page.activeDs
        var ok = appController ? appController.resetDatasetMissing(ds) : false
        if (ok) {
            log(qsTr("↶ Dataset %1 • Missing value cleaning reverted.").arg(ds), true)
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeOutlierCol = ""
            page.activeMissingCol = ""
            refreshAnalysis()
        }
    }

    function applyResetOutliers() {
        var ds = page.activeDs
        var ok = appController ? appController.resetDatasetOutliers(ds) : false
        if (ok) {
            log(qsTr("↶ Dataset %1 • Outlier cleaning reverted.").arg(ds), true)
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeOutlierCol = ""
            page.activeMissingCol = ""
            refreshAnalysis()
        }
    }

    function applyRestore() {
        var ds = page.activeDs
        var ok = ds === 1 ? appController.restoreDataset1() : appController.restoreDataset2()
        if (ok) {
            log(qsTr("↶ Dataset %1 reset to original state.").arg(ds), true)
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeOutlierCol = ""
            page.activeMissingCol = ""
            refreshAnalysis()
        }
    }

    function restoreDataset() {
        applyRestore()
    }

    onVisibleChanged: {
        if (visible) {
            if (!isLoaded(1) && isLoaded(2)) {
                page.activeDs = 2
            }
            refreshAnalysis()
            page.checkSessionRestore()
        }
    }

    onActiveDsChanged: {
        refreshAnalysis()
    }

    Component.onCompleted: {
        if (!isLoaded(1) && isLoaded(2)) {
            page.activeDs = 2
        }
        refreshAnalysis()
        if (page.visible) {
            page.checkSessionRestore()
        }
    }

    Connections {
        target: appController
        function onSessionRestoreDecisionChanged() { page.checkSessionRestore() }
        function onDataset1QualityChanged() { if (page.activeDs === 1) page.rebuildLists() }
        function onDataset2QualityChanged() { if (page.activeDs === 2) page.rebuildLists() }
        function onDataset1OutlierChanged() { if (page.activeDs === 1) page.rebuildLists() }
        function onDataset2OutlierChanged() { if (page.activeDs === 2) page.rebuildLists() }
        function onDataset1CleaningStateChanged() { if (page.activeDs === 1) page.rebuildLists() }
        function onDataset2CleaningStateChanged() { if (page.activeDs === 2) page.rebuildLists() }
        function onDataset1Changed() {
            if (page.activeDs === 1) page.refreshAnalysis()
        }
        function onDataset2Changed() {
            if (page.activeDs === 2) page.refreshAnalysis()
        }
        function onCleaningCompletedSignal(success, message) {
            log(message, success)
            page.activeCleaningDs = 0
            page.activeCleaningOp = ""
            page.activeOutlierCol = ""
            page.activeMissingCol = ""
            refreshAnalysis()
        }
    }

    ScrollView {
        id: pageScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        readonly property real containerWidth: pageScrollView.availableWidth
        readonly property bool isNarrow: containerWidth < 750
        readonly property bool isMediumOrNarrow: containerWidth < 900

        ColumnLayout {
            width: pageScrollView.availableWidth
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 2
                title: qsTr("Next Step: Comparison or Visualization")
                subtitle: qsTr("You can compare the cleaned datasets or create charts on the Visualization page.")
                buttonText: qsTr("Proceed to Comparison →")
                buttonVisible: true
                buttonEnabled: true
                onButtonClicked: {
                    if (appController)
                        appController.setCleaningCompleted(true)
                    page.goToPage(4)
                }
                secondaryButtonText: qsTr("Go to Visualization →")
                secondaryButtonVisible: true
                onSecondaryButtonClicked: {
                    if (appController)
                        appController.setCleaningCompleted(true)
                    page.goToPage(5)
                }
            }

            // =================================================
            // AKTİF DATASET SEÇİCİ
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: dsSelectCol.implicitHeight + 28
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                GridLayout {
                    id: dsSelectCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    columns: dsSelectCol.width < 680 ? 1 : 2
                    rowSpacing: 10
                    columnSpacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            spacing: 10

                            Components.ByteMascot {
                                sizeVariant: "section"
                                source: (appController && appController.cleaningBusy)
                                        ? "qrc:/assets/byte/byte_cleaning.png"
                                        : (page.hasMissingCleaning(page.activeDs) || page.hasOutlierCleaning(page.activeDs)
                                           ? "qrc:/assets/byte/byte_completed.png"
                                           : "qrc:/assets/byte/byte_cleaning.png")
                                animated: appController && appController.cleaningBusy
                            }

                            Label {
                                text: qsTr("Active Dataset:")
                                color: theme.text
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                property bool isMod: page.activeDs === 1
                                    ? (page.appController && page.appController.dataset1Modified)
                                    : (page.appController && page.appController.dataset2Modified)
                                visible: isMod
                                height: 24
                                width: 90
                                radius: 12
                                color: "#E6F6EE"
                                border.width: 1
                                border.color: theme.success

                                Label {
                                    anchors.centerIn: parent
                                    text: qsTr("✓ Cleaned")
                                    color: theme.success
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        Flow {
                            width: dsSelectCol.width
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                implicitWidth: 165
                                implicitHeight: 36
                                text: qsTr("Dataset 1: %1").arg(page.name(1))
                                highlighted: page.activeDs === 1
                                enabled: page.isLoaded(1)
                                onClicked: {
                                    page.activeDs = 1
                                    page.refreshAnalysis()
                                }
                            }

                            Button {
                                implicitWidth: 165
                                implicitHeight: 36
                                text: qsTr("Dataset 2: %1").arg(page.name(2))
                                highlighted: page.activeDs === 2
                                enabled: page.isLoaded(2)
                                onClicked: {
                                    page.activeDs = 2
                                    page.refreshAnalysis()
                                }
                            }
                        }
                    }

                    Button {
                        id: resetBtn
                        Layout.alignment: dsSelectCol.columns === 1 ? Qt.AlignLeft : Qt.AlignRight
                        Layout.preferredWidth: dsSelectCol.columns === 1 ? parent.width : 160
                        Layout.fillWidth: dsSelectCol.columns === 1
                        Layout.preferredHeight: 36
                        text: qsTr("↶ Reset to Original")
                        enabled: (page.activeDs === 1 ? (appController && appController.dataset1Modified) : (appController && appController.dataset2Modified)) && appController && !appController.cleaningBusy
                        property bool clickFeedback: false
                        Timer {
                            id: resetTimer
                            interval: 450
                            onTriggered: resetBtn.clickFeedback = false
                        }
                        background: Rectangle {
                            radius: 8
                            color: resetBtn.down ? theme.surfaceAlt : (resetBtn.hovered ? theme.surfaceAlt : theme.surface)
                            border.color: resetBtn.clickFeedback ? theme.success : theme.border
                            border.width: 1
                        }
                        onClicked: {
                            clickFeedback = true
                            resetTimer.restart()
                            page.applyRestore()
                        }
                    }
                }
            }

            // Category 1: Missing Values & Duplicates
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: Math.max(140, missingMainCol.implicitHeight + 36)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    id: missingMainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 12

                    GridLayout {
                        Layout.fillWidth: true
                        columns: parent.width < 700 ? 1 : 2
                        rowSpacing: 8
                        columnSpacing: 10

                        Label {
                            text: qsTr("🧩 Missing Values & Duplicate Records")
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: parent.columns === 1
                        }

                        Flow {
                            width: missingMainCol.width
                            Layout.fillWidth: parent.columns === 1
                            Layout.alignment: parent.columns === 1 ? Qt.AlignLeft : Qt.AlignRight
                            spacing: 8

                            ComboBox {
                                visible: missingModel.count > 0
                                implicitWidth: 150
                                implicitHeight: 34
                                model: ["Mean (Average)", "Median", "Mode", "Drop Column", "Drop Rows"]
                                onActivated: page.bulkMissingAction = currentText
                            }

                            ColumnLayout {
                                visible: missingModel.count > 0
                                spacing: 2

                                Button {
                                    id: bulkMissingBtn
                                    implicitWidth: 160
                                    implicitHeight: 34
                                    text: qsTr("⚡ Apply All Missing")
                                    enabled: appController && !appController.cleaningBusy
                                    onClicked: page.applyBulkMissing()

                                    property bool isRunning: appController && appController.cleaningBusy && appController.activeCleaningDataset === page.activeDs && appController.activeCleaningOperation === "missing"
                                    background: Rectangle {
                                        radius: 8
                                        color: bulkMissingBtn.down ? theme.surfaceAlt : (bulkMissingBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: bulkMissingBtn.isRunning ? theme.success : theme.border
                                        border.width: 1
                                    }
                                }

                                Components.CompactProgress {
                                    implicitWidth: 160
                                    running: bulkMissingBtn.isRunning
                                    progress: appController ? appController.cleaningProgress : 0
                                    theme: page.theme
                                }
                            }

                            Button {
                                id: resetMissingBtn
                                implicitWidth: 120
                                implicitHeight: 34
                                text: qsTr("↶ Reset Missing")
                                enabled: page.hasMissingCleaning(page.activeDs) && appController && !appController.cleaningBusy
                                property bool clickFeedback: false
                                Timer {
                                    id: resetMissingTimer
                                    interval: 450
                                    onTriggered: resetMissingBtn.clickFeedback = false
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: resetMissingBtn.down ? theme.surfaceAlt : (resetMissingBtn.hovered ? theme.surfaceAlt : theme.surface)
                                    border.color: resetMissingBtn.clickFeedback ? theme.success : (resetMissingBtn.enabled ? theme.border : theme.surfaceAlt)
                                    border.width: 1
                                }
                                onClicked: {
                                    clickFeedback = true
                                    resetMissingTimer.restart()
                                    page.applyResetMissing()
                                }
                            }
                        }
                    }

                    // Duplicates
                    Repeater {
                        model: duplicateModel
                        delegate: Rectangle {
                            property string rowTitle: (model && model.title !== undefined) ? model.title : ""
                            visible: rowTitle !== ""
                            Layout.fillWidth: true
                            height: 46
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
                                    id: removeDupBtn
                                    Layout.preferredWidth: 140
                                    Layout.preferredHeight: 32
                                    text: qsTr("Remove Records")
                                    enabled: appController && !appController.cleaningBusy
                                    onClicked: page.applyRemoveDuplicates()

                                    property bool isRunning: appController && appController.cleaningBusy && appController.activeCleaningDataset === page.activeDs && appController.activeCleaningOperation === "duplicates"
                                    background: Rectangle {
                                        radius: 8
                                        color: removeDupBtn.down ? theme.surfaceAlt : (removeDupBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: removeDupBtn.isRunning ? theme.success : theme.border
                                        border.width: 1
                                    }
                                }
                            }
                        }
                    }

                    // Missing Columns
                    Repeater {
                        model: missingModel
                        delegate: Rectangle {
                            property int missIndex: index
                            property string colName: (model && model.columnName !== undefined) ? model.columnName : ""
                            property string countStr: (model && model.missingCount !== undefined) ? String(model.missingCount) : "0"
                            property string pctStr: (model && model.percentage !== undefined) ? String(model.percentage) : "0"
                            property string actionStr: (model && model.action !== undefined) ? model.action : "Mean (Average)"
                            visible: colName !== ""
                            Layout.fillWidth: true
                            height: 50
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: "• " + colName
                                    color: theme.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.preferredWidth: 190
                                    elide: Text.ElideMiddle
                                }

                                Label {
                                    text: qsTr("%1 missing (%2%)").arg(countStr).arg(pctStr)
                                    color: theme.warning
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }

                                ComboBox {
                                    id: rowActionCombo
                                    Layout.preferredWidth: 175
                                    Layout.preferredHeight: 34
                                    model: ["Mean (Average)", "Median", "Mode", "Drop Column", "Drop Rows"]
                                    currentIndex: Math.max(0, model.indexOf(actionStr))
                                    onActivated: {
                                        if (missIndex >= 0 && missIndex < missingModel.count) {
                                            missingModel.setProperty(missIndex, "action", currentText)
                                        }
                                    }
                                }

                                Button {
                                    id: singleMissingBtn
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 34
                                    text: qsTr("▶ Apply")
                                    enabled: appController && !appController.cleaningBusy
                                    onClicked: page.applySingleMissing(missIndex)

                                    property bool isRunning: appController && appController.cleaningBusy && appController.activeCleaningDataset === page.activeDs && appController.activeCleaningOperation === "single_missing" && appController.activeCleaningColumn === colName
                                    background: Rectangle {
                                        radius: 8
                                        color: singleMissingBtn.down ? theme.surfaceAlt : (singleMissingBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: singleMissingBtn.isRunning ? theme.success : theme.border
                                        border.width: 1
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        visible: !page.isLoaded(page.activeDs)
                        text: qsTr("Dataset is not loaded.")
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }

                    Label {
                        visible: page.isLoaded(page.activeDs) && missingModel.count === 0
                        text: qsTr("✓ No missing values or duplicate records detected in this dataset.")
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
                implicitHeight: Math.max(140, outlierMainCol.implicitHeight + 36)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    id: outlierMainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 12

                    GridLayout {
                        Layout.fillWidth: true
                        columns: parent.width < 720 ? 1 : 2
                        rowSpacing: 8
                        columnSpacing: 10

                        Label {
                            text: qsTr("⚡ Outliers")
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: parent.columns === 1
                        }

                        Flow {
                            width: outlierMainCol.width
                            Layout.fillWidth: parent.columns === 1
                            Layout.alignment: parent.columns === 1 ? Qt.AlignLeft : Qt.AlignRight
                            spacing: 8

                            RowLayout {
                                spacing: 4
                                Label {
                                    text: qsTr("Method")
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                ComboBox {
                                    id: outlierMethodComboBox
                                    implicitWidth: 90
                                    implicitHeight: 32
                                    model: ["IQR", "Z-Score"]
                                    currentIndex: page.outlierMethod === "Z-Score" ? 1 : 0
                                    onActivated: {
                                        page.outlierMethod = currentText
                                        page.refreshAnalysis()
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 4
                                Label {
                                    text: qsTr("Parameter")
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                TextField {
                                    id: outlierParameterField
                                    implicitWidth: 55
                                    implicitHeight: 32
                                    text: page.outlierParam > 0 ? page.outlierParam.toString() : "1.5"
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    validator: DoubleValidator {
                                        bottom: 0.01
                                        top: 100.0
                                        decimals: 4
                                        notation: DoubleValidator.StandardNotation
                                    }
                                    onAccepted: {
                                        applyParamBtn.clicked()
                                    }
                                }

                                Button {
                                    id: applyParamBtn
                                    implicitWidth: 55
                                    implicitHeight: 32
                                    text: qsTr("Apply")
                                    enabled: page.isLoaded(page.activeDs) && appController && !appController.cleaningBusy
                                    property bool clickFeedback: false
                                    Timer {
                                        id: applyParamTimer
                                        interval: 450
                                        onTriggered: applyParamBtn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: applyParamBtn.down ? theme.surfaceAlt : (applyParamBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: applyParamBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        applyParamTimer.restart()
                                        var cleaned = outlierParameterField ? outlierParameterField.text.trim().replace(",", ".") : ""
                                        var val = Number(cleaned)
                                        if (isFinite(val) && val > 0) {
                                            page.outlierParam = val
                                            page.refreshAnalysis()
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 4
                                Label {
                                    text: qsTr("Action")
                                    color: theme.textSecondary
                                    font.pixelSize: 11
                                }

                                ComboBox {
                                    id: outlierActionComboBox
                                    implicitWidth: 140
                                    implicitHeight: 32
                                    model: ["Remove Outliers", "Mean (Average)", "Median", "Mode", "Cap"]
                                    currentIndex: Math.max(0, model.indexOf(page.bulkOutlierAction))
                                    onActivated: page.bulkOutlierAction = currentText
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Button {
                                    id: bulkOutlierBtn
                                    implicitWidth: 155
                                    implicitHeight: 34
                                    text: qsTr("⚡ Apply All Outliers")
                                    enabled: page.isLoaded(page.activeDs) && outlierModel.count > 0 && appController && !appController.cleaningBusy
                                    onClicked: {
                                        var cleaned = outlierParameterField ? outlierParameterField.text.trim().replace(",", ".") : ""
                                        var val = Number(cleaned)
                                        if (isFinite(val) && val > 0) {
                                            page.outlierParam = val
                                        }
                                        page.applyBulkOutliers()
                                    }

                                    property bool isRunning: appController && appController.cleaningBusy && appController.activeCleaningDataset === page.activeDs && appController.activeCleaningOperation === "outliers"
                                    background: Rectangle {
                                        radius: 8
                                        color: bulkOutlierBtn.down ? theme.surfaceAlt : (bulkOutlierBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: bulkOutlierBtn.isRunning ? theme.success : theme.border
                                        border.width: 1
                                    }
                                }

                                Components.CompactProgress {
                                    implicitWidth: 155
                                    running: bulkOutlierBtn.isRunning
                                    progress: appController ? appController.cleaningProgress : 0
                                    theme: page.theme
                                }
                            }

                            Button {
                                id: resetOutlierBtn
                                implicitWidth: 120
                                implicitHeight: 34
                                text: qsTr("↶ Reset Outliers")
                                enabled: page.hasOutlierCleaning(page.activeDs) && appController && !appController.cleaningBusy
                                property bool clickFeedback: false
                                Timer {
                                    id: resetOutlierTimer
                                    interval: 450
                                    onTriggered: resetOutlierBtn.clickFeedback = false
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: resetOutlierBtn.down ? theme.surfaceAlt : (resetOutlierBtn.hovered ? theme.surfaceAlt : theme.surface)
                                    border.color: resetOutlierBtn.clickFeedback ? theme.success : (resetOutlierBtn.enabled ? theme.border : theme.surfaceAlt)
                                    border.width: 1
                                }
                                onClicked: {
                                    clickFeedback = true
                                    resetOutlierTimer.restart()
                                    page.applyResetOutliers()
                                }
                            }
                        }
                    }

                    Repeater {
                        model: outlierModel
                        delegate: Rectangle {
                            id: outRowDelegate
                            property int outIndex: index
                            property string outColName: (model && model.columnName !== undefined) ? model.columnName : ""
                            property string outCountStr: (model && model.outlierCount !== undefined) ? String(model.outlierCount) : "0"
                            property string outPctStr: (model && model.percentage !== undefined) ? String(model.percentage) : "0"
                            property string outActionStr: (model && model.action !== undefined) ? model.action : "Remove Outliers"
                            readonly property bool isCompact: width < 580
                            visible: outColName !== ""
                            Layout.fillWidth: true
                            implicitHeight: isCompact ? 76 : 50
                            radius: 8
                            color: theme.surfaceAlt

                            // Wide Layout (1 row)
                            RowLayout {
                                visible: !outRowDelegate.isCompact
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
                                    text: qsTr("%1 outliers (%2%)").arg(outCountStr).arg(outPctStr)
                                    color: "#FF6E40"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }

                                ComboBox {
                                    id: outlierActionCombo
                                    Layout.preferredWidth: 175
                                    Layout.preferredHeight: 34
                                    model: ["Remove Outliers", "Mean (Average)", "Median", "Mode", "Cap"]
                                    currentIndex: Math.max(0, model.indexOf(outActionStr))
                                    onActivated: {
                                        if (outIndex >= 0 && outIndex < outlierModel.count) {
                                             outlierModel.setProperty(outIndex, "action", currentText)
                                        }
                                    }
                                }

                                Button {
                                    id: singleOutlierBtn
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 34
                                    text: qsTr("▶ Apply")
                                    enabled: appController && !appController.cleaningBusy
                                    onClicked: page.applySingleOutlier(outIndex)

                                    property bool isRunning: appController && appController.cleaningBusy && appController.activeCleaningDataset === page.activeDs && appController.activeCleaningOperation === "single_outlier" && appController.activeCleaningColumn === outColName
                                    background: Rectangle {
                                        radius: 8
                                        color: singleOutlierBtn.down ? theme.surfaceAlt : (singleOutlierBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: singleOutlierBtn.isRunning ? theme.success : theme.border
                                        border.width: 1
                                    }
                                }
                            }

                            // Compact Layout (2 rows)
                            ColumnLayout {
                                visible: outRowDelegate.isCompact
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Label {
                                        text: "△ " + outColName
                                        color: theme.text
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                    }

                                    Label {
                                        text: qsTr("%1 (%2%)").arg(outCountStr).arg(outPctStr)
                                        color: "#FF6E40"
                                        font.pixelSize: 11
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ComboBox {
                                        id: outlierActionComboCompact
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        model: ["Remove Outliers", "Mean (Average)", "Median", "Mode", "Cap"]
                                        currentIndex: Math.max(0, model.indexOf(outActionStr))
                                        onActivated: {
                                            if (outIndex >= 0 && outIndex < outlierModel.count) {
                                                 outlierModel.setProperty(outIndex, "action", currentText)
                                            }
                                        }
                                    }

                                    Button {
                                        id: singleOutlierBtnCompact
                                        Layout.preferredWidth: 90
                                        Layout.preferredHeight: 30
                                        text: qsTr("▶ Apply")
                                        enabled: appController && !appController.cleaningBusy
                                        onClicked: page.applySingleOutlier(outIndex)
                                        background: Rectangle {
                                            radius: 6
                                            color: parent.down ? theme.surfaceAlt : (parent.hovered ? theme.surfaceAlt : theme.surface)
                                            border.color: theme.border
                                            border.width: 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        visible: !page.isLoaded(page.activeDs)
                        text: qsTr("Dataset is not loaded.")
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }

                    Label {
                        visible: page.isLoaded(page.activeDs) && outlierModel.count === 0
                        text: qsTr("✓ No outliers found in this dataset using the (%1) method.").arg(page.outlierMethod)
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
                implicitHeight: Math.max(120, constMainCol.implicitHeight + 36)
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    id: constMainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 12

                    Label {
                        text: qsTr("🗑️ Constant Columns")
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
                            height: 46
                            radius: 8
                            color: theme.surfaceAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Label {
                                    text: qsTr("C • %1 (Contains a single constant value)").arg(constCol)
                                    color: theme.text
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                }
                                Button {
                                    id: removeConstBtn
                                    Layout.preferredWidth: 130
                                    Layout.preferredHeight: 32
                                    text: qsTr("Remove Column")
                                    property bool clickFeedback: false
                                    Timer {
                                        id: removeConstTimer
                                        interval: 450
                                        onTriggered: removeConstBtn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: removeConstBtn.down ? theme.surfaceAlt : (removeConstBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: removeConstBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        removeConstTimer.restart()
                                        page.applyRemoveConstant(constCol)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Category 4: Remove Specific Column
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                implicitHeight: removeMainCol.implicitHeight + 36
                radius: 16
                color: theme.surface
                border.color: theme.border
                border.width: 1

                ColumnLayout {
                    id: removeMainCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 18
                    spacing: 12

                    Label {
                        text: qsTr("🗑️ Remove Column")
                        color: theme.text
                        font.pixelSize: 15
                        font.bold: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: parent.width < 500 ? 1 : 3
                        rowSpacing: 8
                        columnSpacing: 10

                        Label {
                            text: qsTr("Select Column:")
                            color: theme.textSecondary
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ComboBox {
                            id: removeColumnCombo
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            model: page.activeDs === 1
                                   ? (appController ? appController.dataset1ColumnModel : null)
                                   : (appController ? appController.dataset2ColumnModel : null)
                            textRole: "name"
                        }

                        Button {
                            id: removeColSpecificBtn
                            Layout.preferredWidth: parent.columns === 1 ? parent.width : 150
                            Layout.fillWidth: parent.columns === 1
                            Layout.preferredHeight: 36
                            text: qsTr("Remove Column")
                            enabled: removeColumnCombo.currentIndex >= 0 && removeColumnCombo.currentText !== ""
                            property bool clickFeedback: false
                            Timer {
                                id: removeColSpecificTimer
                                interval: 450
                                onTriggered: removeColSpecificBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: removeColSpecificBtn.down ? theme.surfaceAlt : (removeColSpecificBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: removeColSpecificBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                removeColSpecificTimer.restart()
                                var colName = removeColumnCombo.currentText
                                if (colName && colName !== "") {
                                    var ds = page.activeDs
                                    var ok = ds === 1
                                        ? appController.removeDataset1Column(colName)
                                        : appController.removeDataset2Column(colName)
                                    log(qsTr("Dataset %1 • Column '%2' removed.").arg(ds).arg(colName), ok)
                                    removeColumnCombo.currentIndex = -1
                                    page.refreshAnalysis()
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
                            text: qsTr("Live Cleaning Log")
                            color: theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            id: clearLogBtn
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 28
                            text: qsTr("Clear")
                            property bool clickFeedback: false
                            Timer {
                                id: clearLogTimer
                                interval: 450
                                onTriggered: clearLogBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 6
                                color: clearLogBtn.down ? theme.surfaceAlt : (clearLogBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: clearLogBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                clearLogTimer.restart()
                                logModel.clear()
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth

                        ListView {
                            id: logView
                            model: logModel
                            boundsBehavior: Flickable.StopAtBounds
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
                        text: qsTr("No cleaning actions performed yet.")
                        color: theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.maximumWidth: parent.width
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}
