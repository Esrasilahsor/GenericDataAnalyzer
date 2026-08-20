#ifndef APPCONTROLLER_H
#define APPCONTROLLER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QByteArray>
#include <QList>

#include "../parser/ExcelParser.h"
#include "../parser/DataSet.h"
#include "../parser/ParameterDefinition.h"
#include "../parser/RawDataParser.h"

#include "../models/ColumnModel.h"
#include "../models/MappingModel.h"
#include "../models/ParameterModel.h"

#include "../analysis/ComparisonEngine.h"
#include "../analysis/AnalysisEngine.h"


class AppController : public QObject
{
    Q_OBJECT

    // =====================================================
    // DATASET 1
    // =====================================================

    Q_PROPERTY(QString dataset1Name
                   READ dataset1Name
                       NOTIFY dataset1Changed)

    Q_PROPERTY(int dataset1RowCount
                   READ dataset1RowCount
                       NOTIFY dataset1Changed)

    Q_PROPERTY(int dataset1ColumnCount
                   READ dataset1ColumnCount
                       NOTIFY dataset1Changed)

    Q_PROPERTY(QString dataset1SheetName
                   READ dataset1SheetName
                       NOTIFY dataset1Changed)

    // =====================================================
    // DATASET 2
    // =====================================================

    Q_PROPERTY(QString dataset2Name
                   READ dataset2Name
                       NOTIFY dataset2Changed)

    Q_PROPERTY(int dataset2RowCount
                   READ dataset2RowCount
                       NOTIFY dataset2Changed)

    Q_PROPERTY(int dataset2ColumnCount
                   READ dataset2ColumnCount
                       NOTIFY dataset2Changed)

    Q_PROPERTY(QString dataset2SheetName
                   READ dataset2SheetName
                       NOTIFY dataset2Changed)

    // =====================================================
    // WORKING DATASET STATE
    // =====================================================

    Q_PROPERTY(bool dataset1Modified
                   READ dataset1Modified
                       NOTIFY dataset1Changed)

    Q_PROPERTY(bool dataset2Modified
                   READ dataset2Modified
                       NOTIFY dataset2Changed)

    // =====================================================
    // ERROR
    // =====================================================

    Q_PROPERTY(QString lastError
                   READ lastError
                       NOTIFY errorChanged)

    // =====================================================
    // MODELS
    // =====================================================

    Q_PROPERTY(ColumnModel* dataset1ColumnModel
                   READ dataset1ColumnModel
                       CONSTANT)

    Q_PROPERTY(ColumnModel* dataset2ColumnModel
                   READ dataset2ColumnModel
                       CONSTANT)

    Q_PROPERTY(MappingModel* mappingModel
                   READ mappingModel
                       CONSTANT)

    Q_PROPERTY(ParameterModel* parameterModel
                   READ parameterModel
                       CONSTANT)

    // =====================================================
    // COLUMN COMPARISON
    // =====================================================

    Q_PROPERTY(QVariantMap analysisResult
                   READ analysisResult
                       NOTIFY analysisResultChanged)

    Q_PROPERTY(bool analysisAvailable
                   READ analysisAvailable
                       NOTIFY analysisResultChanged)

    // =====================================================
    // DATA QUALITY
    // =====================================================

    Q_PROPERTY(QVariantMap dataset1QualityResult
                   READ dataset1QualityResult
                       NOTIFY dataset1QualityChanged)

    Q_PROPERTY(QVariantMap dataset2QualityResult
                   READ dataset2QualityResult
                       NOTIFY dataset2QualityChanged)

    Q_PROPERTY(bool dataset1QualityAvailable
                   READ dataset1QualityAvailable
                       NOTIFY dataset1QualityChanged)

    Q_PROPERTY(bool dataset2QualityAvailable
                   READ dataset2QualityAvailable
                       NOTIFY dataset2QualityChanged)

    // =====================================================
    // OUTLIER ANALYSIS
    // =====================================================

    Q_PROPERTY(QVariantMap dataset1OutlierResult
                   READ dataset1OutlierResult
                       NOTIFY dataset1OutlierChanged)

    Q_PROPERTY(QVariantMap dataset2OutlierResult
                   READ dataset2OutlierResult
                       NOTIFY dataset2OutlierChanged)

    Q_PROPERTY(bool dataset1OutlierAvailable
                   READ dataset1OutlierAvailable
                       NOTIFY dataset1OutlierChanged)

    Q_PROPERTY(bool dataset2OutlierAvailable
                   READ dataset2OutlierAvailable
                       NOTIFY dataset2OutlierChanged)

    // =====================================================
    // RAW DATA
    // =====================================================

    Q_PROPERTY(bool rawMetadataLoaded
                   READ rawMetadataLoaded
                       NOTIFY rawMetadataChanged)

    Q_PROPERTY(bool rawDataLoaded
                   READ rawDataLoaded
                       NOTIFY rawDataChanged)

    Q_PROPERTY(bool rawParseAvailable
                   READ rawParseAvailable
                       NOTIFY rawParseChanged)

    Q_PROPERTY(int rawParameterDefinitionCount
                   READ rawParameterDefinitionCount
                       NOTIFY rawMetadataChanged)

    Q_PROPERTY(int rawDataByteCount
                   READ rawDataByteCount
                       NOTIFY rawDataChanged)

    Q_PROPERTY(QString rawMetadataFilePath
                   READ rawMetadataFilePath
                       NOTIFY rawMetadataChanged)

    Q_PROPERTY(QString rawDataFilePath
                   READ rawDataFilePath
                       NOTIFY rawDataChanged)

    Q_PROPERTY(QStringList rawWarnings
                   READ rawWarnings
                       NOTIFY rawMetadataChanged)


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

    bool dataset1Modified() const;
    bool dataset2Modified() const;


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

    ParameterModel *parameterModel();


    // =====================================================
    // COMPARISON
    // =====================================================

    QVariantMap analysisResult() const;

    bool analysisAvailable() const;


    // =====================================================
    // QUALITY
    // =====================================================

    QVariantMap dataset1QualityResult() const;
    QVariantMap dataset2QualityResult() const;

    bool dataset1QualityAvailable() const;
    bool dataset2QualityAvailable() const;


    // =====================================================
    // OUTLIER
    // =====================================================

    QVariantMap dataset1OutlierResult() const;
    QVariantMap dataset2OutlierResult() const;

    bool dataset1OutlierAvailable() const;
    bool dataset2OutlierAvailable() const;


    // =====================================================
    // RAW
    // =====================================================

    bool rawMetadataLoaded() const;
    bool rawDataLoaded() const;
    bool rawParseAvailable() const;

    int rawParameterDefinitionCount() const;
    int rawDataByteCount() const;

    QString rawMetadataFilePath() const;
    QString rawDataFilePath() const;

    QStringList rawWarnings() const;


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
    // RESTORE ORIGINAL
    // =====================================================

    Q_INVOKABLE bool restoreDataset1();

    Q_INVOKABLE bool restoreDataset2();


    // =====================================================
    // CLEANING - DUPLICATES
    // =====================================================

    Q_INVOKABLE bool removeDataset1Duplicates();

    Q_INVOKABLE bool removeDataset2Duplicates();


    // =====================================================
    // CLEANING - MISSING ROWS
    // =====================================================

    Q_INVOKABLE bool removeDataset1MissingRows();

    Q_INVOKABLE bool removeDataset2MissingRows();

    // =====================================================
    // CLEANING - FILL MISSING WITH MEAN
    // =====================================================

    Q_INVOKABLE bool fillDataset1MissingWithMean(
        const QString &columnName
        );

    Q_INVOKABLE bool fillDataset2MissingWithMean(
        const QString &columnName
        );

    Q_INVOKABLE bool fillDataset1MissingWithMedian(
        const QString &columnName
        );

    Q_INVOKABLE bool fillDataset2MissingWithMedian(
        const QString &columnName
        );

    Q_INVOKABLE bool fillDataset1MissingWithMode(
        const QString &columnName
        );

    Q_INVOKABLE bool fillDataset2MissingWithMode(
        const QString &columnName
        );

    // =====================================================
    // CLEANING - OUTLIERS
    // =====================================================

    Q_INVOKABLE bool removeDataset1Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE bool removeDataset2Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );
    // =====================================================
    // MAPPING
    // =====================================================

    Q_INVOKABLE void generateMappings();

    Q_INVOKABLE void clearMappings();


    // =====================================================
    // COMPARISON
    // =====================================================

    Q_INVOKABLE bool analyzeColumns(
        const QString &sourceColumn,
        const QString &targetColumn
        );

    Q_INVOKABLE void clearAnalysis();


    // =====================================================
    // QUALITY
    // =====================================================

    Q_INVOKABLE bool analyzeDataset1Quality();

    Q_INVOKABLE bool analyzeDataset2Quality();

    Q_INVOKABLE void clearDataset1Quality();

    Q_INVOKABLE void clearDataset2Quality();


    // =====================================================
    // OUTLIER
    // =====================================================

    Q_INVOKABLE bool analyzeDataset1Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE bool analyzeDataset2Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE void clearDataset1Outliers();

    Q_INVOKABLE void clearDataset2Outliers();


    // =====================================================
    // RAW
    // =====================================================

    Q_INVOKABLE bool loadRawMetadata(
        const QString &filePath
        );

    Q_INVOKABLE bool loadRawDataFile(
        const QString &filePath
        );

    Q_INVOKABLE bool parseRawData();

    Q_INVOKABLE void clearRawMetadata();

    Q_INVOKABLE void clearRawData();

    Q_INVOKABLE void clearRawParse();


signals:

    void dataset1Changed();

    void dataset2Changed();

    void mappingsChanged();

    void errorChanged();

    void analysisResultChanged();

    void dataset1QualityChanged();

    void dataset2QualityChanged();

    void dataset1OutlierChanged();

    void dataset2OutlierChanged();

    void rawMetadataChanged();

    void rawDataChanged();

    void rawParseChanged();


private:

    // =====================================================
    // PARSERS
    // =====================================================

    ExcelParser m_parser1;
    ExcelParser m_parser2;
    ExcelParser m_rawMetadataParser;

    RawDataParser m_rawDataParser;


    // =====================================================
    // WORKING DATASETS
    // =====================================================

    DataSet m_dataset1;
    DataSet m_dataset2;


    // =====================================================
    // ORIGINAL DATASETS
    // =====================================================

    DataSet m_originalDataset1;
    DataSet m_originalDataset2;

    bool m_dataset1Modified = false;
    bool m_dataset2Modified = false;


    // =====================================================
    // MODELS
    // =====================================================

    ColumnModel m_dataset1ColumnModel;
    ColumnModel m_dataset2ColumnModel;

    MappingModel m_mappingModel;

    ParameterModel m_parameterModel;


    // =====================================================
    // ENGINES
    // =====================================================

    ComparisonEngine m_comparisonEngine;

    AnalysisEngine m_analysisEngine;


    // =====================================================
    // COMPARISON
    // =====================================================

    QVariantMap m_analysisResult;

    bool m_analysisAvailable = false;


    // =====================================================
    // QUALITY
    // =====================================================

    QVariantMap m_dataset1QualityResult;
    QVariantMap m_dataset2QualityResult;

    bool m_dataset1QualityAvailable = false;
    bool m_dataset2QualityAvailable = false;


    // =====================================================
    // OUTLIER
    // =====================================================

    QVariantMap m_dataset1OutlierResult;
    QVariantMap m_dataset2OutlierResult;

    bool m_dataset1OutlierAvailable = false;
    bool m_dataset2OutlierAvailable = false;


    // =====================================================
    // RAW
    // =====================================================

    QList<ParameterDefinition>
        m_rawParameterDefinitions;

    QByteArray m_rawData;

    QString m_rawMetadataFilePath;
    QString m_rawDataFilePath;

    QStringList m_rawWarnings;

    bool m_rawMetadataLoaded = false;
    bool m_rawDataLoaded = false;
    bool m_rawParseAvailable = false;


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

    void setError(
        const QString &message
        );

    void clearError();

    QVariantMap statisticsToVariantMap(
        const StatisticsResult &statistics
        ) const;

    QVariantMap qualityToVariantMap(
        const DatasetQualityResult &quality
        ) const;

    QVariantMap outlierToVariantMap(
        const ColumnOutlierAnalysisResult &result
        ) const;
};

#endif // APPCONTROLLER_H