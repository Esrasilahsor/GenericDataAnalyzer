import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Rectangle {
    id: card

    property string title: ""
    property string value: "—"
    property string description: ""
    property string icon: "•"

    Layout.fillWidth: true
    Layout.preferredHeight: 110

    radius: 16

    color: AppTheme.Theme.surface

    border.width: 1
    border.color: AppTheme.Theme.border

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 18

        spacing: 5

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: card.title

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 13

                Layout.fillWidth: true
            }

            Label {
                text: card.icon

                color: AppTheme.Theme.primary

                font.pixelSize: 18
            }
        }

        Label {
            text: card.value

            color: AppTheme.Theme.text

            font.pixelSize: 25
            font.bold: true
        }

        Label {
            text: card.description

            color: AppTheme.Theme.textSecondary

            font.pixelSize: 11
        }
    }
}