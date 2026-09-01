import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Rectangle {
    id: root

    property var theme: AppTheme.Theme
    property var appController

    property int currentStepIndex: 1 // 1: Datasets, 2: Analysis, 3: Cleaning, 4: Comparison, 5: Visualization, 6: Export
    property string title: ""
    property string subtitle: ""
    property string buttonText: ""
    property bool buttonVisible: true
    property bool buttonEnabled: true
    property string secondaryButtonText: ""
    property bool secondaryButtonVisible: false
    property bool secondaryButtonEnabled: true

    signal buttonClicked()
    signal secondaryButtonClicked()

    Layout.fillWidth: true
    Layout.leftMargin: 28
    Layout.rightMargin: 28
    Layout.preferredHeight: 80

    radius: 14
    color: theme.surfaceAlt
    border.width: 1
    border.color: theme.border

    // Step completion based purely on current workflow position/page index
    readonly property bool step1Completed: root.currentStepIndex >= 1
    readonly property bool step2Completed: root.currentStepIndex >= 2
    readonly property bool step3Completed: root.currentStepIndex >= 3
    readonly property bool step4Completed: root.currentStepIndex >= 4
    readonly property bool step5Completed: root.currentStepIndex >= 5
    readonly property bool step6Completed: root.currentStepIndex >= 6

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            // Line 1: Title
            Label {
                text: root.title
                color: theme.text
                font.pixelSize: 13
                font.bold: true
            }

            // Line 2: Subtitle / Description
            Label {
                Layout.fillWidth: true
                text: root.subtitle
                color: theme.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Line 3: Compact Workflow Progress
            RowLayout {
                spacing: 6

                // Step 1: Datasets
                Label {
                    text: root.step1Completed ? (qsTr("Datasets") + " ✓") : qsTr("Datasets")
                    color: root.currentStepIndex === 1 ? theme.text : (root.step1Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 1
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 2: Data Analysis
                Label {
                    text: root.step2Completed ? (qsTr("Data Analysis") + " ✓") : qsTr("Data Analysis")
                    color: root.currentStepIndex === 2 ? theme.text : (root.step2Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 2
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 3: Data Cleaning
                Label {
                    text: root.step3Completed ? (qsTr("Data Cleaning") + " ✓") : qsTr("Data Cleaning")
                    color: root.currentStepIndex === 3 ? theme.text : (root.step3Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 3
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 4: Comparison
                Label {
                    text: root.step4Completed ? (qsTr("Comparison") + " ✓") : qsTr("Comparison")
                    color: root.currentStepIndex === 4 ? theme.text : (root.step4Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 4
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 5: Visualization
                Label {
                    text: root.step5Completed ? (qsTr("Visualization") + " ✓") : qsTr("Visualization")
                    color: root.currentStepIndex === 5 ? theme.text : (root.step5Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 5
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 6: Export
                Label {
                    text: root.step6Completed ? (qsTr("Export") + " ✓") : qsTr("Export")
                    color: root.currentStepIndex === 6 ? theme.text : (root.step6Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 6
                }
            }
        }

        // Secondary Action Button (if any)
        Button {
            visible: root.secondaryButtonVisible
            enabled: root.secondaryButtonEnabled
            Layout.preferredWidth: 165
            Layout.preferredHeight: 36
            text: root.secondaryButtonText
            onClicked: root.secondaryButtonClicked()

            contentItem: Text {
                text: parent.text
                color: parent.enabled ? theme.text : theme.textSecondary
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: parent.down ? theme.surfaceAlt : theme.surface
                border.width: 1
                border.color: theme.border
            }
        }

        // Primary Action Button
        Button {
            visible: root.buttonVisible
            enabled: root.buttonEnabled
            Layout.preferredWidth: 175
            Layout.preferredHeight: 36
            text: root.buttonText
            onClicked: root.buttonClicked()

            contentItem: Text {
                text: parent.text
                color: parent.enabled ? "#FFFFFF" : theme.textSecondary
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8
                color: !parent.enabled ? theme.surfaceAlt : (parent.down ? theme.primaryDark : theme.primary)
            }
        }
    }
}
