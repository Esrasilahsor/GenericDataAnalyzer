import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "components" as Components

ApplicationWindow {
    id: window

    visible: true

    width: 1440
    height: 900

    minimumWidth: 1100
    minimumHeight: 700

    title: "Generic Data Analyzer"

    color: "#F7F5FB"

    property int currentPage: 0

    function pageTitle(index) {
        switch (index) {
        case 0: return "Dashboard"
        case 1: return "Veri Setleri"
        case 2: return "Veri Kalitesi"
        case 3: return "Sütun Eşleştirme"
        case 4: return "Veri Analizi"
        case 5: return "Outlier Analysis"
        case 6: return "Karşılaştırma"
        default: return "Dashboard"
        }
    }

    function pageSubtitle(index) {
        switch (index) {
        case 0:
            return "Veri setlerinizi yönetin ve analiz sürecini başlatın."

        case 1:
            return "Yüklenen veri setlerinin yapısını inceleyin."

        case 2:
            return "Veri kalitesi ve bütünlük sonuçlarını inceleyin."

        case 3:
            return "Karşılaştırılacak sütunları eşleştirin."

        case 4:
            return "Veri setleri üzerinde analiz gerçekleştirin."

        case 5:
            return "Aykırı değerleri IQR yöntemiyle analiz edin."

        case 6:
            return "Eşleştirilmiş veri setlerini karşılaştırın."

        default:
            return ""
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // SOL MENÜ
        Components.Sidebar {
            id: sidebar

            Layout.fillHeight: true

            onPageSelected: {
                window.currentPage = index
            }
        }

        // ANA ALAN
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            spacing: 0

            // ÜST BAR
            Components.TopBar {
                Layout.fillWidth: true

                title: window.pageTitle(window.currentPage)

                subtitle: window.pageSubtitle(window.currentPage)
            }

            // AYIRICI ÇİZGİ
            Rectangle {
                Layout.fillWidth: true

                height: 1

                color: "#E5DFF0"
            }

            // SAYFALAR
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
                        return "qrc:/qml/pages/DataQualityPage.qml"

                    case 3:
                        return "qrc:/qml/pages/MappingPage.qml"

                    case 4:
                        return "qrc:/qml/pages/AnalysisPage.qml"

                    case 5:
                        return "qrc:/qml/pages/OutlierPage.qml"

                    case 6:
                        return "qrc:/qml/pages/ComparisonPage.qml"

                    default:
                        return "qrc:/qml/pages/DashboardPage.qml"
                    }
                }
            }
        }
    }
}