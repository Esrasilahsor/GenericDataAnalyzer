import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../" as AppTheme

Item {
    id: page

    property var theme: AppTheme.Theme
    property var appController
    property var mainWindow

    function go(index) {
        if (page.mainWindow)
            page.mainWindow.currentPage = index
    }

    function loaded(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1Name !== ""
                : page.appController.dataset2Name !== ""
    }

    function name(dataset) {
        if (!page.appController)
            return "Yüklenmedi"

        var value = dataset === 1
                ? page.appController.dataset1Name
                : page.appController.dataset2Name

        return value !== "" ? value : "Yüklenmedi"
    }

    function rows(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1RowCount
                : page.appController.dataset2RowCount
    }

    function columns(dataset) {
        if (!page.appController)
            return 0

        return dataset === 1
                ? page.appController.dataset1ColumnCount
                : page.appController.dataset2ColumnCount
    }

    function qualityAvailable(dataset) {
        if (!page.appController)
            return false

        return dataset === 1
                ? page.appController.dataset1QualityAvailable
                : page.appController.dataset2QualityAvailable
    }

    function problemCount(dataset) {
        if (!qualityAvailable(dataset))
            return 0

        var result = dataset === 1
                ? page.appController.dataset1QualityResult
                : page.appController.dataset2QualityResult

        return Number(result.columnsWithMissingValues || 0)
                + (Number(result.duplicateRowCount || 0) > 0 ? 1 : 0)
                + Number(result.constantColumnCount || 0)
    }

    function datasetStatus(dataset) {
        if (!loaded(dataset))
            return "Dosya yüklenmedi"

        if (!qualityAvailable(dataset))
            return "Analiz bekliyor"

        var isModified = dataset === 1
            ? (page.appController && page.appController.dataset1Modified)
            : (page.appController && page.appController.dataset2Modified)

        if (isModified)
            return "✓ Temizlendi / Güncellendi"

        return problemCount(dataset) > 0
                ? "⚠ İnceleme gerekli"
                : "✓ Analize hazır"
    }

    function datasetStatusColor(dataset) {
        if (!loaded(dataset) || !qualityAvailable(dataset))
            return theme.textSecondary

        var isModified = dataset === 1
            ? (page.appController && page.appController.dataset1Modified)
            : (page.appController && page.appController.dataset2Modified)

        if (isModified)
            return theme.success

        return problemCount(dataset) > 0
                ? theme.warning
                : theme.success
    }

    function isStepCompleted(stepIndex) {
        if (!page.appController)
            return false

        switch (stepIndex) {
        case 1:
            return page.loaded(1) || page.loaded(2)
        case 2:
            return (page.loaded(1) && page.qualityAvailable(1)) ||
                   (page.loaded(2) && page.qualityAvailable(2))
        case 3:
            return (page.loaded(1) || page.loaded(2)) &&
                   (page.appController.cleaningCompleted ||
                    page.appController.dataset1Modified ||
                    page.appController.dataset2Modified ||
                    (page.qualityAvailable(1) && page.problemCount(1) === 0 && (!page.loaded(2) || page.problemCount(2) === 0)))
        case 4:
            return page.appController.datasetComparisonAvailable
        case 5:
            return page.appController.visualizationAvailable
        default:
            return false
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: page.width
            spacing: 18

            // =================================================
            // HEADER
            // =================================================

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 24
                spacing: 5
            }

            // =================================================
            // QUICK START
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 118

                radius: 18
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 14
                        color: theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "#FFFFFF"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Analiz sürecine başlayın"
                            color: theme.text
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Label {
                            text: "İki veri setini yükleyerek kalite, istatistik, aykırı değer ve karşılaştırma adımlarını tek akışta tamamlayabilirsiniz."
                            color: theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        Layout.preferredWidth: 175
                        Layout.preferredHeight: 42
                        text: "Veri Setlerine Git →"
                        onClicked: page.go(1)

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 9
                            color: theme.primary
                        }
                    }
                }
            }

            // =================================================
            // DATASET CARDS
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                spacing: 14

                Repeater {
                    model: 2

                    delegate: Rectangle {
                        id: datasetCard

                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        radius: 16
                        color: theme.surface
                        border.width: 1
                        border.color: theme.border

                        property int dataset: index + 1
                        property bool isLoaded: page.loaded(dataset)
                        property bool hasProblems: page.problemCount(dataset) > 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: "DATASET " + datasetCard.dataset
                                    color: theme.primary
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: page.datasetStatus(datasetCard.dataset)
                                    color: page.datasetStatusColor(datasetCard.dataset)
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Label {
                                text: page.name(datasetCard.dataset)
                                color: theme.text
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            Label {
                                text:
                                    datasetCard.isLoaded
                                    ? page.rows(datasetCard.dataset)
                                      + " satır  •  "
                                      + page.columns(datasetCard.dataset)
                                      + " sütun"
                                    : "Dosya yüklenmedi"
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }

                            Label {
                                property bool isMod: datasetCard.dataset === 1
                                    ? (page.appController && page.appController.dataset1Modified)
                                    : (page.appController && page.appController.dataset2Modified)

                                text:
                                    datasetCard.isLoaded && page.qualityAvailable(datasetCard.dataset)
                                    ? (isMod
                                       ? ("Temizleme uygulandı (" + (datasetCard.hasProblems ? page.problemCount(datasetCard.dataset) + " kalan sorun)" : "tüm sorunlar giderildi)"))
                                       : (datasetCard.hasProblems
                                          ? page.problemCount(datasetCard.dataset) + " kalite problemi tespit edildi."
                                          : "Kalite problemi tespit edilmedi."))
                                    : "Analiz sonucu henüz oluşturulmadı."
                                color:
                                    isMod
                                    ? theme.success
                                    : (datasetCard.hasProblems ? theme.warning : theme.textSecondary)
                                font.pixelSize: 12
                            }

                            Item {
                                Layout.fillHeight: true
                            }

                            Button {
                                Layout.preferredWidth: 160
                                Layout.preferredHeight: 36

                                text:
                                    !datasetCard.isLoaded
                                    ? "Veri Setlerine Git"
                                    : "Veri Analizine Git →"

                                onClicked:
                                    page.go(
                                        datasetCard.isLoaded ? 2 : 1
                                    )

                                contentItem: Text {
                                    text: parent.text
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    radius: 8
                                    color: theme.primary
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // WORKFLOW
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 185

                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Label {
                        text: "Analiz İş Akışı"
                        color: theme.text
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Label {
                        text: "Her adım bir sonraki aşamaya yönlendirir."
                        color: theme.textSecondary
                        font.pixelSize: 12
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Repeater {
                            model: [
                                {
                                    number: "01",
                                    title: "Veri Setleri",
                                    description: "Excel / CSV yükle ve önizle",
                                    pageIndex: 1
                                },
                                {
                                    number: "02",
                                    title: "Veri Analizi",
                                    description: "Kalite, istatistik ve outlier",
                                    pageIndex: 2
                                },
                                {
                                    number: "03",
                                    title: "Veri Temizleme",
                                    description: "Sorunları seç ve uygula",
                                    pageIndex: 3
                                },
                                {
                                    number: "04",
                                    title: "Karşılaştırma",
                                    description: "Eşleştir ve karşılaştır",
                                    pageIndex: 4
                                },
                                {
                                    number: "05",
                                    title: "Görselleştirme",
                                    description: "Grafik çiz ve dışa aktar",
                                    pageIndex: 5
                                }
                            ]

                            delegate: Rectangle {
                                id: workflowCard

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                radius: 11
                                color: workflowMouse.containsMouse
                                       ? theme.surfaceAlt
                                       : theme.background
                                border.width: workflowMouse.containsMouse ? 1 : 0
                                border.color: theme.primary

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Label {
                                            text: modelData.number
                                            color: page.isStepCompleted(modelData.pageIndex)
                                                   ? theme.success
                                                   : theme.primary
                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            visible: page.isStepCompleted(modelData.pageIndex)
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 80
                                            radius: 10
                                            color: "#E6F6EE"
                                            border.width: 1
                                            border.color: theme.success

                                            Label {
                                                anchors.centerIn: parent
                                                text: "✓ Tamamlandı"
                                                color: theme.success
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Label {
                                        text: modelData.title
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    Label {
                                        text: modelData.description
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                    }

                                    Label {
                                        text: page.isStepCompleted(modelData.pageIndex) ? "Görüntüle →" : "Aç →"
                                        color: page.isStepCompleted(modelData.pageIndex) ? theme.success : theme.primary
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: workflowMouse

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: page.go(modelData.pageIndex)
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // RECENT SESSION & ACTIVITY HISTORY CARD
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 330
                radius: 16
                color: theme.surface
                border.width: 1
                border.color: theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // Card Header & Actions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 8
                                Label {
                                    text: "🕒 Son İşlemler ve Oturum Kayıtları"
                                    color: theme.text
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Rectangle {
                                    visible: page.appController && page.appController.autoRestoreEnabled
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: 140
                                    radius: 10
                                    color: "#E6F6EE"
                                    border.width: 1
                                    border.color: theme.success

                                    Label {
                                        anchors.centerIn: parent
                                        text: "✓ Oturum Hatırlandı"
                                        color: theme.success
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            Label {
                                text: "Önceki oturumunuzda çalıştığınız dosyalar ve son yapılan analiz / temizleme işlemleri."
                                color: theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Button {
                            visible: page.appController && page.appController.hasPreviousSession
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: 180
                            text: "🔄 Son Oturumu Yükle"
                            onClicked: {
                                if (page.appController) {
                                    page.appController.restoreLastSession()
                                }
                            }
                        }

                        Button {
                            visible: (page.appController && page.appController.recentActivities.length > 0) ||
                                     (page.appController && page.appController.recentFiles.length > 0)
                            Layout.preferredHeight: 34
                            Layout.preferredWidth: 120
                            text: "🗑 Geçmişi Sil"
                            onClicked: {
                                if (page.appController) {
                                    page.appController.clearRecentActivities()
                                    page.appController.clearRecentFiles()
                                }
                            }
                        }
                    }

                    // Content Split: Left (Recent Files) & Right (Recent Activities Timeline)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16

                        // Left Column: Recent Files
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: theme.background
                            border.width: 1
                            border.color: theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "📂 Son Kullanılan Dosyalar"
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: ((page.appController && page.appController.recentFiles) ? page.appController.recentFiles.length : 0) + " dosya"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 6
                                    model: page.appController ? page.appController.recentFiles : []

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 52
                                        radius: 8
                                        color: theme.surface
                                        border.width: 1
                                        border.color: theme.border

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 10

                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: 6
                                                color: modelData.type && modelData.type.indexOf("Bin") !== -1 ? "#EDE7F6" : "#E8F5E9"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: modelData.name && modelData.name.indexOf(".bin") !== -1 ? "BIN" : (modelData.name && modelData.name.indexOf(".csv") !== -1 ? "CSV" : "XLS")
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: modelData.type && modelData.type.indexOf("Bin") !== -1 ? "#5E35B1" : "#2E7D32"
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Label {
                                                    text: modelData.name || ""
                                                    color: theme.text
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    elide: Text.ElideMiddle
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: (modelData.type || "") + " • " + (modelData.rowCount ? modelData.rowCount + " satır • " : "") + (modelData.timestamp || "")
                                                    color: theme.textSecondary
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Button {
                                                Layout.preferredHeight: 28
                                                Layout.preferredWidth: 65
                                                text: "D1 Yükle"
                                                font.pixelSize: 10
                                                onClicked: {
                                                    if (page.appController && modelData.path) {
                                                        page.appController.loadRecentFileAsDataset(1, modelData.path)
                                                    }
                                                }
                                            }

                                            Button {
                                                Layout.preferredHeight: 28
                                                Layout.preferredWidth: 65
                                                text: "D2 Yükle"
                                                font.pixelSize: 10
                                                onClicked: {
                                                    if (page.appController && modelData.path) {
                                                        page.appController.loadRecentFileAsDataset(2, modelData.path)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !page.appController || !page.appController.recentFiles || page.appController.recentFiles.length === 0
                                        text: "Henüz açılan dosya geçmişi yok."
                                        color: theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Right Column: Activity History Timeline
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: theme.background
                            border.width: 1
                            border.color: theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: "⚡ Son Yapılan İşlemler"
                                        color: theme.text
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Label {
                                        text: ((page.appController && page.appController.recentActivities) ? page.appController.recentActivities.length : 0) + " kayıt"
                                        color: theme.textSecondary
                                        font.pixelSize: 11
                                    }
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 6
                                    model: page.appController ? page.appController.recentActivities : []

                                    delegate: Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: 8
                                        color: theme.surface
                                        border.width: 1
                                        border.color: theme.border

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredHeight: 22
                                                Layout.preferredWidth: 68
                                                radius: 4
                                                color: modelData.category === "Yükleme" ? "#E3F2FD" :
                                                       modelData.category === "Temizleme" ? "#FFF3E0" :
                                                       modelData.category === "Karşılaştırma" ? "#FCE4EC" :
                                                       modelData.category === "Görselleştirme" ? "#E8F5E9" :
                                                       modelData.category === "Ham Veri" ? "#EDE7F6" : "#ECEFF1"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: modelData.category || "İşlem"
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: modelData.category === "Yükleme" ? "#1565C0" :
                                                           modelData.category === "Temizleme" ? "#E65100" :
                                                           modelData.category === "Karşılaştırma" ? "#AD1457" :
                                                           modelData.category === "Görselleştirme" ? "#2E7D32" :
                                                           modelData.category === "Ham Veri" ? "#5E35B1" : "#455A64"
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Label {
                                                    text: modelData.title || ""
                                                    color: theme.text
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: modelData.detail || ""
                                                    color: theme.textSecondary
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Label {
                                                text: modelData.timeShort || ""
                                                color: theme.textSecondary
                                                font.pixelSize: 10
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !page.appController || !page.appController.recentActivities || page.appController.recentActivities.length === 0
                                        text: "Henüz işlem kaydı bulunmuyor."
                                        color: theme.textSecondary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================
            // NEXT ACTION
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.preferredHeight: 92

                radius: 14
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: theme.primary

                        Label {
                            anchors.centerIn: parent
                            text: "i"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: "Önerilen sonraki adım"
                            color: theme.text
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Label {
                            text:
                                !page.loaded(1) && !page.loaded(2)
                                ? "Önce veri setlerinizi yükleyin."
                                : (!page.qualityAvailable(1) &&
                                   (!page.loaded(2) || !page.qualityAvailable(2)))
                                  ? "Veri Analizi ekranından veri kalitesini ve istatistikleri inceleyin."
                                  : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                    ? "Tespit edilen problemleri Veri Temizleme ekranından yönetin."
                                    : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                      ? "Veri setlerinizi Karşılaştırma ekranında eşleştirip karşılaştırın."
                                      : "Görselleştirme sayfasında grafiklerinizi inceleyebilirsiniz."
                            color: theme.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        Layout.preferredWidth: 170
                        Layout.preferredHeight: 38

                        text:
                            !page.loaded(1) && !page.loaded(2)
                            ? "Veri Setlerine Git →"
                            : (!page.qualityAvailable(1) &&
                               (!page.loaded(2) || !page.qualityAvailable(2)))
                              ? "Veri Analizi →"
                              : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                ? "Veri Temizleme →"
                                : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                  ? "Karşılaştırma →"
                                  : "Görselleştirme →"

                        onClicked:
                            !page.loaded(1) && !page.loaded(2)
                            ? page.go(1)
                            : (!page.qualityAvailable(1) &&
                               (!page.loaded(2) || !page.qualityAvailable(2)))
                              ? page.go(2)
                              : (!page.isStepCompleted(3) && (page.problemCount(1) > 0 || page.problemCount(2) > 0))
                                ? page.go(3)
                                : (!page.isStepCompleted(4) && page.loaded(1) && page.loaded(2))
                                  ? page.go(4)
                                  : page.go(5)

                        contentItem: Text {
                            text: parent.text
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 8
                            color: theme.primary
                        }
                    }
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }
}
