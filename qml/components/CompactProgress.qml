import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../" as AppTheme

Item {
    id: root

    property var theme: AppTheme.Theme
    property int progress: 0 // 0 - 100
    property bool running: false
    property color progressColor: (theme && theme.success) ? theme.success : "#22c55e"
    property int barHeight: 4

    // Clamped progress (0 to 100)
    readonly property int clampedProgress: Math.max(0, Math.min(100, isNaN(progress) ? 0 : progress))

    // Internal state to hold 100% briefly before hiding
    property bool showCompleted: false

    onRunningChanged: {
        if (!running) {
            if (clampedProgress >= 100) {
                showCompleted = true
                hideTimer.restart()
            } else {
                showCompleted = false
                hideTimer.stop()
            }
        } else {
            showCompleted = false
            hideTimer.stop()
        }
    }

    Timer {
        id: hideTimer
        interval: 650
        onTriggered: {
            root.showCompleted = false
        }
    }

    visible: running || showCompleted
    height: visible ? 16 : 0
    implicitHeight: height
    implicitWidth: 160

    Behavior on height {
        NumberAnimation { duration: 150 }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 6
        visible: root.visible

        // Progress track & fill
        Rectangle {
            id: trackRect
            Layout.fillWidth: true
            Layout.preferredHeight: root.barHeight
            radius: root.barHeight / 2
            color: (root.theme && root.theme.surfaceAlt) ? root.theme.surfaceAlt : "#2a2d34"
            border.color: (root.theme && root.theme.border) ? root.theme.border : "#3a3f4b"
            border.width: 1
            clip: true

            Rectangle {
                id: fillRect
                height: trackRect.height
                radius: trackRect.radius
                color: root.progressColor
                width: trackRect.width > 0 ? (trackRect.width * (root.clampedProgress / 100.0)) : 0

                Behavior on width {
                    NumberAnimation { duration: 120 }
                }
            }
        }

        // Percentage text
        Label {
            text: root.clampedProgress + "%"
            color: root.progressColor
            font.pixelSize: 10
            font.bold: true
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
        }
    }
}
