import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window

    visible: true

    width: 1200
    height: 750

    minimumWidth: 900
    minimumHeight: 600

    title: "Generic Data Analyzer"

    color: "#151922"

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
                Layout.preferredHeight: 220

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent

                    spacing: 20

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Dataset 1"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "No Excel file selected"

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Select Excel 1"

                        width: 160
                        height: 45

                        onClicked: {
                            console.log("Excel 1 selection will be added.")
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220

                radius: 12

                color: "#1D2330"

                border.color: "#30394A"
                border.width: 1

                Column {
                    anchors.centerIn: parent

                    spacing: 20

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Dataset 2"

                        color: "white"

                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "No Excel file selected"

                        color: "#8F98A8"

                        font.pixelSize: 14
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter

                        text: "Select Excel 2"

                        width: 160
                        height: 45

                        onClicked: {
                            console.log("Excel 2 selection will be added.")
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

                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "No dataset loaded"

                    color: "white"

                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "Dataset information will appear here."

                    color: "#8F98A8"

                    font.pixelSize: 15
                }
            }
        }
    }
}