import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "." as AppTheme
import "components" as Components

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
            return "Görselleştirme & Export"

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
            return "Veri setlerinizi yönetin ve analiz sürecini başlatın."

        case 1:
            return "Veri setlerinizi yükleyin, yapısını inceleyin ve önizleyin."

        case 2:
            return "İstatistikleri, veri kalitesini, dağılımları ve aykırı değerleri inceleyin."

        case 3:
            return "Analiz sonucunda belirlenen sorunları seçerek tek seferde temizleyin."

        case 4:
            return "Sütunları eşleştirin ve iki veri setini karşılaştırın."

        case 5:
            return "Temizlenmiş veya orijinal verilerin grafiklerini inceleyin ve Excel/CSV/JSON olarak dışa aktarın."

        case 6:
            return "Ham ikili veri paketlerini ve parametre metadatasını ayrıştırın, tablosunu inceleyin."

        default:
            return ""
        }
    }

    // =========================================================
    // ANA LAYOUT
    // =========================================================

    RowLayout {
        anchors.fill: parent

        spacing: 0

        // =====================================================
        // SIDEBAR
        // =====================================================

        Components.Sidebar {
            id: sidebar

            Layout.fillHeight: true

            currentPage: window.currentPage

            onPageSelected: {
                window.currentPage = index
            }
        }

        // =====================================================
        // SAĞ ANA ALAN
        // =====================================================

        ColumnLayout {
            Layout.fillWidth: true

            Layout.fillHeight: true

            spacing: 0

            // =================================================
            // TOP BAR
            // =================================================

            Components.TopBar {
                id: topBar

                Layout.fillWidth: true

                title:
                    window.pageTitle(
                        window.currentPage
                    )

                subtitle:
                    window.pageSubtitle(
                        window.currentPage
                    )

                onThemeToggleRequested: {
                    AppTheme.Theme.darkMode =
                            !AppTheme.Theme.darkMode
                }
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
            // SAYFA LOADER
            // =================================================

            Loader {
                id: pageLoader

                Layout.fillWidth: true

                Layout.fillHeight: true

                source: {
                    switch (window.currentPage) {

                    case 0:
                        return "qrc:/qml/pages/DashboardPage.qml"

                    case 1:
                        return "qrc:/qml/pages/DatasetsPage.qml"

                    case 2:
                        return "qrc:/qml/pages/AnalysisPage.qml"

                    case 3:
                        return "qrc:/qml/pages/DataCleaningPage.qml"

                    case 4:
                        return "qrc:/qml/pages/ComparisonPage.qml"

                    case 5:
                        return "qrc:/qml/pages/VisualizationPage.qml"

                    case 6:
                        return "qrc:/qml/pages/RawDataPage.qml"

                    default:
                        return "qrc:/qml/pages/DashboardPage.qml"
                    }
                }

                // =================================================
                // SAYFAYA ORTAK REFERANSLAR
                // =================================================

                onLoaded: {

                    if (item &&
                            item.hasOwnProperty("mainWindow")) {

                        item.mainWindow = window
                    }

                    if (item &&
                            item.hasOwnProperty("appController")) {

                        item.appController =
                                appController
                    }
                }
            }
        }
    }
}