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
                    appController: window.appController
                }

                Pages.DatasetsPage {
                    mainWindow: window
                    appController: window.appController
                }

                Pages.AnalysisPage {
                    mainWindow: window
                    appController: window.appController
                }

                Pages.DataCleaningPage {
                    mainWindow: window
                    appController: window.appController
                }

                Pages.ComparisonPage {
                    mainWindow: window
                    appController: window.appController
                }

                Pages.VisualizationPage {
                    mainWindow: window
                    appController: window.appController
                }

                Pages.RawDataPage {
                    mainWindow: window
                    appController: window.appController
                }
            }
        }
    }
}
