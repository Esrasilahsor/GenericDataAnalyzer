import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Rectangle {
    id: root

    property string title: ""
    property string datasetName: ""

    property int rowCount: 0
    property int columnCount: 0

    property string sheetName: ""

    property var model: null

    Layout.preferredHeight: 430

    radius: 14

    color: AppTheme.Theme.surface

    border.color: AppTheme.Theme.border
    border.width: 1

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 18

        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true

                spacing: 3

                Label {
                    text: root.title

                    color: AppTheme.Theme.text

                    font.pixelSize: 19
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true

                    text:
                        root.datasetName === ""
                        ? qsTr("No dataset loaded yet.")
                        : root.datasetName

                    color: AppTheme.Theme.textSecondary

                    font.pixelSize: 12

                    elide: Text.ElideMiddle
                }
            }

            Label {
                visible:
                    root.sheetName !== ""

                text:
                    root.sheetName === ""
                    ? ""
                    : qsTr("Sheet: ") + root.sheetName

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 11
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 20

            Label {
                text:
                    qsTr("Rows: %1").arg(root.rowCount)

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 12
            }

            Label {
                text:
                    qsTr("Columns: %1").arg(root.columnCount)

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 12
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true

            height: 42

            radius: 8

            color: AppTheme.Theme.surfaceAlt

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 12
                anchors.rightMargin: 12

                spacing: 0

                Label {
                    Layout.preferredWidth: 250

                    text: qsTr("Column")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }

                Label {
                    Layout.preferredWidth: 130

                    text: qsTr("Data Type")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }

                Label {
                    Layout.preferredWidth: 100

                    text: qsTr("Missing")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }

                Label {
                    Layout.preferredWidth: 100

                    text: qsTr("Missing %")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }

                Label {
                    Layout.preferredWidth: 100

                    text: qsTr("Unique")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true

                    text: qsTr("Numeric")

                    color: AppTheme.Theme.text

                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 8

            color: AppTheme.Theme.surfaceAlt

            border.color: AppTheme.Theme.border
            border.width: 1

            ListView {
                id: columnList

                anchors.fill: parent

                clip: true

                boundsBehavior: Flickable.StopAtBounds

                model: root.model

                delegate: Rectangle {
                    width: columnList.width

                    height: 42

                    color:
                        index % 2 === 0
                        ? AppTheme.Theme.surface
                        : AppTheme.Theme.surfaceAlt

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        spacing: 0

                        Label {
                            Layout.preferredWidth: 250

                            text: name

                            color: AppTheme.Theme.text

                            font.pixelSize: 11

                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.preferredWidth: 130

                            text: dataType

                            color: AppTheme.Theme.primary

                            font.pixelSize: 11
                            font.bold: true
                        }

                        Label {
                            Layout.preferredWidth: 100

                            text: missingCount

                            color:
                                missingCount > 0
                                ? AppTheme.Theme.warning
                                : AppTheme.Theme.textSecondary

                            font.pixelSize: 11
                        }

                        Label {
                            Layout.preferredWidth: 100

                            text:
                                Number(
                                    missingPercentage
                                ).toFixed(2) + "%"

                            color:
                                missingPercentage > 0
                                ? AppTheme.Theme.warning
                                : AppTheme.Theme.textSecondary

                            font.pixelSize: 11
                        }

                        Label {
                            Layout.preferredWidth: 100

                            text: uniqueCount

                            color: AppTheme.Theme.textSecondary

                            font.pixelSize: 11
                        }

                        Label {
                            Layout.fillWidth: true

                            text:
                                isNumeric
                                ? qsTr("Yes")
                                : qsTr("No")

                            color:
                                isNumeric
                                ? AppTheme.Theme.success
                                : AppTheme.Theme.textSecondary

                            font.pixelSize: 11
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            Label {
                anchors.centerIn: parent

                visible:
                    root.model === null ||
                    root.model.count === 0

                text:
                    root.datasetName === ""
                    ? qsTr("Load a file to preview the dataset.")
                    : qsTr("No column information found.")

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 12
            }
        }
    }
}