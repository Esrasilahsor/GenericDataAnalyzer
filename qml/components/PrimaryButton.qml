import QtQuick 2.15
import QtQuick.Controls 2.15

import "../" as AppTheme

Button {
    id: button

    property bool destructive: false

    implicitHeight: 42

    leftPadding: 18
    rightPadding: 18

    contentItem: Text {
        text: button.text

        color:
            button.enabled
            ? "#FFFFFF"
            : AppTheme.Theme.textSecondary

        font.pixelSize: 13
        font.bold: true

        horizontalAlignment:
            Text.AlignHCenter

        verticalAlignment:
            Text.AlignVCenter
    }

    background: Rectangle {
        radius: 10

        color:
            !button.enabled
            ? AppTheme.Theme.surfaceAlt
            : button.destructive
              ? AppTheme.Theme.error
              : button.down
                ? AppTheme.Theme.primaryDark
                : AppTheme.Theme.primary
    }
}