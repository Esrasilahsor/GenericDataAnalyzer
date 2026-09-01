import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Rectangle {
    id: topBar

    height: 76

    property string title: qsTr("Dashboard")

    property string subtitle:
        qsTr("Manage and analyze your datasets.")

    signal themeToggleRequested()

    color: AppTheme.Theme.background

    RowLayout {
        anchors.fill: parent

        anchors.leftMargin: 28
        anchors.rightMargin: 28

        spacing: 20

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 2

            Label {
                text: topBar.title

                color: AppTheme.Theme.text

                font.pixelSize: 25
                font.bold: true
            }

            Label {
                text: topBar.subtitle

                color: AppTheme.Theme.textSecondary

                font.pixelSize: 13
            }
        }

        Rectangle {
            width: 42
            height: 42

            radius: 21

            color: AppTheme.Theme.surface

            border.width: 1

            border.color: AppTheme.Theme.border

            Label {
                anchors.centerIn: parent

                text:
                    AppTheme.Theme.darkMode
                    ? "☀"
                    : "☾"

                color: AppTheme.Theme.primary

                font.pixelSize: 19
            }

            MouseArea {
                anchors.fill: parent

                cursorShape:
                    Qt.PointingHandCursor

                onClicked: {
                    topBar.themeToggleRequested()
                }
            }
        }
    }
}