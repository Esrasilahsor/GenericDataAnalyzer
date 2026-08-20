import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: window

    visible: true
    width: 1350
    height: 850

    minimumWidth: 1050
    minimumHeight: 700

    title: "Generic Data Analyzer"
    color: "#151922"

    // =====================================================
    // HELPERS
    // =====================================================

    function formatNumber(value) {
        if (value === undefined || value === null)
            return "-"

        return Number(value).toFixed(2)
    }

    function formatDifference(value) {
        if (value === undefined || value === null)
            return "-"

        var number = Number(value)

        if (number > 0)
            return "+" + number.toFixed(2)

        return number.toFixed(2)
    }

    function formatList(value) {
        if (value === undefined || value === null)
            return "-"

        if (value.length === 0)
            return "None"

        return value.join(", ")
    }

    // =====================================================
    // FILE DIALOGS
    // =====================================================

    FileDialog {
        id: dataset1Dialog

        title: "Select Dataset 1"

        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadDataset1(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }

            dataset1OutlierColumn.currentIndex = -1
            dataset1FillColumn.currentIndex = -1
            dataset1CleaningOutlierColumn.currentIndex = -1
            dataset1CleaningOutlierMethod.currentIndex = 0
            dataset1CleaningOutlierAction.currentIndex = 0
        }
    }

    FileDialog {
        id: dataset2Dialog

        title: "Select Dataset 2"

        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadDataset2(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }

            dataset2OutlierColumn.currentIndex = -1
            dataset2FillColumn.currentIndex = -1
            dataset2CleaningOutlierColumn.currentIndex = -1
            dataset2CleaningOutlierMethod.currentIndex = 0
            dataset2CleaningOutlierAction.currentIndex = 0
        }
    }

    FileDialog {
        id: rawMetadataDialog

        title: "Select Raw Metadata Excel"

        nameFilters: [
            "Excel Files (*.xlsx)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadRawMetadata(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }
        }
    }

    FileDialog {
        id: rawDataDialog

        title: "Select Raw Data File"

        nameFilters: [
            "Raw Data Files (*.bin *.dat *.raw)",
            "All Files (*)"
        ]

        selectExisting: true
        selectMultiple: false

        onAccepted: {
            var success =
                    appController.loadRawDataFile(fileUrl)

            if (!success) {
                errorDialog.text =
                        appController.lastError

                errorDialog.open()
            }
        }
    }

    MessageDialog {
        id: errorDialog

        title: "Error"
        icon: StandardIcon.Critical
    }

    // =====================================================
    // HEADER
    // =====================================================

    Rectangle {
        id: headerBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 70

        color: "#1D2330"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            spacing: 20

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: "Generic Data Analyzer"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Item {
                width: Math.max(
                           0,
                           headerBar.width - 500
                       )

                height: 1
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: "Excel & Raw Data Analysis Platform"

                color: "#AAB2C0"

                font.pixelSize: 14
            }
        }
    }

    // =====================================================
    // MAIN SCROLL AREA
    // =====================================================

    Flickable {
        id: flickable

        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        clip: true

        contentWidth: width
        contentHeight: contentColumn.height + 60

        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Column {
            id: contentColumn

            width: flickable.width

            spacing: 24

            Item {
                width: 1
                height: 25
            }

            // =================================================
            // DATASET SELECTION
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Dataset Selection"

                    color: "white"

                    font.pixelSize: 28
                    font.bold: true
                }

                Text {
                    text: "Select two Excel datasets to start the analysis."

                    color: "#AAB2C0"

                    font.pixelSize: 15
                }
            }

            Row {
                width: parent.width - 60
                height: 215

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Dataset 1"

                            color: "white"

                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.dataset1Name.length > 0
                                ? appController.dataset1Name
                                : "No Excel file selected"

                            color: "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset1Name.length > 0

                            text:
                                "Sheet: "
                                + appController.dataset1SheetName

                            color: "#AAB2C0"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset1Name.length > 0

                            text:
                                "Rows: "
                                + appController.dataset1RowCount
                                + " | Columns: "
                                + appController.dataset1ColumnCount

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 175
                            height: 42

                            text:
                                appController.dataset1Name.length > 0
                                ? "Change Excel 1"
                                : "Select Excel 1"

                            onClicked:
                                dataset1Dialog.open()
                        }
                    }
                }

                // =============================================
                // DATASET 2
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Dataset 2"

                            color: "white"

                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.dataset2Name.length > 0
                                ? appController.dataset2Name
                                : "No Excel file selected"

                            color: "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset2Name.length > 0

                            text:
                                "Sheet: "
                                + appController.dataset2SheetName

                            color: "#AAB2C0"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.dataset2Name.length > 0

                            text:
                                "Rows: "
                                + appController.dataset2RowCount
                                + " | Columns: "
                                + appController.dataset2ColumnCount

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 175
                            height: 42

                            text:
                                appController.dataset2Name.length > 0
                                ? "Change Excel 2"
                                : "Select Excel 2"

                            onClicked:
                                dataset2Dialog.open()
                        }
                    }
                }
            }

            // =================================================
            // COLUMN DISCOVERY
            // =================================================

            Text {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                text: "Column Discovery"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Row {
                width: parent.width - 60
                height: 340

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 COLUMNS
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15

                        spacing: 10

                        Text {
                            text: "Dataset 1 Columns"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width
                            height: 40

                            radius: 6
                            color: "#262E3D"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    width: parent.width - 245

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Column"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Type"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Missing"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Unique"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: 245

                            clip: true

                            model:
                                appController.dataset1ColumnModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        width: parent.width - 245

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.name

                                        color: "white"

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 85

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.dataType

                                        color:
                                            model.isNumeric
                                            ? "#9CCBFF"
                                            : "#D2B4FF"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.missingCount

                                        color:
                                            model.missingCount > 0
                                            ? "#FFB4AB"
                                            : "#AAB2C0"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.uniqueCount

                                        color: "#AAB2C0"
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                visible:
                                    appController.dataset1ColumnModel.count() === 0

                                text:
                                    "Load Dataset 1 to discover columns"

                                color: "#7F899A"
                            }
                        }
                    }
                }

                // =============================================
                // DATASET 2 COLUMNS
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color: "#30394A"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15

                        spacing: 10

                        Text {
                            text: "Dataset 2 Columns"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            width: parent.width
                            height: 40

                            radius: 6
                            color: "#262E3D"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text {
                                    width: parent.width - 245

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Column"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Type"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Missing"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }

                                Text {
                                    width: 80

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Unique"

                                    color: "#D7DCE5"
                                    font.bold: true
                                }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: 245

                            clip: true

                            model:
                                appController.dataset2ColumnModel

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 42

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent

                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Text {
                                        width: parent.width - 245

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.name

                                        color: "white"

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: 85

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.dataType

                                        color:
                                            model.isNumeric
                                            ? "#9CCBFF"
                                            : "#D2B4FF"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.missingCount

                                        color:
                                            model.missingCount > 0
                                            ? "#FFB4AB"
                                            : "#AAB2C0"
                                    }

                                    Text {
                                        width: 80

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: model.uniqueCount

                                        color: "#AAB2C0"
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                visible:
                                    appController.dataset2ColumnModel.count() === 0

                                text:
                                    "Load Dataset 2 to discover columns"

                                color: "#7F899A"
                            }
                        }
                    }
                }
            }

            // =================================================
            // DATA QUALITY
            // =================================================

            Text {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                text: "Dataset Quality Analysis"

                color: "white"

                font.pixelSize: 24
                font.bold: true
            }

            Row {
                width: parent.width - 60
                height: 480

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 QUALITY
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1QualityAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Row {
                            width: parent.width
                            height: 42

                            Text {
                                width: parent.width - 170

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1 Quality"

                                color: "white"

                                font.pixelSize: 18
                                font.bold: true
                            }

                            Button {
                                width: 170
                                height: 38

                                text:
                                    appController.dataset1QualityAvailable
                                    ? "Reanalyze Quality"
                                    : "Analyze Quality"

                                enabled:
                                    appController.dataset1Name.length > 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset1Quality()

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset1QualityAvailable

                            width: parent.width

                            text:
                                appController.dataset1Name.length > 0
                                ? "Click Analyze Quality to inspect this dataset."
                                : "Load Dataset 1 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 6

                            visible:
                                appController.dataset1QualityAvailable

                            Rectangle {
                                width: parent.width
                                height: 36

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Rows: "
                                        + appController.dataset1QualityResult["rowCount"]
                                        + "   |   Columns: "
                                        + appController.dataset1QualityResult["columnCount"]

                                    color: "white"
                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Missing Values: "
                                    + appController.dataset1QualityResult["totalMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Missing Percentage: "
                                    + formatNumber(
                                          appController.dataset1QualityResult["missingPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset1QualityResult["totalMissingValues"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Columns With Missing: "
                                    + appController.dataset1QualityResult["columnsWithMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Missing Columns: "
                                    + formatList(
                                          appController.dataset1QualityResult["columnsWithMissing"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Duplicate Rows: "
                                    + appController.dataset1QualityResult["duplicateRowCount"]

                                color:
                                    appController.dataset1QualityResult["duplicateRowCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Duplicate Percentage: "
                                    + formatNumber(
                                          appController.dataset1QualityResult["duplicatePercentage"]
                                      )
                                    + "%"

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Constant Columns: "
                                    + appController.dataset1QualityResult["constantColumnCount"]

                                color:
                                    appController.dataset1QualityResult["constantColumnCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Constant Column Names: "
                                    + formatList(
                                          appController.dataset1QualityResult["constantColumns"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Numeric Columns: "
                                    + appController.dataset1QualityResult["numericColumnCount"]

                                color: "#9CCBFF"
                            }

                            Text {
                                text:
                                    "Non-Numeric Columns: "
                                    + appController.dataset1QualityResult["nonNumericColumnCount"]

                                color: "#D2B4FF"
                            }
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 140
                            height: 36

                            visible:
                                appController.dataset1QualityAvailable

                            text: "Clear Quality"

                            onClicked:
                                appController.clearDataset1Quality()
                        }
                    }
                }

                // =============================================
                // DATASET 2 QUALITY
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2QualityAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Row {
                            width: parent.width
                            height: 42

                            Text {
                                width: parent.width - 170

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2 Quality"

                                color: "white"

                                font.pixelSize: 18
                                font.bold: true
                            }

                            Button {
                                width: 170
                                height: 38

                                text:
                                    appController.dataset2QualityAvailable
                                    ? "Reanalyze Quality"
                                    : "Analyze Quality"

                                enabled:
                                    appController.dataset2Name.length > 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset2Quality()

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset2QualityAvailable

                            width: parent.width

                            text:
                                appController.dataset2Name.length > 0
                                ? "Click Analyze Quality to inspect this dataset."
                                : "Load Dataset 2 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 6

                            visible:
                                appController.dataset2QualityAvailable

                            Rectangle {
                                width: parent.width
                                height: 36

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Rows: "
                                        + appController.dataset2QualityResult["rowCount"]
                                        + "   |   Columns: "
                                        + appController.dataset2QualityResult["columnCount"]

                                    color: "white"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Missing Values: "
                                    + appController.dataset2QualityResult["totalMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Missing Percentage: "
                                    + formatNumber(
                                          appController.dataset2QualityResult["missingPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset2QualityResult["totalMissingValues"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Columns With Missing: "
                                    + appController.dataset2QualityResult["columnsWithMissingValues"]

                                color: "#D7DCE5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Missing Columns: "
                                    + formatList(
                                          appController.dataset2QualityResult["columnsWithMissing"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Duplicate Rows: "
                                    + appController.dataset2QualityResult["duplicateRowCount"]

                                color:
                                    appController.dataset2QualityResult["duplicateRowCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                text:
                                    "Duplicate Percentage: "
                                    + formatNumber(
                                          appController.dataset2QualityResult["duplicatePercentage"]
                                      )
                                    + "%"

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Constant Columns: "
                                    + appController.dataset2QualityResult["constantColumnCount"]

                                color:
                                    appController.dataset2QualityResult["constantColumnCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Constant Column Names: "
                                    + formatList(
                                          appController.dataset2QualityResult["constantColumns"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Numeric Columns: "
                                    + appController.dataset2QualityResult["numericColumnCount"]

                                color: "#9CCBFF"
                            }

                            Text {
                                text:
                                    "Non-Numeric Columns: "
                                    + appController.dataset2QualityResult["nonNumericColumnCount"]

                                color: "#D2B4FF"
                            }
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 140
                            height: 36

                            visible:
                                appController.dataset2QualityAvailable

                            text: "Clear Quality"

                            onClicked:
                                appController.clearDataset2Quality()
                        }
                    }
                }
            }


            // =========================================================
            // DATA CLEANING
            // =========================================================

            Column {
                width: parent.width - 60
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Data Cleaning"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text:
                        "Cleaning operations are applied only to the working dataset. "
                        + "The original dataset is preserved and can be restored."

                    color: "#AAB2C0"

                    font.pixelSize: 14

                    wrapMode: Text.WordWrap
                }
            }


            // =========================================================
            // CLEANING PANELS
            // =========================================================

            Row {
                width: parent.width - 60
                height: 1280

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20


                // =====================================================
                // DATASET 1
                // =====================================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1Modified
                        ? "#C792EA"
                        : "#30394A"

                    border.width: 1


                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12


                        // -------------------------------------------------
                        // TITLE
                        // -------------------------------------------------

                        Text {
                            text: "Dataset 1 Cleaning"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }


                        // -------------------------------------------------
                        // STATUS
                        // -------------------------------------------------

                        Text {
                            width: parent.width

                            text:
                                appController.dataset1Name.length > 0
                                ?
                                (
                                    appController.dataset1Modified
                                    ? "Working dataset has been modified."
                                    : "Working dataset is identical to the original."
                                )
                                :
                                "Load Dataset 1 first."

                            color:
                                appController.dataset1Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"

                            wrapMode: Text.WordWrap
                        }


                        // -------------------------------------------------
                        // ROW COUNT
                        // -------------------------------------------------

                        Rectangle {
                            width: parent.width
                            height: 42

                            radius: 6

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    appController.dataset1Name.length > 0
                                    ?
                                    "Current Rows: "
                                    + appController.dataset1RowCount
                                    :
                                    "No Dataset"

                                color: "white"

                                font.bold: true
                            }
                        }


                        // =================================================
                        // ROW OPERATIONS
                        // =================================================

                        Text {
                            text: "Row Operations"

                            color: "#9CCBFF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Duplicate Rows"

                            enabled:
                                appController.dataset1Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset1Duplicates()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Rows With Missing Values"

                            enabled:
                                appController.dataset1Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset1MissingRows()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 1

                            color: "#30394A"
                        }


                        // =================================================
                        // FILL MISSING
                        // =================================================

                        Text {
                            text: "Fill Missing Values"

                            color: "#9CCBFF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Text {
                            text: "Select Column"

                            color: "#AAB2C0"
                        }


                        ComboBox {
                            id: dataset1FillColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset1ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }


                        // -------------------------------------------------
                        // SELECTED COLUMN INFO
                        // -------------------------------------------------

                        Rectangle {
                            width: parent.width
                            height: 38

                            radius: 5

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    dataset1FillColumn.currentIndex >= 0
                                    ?
                                    "Selected Column: "
                                    + dataset1FillColumn.currentText
                                    :
                                    "No column selected"

                                color:
                                    dataset1FillColumn.currentIndex >= 0
                                    ? "#9CCBFF"
                                    : "#7F899A"

                                font.bold:
                                    dataset1FillColumn.currentIndex >= 0
                            }
                        }


                        // -------------------------------------------------
                        // MEAN
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mean"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MEAN COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMean(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MEAN SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        // -------------------------------------------------
                        // MEDIAN
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Median"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MEDIAN COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMedian(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MEDIAN SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        // -------------------------------------------------
                        // MODE
                        // -------------------------------------------------

                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mode"

                            enabled:
                                dataset1FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "MODE COLUMN:",
                                    dataset1FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset1MissingWithMode(
                                            dataset1FillColumn.currentText
                                        )

                                console.log(
                                    "MODE SUCCESS:",
                                    success
                                )

                                console.log(
                                    "MODE ERROR:",
                                    appController.lastError
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }



                        // =================================================
                        // OUTLIER CLEANING
                        // =================================================

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#30394A"
                        }

                        Text {
                            text: "Outlier Cleaning"
                            color: "#FFB4A9"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: "Select Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierColumn

                            width: parent.width
                            height: 42

                            model: appController.dataset1ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Text {
                            text: "Detection Method"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierMethod

                            width: parent.width
                            height: 42

                            model: [
                                "IQR",
                                "Z-Score"
                            ]

                            currentIndex: 0
                        }

                        Text {
                            text:
                                dataset1CleaningOutlierMethod.currentText === "IQR"
                                ? "IQR Multiplier"
                                : "Z-Score Threshold"

                            color: "#AAB2C0"
                        }

                        TextField {
                            id: dataset1CleaningOutlierParameter

                            width: parent.width
                            height: 42

                            text:
                                dataset1CleaningOutlierMethod.currentText === "IQR"
                                ? "1.5"
                                : "3.0"

                            validator: DoubleValidator {
                                bottom: 0.01
                                top: 100.0
                                decimals: 3
                            }
                        }

                        Text {
                            text: "Action"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1CleaningOutlierAction

                            width: parent.width
                            height: 42

                            model: [
                                "Keep",
                                "Mark",
                                "Remove"
                            ]

                            currentIndex: 0
                        }

                        Button {
                            width: parent.width
                            height: 42

                            text: "Apply Outlier Operation"

                            enabled:
                                dataset1CleaningOutlierColumn.currentIndex >= 0
                                &&
                                dataset1CleaningOutlierParameter.text.length > 0

                            onClicked: {
                                var success =
                                        appController.applyDataset1OutlierAction(
                                            dataset1CleaningOutlierColumn.currentText,
                                            dataset1CleaningOutlierMethod.currentText,
                                            dataset1CleaningOutlierAction.currentText,
                                            Number(
                                                dataset1CleaningOutlierParameter.text
                                            )
                                        )

                                if (!success) {
                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 150

                            visible:
                                Object.keys(
                                    appController.dataset1OutlierCleaningResult
                                ).length > 0

                            radius: 6
                            color: "#262E3D"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Text {
                                    text:
                                        "Method: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["method"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Action: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["action"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Outliers: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["outlierCount"]
                                            || 0
                                        )

                                    color: "#FFB4A9"
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Marked Rows: "
                                        + (
                                            appController.dataset1OutlierCleaningResult["markedRows"]
                                            || []
                                        ).join(", ")

                                    color: "#FFE29A"
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        appController.dataset1OutlierCleaningResult["message"]
                                        || ""

                                    color: "#9FE3B5"
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // =================================================
                        // RESTORE
                        // =================================================

                        Button {
                            width: parent.width
                            height: 44

                            text: "Restore Original Dataset"

                            enabled:
                                appController.dataset1Modified

                            onClicked: {

                                var success =
                                        appController.restoreDataset1()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }

                                dataset1FillColumn.currentIndex = -1
                                dataset1CleaningOutlierColumn.currentIndex = -1
                            }
                        }
                    }
                }

                // =====================================================
                // DATASET 2
                // =====================================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2Modified
                        ? "#C792EA"
                        : "#30394A"

                    border.width: 1


                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12


                        Text {
                            text: "Dataset 2 Cleaning"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }


                        Text {
                            width: parent.width

                            text:
                                appController.dataset2Name.length > 0
                                ?
                                (
                                    appController.dataset2Modified
                                    ? "Working dataset has been modified."
                                    : "Working dataset is identical to the original."
                                )
                                :
                                "Load Dataset 2 first."

                            color:
                                appController.dataset2Modified
                                ? "#D2B4FF"
                                : "#AAB2C0"

                            wrapMode: Text.WordWrap
                        }


                        Rectangle {
                            width: parent.width
                            height: 42

                            radius: 6

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    appController.dataset2Name.length > 0
                                    ?
                                    "Current Rows: "
                                    + appController.dataset2RowCount
                                    :
                                    "No Dataset"

                                color: "white"

                                font.bold: true
                            }
                        }


                        // =================================================
                        // ROW OPERATIONS
                        // =================================================

                        Text {
                            text: "Row Operations"

                            color: "#D2B4FF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Duplicate Rows"

                            enabled:
                                appController.dataset2Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset2Duplicates()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Remove Rows With Missing Values"

                            enabled:
                                appController.dataset2Name.length > 0

                            onClicked: {

                                var success =
                                        appController.removeDataset2MissingRows()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 1

                            color: "#30394A"
                        }


                        // =================================================
                        // FILL MISSING
                        // =================================================

                        Text {
                            text: "Fill Missing Values"

                            color: "#D2B4FF"

                            font.pixelSize: 15
                            font.bold: true
                        }


                        Text {
                            text: "Select Column"

                            color: "#AAB2C0"
                        }


                        ComboBox {
                            id: dataset2FillColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset2ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }


                        Rectangle {
                            width: parent.width
                            height: 38

                            radius: 5

                            color: "#262E3D"

                            Text {
                                anchors.centerIn: parent

                                text:
                                    dataset2FillColumn.currentIndex >= 0
                                    ?
                                    "Selected Column: "
                                    + dataset2FillColumn.currentText
                                    :
                                    "No column selected"

                                color:
                                    dataset2FillColumn.currentIndex >= 0
                                    ? "#D2B4FF"
                                    : "#7F899A"

                                font.bold:
                                    dataset2FillColumn.currentIndex >= 0
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mean"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MEAN COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMean(
                                            dataset2FillColumn.currentText
                                        )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Median"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MEDIAN COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMedian(
                                            dataset2FillColumn.currentText
                                        )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }


                        Button {
                            width: parent.width
                            height: 42

                            text: "Fill Missing With Mode"

                            enabled:
                                dataset2FillColumn.currentIndex >= 0

                            onClicked: {

                                console.log(
                                    "DATASET 2 MODE COLUMN:",
                                    dataset2FillColumn.currentText
                                )

                                var success =
                                        appController.fillDataset2MissingWithMode(
                                            dataset2FillColumn.currentText
                                        )

                                console.log(
                                    "DATASET 2 MODE SUCCESS:",
                                    success
                                )

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }



                        // =================================================
                        // OUTLIER CLEANING
                        // =================================================

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#30394A"
                        }

                        Text {
                            text: "Outlier Cleaning"
                            color: "#FFB4A9"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: "Select Numeric Column"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierColumn

                            width: parent.width
                            height: 42

                            model: appController.dataset2ColumnModel
                            textRole: "name"
                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Text {
                            text: "Detection Method"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierMethod

                            width: parent.width
                            height: 42

                            model: [
                                "IQR",
                                "Z-Score"
                            ]

                            currentIndex: 0
                        }

                        Text {
                            text:
                                dataset2CleaningOutlierMethod.currentText === "IQR"
                                ? "IQR Multiplier"
                                : "Z-Score Threshold"

                            color: "#AAB2C0"
                        }

                        TextField {
                            id: dataset2CleaningOutlierParameter

                            width: parent.width
                            height: 42

                            text:
                                dataset2CleaningOutlierMethod.currentText === "IQR"
                                ? "1.5"
                                : "3.0"

                            validator: DoubleValidator {
                                bottom: 0.01
                                top: 100.0
                                decimals: 3
                            }
                        }

                        Text {
                            text: "Action"
                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2CleaningOutlierAction

                            width: parent.width
                            height: 42

                            model: [
                                "Keep",
                                "Mark",
                                "Remove"
                            ]

                            currentIndex: 0
                        }

                        Button {
                            width: parent.width
                            height: 42

                            text: "Apply Outlier Operation"

                            enabled:
                                dataset2CleaningOutlierColumn.currentIndex >= 0
                                &&
                                dataset2CleaningOutlierParameter.text.length > 0

                            onClicked: {
                                var success =
                                        appController.applyDataset2OutlierAction(
                                            dataset2CleaningOutlierColumn.currentText,
                                            dataset2CleaningOutlierMethod.currentText,
                                            dataset2CleaningOutlierAction.currentText,
                                            Number(
                                                dataset2CleaningOutlierParameter.text
                                            )
                                        )

                                if (!success) {
                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 150

                            visible:
                                Object.keys(
                                    appController.dataset2OutlierCleaningResult
                                ).length > 0

                            radius: 6
                            color: "#262E3D"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5

                                Text {
                                    text:
                                        "Method: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["method"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Action: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["action"]
                                            || "-"
                                        )

                                    color: "#AAB2C0"
                                }

                                Text {
                                    text:
                                        "Outliers: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["outlierCount"]
                                            || 0
                                        )

                                    color: "#FFB4A9"
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Marked Rows: "
                                        + (
                                            appController.dataset2OutlierCleaningResult["markedRows"]
                                            || []
                                        ).join(", ")

                                    color: "#FFE29A"
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        appController.dataset2OutlierCleaningResult["message"]
                                        || ""

                                    color: "#9FE3B5"
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Button {
                            width: parent.width
                            height: 44

                            text: "Restore Original Dataset"

                            enabled:
                                appController.dataset2Modified

                            onClicked: {

                                var success =
                                        appController.restoreDataset2()

                                if (!success) {

                                    errorDialog.text =
                                            appController.lastError

                                    errorDialog.open()
                                }

                                dataset2FillColumn.currentIndex = -1
                                dataset2CleaningOutlierColumn.currentIndex = -1
                            }
                        }
                    }
                }
            }


            // =================================================
            // OUTLIER ANALYSIS
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 6

                Text {
                    text: "Outlier Analysis"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text:
                        "Detect numeric outliers using the IQR method (multiplier: 1.5)."

                    color: "#AAB2C0"

                    font.pixelSize: 14
                }
            }

            Row {
                width: parent.width - 60
                height: 500

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                // =============================================
                // DATASET 1 OUTLIER
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset1OutlierAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Text {
                            text: "Dataset 1 Outliers"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "Select a numeric column"

                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset1OutlierColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset1ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset1Name.length > 0
                        }

                        Row {
                            width: parent.width

                            spacing: 10

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Analyze Outliers"

                                enabled:
                                    dataset1OutlierColumn.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset1Outliers(
                                                dataset1OutlierColumn.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset1OutlierAvailable

                                onClicked:
                                    appController.clearDataset1Outliers()
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset1OutlierAvailable

                            text:
                                appController.dataset1Name.length > 0
                                ? "Choose a numeric column and run the analysis."
                                : "Load Dataset 1 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 7

                            visible:
                                appController.dataset1OutlierAvailable

                            Rectangle {
                                width: parent.width
                                height: 38

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Column: "
                                        + appController.dataset1OutlierResult["columnName"]

                                    color: "#9CCBFF"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Valid Values: "
                                    + appController.dataset1OutlierResult["validValueCount"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q1: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["q1"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q3: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["q3"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "IQR: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["iqr"]
                                      )

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Lower Bound: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["lowerBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Text {
                                text:
                                    "Upper Bound: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["upperBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Outlier Count: "
                                    + appController.dataset1OutlierResult["outlierCount"]

                                color:
                                    appController.dataset1OutlierResult["outlierCount"] > 0
                                    ? "#FFB4AB"
                                    : "#9FE3B5"

                                font.bold: true
                            }

                            Text {
                                text:
                                    "Outlier Percentage: "
                                    + formatNumber(
                                          appController.dataset1OutlierResult["outlierPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset1OutlierResult["outlierCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Outlier Values: "
                                    + formatList(
                                          appController.dataset1OutlierResult["outlierValues"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // =============================================
                // DATASET 2 OUTLIER
                // =============================================

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.dataset2OutlierAvailable
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18

                        spacing: 12

                        Text {
                            text: "Dataset 2 Outliers"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: "Select a numeric column"

                            color: "#AAB2C0"
                        }

                        ComboBox {
                            id: dataset2OutlierColumn

                            width: parent.width
                            height: 42

                            model:
                                appController.dataset2ColumnModel

                            textRole: "name"

                            currentIndex: -1

                            enabled:
                                appController.dataset2Name.length > 0
                        }

                        Row {
                            width: parent.width

                            spacing: 10

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Analyze Outliers"

                                enabled:
                                    dataset2OutlierColumn.currentIndex >= 0

                                onClicked: {
                                    var success =
                                            appController.analyzeDataset2Outliers(
                                                dataset2OutlierColumn.currentText
                                            )

                                    if (!success) {
                                        errorDialog.text =
                                                appController.lastError

                                        errorDialog.open()
                                    }
                                }
                            }

                            Button {
                                width:
                                    (parent.width - 10) / 2

                                height: 40

                                text: "Clear"

                                enabled:
                                    appController.dataset2OutlierAvailable

                                onClicked:
                                    appController.clearDataset2Outliers()
                            }
                        }

                        Text {
                            visible:
                                !appController.dataset2OutlierAvailable

                            text:
                                appController.dataset2Name.length > 0
                                ? "Choose a numeric column and run the analysis."
                                : "Load Dataset 2 first."

                            color: "#7F899A"

                            wrapMode: Text.WordWrap
                        }

                        Column {
                            width: parent.width

                            spacing: 7

                            visible:
                                appController.dataset2OutlierAvailable

                            Rectangle {
                                width: parent.width
                                height: 38

                                radius: 5
                                color: "#262E3D"

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "Column: "
                                        + appController.dataset2OutlierResult["columnName"]

                                    color: "#D2B4FF"

                                    font.bold: true
                                }
                            }

                            Text {
                                text:
                                    "Valid Values: "
                                    + appController.dataset2OutlierResult["validValueCount"]

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q1: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["q1"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "Q3: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["q3"]
                                      )

                                color: "#D7DCE5"
                            }

                            Text {
                                text:
                                    "IQR: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["iqr"]
                                      )

                                color: "#D7DCE5"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Lower Bound: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["lowerBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Text {
                                text:
                                    "Upper Bound: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["upperBound"]
                                      )

                                color: "#AAB2C0"
                            }

                            Rectangle {
                                width: parent.width
                                height: 1

                                color: "#30394A"
                            }

                            Text {
                                text:
                                    "Outlier Count: "
                                    + appController.dataset2OutlierResult["outlierCount"]

                                color:
                                    appController.dataset2OutlierResult["outlierCount"] > 0
                                    ? "#FFB4AB"
                                    : "#9FE3B5"

                                font.bold: true
                            }

                            Text {
                                text:
                                    "Outlier Percentage: "
                                    + formatNumber(
                                          appController.dataset2OutlierResult["outlierPercentage"]
                                      )
                                    + "%"

                                color:
                                    appController.dataset2OutlierResult["outlierCount"] > 0
                                    ? "#FFE29A"
                                    : "#9FE3B5"
                            }

                            Text {
                                width: parent.width

                                text:
                                    "Outlier Values: "
                                    + formatList(
                                          appController.dataset2OutlierResult["outlierValues"]
                                      )

                                color: "#AAB2C0"

                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // =================================================
            // COLUMN MATCHING
            // =================================================

            Row {
                width: parent.width - 60
                height: 45

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 10

                Text {
                    width: parent.width - 330

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text: "Column Matching Suggestions"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Button {
                    width: 160
                    height: 40

                    text: "Regenerate Matches"

                    enabled:
                        appController.dataset1Name.length > 0
                        &&
                        appController.dataset2Name.length > 0

                    onClicked:
                        appController.generateMappings()
                }

                Button {
                    width: 140
                    height: 40

                    text: "Clear"

                    enabled:
                        mappingList.count > 0

                    onClicked:
                        appController.clearMappings()
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 400

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 45

                        radius: 6
                        color: "#262E3D"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Text {
                                width: parent.width * 0.24

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1 Column"

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 40

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "→"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#8FA9C4"

                                font.pixelSize: 18
                            }

                            Text {
                                width: parent.width * 0.24

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2 Column"

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 130

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Similarity"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 85

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Accept"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }

                            Text {
                                width: 110

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Analysis"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"
                                font.bold: true
                            }
                        }
                    }

                    ListView {
                        id: mappingList

                        width: parent.width
                        height: 310

                        clip: true

                        model:
                            appController.mappingModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 55

                            color:
                                index % 2 === 0
                                ? "#1D2330"
                                : "#202735"

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 15
                                anchors.rightMargin: 15

                                Text {
                                    width: parent.width * 0.24

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.sourceColumn

                                    color: "white"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: 40

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "→"

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    color: "#8FA9C4"

                                    font.pixelSize: 17
                                }

                                Text {
                                    width: parent.width * 0.24

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.targetColumn.length > 0
                                        ? model.targetColumn
                                        : "No match"

                                    color:
                                        model.targetColumn.length > 0
                                        ? "white"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 130
                                    height: 30

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    radius: 15

                                    color: {
                                        if (model.similarityScore >= 80)
                                            return "#234B3A"

                                        if (model.similarityScore >= 50)
                                            return "#514525"

                                        return "#512C32"
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            Number(
                                                model.similarityScore
                                            ).toFixed(1) + "%"

                                        color: "white"

                                        font.bold: true
                                    }
                                }

                                CheckBox {
                                    width: 85

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    checked: model.accepted

                                    enabled:
                                        model.targetColumn.length > 0

                                    onToggled: {
                                        appController.mappingModel.setAccepted(
                                            index,
                                            checked
                                        )
                                    }
                                }

                                Button {
                                    width: 110
                                    height: 36

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: "Analyze"

                                    enabled:
                                        model.targetColumn.length > 0

                                    onClicked: {
                                        var success =
                                                appController.analyzeColumns(
                                                    model.sourceColumn,
                                                    model.targetColumn
                                                )

                                        if (!success) {
                                            errorDialog.text =
                                                    appController.lastError

                                            errorDialog.open()
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            visible:
                                mappingList.count === 0

                            text:
                                "No matching suggestions available."

                            color: "#7F899A"

                            font.pixelSize: 15
                        }
                    }
                }
            }

            // =================================================
            // COMPARISON ANALYSIS
            // =================================================

            Row {
                width: parent.width - 60
                height: 45

                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    width: parent.width - 140

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text: "Comparison Analysis"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Button {
                    width: 140
                    height: 40

                    text: "Clear Analysis"

                    enabled:
                        appController.analysisAvailable

                    onClicked:
                        appController.clearAnalysis()
                }
            }

            Rectangle {
                width: parent.width - 60

                height:
                    appController.analysisAvailable
                    ? 580
                    : 170

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent

                    spacing: 10

                    visible:
                        !appController.analysisAvailable

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text: "No analysis result"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text:
                            "Click Analyze on a numeric column mapping."

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 20

                    spacing: 15

                    visible:
                        appController.analysisAvailable

                    Rectangle {
                        width: parent.width
                        height: 75

                        radius: 8
                        color: "#202735"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20

                            Text {
                                width: parent.width * 0.45

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text:
                                    appController.analysisAvailable
                                    ? appController.analysisResult["sourceColumn"]
                                    : ""

                                color: "#9CCBFF"

                                font.pixelSize: 17
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width * 0.10

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "↔"

                                color: "#AAB2C0"

                                font.pixelSize: 22
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter
                            }

                            Text {
                                width: parent.width * 0.45

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text:
                                    appController.analysisAvailable
                                    ? appController.analysisResult["targetColumn"]
                                    : ""

                                color: "#D2B4FF"

                                font.pixelSize: 17
                                font.bold: true

                                horizontalAlignment:
                                    Text.AlignHCenter

                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 45

                        radius: 6
                        color: "#262E3D"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Statistic"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 1"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#9CCBFF"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Dataset 2"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D2B4FF"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Difference"

                                horizontalAlignment:
                                    Text.AlignHCenter

                                color: "#D7DCE5"

                                font.bold: true
                            }
                        }
                    }

                    Column {
                        width: parent.width

                        spacing: 0

                        Repeater {
                            model: [
                                {
                                    label: "Count",
                                    sourceKey: "count",
                                    targetKey: "count",
                                    differenceKey: "",
                                    format: false
                                },
                                {
                                    label: "Mean",
                                    sourceKey: "mean",
                                    targetKey: "mean",
                                    differenceKey: "meanDifference",
                                    format: true
                                },
                                {
                                    label: "Median",
                                    sourceKey: "median",
                                    targetKey: "median",
                                    differenceKey: "medianDifference",
                                    format: true
                                },
                                {
                                    label: "Minimum",
                                    sourceKey: "minimum",
                                    targetKey: "minimum",
                                    differenceKey: "minimumDifference",
                                    format: true
                                },
                                {
                                    label: "Maximum",
                                    sourceKey: "maximum",
                                    targetKey: "maximum",
                                    differenceKey: "maximumDifference",
                                    format: true
                                },
                                {
                                    label: "Range",
                                    sourceKey: "range",
                                    targetKey: "range",
                                    differenceKey: "rangeDifference",
                                    format: true
                                },
                                {
                                    label: "Std. Deviation",
                                    sourceKey: "standardDeviation",
                                    targetKey: "standardDeviation",
                                    differenceKey: "standardDeviationDifference",
                                    format: true
                                },
                                {
                                    label: "Variance",
                                    sourceKey: "variance",
                                    targetKey: "variance",
                                    differenceKey: "varianceDifference",
                                    format: true
                                },
                                {
                                    label: "Q1",
                                    sourceKey: "q1",
                                    targetKey: "q1",
                                    differenceKey: "q1Difference",
                                    format: true
                                },
                                {
                                    label: "Q3",
                                    sourceKey: "q3",
                                    targetKey: "q3",
                                    differenceKey: "q3Difference",
                                    format: true
                                },
                                {
                                    label: "IQR",
                                    sourceKey: "iqr",
                                    targetKey: "iqr",
                                    differenceKey: "iqrDifference",
                                    format: true
                                }
                            ]

                            delegate: Rectangle {
                                width: parent.width
                                height: 36

                                color:
                                    index % 2 === 0
                                    ? "#1D2330"
                                    : "#202735"

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    anchors.rightMargin: 15

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: modelData.label

                                        color: "white"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            var value =
                                                    appController.analysisResult[
                                                        "sourceStatistics"
                                                    ][modelData.sourceKey]

                                            return modelData.format
                                                    ? formatNumber(value)
                                                    : value
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#AAB2C0"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            var value =
                                                    appController.analysisResult[
                                                        "targetStatistics"
                                                    ][modelData.targetKey]

                                            return modelData.format
                                                    ? formatNumber(value)
                                                    : value
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#AAB2C0"
                                    }

                                    Text {
                                        width: parent.width * 0.25

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        text: {
                                            if (!appController.analysisAvailable)
                                                return "-"

                                            if (modelData.differenceKey.length === 0)
                                                return "-"

                                            return formatDifference(
                                                appController.analysisResult[
                                                    modelData.differenceKey
                                                ]
                                            )
                                        }

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color:
                                            modelData.differenceKey.length > 0
                                            ? "#FFE29A"
                                            : "#7F899A"
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // RAW DATA PARSING
            // =================================================

            Column {
                width: parent.width - 60

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Text {
                    text: "Raw Data Parsing"

                    color: "white"

                    font.pixelSize: 24
                    font.bold: true
                }

                Text {
                    text:
                        "Load parameter metadata and raw binary data, then decode the packet."

                    color: "#AAB2C0"

                    font.pixelSize: 14
                }
            }

            Row {
                width: parent.width - 60
                height: 200

                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 20

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.rawMetadataLoaded
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Parameter Metadata"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.rawMetadataLoaded
                                ? "Metadata loaded successfully"
                                : "No metadata selected"

                            color:
                                appController.rawMetadataLoaded
                                ? "#9FE3B5"
                                : "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.rawMetadataLoaded

                            text:
                                appController.rawParameterDefinitionCount
                                + " parameter definitions"

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 190
                            height: 42

                            text:
                                appController.rawMetadataLoaded
                                ? "Change Metadata"
                                : "Select Metadata"

                            onClicked:
                                rawMetadataDialog.open()
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 2
                    height: parent.height

                    radius: 12

                    color: "#1D2330"

                    border.color:
                        appController.rawDataLoaded
                        ? "#4E8A68"
                        : "#30394A"

                    border.width: 1

                    Column {
                        anchors.centerIn: parent

                        spacing: 12

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text: "Raw Data"

                            color: "white"

                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            text:
                                appController.rawDataLoaded
                                ? "Raw data loaded successfully"
                                : "No raw data selected"

                            color:
                                appController.rawDataLoaded
                                ? "#9FE3B5"
                                : "#9DA9BE"
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            visible:
                                appController.rawDataLoaded

                            text:
                                appController.rawDataByteCount
                                + " bytes"

                            color: "#AAB2C0"
                        }

                        Button {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            width: 190
                            height: 42

                            text:
                                appController.rawDataLoaded
                                ? "Change Raw Data"
                                : "Select Raw Data"

                            onClicked:
                                rawDataDialog.open()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 90

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Row {
                    anchors.centerIn: parent

                    spacing: 15

                    Button {
                        width: 190
                        height: 42

                        text: "Parse Raw Data"

                        enabled:
                            appController.rawMetadataLoaded
                            &&
                            appController.rawDataLoaded

                        onClicked: {
                            var success =
                                    appController.parseRawData()

                            if (!success) {
                                errorDialog.text =
                                        appController.lastError

                                errorDialog.open()
                            }
                        }
                    }

                    Button {
                        width: 150
                        height: 42

                        text: "Clear Results"

                        enabled:
                            appController.rawParseAvailable

                        onClicked:
                            appController.clearRawParse()
                    }

                    Text {
                        anchors.verticalCenter:
                            parent.verticalCenter

                        text:
                            appController.rawParseAvailable
                            ? "Parse completed"
                            : "Waiting for raw data"

                        color:
                            appController.rawParseAvailable
                            ? "#9FE3B5"
                            : "#AAB2C0"

                        font.bold: true
                    }
                }
            }

            Rectangle {
                width: parent.width - 60
                height: 430

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 10

                    Text {
                        text: "Parsed Parameters"

                        color: "white"

                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        width: parent.width
                        height: 42

                        radius: 6

                        color: "#262E3D"

                        Row {
                            anchors.fill: parent

                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Parameter"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.20

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Value"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.15

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Type"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.15

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Unit"

                                color: "#D7DCE5"

                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.25

                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "Status"

                                color: "#D7DCE5"

                                font.bold: true
                            }
                        }
                    }

                    ListView {
                        id: parsedParameterList

                        width: parent.width
                        height: 330

                        clip: true

                        model:
                            appController.parameterModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 50

                            color:
                                index % 2 === 0
                                ? "#1D2330"
                                : "#202735"

                            Row {
                                anchors.fill: parent

                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Text {
                                    width: parent.width * 0.25

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.dataName

                                    color: "white"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.20

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.displayValue

                                    color:
                                        model.valid
                                        ? "#9CCBFF"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.15

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text: model.dataType

                                    color: "#AAB2C0"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.15

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.unit.length > 0
                                        ? model.unit
                                        : "-"

                                    color: "#AAB2C0"

                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width * 0.25

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    text:
                                        model.valid
                                        ? model.status
                                        : model.errorMessage

                                    color:
                                        model.valid
                                        ? "#9FE3B5"
                                        : "#FFB4AB"

                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            visible:
                                parsedParameterList.count === 0

                            text:
                                "Load metadata and raw data, then click Parse Raw Data."

                            color: "#7F899A"

                            font.pixelSize: 14
                        }
                    }
                }
            }

            // =================================================
            // RAW WARNINGS
            // =================================================

            Rectangle {
                width: parent.width - 60

                height:
                    appController.rawWarnings.length > 0
                    ? 110
                    : 0

                visible:
                    appController.rawWarnings.length > 0

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 12

                color: "#332D1E"

                border.color: "#6E6035"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 15

                    spacing: 8

                    Text {
                        text: "Metadata Warnings"

                        color: "#FFE29A"

                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text:
                            appController.rawWarnings.join("\n")

                        color: "#D7C98F"

                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item {
                width: 1
                height: 30
            }
        }
    }
}