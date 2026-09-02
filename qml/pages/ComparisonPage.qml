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

    property var comparisonResult: ({})
    property int selectedComparisonIndex: 0
    property string compChartType: "stats" // "stats", "distribution", "boxplot", "trend"
    property string saveStatusMessage: ""
    property bool saveSuccess: true
    property bool sessionRestored: false
    property bool isRestoring: false

    onAppControllerChanged: {
        if (page.appController && page.appController.sessionRestoreDecision === 1 && !page.sessionRestored) {
            page.checkSessionRestore()
        }
    }

    onCompChartTypeChanged: {
        page.syncChartCombo()
        compCanvas.requestPaint()
        page.saveComparisonState()
    }

    onSelectedComparisonIndexChanged: {
        compCanvas.requestPaint()
        page.saveComparisonState()
    }

    ListModel {
        id: mappingRows
    }

    function saveComparisonState() {
        if (!appController || page.isRestoring) return
        var rows = []
        for (var i = 0; i < mappingRows.count; ++i) {
            var r = mappingRows.get(i)
            rows.push({
                sourceColumn: r.sourceColumn || "",
                targetColumn: r.targetColumn || "",
                similarityScore: r.similarityScore || 0,
                selected: r.selected !== undefined ? r.selected : true
            })
        }
        var compData = {
            mappingRows: rows,
            selectedComparisonIndex: page.selectedComparisonIndex,
            compChartType: page.compChartType,
            comparisonResult: page.comparisonResult
        }
        appController.saveComparisonSession(compData)
    }

    function checkSessionRestore() {
        if (page.sessionRestored || !page.appController) return
        if (page.appController.sessionRestoreDecision === 1) {
            page.isRestoring = true
            page.sessionRestored = true
            var comp = page.appController.getSavedComparisonSession()
            if (comp && (comp.mappingRows || comp.comparisonResult || comp.compChartType)) {
                if (comp.mappingRows && comp.mappingRows.length > 0) {
                    mappingRows.clear()
                    for (var i = 0; i < comp.mappingRows.length; ++i) {
                        var mr = comp.mappingRows[i]
                        mappingRows.append({
                            sourceColumn: mr.sourceColumn || "",
                            targetColumn: mr.targetColumn || "",
                            similarityScore: mr.similarityScore || 0,
                            selected: mr.selected !== undefined ? mr.selected : true
                        })
                    }
                }
                if (comp.compChartType !== undefined && comp.compChartType !== "") {
                    page.compChartType = comp.compChartType
                    page.syncChartCombo()
                }
                if (comp.selectedComparisonIndex !== undefined) {
                    page.selectedComparisonIndex = comp.selectedComparisonIndex
                }
                if (comp.comparisonResult && comp.comparisonResult.results) {
                    page.comparisonResult = comp.comparisonResult
                } else if (page.appController.datasetComparisonAvailable) {
                    page.comparisonResult = page.appController.datasetComparisonResult
                }
                compCanvas.requestPaint()
            }
            page.isRestoring = false
            return
        }
    }

    function syncChartCombo() {
        if (typeof chartTypeCombo === "undefined" || !chartTypeCombo) return
        var idx = 0
        switch (page.compChartType) {
        case "stats": idx = 0; break;
        case "distribution": idx = 1; break;
        case "boxplot": idx = 2; break;
        case "trend": idx = 3; break;
        }
        if (chartTypeCombo.currentIndex !== idx) {
            chartTypeCombo.currentIndex = idx
        }
    }

    onVisibleChanged: {
        if (page.visible) {
            if (page.appController && page.appController.sessionRestoreDecision === 1 && !page.sessionRestored) {
                page.checkSessionRestore()
            } else if (mappingRows.count === 0) {
                loadSuggestedMappings()
            }
        }
    }

    Connections {
        target: page.appController
        ignoreUnknownSignals: true

        function onSessionRestoreDecisionChanged() {
            if (page.appController.sessionRestoreDecision === 1) {
                page.checkSessionRestore()
            }
        }

        function onDatasetComparisonChanged() {
            if (page.appController && page.appController.datasetComparisonAvailable) {
                page.comparisonResult = page.appController.datasetComparisonResult
                page.selectedComparisonIndex = 0
                compCanvas.requestPaint()
                page.saveComparisonState()
            }
        }

        function onDataset1Changed() {
            page.sessionRestored = false
            loadSuggestedMappings()
        }

        function onDataset2Changed() {
            page.sessionRestored = false
            loadSuggestedMappings()
        }
    }

    function goToPage(index) {
        if (mainWindow) mainWindow.currentPage = index
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
        var s = (src !== undefined && src !== "") ? src : firstColumn(1)
        var t = (tgt !== undefined && tgt !== "") ? tgt : firstColumn(2)
        mappingRows.append({
            sourceColumn: s,
            targetColumn: t,
            similarityScore: finalScore,
            selected: true
        })
        page.saveComparisonState()
    }

    function removeMapping(index) {
        if (index >= 0 && index < mappingRows.count) {
            mappingRows.remove(index)
            page.saveComparisonState()
        }
    }

    function loadSuggestedMappings() {
        mappingRows.clear()
        if (!appController) return

        var suggestions = appController.getSuggestedMappings()
        if (suggestions && suggestions.length > 0) {
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
            if (r.selected && r.sourceColumn && r.targetColumn &&
                r.sourceColumn !== "" && r.targetColumn !== "") {
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
            page.saveComparisonState()
        }
    }

    function runSingleComparison(src, tgt) {
        if (!appController || !src || !tgt || src === "" || tgt === "") return
        var ok = appController.compareDatasets([{ sourceColumn: src, targetColumn: tgt }])
        if (ok) {
            page.comparisonResult = appController.datasetComparisonResult
            page.selectedComparisonIndex = 0
            compCanvas.requestPaint()
            page.saveComparisonState()
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
            page.saveStatusMessage = qsTr("✓ Chart saved: %1").arg(path)
        } else {
            page.saveSuccess = false
            page.saveStatusMessage = qsTr("✕ Failed to save chart: %1").arg(appController.lastError || qsTr("Error"))
        }
        statusTimer.restart()
    }

    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: page.saveStatusMessage = ""
    }

    Component.onCompleted: {
        if (page.appController && page.appController.sessionRestoreDecision === 1) {
            page.checkSessionRestore()
        } else {
            loadSuggestedMappings()
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
            spacing: 16

            Item { Layout.preferredHeight: 8 }

            // =================================================
            // NAVIGATION & WORKFLOW PROGRESS
            // =================================================

            Components.WorkflowNavCard {
                theme: page.theme
                appController: page.appController
                currentStepIndex: 4
                title: qsTr("Next Step: Visualization")
                subtitle: qsTr("Create interactive charts and inspect visual distribution trends for your datasets.")
                buttonText: qsTr("Proceed to Visualization →")
                buttonVisible: true
                buttonEnabled: true
                onButtonClicked: page.goToPage(5)
            }

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
                                text: qsTr("Column Mapping (Dataset 1 ⇆ Dataset 2)")
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Label {
                                text: qsTr("Sorted by automatic similarity algorithm. Only selected column pairs will be compared.")
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Button {
                            id: autoMapBtn
                            Layout.preferredWidth: 210
                            Layout.preferredHeight: 38
                            text: qsTr("⚡ Suggest Auto Mapping")
                            property bool clickFeedback: false
                            Timer {
                                id: autoMapTimer
                                interval: 450
                                onTriggered: autoMapBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: autoMapBtn.down ? theme.surfaceAlt : (autoMapBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: autoMapBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                autoMapTimer.restart()
                                page.loadSuggestedMappings()
                            }
                        }

                        Button {
                            id: addManualBtn
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 38
                            text: qsTr("+ Add Manual")
                            property bool clickFeedback: false
                            Timer {
                                id: addManualTimer
                                interval: 450
                                onTriggered: addManualBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: addManualBtn.down ? theme.surfaceAlt : (addManualBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: addManualBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                addManualTimer.restart()
                                page.addMapping()
                            }
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
                                text: qsTr("DATASET 1: %1").arg(page.name(1))
                                color: "#FF4081"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            Item { Layout.preferredWidth: 110 }
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("DATASET 2: %1").arg(page.name(2))
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
                                    valueRole: "name"

                                    function syncIndex() {
                                        var colName = (itemData && itemData.sourceColumn) ? itemData.sourceColumn : ""
                                        if (colName !== "") {
                                            var idx = find(colName)
                                            if (idx >= 0 && idx !== currentIndex) {
                                                currentIndex = idx
                                            }
                                        }
                                    }

                                    Component.onCompleted: syncIndex()
                                    onModelChanged: syncIndex()

                                    onActivated: {
                                        if (currentText !== "") {
                                            mappingRows.setProperty(rowIndex, "sourceColumn", currentText)
                                        }
                                    }
                                    onCurrentTextChanged: {
                                        if (currentText !== "" && activeFocus) {
                                            mappingRows.setProperty(rowIndex, "sourceColumn", currentText)
                                        }
                                    }
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
                                        text: itemData && itemData.similarityScore > 0 ? ("⚡ " + itemData.similarityScore + "%") : qsTr("↔ Manual")
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
                                    valueRole: "name"

                                    function syncIndex() {
                                        var colName = (itemData && itemData.targetColumn) ? itemData.targetColumn : ""
                                        if (colName !== "") {
                                            var idx = find(colName)
                                            if (idx >= 0 && idx !== currentIndex) {
                                                currentIndex = idx
                                            }
                                        }
                                    }

                                    Component.onCompleted: syncIndex()
                                    onModelChanged: syncIndex()

                                    onActivated: {
                                        if (currentText !== "") {
                                            mappingRows.setProperty(rowIndex, "targetColumn", currentText)
                                        }
                                    }
                                    onCurrentTextChanged: {
                                        if (currentText !== "" && activeFocus) {
                                            mappingRows.setProperty(rowIndex, "targetColumn", currentText)
                                        }
                                    }
                                }

                                Button {
                                    id: singleCompBtn
                                    Layout.preferredWidth: 95
                                    Layout.preferredHeight: 34
                                    text: qsTr("▶ Compare")
                                    property bool clickFeedback: false
                                    Timer {
                                        id: singleCompTimer
                                        interval: 450
                                        onTriggered: singleCompBtn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: singleCompBtn.down ? theme.surfaceAlt : (singleCompBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: singleCompBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        singleCompTimer.restart()
                                        var src = sourceCombo.currentText
                                        var tgt = targetCombo.currentText
                                        if (src && tgt && src !== "" && tgt !== "") {
                                            mappingRows.setProperty(rowIndex, "sourceColumn", src)
                                            mappingRows.setProperty(rowIndex, "targetColumn", tgt)
                                            page.runSingleComparison(src, tgt)
                                        }
                                    }
                                }

                                Button {
                                    id: removeMapBtn
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    text: "×"
                                    property bool clickFeedback: false
                                    Timer {
                                        id: removeMapTimer
                                        interval: 450
                                        onTriggered: removeMapBtn.clickFeedback = false
                                    }
                                    background: Rectangle {
                                        radius: 8
                                        color: removeMapBtn.down ? theme.surfaceAlt : (removeMapBtn.hovered ? theme.surfaceAlt : theme.surface)
                                        border.color: removeMapBtn.clickFeedback ? theme.success : theme.border
                                        border.width: 1
                                    }
                                    onClicked: {
                                        clickFeedback = true
                                        removeMapTimer.restart()
                                        page.removeMapping(rowIndex)
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        visible: mappingRows.count === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        text: qsTr("No mappings added yet. Click '⚡ Suggest Auto Mapping' or '+ Add Manual' button.")
                        color: theme.textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("%1 selected mappings will be compared").arg(validMappingCount())
                            color: theme.textSecondary
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Button {
                            id: compareSelectedBtn
                            Layout.preferredWidth: 240
                            Layout.preferredHeight: 42
                            enabled: validMappingCount() > 0
                            text: qsTr("📊 Compare Selected (%1) →").arg(validMappingCount())
                            property bool clickFeedback: false
                            Timer {
                                id: compareSelectedTimer
                                interval: 450
                                onTriggered: compareSelectedBtn.clickFeedback = false
                            }
                            background: Rectangle {
                                radius: 8
                                color: compareSelectedBtn.down ? theme.surfaceAlt : (compareSelectedBtn.hovered ? theme.surfaceAlt : theme.surface)
                                border.color: compareSelectedBtn.clickFeedback ? theme.success : theme.border
                                border.width: 1
                            }
                            onClicked: {
                                clickFeedback = true
                                compareSelectedTimer.restart()
                                page.runComparison()
                            }
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
                                 Label {
                            text: qsTr("Comparison Results")
                            color: theme.text
                            font.pixelSize: 15
                            font.bold: true
                        }

                        ListView {
                            id: compList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
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
                                            text: qsTr("Mean Diff: %1 • Median Diff: %2").arg(Number(modelData.meanDifference || 0).toFixed(2)).arg(Number(modelData.medianDifference || 0).toFixed(2))
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
                            text: qsTr("No comparison performed yet. Select mappings above and click 'Compare Selected'.")
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
                                text: curr ? (curr.sourceColumn + " (D1) vs " + curr.targetColumn + " (D2)") : qsTr("Comparison Chart")
                                color: theme.text
                                font.pixelSize: 14
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                            }

                            ComboBox {
                                id: chartTypeCombo
                                Layout.preferredWidth: 190
                                Layout.preferredHeight: 34
                                model: [qsTr("Column Statistics"), qsTr("Distribution / Density"), qsTr("Box Plot"), qsTr("Trend / Line")]
                                onActivated: {
                                    switch (currentIndex) {
                                    case 0: page.compChartType = "stats"; break;
                                    case 1: page.compChartType = "distribution"; break;
                                    case 2: page.compChartType = "boxplot"; break;
                                    case 3: page.compChartType = "trend"; break;
                                    }
                                    compCanvas.requestPaint()
                                    page.saveComparisonState()
                                }
                            }

                            Button {
                                id: saveCompChartBtn
                                Layout.preferredWidth: 140
                                Layout.preferredHeight: 34
                                text: qsTr("💾 Save Chart")
                                property bool clickFeedback: false
                                Timer {
                                    id: saveCompChartTimer
                                    interval: 450
                                    onTriggered: saveCompChartBtn.clickFeedback = false
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: saveCompChartBtn.down ? theme.surfaceAlt : (saveCompChartBtn.hovered ? theme.surfaceAlt : theme.surface)
                                    border.color: saveCompChartBtn.clickFeedback ? theme.success : theme.border
                                    border.width: 1
                                }
                                onClicked: {
                                    clickFeedback = true
                                    saveCompChartTimer.restart()
                                    page.saveChart()
                                }
                            }
                        }

                        // Legend
                        RowLayout {
                            spacing: 14
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#FF4081" }
                                Label { text: qsTr("Dataset 1 (%1)").arg(page.name(1)); color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                            RowLayout {
                                spacing: 6
                                Rectangle { width: 12; height: 12; radius: 6; color: "#7C4DFF" }
                                Label { text: qsTr("Dataset 2 (%1)").arg(page.name(2)); color: theme.text; font.pixelSize: 11; font.bold: true }
                            }
                        }

                        // Canvas
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Canvas {
                                id: compCanvas
                                anchors.fill: parent

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    var resList = page.comparisonResult.results || []
                                    if (resList.length === 0 || page.selectedComparisonIndex >= resList.length) {
                                        return
                                    }

                                    var dataItem = resList[page.selectedComparisonIndex]
                                if (appController) {
                                    appController.setVisualizationAvailable(true)
                                }
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
                                        { name: qsTr("Mean"), diff: dataItem.meanDifference || 0 },
                                        { name: qsTr("Median"), diff: dataItem.medianDifference || 0 },
                                        { name: qsTr("IQR Change"), diff: dataItem.iqrDifference || 0 },
                                        { name: qsTr("Std. Dev."), diff: dataItem.standardDeviationDifference || 0 }
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
                                else if (page.compChartType === "trend") {
                                    var trendData = appController.createDatasetComparisonChart(dataItem.sourceColumn, dataItem.targetColumn)
                                    if (!trendData || !trendData.success || !trendData.sourceValues || trendData.sourceValues.length === 0) {
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "12px sans-serif"
                                        ctx.textAlign = "center"
                                        ctx.fillText(trendData ? (trendData.errorMessage || qsTr("No numeric trend data available.")) : qsTr("No trend data."), width / 2, height / 2)
                                        return
                                    }

                                    var sVals = trendData.sourceValues
                                    var tVals = trendData.targetValues
                                    var totalPts = Math.min(sVals.length, tVals.length)

                                    if (totalPts <= 0) {
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "12px sans-serif"
                                        ctx.textAlign = "center"
                                        ctx.fillText(qsTr("No paired data points found for trend analysis."), width / 2, height / 2)
                                        return
                                    }

                                    // Find global min and max Y
                                    var minY = sVals[0]
                                    var maxY = sVals[0]
                                    for (var ti = 0; ti < totalPts; ++ti) {
                                        var v1 = sVals[ti]
                                        var v2 = tVals[ti]
                                        if (v1 < minY) minY = v1
                                        if (v1 > maxY) maxY = v1
                                        if (v2 < minY) minY = v2
                                        if (v2 > maxY) maxY = v2
                                    }
                                    if (minY === maxY) {
                                        minY -= 1.0
                                        maxY += 1.0
                                    }
                                    var yRng = maxY - minY

                                    function yToCoord(v) {
                                        return (height - padB) - ((v - minY) / yRng) * (plotH - 20) - 10
                                    }

                                    // Downsampling for high-performance smooth rendering with 100k+ rows
                                    var maxRenderPoints = 600
                                    var tStep = totalPts > maxRenderPoints ? Math.ceil(totalPts / maxRenderPoints) : 1

                                    // Draw grid lines & Y labels
                                    ctx.strokeStyle = theme.border
                                    ctx.lineWidth = 1
                                    ctx.setLineDash([4, 4])
                                    for (var tg = 0; tg <= 4; ++tg) {
                                        var tgVal = minY + (tg / 4.0) * yRng
                                        var tgy = yToCoord(tgVal)
                                        ctx.beginPath()
                                        ctx.moveTo(padL, tgy)
                                        ctx.lineTo(width - padR, tgy)
                                        ctx.stroke()

                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "10px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText(Number(tgVal).toFixed(1), padL - 8, tgy + 3)
                                    }
                                    ctx.setLineDash([])

                                    // Dataset 1 Series (Pink/Red: #FF4081)
                                    ctx.strokeStyle = "#FF4081"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    var first1 = true
                                    for (var tp = 0; tp < totalPts; tp += tStep) {
                                        var xPos = padL + (tp / (totalPts - 1 || 1)) * plotW
                                        var yPos = yToCoord(sVals[tp])
                                        if (first1) { ctx.moveTo(xPos, yPos); first1 = false; }
                                        else { ctx.lineTo(xPos, yPos); }
                                    }
                                    if ((totalPts - 1) % tStep !== 0) {
                                        var xLast = padL + plotW
                                        var yLast = yToCoord(sVals[totalPts - 1])
                                        ctx.lineTo(xLast, yLast)
                                    }
                                    ctx.stroke()

                                    // Dataset 2 Series (Purple: #7C4DFF)
                                    ctx.strokeStyle = "#7C4DFF"
                                    ctx.lineWidth = 2.5
                                    ctx.beginPath()
                                    var first2 = true
                                    for (var tq = 0; tq < totalPts; tq += tStep) {
                                        var xPos2 = padL + (tq / (totalPts - 1 || 1)) * plotW
                                        var yPos2 = yToCoord(tVals[tq])
                                        if (first2) { ctx.moveTo(xPos2, yPos2); first2 = false; }
                                        else { ctx.lineTo(xPos2, yPos2); }
                                    }
                                    if ((totalPts - 1) % tStep !== 0) {
                                        var xLast2 = padL + plotW
                                        var yLast2 = yToCoord(tVals[totalPts - 1])
                                        ctx.lineTo(xLast2, yLast2)
                                    }
                                    ctx.stroke()

                                    // X Axis Labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "11px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText(qsTr("Sample / Record Index (1 to %1)").arg(totalPts), padL + plotW / 2, height - padB + 30)

                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "left"
                                    ctx.fillText("1", padL, height - padB + 16)
                                    ctx.textAlign = "center"
                                    ctx.fillText(Math.floor(totalPts / 2).toString(), padL + plotW / 2, height - padB + 16)
                                    ctx.textAlign = "right"
                                    ctx.fillText(totalPts.toString(), width - padR, height - padB + 16)
                                }
                                else if (page.compChartType === "distribution") {
                                    var distData = appController.createDatasetComparisonDistributionChart(dataItem.sourceColumn, dataItem.targetColumn, 25)
                                    if (!distData || !distData.success || !distData.centers || distData.centers.length === 0) {
                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "12px sans-serif"
                                        ctx.textAlign = "center"
                                        ctx.fillText(distData ? (distData.errorMessage || qsTr("No distribution data available.")) : qsTr("No distribution data."), width / 2, height / 2)
                                        return
                                    }

                                    var dCenters = distData.centers
                                    var sDensities = distData.sourceDensities
                                    var tDensities = distData.targetDensities
                                    var dBinCount = dCenters.length
                                    var minX = distData.minimum
                                    var maxX = distData.maximum
                                    var xRng = (maxX - minX) === 0 ? 1.0 : (maxX - minX)

                                    // Find max density for Y scale
                                    var maxDensity = 0.001
                                    for (var dk = 0; dk < dBinCount; ++dk) {
                                        if (sDensities[dk] > maxDensity) maxDensity = sDensities[dk]
                                        if (tDensities[dk] > maxDensity) maxDensity = tDensities[dk]
                                    }
                                    maxDensity = maxDensity * 1.15

                                    function xToDistCoord(val) {
                                        return padL + ((val - minX) / xRng) * plotW
                                    }

                                    function densityToCoord(dens) {
                                        return (height - padB) - (dens / maxDensity) * (plotH - 20) - 5
                                    }

                                    // Draw grid lines & Y labels (density % or relative)
                                    ctx.strokeStyle = theme.border
                                    ctx.lineWidth = 1
                                    ctx.setLineDash([4, 4])
                                    for (var gd = 0; gd <= 4; ++gd) {
                                        var dVal = (gd / 4.0) * maxDensity
                                        var dgy = densityToCoord(dVal)
                                        ctx.beginPath()
                                        ctx.moveTo(padL, dgy)
                                        ctx.lineTo(width - padR, dgy)
                                        ctx.stroke()

                                        ctx.fillStyle = theme.textSecondary
                                        ctx.font = "10px sans-serif"
                                        ctx.textAlign = "right"
                                        ctx.fillText((dVal * 100).toFixed(1) + "%", padL - 8, dgy + 3)
                                    }
                                    ctx.setLineDash([])

                                    var zeroY = height - padB

                                    // Area & Curve for Dataset 1 (Pink #FF4081)
                                    if (distData.sourceValidCount > 0) {
                                        // Fill Area
                                        ctx.fillStyle = "rgba(255, 64, 129, 0.18)"
                                        ctx.beginPath()
                                        ctx.moveTo(xToDistCoord(dCenters[0]), zeroY)
                                        for (var d1 = 0; d1 < dBinCount; ++d1) {
                                            ctx.lineTo(xToDistCoord(dCenters[d1]), densityToCoord(sDensities[d1]))
                                        }
                                        ctx.lineTo(xToDistCoord(dCenters[dBinCount - 1]), zeroY)
                                        ctx.closePath()
                                        ctx.fill()

                                        // Stroke Line
                                        ctx.strokeStyle = "#FF4081"
                                        ctx.lineWidth = 2.5
                                        ctx.beginPath()
                                        for (var sl1 = 0; sl1 < dBinCount; ++sl1) {
                                            var cx1 = xToDistCoord(dCenters[sl1])
                                            var cy1 = densityToCoord(sDensities[sl1])
                                            if (sl1 === 0) ctx.moveTo(cx1, cy1); else ctx.lineTo(cx1, cy1);
                                        }
                                        ctx.stroke()

                                        // Draw points
                                        ctx.fillStyle = "#FF4081"
                                        for (var pt1 = 0; pt1 < dBinCount; ++pt1) {
                                            var px1 = xToDistCoord(dCenters[pt1])
                                            var py1 = densityToCoord(sDensities[pt1])
                                            ctx.beginPath()
                                            ctx.arc(px1, py1, 3.5, 0, 2 * Math.PI)
                                            ctx.fill()
                                        }
                                    }

                                    // Area & Curve for Dataset 2 (Purple #7C4DFF)
                                    if (distData.targetValidCount > 0) {
                                        // Fill Area
                                        ctx.fillStyle = "rgba(124, 77, 255, 0.18)"
                                        ctx.beginPath()
                                        ctx.moveTo(xToDistCoord(dCenters[0]), zeroY)
                                        for (var d2 = 0; d2 < dBinCount; ++d2) {
                                            ctx.lineTo(xToDistCoord(dCenters[d2]), densityToCoord(tDensities[d2]))
                                        }
                                        ctx.lineTo(xToDistCoord(dCenters[dBinCount - 1]), zeroY)
                                        ctx.closePath()
                                        ctx.fill()

                                        // Stroke Line
                                        ctx.strokeStyle = "#7C4DFF"
                                        ctx.lineWidth = 2.5
                                        ctx.beginPath()
                                        for (var sl2 = 0; sl2 < dBinCount; ++sl2) {
                                            var cx2 = xToDistCoord(dCenters[sl2])
                                            var cy2 = densityToCoord(tDensities[sl2])
                                            if (sl2 === 0) ctx.moveTo(cx2, cy2); else ctx.lineTo(cx2, cy2);
                                        }
                                        ctx.stroke()

                                        // Draw points
                                        ctx.fillStyle = "#7C4DFF"
                                        for (var pt2 = 0; pt2 < dBinCount; ++pt2) {
                                            var px2 = xToDistCoord(dCenters[pt2])
                                            var py2 = densityToCoord(tDensities[pt2])
                                            ctx.beginPath()
                                            ctx.arc(px2, py2, 3.5, 0, 2 * Math.PI)
                                            ctx.fill()
                                        }
                                    }

                                    // X Axis Labels (Values)
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "11px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.fillText(qsTr("Column Value Domain (%1 to %2)").arg(Number(minX).toFixed(1)).arg(Number(maxX).toFixed(1)), padL + plotW / 2, height - padB + 30)

                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "left"
                                    ctx.fillText(Number(minX).toFixed(1), padL, height - padB + 16)
                                    ctx.textAlign = "center"
                                    ctx.fillText(Number((minX + maxX) / 2).toFixed(1), padL + plotW / 2, height - padB + 16)
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(maxX).toFixed(1), width - padR, height - padB + 16)
                                }
                                else if (page.compChartType === "boxplot") {
                                    var bp1 = appController.createDataset1BoxPlot(dataItem.sourceColumn, 1.5)
                                    var bp2 = appController.createDataset2BoxPlot(dataItem.targetColumn, 1.5)

                                    var min1 = (bp1 && bp1.minimum !== undefined) ? bp1.minimum : 0
                                    var max1 = (bp1 && bp1.maximum !== undefined) ? bp1.maximum : 100
                                    var min2 = (bp2 && bp2.minimum !== undefined) ? bp2.minimum : 0
                                    var max2 = (bp2 && bp2.maximum !== undefined) ? bp2.maximum : 100

                                    var globalMin = Math.min(min1, min2)
                                    var globalMax = Math.max(max1, max2)
                                    var rng = (globalMax - globalMin) === 0 ? 1 : (globalMax - globalMin)

                                    function valToY(v) {
                                        return (height - padB) - ((v - globalMin) / rng) * (plotH - 40) - 20
                                    }

                                    var c1X = padL + plotW * 0.35
                                    var c2X = padL + plotW * 0.65
                                    var bW = 70

                                    // Box 1 (Dataset 1)
                                    if (bp1 && bp1.success) {
                                        var q1_1 = bp1.q1, med1 = bp1.median, q3_1 = bp1.q3
                                        var lW1 = bp1.lowerWhisker !== undefined ? bp1.lowerWhisker : min1
                                        var uW1 = bp1.upperWhisker !== undefined ? bp1.upperWhisker : max1

                                        ctx.strokeStyle = "#FF4081"; ctx.lineWidth = 2
                                        ctx.beginPath()
                                        ctx.moveTo(c1X, valToY(lW1)); ctx.lineTo(c1X, valToY(uW1))
                                        ctx.moveTo(c1X - 15, valToY(lW1)); ctx.lineTo(c1X + 15, valToY(lW1))
                                        ctx.moveTo(c1X - 15, valToY(uW1)); ctx.lineTo(c1X + 15, valToY(uW1))
                                        ctx.stroke()

                                        var yQ3_1 = valToY(q3_1), yQ1_1 = valToY(q1_1)
                                        var grad1 = ctx.createLinearGradient(c1X - bW/2, yQ3_1, c1X + bW/2, yQ1_1)
                                        grad1.addColorStop(0, "#FF4081")
                                        grad1.addColorStop(1, "#FF80AB")
                                        ctx.fillStyle = grad1
                                        ctx.fillRect(c1X - bW/2, yQ3_1, bW, yQ1_1 - yQ3_1)
                                        ctx.strokeStyle = "#C2185B"
                                        ctx.strokeRect(c1X - bW/2, yQ3_1, bW, yQ1_1 - yQ3_1)

                                        ctx.strokeStyle = "#FFD600"; ctx.lineWidth = 3
                                        ctx.beginPath()
                                        ctx.moveTo(c1X - bW/2, valToY(med1)); ctx.lineTo(c1X + bW/2, valToY(med1))
                                        ctx.stroke()

                                        ctx.fillStyle = theme.text; ctx.font = "bold 9px sans-serif"; ctx.textAlign = "right"
                                        ctx.fillText("Med: " + Number(med1).toFixed(1), c1X - bW/2 - 6, valToY(med1) + 3)
                                    }

                                    // Box 2 (Dataset 2)
                                    if (bp2 && bp2.success) {
                                        var q1_2 = bp2.q1, med2 = bp2.median, q3_2 = bp2.q3
                                        var lW2 = bp2.lowerWhisker !== undefined ? bp2.lowerWhisker : min2
                                        var uW2 = bp2.upperWhisker !== undefined ? bp2.upperWhisker : max2

                                        ctx.strokeStyle = "#7C4DFF"; ctx.lineWidth = 2
                                        ctx.beginPath()
                                        ctx.moveTo(c2X, valToY(lW2)); ctx.lineTo(c2X, valToY(uW2))
                                        ctx.moveTo(c2X - 15, valToY(lW2)); ctx.lineTo(c2X + 15, valToY(lW2))
                                        ctx.moveTo(c2X - 15, valToY(uW2)); ctx.lineTo(c2X + 15, valToY(uW2))
                                        ctx.stroke()

                                        var yQ3_2 = valToY(q3_2), yQ1_2 = valToY(q1_2)
                                        var grad2 = ctx.createLinearGradient(c2X - bW/2, yQ3_2, c2X + bW/2, yQ1_2)
                                        grad2.addColorStop(0, "#7C4DFF")
                                        grad2.addColorStop(1, "#00E5FF")
                                        ctx.fillStyle = grad2
                                        ctx.fillRect(c2X - bW/2, yQ3_2, bW, yQ1_2 - yQ3_2)
                                        ctx.strokeStyle = "#512DA8"
                                        ctx.strokeRect(c2X - bW/2, yQ3_2, bW, yQ1_2 - yQ3_2)

                                        ctx.strokeStyle = "#FFD600"; ctx.lineWidth = 3
                                        ctx.beginPath()
                                        ctx.moveTo(c2X - bW/2, valToY(med2)); ctx.lineTo(c2X + bW/2, valToY(med2))
                                        ctx.stroke()

                                        ctx.fillStyle = theme.text; ctx.font = "bold 9px sans-serif"; ctx.textAlign = "left"
                                        ctx.fillText("Med: " + Number(med2).toFixed(1), c2X + bW/2 + 6, valToY(med2) + 3)
                                    }

                                    ctx.fillStyle = theme.text; ctx.font = "bold 11px sans-serif"; ctx.textAlign = "center"
                                    ctx.fillText((dataItem.sourceColumn || "") + " (D1)", c1X, height - padB + 20)
                                    ctx.fillText((dataItem.targetColumn || "") + " (D2)", c2X, height - padB + 20)

                                    // Y min/max labels
                                    ctx.fillStyle = theme.textSecondary
                                    ctx.font = "10px sans-serif"
                                    ctx.textAlign = "right"
                                    ctx.fillText(Number(globalMax).toFixed(1), padL - 8, padT + 10)
                                    ctx.fillText(Number(globalMin).toFixed(1), padL - 8, height - padB)
                                }
                            }

                            Item {
                                anchors.fill: parent
                                visible: (!page.comparisonResult || !page.comparisonResult.results || page.comparisonResult.results.length === 0)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 10

                                    Components.ByteMascot {
                                        Layout.alignment: Qt.AlignHCenter
                                        mascotWidth: 120
                                        mascotHeight: 120
                                        source: "qrc:/assets/byte/byte_comparing.png"
                                        animated: false
                                    }

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("Select a mapping from the left to view comparison chart.")
                                        color: theme.textSecondary
                                        font.pixelSize: 13
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
}