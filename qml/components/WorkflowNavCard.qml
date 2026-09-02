import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Rectangle {
    id: root

    property var theme: AppTheme.Theme
    property var appController

    property int currentStepIndex: -1 // -1: Dashboard/None, 0: Datasets, 1: Analysis, 2: Cleaning, 3: Comparison, 4: Visualization, 5: Export

    readonly property bool step0Completed: root.currentStepIndex >= 0
    readonly property bool step1Completed: root.currentStepIndex >= 1
    readonly property bool step2Completed: root.currentStepIndex >= 2
    readonly property bool step3Completed: root.currentStepIndex >= 3
    readonly property bool step4Completed: root.currentStepIndex >= 4
    readonly property bool step5Completed: root.currentStepIndex >= 5

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
    readonly property bool isCompact: root.width < 640

    implicitHeight: navLayout.implicitHeight + 28

    GridLayout {
        id: navLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        columns: root.isCompact ? 1 : 2
        rowSpacing: 10
        columnSpacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 4

            // Line 1: Title
            Label {
                text: root.title
                color: theme.text
                font.pixelSize: 13
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            // Line 2: Subtitle / Description
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.subtitle
                color: theme.textSecondary
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            // Line 3: Compact Workflow Progress
            Flow {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 5

                // Step 0: Datasets
                Label {
                    text: root.step0Completed ? (qsTr("Datasets") + " ✓") : qsTr("Datasets")
                    color: root.currentStepIndex === 0 ? theme.text : (root.step0Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 0
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 1: Data Analysis
                Label {
                    text: root.step1Completed ? (qsTr("Data Analysis") + " ✓") : qsTr("Data Analysis")
                    color: root.currentStepIndex === 1 ? theme.text : (root.step1Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 1
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 2: Data Cleaning
                Label {
                    text: root.step2Completed ? (qsTr("Data Cleaning") + " ✓") : qsTr("Data Cleaning")
                    color: root.currentStepIndex === 2 ? theme.text : (root.step2Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 2
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 3: Comparison
                Label {
                    text: root.step3Completed ? (qsTr("Comparison") + " ✓") : qsTr("Comparison")
                    color: root.currentStepIndex === 3 ? theme.text : (root.step3Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 3
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 4: Visualization
                Label {
                    text: root.step4Completed ? (qsTr("Visualization") + " ✓") : qsTr("Visualization")
                    color: root.currentStepIndex === 4 ? theme.text : (root.step4Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 4
                }

                Label {
                    text: "·"
                    color: theme.border
                    font.pixelSize: 10
                }

                // Step 5: Export
                Label {
                    text: root.step5Completed ? (qsTr("Export") + " ✓") : qsTr("Export")
                    color: root.currentStepIndex === 5 ? theme.text : (root.step5Completed ? theme.success : theme.textSecondary)
                    font.pixelSize: 10
                    font.bold: root.currentStepIndex === 5
                }
            }
        }

        // Action Buttons Row
        RowLayout {
            Layout.alignment: root.isCompact ? Qt.AlignLeft : (Qt.AlignRight | Qt.AlignVCenter)
            spacing: 8
            visible: root.buttonVisible || root.secondaryButtonVisible

            // Secondary Action Button (if any)
            Button {
                visible: root.secondaryButtonVisible
                enabled: root.secondaryButtonEnabled
                Layout.preferredWidth: root.isCompact ? (root.buttonVisible ? 140 : 180) : 165
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
                Layout.preferredWidth: root.isCompact ? (root.secondaryButtonVisible ? 150 : 185) : 175
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
}
