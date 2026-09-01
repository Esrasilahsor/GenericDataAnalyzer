import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import GenericDataAnalyzer 1.0
import "." as AppTheme
import "components" as Components
import "pages" as Pages

ApplicationWindow {
    id: window

    visible: true

    width: 1440
    height: 900

    minimumWidth: 1100
    minimumHeight: 700

    title: qsTr("Generic Data Analyzer")

    color: AppTheme.Theme.background

    property int currentPage: 0
    property var controller: AppController

    // =========================================================
    // GLOBAL ALERT / WARNING POPUP
    // =========================================================

    function showAlert(title, message, subtitle, type, helpText) {
        globalAlertPopup.showNotification(
            title || qsTr("Operation / Analysis Notification"),
            message || "",
            subtitle || qsTr("A notification or warning occurred during the operation."),
            type || "warning",
            helpText || qsTr("You can review the documentation for information about the file format.")
        )
    }

    Connections {
        target: window.controller
        ignoreUnknownSignals: true

        function onErrorChanged() {
            if (window.controller &&
                window.controller.lastError &&
                window.controller.lastError !== "") {
                window.showAlert(
                    qsTr("Operation / Analysis Notification"),
                    window.controller.lastError,
                    qsTr("A notification or warning occurred during the operation."),
                    "warning"
                )
            }
        }
    }

    // =========================================================
    // SAYFA BAŞLIKLARI
    // =========================================================

    function pageTitle(index) {
        switch (index) {
        case 0:
            return qsTr("Dashboard")

        case 1:
            return qsTr("Datasets")

        case 2:
            return qsTr("Data Analysis")

        case 3:
            return qsTr("Data Cleaning")

        case 4:
            return qsTr("Comparison")

        case 5:
            return qsTr("Visualization")

        case 6:
            return qsTr("Export")

        case 7:
            return qsTr("Raw Data Parsing")

        default:
            return qsTr("Dashboard")
        }
    }

    // =========================================================
    // SAYFA ALT BAŞLIKLARI
    // =========================================================

    function pageSubtitle(index) {
        switch (index) {
        case 0:
            return qsTr("System status overview, loaded datasets and quick summary.")

        case 1:
            return qsTr("Load, inspect and manage your Excel, CSV or text datasets.")

        case 2:
            return qsTr("Perform column-based statistics, exploratory analysis and correlations.")

        case 3:
            return qsTr("Handle missing values, clean outliers and eliminate duplicates.")

        case 4:
            return qsTr("Map columns and compare differences between two datasets.")

        case 5:
            return qsTr("Generate interactive charts, inspect trends and save chart visualizations.")

        case 6:
            return qsTr("Export cleaned and analyzed dataset records to Excel, CSV or JSON formats.")

        case 7:
            return qsTr("Parse binary/text raw packet streams using protocol parameter definitions.")

        default:
            return ""
        }
    }

    // =========================================================
    // ANA DÜZEN
    // =========================================================

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =====================================================
        // SOL MENÜ
        // =====================================================

        Components.Sidebar {
            id: sidebar

            Layout.fillHeight: true

            Layout.preferredWidth: 260
            Layout.minimumWidth: 260
            Layout.maximumWidth: 260

            currentPage: window.currentPage

            onPageSelected: {
                window.currentPage = index
            }
        }

        // =====================================================
        // AYIRICI ÇİZGİ
        // =====================================================

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: AppTheme.Theme.border
        }

        // =====================================================
        // SAĞ İÇERİK ALANI
        // =====================================================

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // =================================================
            // ÜST BAŞLIK ALANI
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74

                color: AppTheme.Theme.surface

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28

                    ColumnLayout {
                        spacing: 2

                        Label {
                            text: window.pageTitle(window.currentPage)
                            color: AppTheme.Theme.text
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Label {
                            text: window.pageSubtitle(window.currentPage)
                            color: AppTheme.Theme.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: AppTheme.Theme.surfaceAlt
                        border.color: AppTheme.Theme.border
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: AppTheme.Theme.darkMode ? "🌙" : "☀️"
                            font.pixelSize: 18
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AppTheme.Theme.darkMode = !AppTheme.Theme.darkMode
                        }
                    }
                }
            }

            // =================================================
            // BAŞLIK ALTI AYIRICI
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: AppTheme.Theme.border
            }

            // =================================================
            // SAYFALAR (STACK LAYOUT - TÜM DURUM KORUNUR)
            // =================================================

            StackLayout {
                id: mainStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.currentPage

                Pages.DashboardPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.DatasetsPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.AnalysisPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.DataCleaningPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.ComparisonPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.VisualizationPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.ExportPage {
                    mainWindow: window
                    appController: window.controller
                }

                Pages.RawDataPage {
                    mainWindow: window
                    appController: window.controller
                }
            }
        }
    }

    // =========================================================
    // MERKEZİ MODAL BİLDİRİM / UYARI DİYALOĞU
    // =========================================================

    Components.AnalysisNotificationDialog {
        id: globalAlertPopup
        x: Math.round((window.width - width) / 2)
        y: Math.round((window.height - height) / 2)

        onClosed: {
            if (window.controller && window.controller.lastError !== "") {
                window.controller.clearError()
            }
        }
    }
}
