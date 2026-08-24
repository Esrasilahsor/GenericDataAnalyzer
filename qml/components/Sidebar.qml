import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Rectangle {
    id: sidebar

    width: 240

    // =====================================================
    // AKTİF SAYFA
    // =====================================================

    property int currentPage: 0

    color: AppTheme.Theme.surface

    signal pageSelected(int index)

    // =====================================================
    // ANA LAYOUT
    // =====================================================

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 16

        spacing: 8

        // =================================================
        // LOGO
        // =================================================

        RowLayout {
            Layout.fillWidth: true

            Layout.topMargin: 6
            Layout.bottomMargin: 20

            spacing: 10

            Image {
                id: appLogo

                Layout.preferredWidth: 48
                Layout.preferredHeight: 48

                source:
                    AppTheme.Theme.darkMode
                    ? "qrc:/qml/assets/logo_dark.png"
                    : "qrc:/qml/assets/logo_light.png"

                fillMode: Image.PreserveAspectFit

                smooth: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: 0

                Label {
                    text: "Generic"

                    color: AppTheme.Theme.primary

                    font.pixelSize: 17
                    font.bold: true
                }

                Label {
                    text: "Data Analyzer"

                    color: AppTheme.Theme.text

                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        // =================================================
        // NAVIGATION
        // =================================================

        Repeater {
            model: [
                { title: "Dashboard", icon: "⌂" },
                { title: "Veri Setleri", icon: "▣" },
                { title: "Veri Analizi", icon: "▥" },
                { title: "Veri Temizleme", icon: "✦" },
                { title: "Karşılaştırma", icon: "⇆" },
                { title: "Görselleştirme & Export", icon: "📈" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true

                height: 46

                radius: 12

                // AKTİF MENÜ
                color:
                    index === sidebar.currentPage
                    ? AppTheme.Theme.surfaceAlt
                    : "transparent"

                border.width:
                    index === sidebar.currentPage
                    ? 1
                    : 0

                border.color:
                    AppTheme.Theme.primary

                RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 14
                    anchors.rightMargin: 12

                    spacing: 12

                    Label {
                        text: modelData.icon

                        color:
                            index === sidebar.currentPage
                            ? AppTheme.Theme.primary
                            : AppTheme.Theme.textSecondary

                        font.pixelSize: 18

                        Layout.preferredWidth: 24

                        horizontalAlignment:
                            Text.AlignHCenter
                    }

                    Label {
                        text: modelData.title

                        color:
                            index === sidebar.currentPage
                            ? AppTheme.Theme.text
                            : AppTheme.Theme.textSecondary

                        font.pixelSize: 14

                        font.bold:
                            index === sidebar.currentPage

                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        sidebar.pageSelected(index)
                    }
                }
            }
        }

        // =================================================
        // ALT BOŞLUK
        // =================================================

        Item {
            Layout.fillHeight: true
        }

        // =================================================
        // AYIRICI
        // =================================================

        Rectangle {
            Layout.fillWidth: true

            height: 1

            color: AppTheme.Theme.border
        }

        // =================================================
        // ALT YAZI
        // =================================================

        Label {
            text: "Generic Data Analyzer"

            color: AppTheme.Theme.textSecondary

            font.pixelSize: 11

            Layout.fillWidth: true

            horizontalAlignment:
                Text.AlignHCenter

            Layout.bottomMargin: 4
        }
    }
}