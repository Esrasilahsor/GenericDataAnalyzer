import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: window

    visible: true
    width: 1200
    height: 750

    minimumWidth: 900
    minimumHeight: 600

    title: "Generic Data Analyzer"
    color: "#151922"

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
            var success = appController.loadDataset1(fileUrl)

            if (!success) {
                errorDialog.text = appController.lastError
                errorDialog.open()
            }
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
            var success = appController.loadDataset2(fileUrl)

            if (!success) {
                errorDialog.text = appController.lastError
                errorDialog.open()
            }
        }
    }

    MessageDialog {
        id: errorDialog

        title: "Error"
        icon: StandardIcon.Critical
    }

    header: Rectangle {
        height: 70
        color: "#1D2330"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 30
            anchors.rightMargin: 30

            Text {
                text: "Generic Data Analyzer"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Excel Analysis Platform"
                color: "#AAB2C0"
                font.pixelSize: 14
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        anchors.topMargin: 30
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        anchors.bottomMargin: 30

        spacing: 25

        Text {
            text: "Dataset Selection"

            color: "white"

            font.pixelSize: 28
            font.bold: true
        }

        Text {
            text: "Select two Excel datasets to start the analysis."

            color: "#AAB2C0"

            font.pixelSize: 16
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 240

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Dataset 1"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: appController.dataset1Name.length > 0
                              ? appController.dataset1Name
                              : "No Excel file selected"

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        visible: appController.dataset1Name.length > 0

                        text: "Sheet: "
                              + appController.dataset1SheetName

                        color: "#AAB2C0"

                        font.pixelSize: 13
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        visible: appController.dataset1Name.length > 0

                        text: "Rows: "
                              + appController.dataset1RowCount
                              + " | Columns: "
                              + appController.dataset1ColumnCount

                        color: "#AAB2C0"

                        font.pixelSize: 13
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter

                        width: 170
                        height: 45

                        text: "Select Excel 1"

                        onClicked: {
                            dataset1Dialog.open()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 240

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Dataset 2"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: appController.dataset2Name.length > 0
                              ? appController.dataset2Name
                              : "No Excel file selected"

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        visible: appController.dataset2Name.length > 0

                        text: "Sheet: "
                              + appController.dataset2SheetName

                        color: "#AAB2C0"

                        font.pixelSize: 13
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        visible: appController.dataset2Name.length > 0

                        text: "Rows: "
                              + appController.dataset2RowCount
                              + " | Columns: "
                              + appController.dataset2ColumnCount

                        color: "#AAB2C0"

                        font.pixelSize: 13
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter

                        width: 170
                        height: 45

                        text: "Select Excel 2"

                        onClicked: {
                            dataset2Dialog.open()
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 12

            color: "#1D2330"

            border.color: "#30394A"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: {
                        if (appController.dataset1Name.length === 0
                                && appController.dataset2Name.length === 0) {
                            return "No dataset loaded"
                        }

                        if (appController.dataset1Name.length > 0
                                && appController.dataset2Name.length === 0) {
                            return "Dataset 1 loaded"
                        }

                        if (appController.dataset1Name.length === 0
                                && appController.dataset2Name.length > 0) {
                            return "Dataset 2 loaded"
                        }

                        return "Both datasets loaded"
                    }

                    color: "white"

                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: {
                        if (appController.dataset1Name.length > 0
                                && appController.dataset2Name.length > 0) {
                            return "Datasets are ready for column analysis."
                        }

                        return "Select Excel files to continue."
                    }

                    color: "#8F98A8"

                    font.pixelSize: 15
                }
            }
        }
    }
}