import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: sidebar

    width: 240
    color: "#FFFFFF"

    property int selectedIndex: 0

    signal pageSelected(int index)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 20
            spacing: 2

            Label {
                text: "Generic"
                color: "#A78BCE"
                font.pixelSize: 22
                font.bold: true
            }

            Label {
                text: "Data Analyzer"
                color: "#302B3D"
                font.pixelSize: 17
                font.bold: true
            }
        }

        Repeater {
            model: [
                { title: "Dashboard", icon: "⌂" },
                { title: "Veri Setleri", icon: "▣" },
                { title: "Veri Kalitesi", icon: "◈" },
                { title: "Sütun Eşleştirme", icon: "⇄" },
                { title: "Veri Analizi", icon: "▥" },
                { title: "Outlier Analysis", icon: "△" },
                { title: "Karşılaştırma", icon: "⇆" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 46

                radius: 12

                color: index === sidebar.selectedIndex
                       ? "#F1EDF8"
                       : "transparent"

                border.width: index === sidebar.selectedIndex ? 1 : 0
                border.color: "#A78BCE"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 12

                    Label {
                        text: modelData.icon

                        color: index === sidebar.selectedIndex
                               ? "#A78BCE"
                               : "#777184"

                        font.pixelSize: 18

                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: modelData.title

                        color: index === sidebar.selectedIndex
                               ? "#302B3D"
                               : "#777184"

                        font.pixelSize: 14
                        font.bold: index === sidebar.selectedIndex

                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        sidebar.selectedIndex = index
                        sidebar.pageSelected(index)
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E5DFF0"
        }

        Label {
            text: "Generic Data Analyzer"

            color: "#777184"
            font.pixelSize: 11

            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 4
        }
    }
}