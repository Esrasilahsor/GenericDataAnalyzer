#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QString>
#include <QVariantMap>

#include "../parser/ExcelParser.h"
#include "../parser/DataSet.h"

#include "../models/ColumnModel.h"
#include "../models/MappingModel.h"

#include "../analysis/ComparisonEngine.h"
#include "../analysis/AnalysisEngine.h"


class AppController : public QObject
{
    Q_OBJECT

    // =====================================================
    // DATASET 1
    // =====================================================

    Q_PROPERTY(
        QString dataset1Name
            READ dataset1Name
                NOTIFY dataset1Changed
        )

    Q_PROPERTY(
        int dataset1RowCount
            READ dataset1RowCount
                NOTIFY dataset1Changed
        )

    Q_PROPERTY(
        int dataset1ColumnCount
            READ dataset1ColumnCount
                NOTIFY dataset1Changed
        )

    Q_PROPERTY(
        QString dataset1SheetName
            READ dataset1SheetName
                NOTIFY dataset1Changed
        )


    // =====================================================
    // DATASET 2
    // =====================================================

    Q_PROPERTY(
        QString dataset2Name
            READ dataset2Name
                NOTIFY dataset2Changed
        )

    Q_PROPERTY(
        int dataset2RowCount
            READ dataset2RowCount
                NOTIFY dataset2Changed
        )

    Q_PROPERTY(
        int dataset2ColumnCount
            READ dataset2ColumnCount
                NOTIFY dataset2Changed
        )

    Q_PROPERTY(
        QString dataset2SheetName
            READ dataset2SheetName
                NOTIFY dataset2Changed
        )


    // =====================================================
    // ERROR
    // =====================================================

    Q_PROPERTY(
        QString lastError
            READ lastError
                NOTIFY errorChanged
        )


    // =====================================================
    // MODELS
    // =====================================================

    Q_PROPERTY(
        ColumnModel* dataset1ColumnModel
            READ dataset1ColumnModel
                CONSTANT
        )

    Q_PROPERTY(
        ColumnModel* dataset2ColumnModel
            READ dataset2ColumnModel
                CONSTANT
        )

    Q_PROPERTY(
        MappingModel* mappingModel
            READ mappingModel
                CONSTANT
        )


    // =====================================================
    // ANALYSIS
    // =====================================================

    Q_PROPERTY(
        QVariantMap analysisResult
            READ analysisResult
                NOTIFY analysisResultChanged
        )

    Q_PROPERTY(
        bool analysisAvailable
            READ analysisAvailable
                NOTIFY analysisResultChanged
        )


public:

    explicit AppController(
        QObject *parent = nullptr
        );


    // =====================================================
    // DATASET GETTERS
    // =====================================================

    QString dataset1Name() const;
    QString dataset2Name() const;

    int dataset1RowCount() const;
    int dataset2RowCount() const;

    int dataset1ColumnCount() const;
    int dataset2ColumnCount() const;

    QString dataset1SheetName() const;
    QString dataset2SheetName() const;


    // =====================================================
    // ERROR
    // =====================================================

    QString lastError() const;


    // =====================================================
    // MODELS
    // =====================================================

    ColumnModel *dataset1ColumnModel();

    ColumnModel *dataset2ColumnModel();

    MappingModel *mappingModel();


    // =====================================================
    // ANALYSIS GETTERS
    // =====================================================

    QVariantMap analysisResult() const;

    bool analysisAvailable() const;


    // =====================================================
    // DATASET LOADING
    // =====================================================

    Q_INVOKABLE bool loadDataset1(
        const QString &filePath
        );

    Q_INVOKABLE bool loadDataset2(
        const QString &filePath
        );


    // =====================================================
    // MAPPING
    // =====================================================

    Q_INVOKABLE void generateMappings();

    Q_INVOKABLE void clearMappings();


    // =====================================================
    // ANALYSIS
    // =====================================================

    /*
     * QML'den iki sütunun ismini vererek
     * karşılaştırma yapacağız.
     *
     * Örnek:
     *
     * analyzeColumns(
     *     "Egzoz Sıcaklığı",
     *     "Egzoz Sicakligi"
     * )
     */

    Q_INVOKABLE bool analyzeColumns(
        const QString &sourceColumn,
        const QString &targetColumn
        );

    Q_INVOKABLE void clearAnalysis();


signals:

    // =====================================================
    // DATASET SIGNALS
    // =====================================================

    void dataset1Changed();

    void dataset2Changed();


    // =====================================================
    // MAPPING SIGNALS
    // =====================================================

    void mappingsChanged();


    // =====================================================
    // ERROR SIGNAL
    // =====================================================

    void errorChanged();


    // =====================================================
    // ANALYSIS SIGNAL
    // =====================================================

    void analysisResultChanged();


private:

    // =====================================================
    // PARSERS
    // =====================================================

    ExcelParser m_parser1;
    ExcelParser m_parser2;


    // =====================================================
    // DATASETS
    // =====================================================

    DataSet m_dataset1;
    DataSet m_dataset2;


    // =====================================================
    // MODELS
    // =====================================================

    ColumnModel m_dataset1ColumnModel;
    ColumnModel m_dataset2ColumnModel;

    MappingModel m_mappingModel;


    // =====================================================
    // ENGINES
    // =====================================================

    ComparisonEngine m_comparisonEngine;

    AnalysisEngine m_analysisEngine;


    // =====================================================
    // ANALYSIS RESULT
    // =====================================================

    QVariantMap m_analysisResult;

    bool m_analysisAvailable = false;


    // =====================================================
    // ERROR
    // =====================================================

    QString m_lastError;


    // =====================================================
    // HELPERS
    // =====================================================

    QString normalizeFilePath(
        const QString &filePath
        ) const;

    void tryGenerateMappings();


    /*
     * StatisticsResult yapısını QML'in rahat
     * okuyabileceği QVariantMap'e çevirir.
     */
    QVariantMap statisticsToVariantMap(
        const StatisticsResult &statistics
        ) const;
};

#endif // APPCONTROLLER_H