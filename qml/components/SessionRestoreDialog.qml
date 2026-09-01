import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Popup {
    id: restoreDialog

    property string title: qsTr("Restore Previous Session")
    property string moduleName: qsTr("Data Analysis")
    property string message: qsTr("Would you like to restore the last Data Analysis session?")
    property string details: qsTr("You can restore your previous working state or start with a fresh state on the loaded dataset.")

    signal restoreClicked()
    signal startFreshClicked()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    width: Math.min(480, parent ? Math.max(340, parent.width - 40) : 480)

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    background: Rectangle {
        radius: 16
        color: AppTheme.Theme.surface
        border.width: 1
        border.color: AppTheme.Theme.border
    }

    contentItem: ColumnLayout {
        spacing: 0

        // =========================================================
        // 1. HEADER
        // =========================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 16
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 12

                // Icon Badge
                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 19
                    color: Qt.rgba(AppTheme.Theme.primary.r, AppTheme.Theme.primary.g, AppTheme.Theme.primary.b, 0.15)

                    Label {
                        anchors.centerIn: parent
                        text: "🔄"
                        font.pixelSize: 18
                    }
                }

                // Title and Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: restoreDialog.title
                        color: AppTheme.Theme.text
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Label {
                        visible: restoreDialog.moduleName !== ""
                        Layout.fillWidth: true
                        text: restoreDialog.moduleName
                        color: AppTheme.Theme.primary
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                // Close Button (✕) -> Defaults to Start Fresh
                Button {
                    id: closeButton
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    flat: true
                    onClicked: {
                        restoreDialog.startFreshClicked()
                        restoreDialog.close()
                    }

                    contentItem: Text {
                        text: "✕"
                        color: parent.hovered ? AppTheme.Theme.text : AppTheme.Theme.textSecondary
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 15
                        color: parent.hovered ? AppTheme.Theme.surfaceAlt : "transparent"
                    }
                }
            }
        }

        // Header Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AppTheme.Theme.border
        }

        // =========================================================
        // 2. CONTENT AREA
        // =========================================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: restoreDialog.message
                color: AppTheme.Theme.text
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                text: restoreDialog.details
                color: AppTheme.Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                lineHeight: 1.2
            }
        }

        // Footer Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AppTheme.Theme.border
        }

        // =========================================================
        // 3. FOOTER BUTTONS
        // =========================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: 16
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 12

                Item { Layout.fillWidth: true }

                // Start Fresh Button
                Button {
                    id: startFreshBtn
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 36
                    text: qsTr("Start Fresh")

                    contentItem: Text {
                        text: parent.text
                        color: parent.down ? AppTheme.Theme.text : AppTheme.Theme.textSecondary
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: parent.down ? AppTheme.Theme.surfaceAlt : "transparent"
                        border.width: 1
                        border.color: AppTheme.Theme.border
                    }

                    onClicked: {
                        restoreDialog.startFreshClicked()
                        restoreDialog.close()
                    }
                }

                // Restore Button
                Button {
                    id: restoreBtn
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 36
                    text: qsTr("Restore")

                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: parent.down ? AppTheme.Theme.primaryDark : AppTheme.Theme.primary
                    }

                    onClicked: {
                        restoreDialog.restoreClicked()
                        restoreDialog.close()
                    }
                }
            }
        }
    }

    function showPrompt(moduleTitle, questionText, detailsText) {
        if (moduleTitle) moduleName = moduleTitle
        if (questionText) message = questionText
        if (detailsText) details = detailsText
        open()
    }
}
