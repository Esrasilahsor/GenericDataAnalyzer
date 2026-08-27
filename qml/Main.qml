import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

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

    title: "Generic Data Analyzer"

    color: AppTheme.Theme.background

    property int currentPage: 0
    property var controller: appController

    // =========================================================
    // GLOBAL ALERT / WARNING POPUP
    // =========================================================

    property string alertTitle: "Bildirim"
    property string alertSubtitle: ""
    property string alertMessage: ""
    property string alertType: "warning" // "warning", "error", "info", "success"

    function showAlert(title, message, subtitle, type) {
        window.alertTitle = title || "Bildirim"
        window.alertSubtitle = subtitle || ""
        window.alertMessage = message || ""
        window.alertType = type || "warning"
        globalAlertPopup.open()
    }

    Connections {
        target: window.controller
        ignoreUnknownSignals: true

        function onErrorChanged() {
            if (window.controller &&
                window.controller.lastError &&
                window.controller.lastError !== "") {
                window.showAlert(
                    "İşlem / Analiz Bildirimi",
                    window.controller.lastError,
                    "İşlem sırasında bir bildirim veya uyarı oluştu.",
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
            return "Dashboard"

        case 1:
            return "Veri Setleri"

        case 2:
            return "Veri Analizi"

        case 3:
            return "Veri Temizleme"

        case 4:
            return "Karşılaştırma"

        case 5:
            return "Görselleştirme"

        case 6:
            return "Raw Data Parsing"

        default:
            return "Dashboard"
        }
    }

    // =========================================================
    // SAYFA ALT BAŞLIKLARI
    // =========================================================

    function pageSubtitle(index) {
        switch (index) {
        case 0:
            return "Sistem genel durumu, yüklü veri setleri ve hızlı analiz özeti."

        case 1:
            return "Excel, CSV veya JSON formatındaki veri setlerinizi yükleyin ve yönetin."

        case 2:
            return "Sütun bazlı istatistikler, dağılımlar ve korelasyon analizi gerçekleştirin."

        case 3:
            return "Eksik verileri doldurun, aykırı değerleri temizleyin ve tekrarları kaldırın."

        case 4:
            return "İki farklı veri seti arasındaki benzerlik ve istatistiksel farkları inceleyin."

        case 5:
            return "Temizlenmiş veya orijinal verilerin grafiklerini inceleyin ve Excel/CSV/JSON olarak dışa aktarın."

        case 6:
            return "Protokol parametre tablosu (Excel) ile binary/metin paket verilerini ayrıştırın."

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

    Popup {
        id: globalAlertPopup
        x: Math.round((window.width - width) / 2)
        y: Math.round((window.height - height) / 2)
        width: Math.min(520, window.width - 40)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0

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
            spacing: 16
            anchors.margins: 22

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 22
                    color: window.alertType === "error" ? "#FFEBEE" :
                           window.alertType === "success" ? "#E8F5E9" :
                           window.alertType === "info" ? "#E3F2FD" : "#FFF4E5"

                    Label {
                        anchors.centerIn: parent
                        text: window.alertType === "error" ? "✕" :
                              window.alertType === "success" ? "✓" :
                              window.alertType === "info" ? "ℹ" : "⚠"
                        color: window.alertType === "error" ? "#D32F2F" :
                               window.alertType === "success" ? "#2E7D32" :
                               window.alertType === "info" ? "#1976D2" : "#ED6C02"
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: window.alertTitle
                        color: AppTheme.Theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Label {
                        visible: window.alertSubtitle !== ""
                        text: window.alertSubtitle
                        color: AppTheme.Theme.textSecondary
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: AppTheme.Theme.border
            }

            Label {
                Layout.fillWidth: true
                text: window.alertMessage
                color: AppTheme.Theme.text
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                lineHeight: 1.3
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Button {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 38
                    text: "Tamam"

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
                        globalAlertPopup.close()
                    }
                }
            }
        }

        onClosed: {
            if (window.controller && window.controller.lastError !== "") {
                window.controller.clearError()
            }
            window.alertMessage = ""
        }
    }
}
