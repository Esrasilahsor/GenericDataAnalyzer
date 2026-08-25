import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Rectangle {
    id: card

    property string datasetTitle: "Dataset"
    property string fileName: "Henüz dosya seçilmedi"
    property string rows: "—"
    property string columns: "—"
    property bool loaded: false

    signal browseRequested()

    Layout.fillWidth: true
    Layout.preferredHeight: 190

    radius: 18

    color: AppTheme.Theme.surface

    border.width: 1
    border.color: AppTheme.Theme.border

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 20

        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: card.datasetTitle

                color: AppTheme.Theme.text

                font.pixelSize: 16
                font.bold: true

                Layout.fillWidth: true
            }

            Label {
                text:
                    card.loaded
                    ? "Loaded"
                    : "Empty"

                color:
                    card.loaded
                    ? AppTheme.Theme.success
                    : AppTheme.Theme.textSecondary

                font.pixelSize: 11
                font.bold: true
            }
        }

        Label {
            text: card.fileName

            color: AppTheme.Theme.textSecondary

            font.pixelSize: 12

            elide: Text.ElideMiddle

            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 24

            ColumnLayout {
                spacing: 2

                Label {
                    text: "Records"

                    color: AppTheme.Theme.textSecondary

                    font.pixelSize: 11
                }

                Label {
                    text: card.rows

                    color: AppTheme.Theme.text

                    font.bold: true
                }
            }

            ColumnLayout {
                spacing: 2

                Label {
                    text: "Columns"

                    color: AppTheme.Theme.textSecondary

                    font.pixelSize: 11
                }

                Label {
                    text: card.columns

                    color: AppTheme.Theme.text

                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Dosya Seç"

                onClicked: {
                    card.browseRequested()
                }

                contentItem: Text {
                    text: "Dosya Seç"

                    color: "white"

                    font.pixelSize: 12
                    font.bold: true

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10

                    color: AppTheme.Theme.primary
                }
            }
        }
    }
}