import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Popup {
    id: notificationDialog

    property string title: qsTr("Operation / Analysis Notification")
    property string subtitle: qsTr("A notification or warning occurred during the operation.")
    property string message: ""
    property string notificationType: "warning" // "warning", "error", "info", "success"
    property string helpText: qsTr("You can review the documentation for information about the file format.")
    property bool showHelpText: true

    // Computed list of error items for multi-line messages
    readonly property var messageLines: {
        if (!message || message.trim() === "") return []
        var lines = message.split("\n")
        var result = []
        for (var i = 0; i < lines.length; ++i) {
            var trimmed = lines[i].trim()
            if (trimmed !== "") {
                result.push(trimmed)
            }
        }
        return result
    }

    readonly property bool isMultiLine: messageLines.length > 1

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    width: Math.min(520, parent ? Math.max(340, parent.width - 40) : 520)

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
                    color: notificationType === "error" ? Qt.rgba(AppTheme.Theme.error.r, AppTheme.Theme.error.g, AppTheme.Theme.error.b, 0.15) :
                           notificationType === "success" ? Qt.rgba(AppTheme.Theme.success.r, AppTheme.Theme.success.g, AppTheme.Theme.success.b, 0.15) :
                           notificationType === "info" ? Qt.rgba(AppTheme.Theme.primary.r, AppTheme.Theme.primary.g, AppTheme.Theme.primary.b, 0.15) :
                           Qt.rgba(AppTheme.Theme.warning.r, AppTheme.Theme.warning.g, AppTheme.Theme.warning.b, 0.15)

                    Label {
                        anchors.centerIn: parent
                        text: notificationType === "error" ? "✕" :
                              notificationType === "success" ? "✓" :
                              notificationType === "info" ? "ℹ" : "⚠"
                        color: notificationType === "error" ? AppTheme.Theme.error :
                               notificationType === "success" ? AppTheme.Theme.success :
                               notificationType === "info" ? AppTheme.Theme.primary :
                               AppTheme.Theme.warning
                        font.pixelSize: 18
                        font.bold: true
                    }
                }

                // Title and Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: notificationDialog.title
                        color: AppTheme.Theme.text
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Label {
                        visible: notificationDialog.subtitle !== ""
                        Layout.fillWidth: true
                        text: notificationDialog.subtitle
                        color: AppTheme.Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                // Close Button (✕)
                Button {
                    id: closeButton
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    flat: true
                    onClicked: notificationDialog.close()

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
        Item {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            Layout.preferredHeight: isMultiLine ? Math.min(220, Math.max(60, messageLines.length * 42)) : Math.max(38, singleLineLabel.implicitHeight)

            // Case A: Multi-line error list with ScrollView
            ScrollView {
                id: errorScrollView
                anchors.fill: parent
                visible: isMultiLine
                clip: true

                ColumnLayout {
                    width: errorScrollView.width
                    spacing: 8

                    Repeater {
                        model: notificationDialog.messageLines

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(34, itemRow.implicitHeight + 12)
                            radius: 8
                            color: AppTheme.Theme.surfaceAlt
                            border.width: 1
                            border.color: Qt.rgba(AppTheme.Theme.border.r, AppTheme.Theme.border.g, AppTheme.Theme.border.b, 0.6)

                            RowLayout {
                                id: itemRow
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Label {
                                    text: "•"
                                    color: notificationType === "error" ? AppTheme.Theme.error : AppTheme.Theme.warning
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData
                                    color: AppTheme.Theme.text
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.2
                                }
                            }
                        }
                    }
                }
            }

            // Case B: Single line message (Compact display)
            Label {
                id: singleLineLabel
                anchors.fill: parent
                visible: !isMultiLine
                text: notificationDialog.message
                color: AppTheme.Theme.text
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                lineHeight: 1.3
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Footer Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: AppTheme.Theme.border
        }

        // =========================================================
        // 3. FOOTER
        // =========================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 16
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 12

                // Left: Optional documentation / helper text
                Label {
                    visible: notificationDialog.showHelpText && notificationDialog.helpText !== ""
                    Layout.fillWidth: true
                    text: notificationDialog.helpText
                    color: AppTheme.Theme.textSecondary
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Item {
                    visible: !notificationDialog.showHelpText || notificationDialog.helpText === ""
                    Layout.fillWidth: true
                }

                // Right: OK Button
                Button {
                    id: okButton
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 36
                    text: qsTr("OK")

                    contentItem: Text {
                        text: parent.text
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: parent.down ? AppTheme.Theme.primaryDark : AppTheme.Theme.primary
                    }

                    onClicked: {
                        notificationDialog.close()
                    }
                }
            }
        }
    }

    function showNotification(titleText, messageText, subtitleText, type, help) {
        if (titleText !== undefined && titleText !== null && titleText !== "")
            title = titleText
        else
            title = qsTr("Operation / Analysis Notification")

        message = messageText || ""

        if (subtitleText !== undefined && subtitleText !== null && subtitleText !== "")
            subtitle = subtitleText
        else
            subtitle = qsTr("A notification or warning occurred during the operation.")

        if (type !== undefined && type !== null && type !== "")
            notificationType = type
        else
            notificationType = "warning"

        if (help !== undefined && help !== null) {
            helpText = help
            showHelpText = help !== ""
        }

        open()
    }
}
