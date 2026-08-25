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
#include "../parser/ParserTypes.h"
#include "../parser/RawDataParser.h"

#include "../models/ColumnModel.h"
#include "../models/MappingModel.h"
#include "../models/ParameterModel.h"

#include "../analysis/ComparisonEngine.h"
#include "../analysis/AnalysisEngine.h"
#include "../analysis/EdaEngine.h"
#include "../cleaning/CleaningEngine.h"
#include "../visualization/VisualizationEngine.h"
#include "../export/ExportEngine.h"

class AppController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString dataset1Name READ dataset1Name NOTIFY dataset1Changed)
    Q_PROPERTY(int dataset1RowCount READ dataset1RowCount NOTIFY dataset1Changed)
    Q_PROPERTY(int dataset1ColumnCount READ dataset1ColumnCount NOTIFY dataset1Changed)
    Q_PROPERTY(QString dataset1SheetName READ dataset1SheetName NOTIFY dataset1Changed)
    Q_PROPERTY(QString dataDirectory READ dataDirectory CONSTANT)

    Q_PROPERTY(QString dataset2Name READ dataset2Name NOTIFY dataset2Changed)
    Q_PROPERTY(int dataset2RowCount READ dataset2RowCount NOTIFY dataset2Changed)
    Q_PROPERTY(int dataset2ColumnCount READ dataset2ColumnCount NOTIFY dataset2Changed)
    Q_PROPERTY(QString dataset2SheetName READ dataset2SheetName NOTIFY dataset2Changed)

    Q_PROPERTY(bool dataset1Modified READ dataset1Modified NOTIFY dataset1Changed)
    Q_PROPERTY(bool dataset2Modified READ dataset2Modified NOTIFY dataset2Changed)

    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged)

    Q_PROPERTY(ColumnModel* dataset1ColumnModel READ dataset1ColumnModel CONSTANT)
    Q_PROPERTY(ColumnModel* dataset2ColumnModel READ dataset2ColumnModel CONSTANT)
    Q_PROPERTY(MappingModel* mappingModel READ mappingModel CONSTANT)
    Q_PROPERTY(ParameterModel* parameterModel READ parameterModel CONSTANT)

    Q_PROPERTY(QVariantMap analysisResult READ analysisResult NOTIFY analysisResultChanged)
    Q_PROPERTY(bool analysisAvailable READ analysisAvailable NOTIFY analysisResultChanged)

    Q_PROPERTY(QVariantMap datasetComparisonResult READ datasetComparisonResult NOTIFY datasetComparisonChanged)
    Q_PROPERTY(bool datasetComparisonAvailable READ datasetComparisonAvailable NOTIFY datasetComparisonChanged)

    Q_PROPERTY(QVariantMap dataset1EdaResult READ dataset1EdaResult NOTIFY dataset1EdaChanged)
    Q_PROPERTY(QVariantMap dataset2EdaResult READ dataset2EdaResult NOTIFY dataset2EdaChanged)
    Q_PROPERTY(bool dataset1EdaAvailable READ dataset1EdaAvailable NOTIFY dataset1EdaChanged)
    Q_PROPERTY(bool dataset2EdaAvailable READ dataset2EdaAvailable NOTIFY dataset2EdaChanged)

    Q_PROPERTY(QVariantMap dataset1CorrelationResult READ dataset1CorrelationResult NOTIFY dataset1CorrelationChanged)
    Q_PROPERTY(QVariantMap dataset2CorrelationResult READ dataset2CorrelationResult NOTIFY dataset2CorrelationChanged)
    Q_PROPERTY(bool dataset1CorrelationAvailable READ dataset1CorrelationAvailable NOTIFY dataset1CorrelationChanged)
    Q_PROPERTY(bool dataset2CorrelationAvailable READ dataset2CorrelationAvailable NOTIFY dataset2CorrelationChanged)

    Q_PROPERTY(QVariantMap dataset1QualityResult READ dataset1QualityResult NOTIFY dataset1QualityChanged)
    Q_PROPERTY(QVariantMap dataset2QualityResult READ dataset2QualityResult NOTIFY dataset2QualityChanged)
    Q_PROPERTY(bool dataset1QualityAvailable READ dataset1QualityAvailable NOTIFY dataset1QualityChanged)
    Q_PROPERTY(bool dataset2QualityAvailable READ dataset2QualityAvailable NOTIFY dataset2QualityChanged)

    Q_PROPERTY(QVariantMap dataset1OutlierResult READ dataset1OutlierResult NOTIFY dataset1OutlierChanged)
    Q_PROPERTY(QVariantMap dataset2OutlierResult READ dataset2OutlierResult NOTIFY dataset2OutlierChanged)
    Q_PROPERTY(bool dataset1OutlierAvailable READ dataset1OutlierAvailable NOTIFY dataset1OutlierChanged)
    Q_PROPERTY(bool dataset2OutlierAvailable READ dataset2OutlierAvailable NOTIFY dataset2OutlierChanged)

    Q_PROPERTY(QVariantMap dataset1OutlierCleaningResult
                   READ dataset1OutlierCleaningResult
                       NOTIFY dataset1OutlierCleaningChanged)

    Q_PROPERTY(QVariantMap dataset2OutlierCleaningResult
                   READ dataset2OutlierCleaningResult
                       NOTIFY dataset2OutlierCleaningChanged)

    Q_PROPERTY(bool rawMetadataLoaded READ rawMetadataLoaded NOTIFY rawMetadataChanged)
    Q_PROPERTY(bool rawDataLoaded READ rawDataLoaded NOTIFY rawDataChanged)
    Q_PROPERTY(bool rawParseAvailable READ rawParseAvailable NOTIFY rawParseChanged)
    Q_PROPERTY(int rawParameterDefinitionCount READ rawParameterDefinitionCount NOTIFY rawMetadataChanged)
    Q_PROPERTY(int rawDataByteCount READ rawDataByteCount NOTIFY rawDataChanged)
    Q_PROPERTY(QString rawMetadataFilePath READ rawMetadataFilePath NOTIFY rawMetadataChanged)
    Q_PROPERTY(QString rawDataFilePath READ rawDataFilePath NOTIFY rawDataChanged)
    Q_PROPERTY(QStringList rawWarnings READ rawWarnings NOTIFY rawMetadataChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    QString dataset1Name() const;
    QString dataset2Name() const;
    QString dataDirectory() const;

    int dataset1RowCount() const;
    int dataset2RowCount() const;

    int dataset1ColumnCount() const;
    int dataset2ColumnCount() const;

    QString dataset1SheetName() const;
    QString dataset2SheetName() const;

    bool dataset1Modified() const;
    bool dataset2Modified() const;

    QString lastError() const;

    ColumnModel *dataset1ColumnModel();
    ColumnModel *dataset2ColumnModel();
    MappingModel *mappingModel();
    ParameterModel *parameterModel();

    QVariantMap analysisResult() const;
    bool analysisAvailable() const;

    QVariantMap datasetComparisonResult() const;
    bool datasetComparisonAvailable() const;

    QVariantMap dataset1EdaResult() const;
    QVariantMap dataset2EdaResult() const;
    bool dataset1EdaAvailable() const;
    bool dataset2EdaAvailable() const;

    QVariantMap dataset1CorrelationResult() const;
    QVariantMap dataset2CorrelationResult() const;
    bool dataset1CorrelationAvailable() const;
    bool dataset2CorrelationAvailable() const;

    QVariantMap dataset1QualityResult() const;
    QVariantMap dataset2QualityResult() const;
    bool dataset1QualityAvailable() const;
    bool dataset2QualityAvailable() const;

    QVariantMap dataset1OutlierResult() const;
    QVariantMap dataset2OutlierResult() const;
    bool dataset1OutlierAvailable() const;
    bool dataset2OutlierAvailable() const;

    QVariantMap dataset1OutlierCleaningResult() const;
    QVariantMap dataset2OutlierCleaningResult() const;

    bool rawMetadataLoaded() const;
    bool rawDataLoaded() const;
    bool rawParseAvailable() const;

    int rawParameterDefinitionCount() const;
    int rawDataByteCount() const;

    QString rawMetadataFilePath() const;
    QString rawDataFilePath() const;
    QStringList rawWarnings() const;

    Q_INVOKABLE bool loadDataset1(const QString &filePath);
    Q_INVOKABLE bool loadDataset2(const QString &filePath);

    Q_INVOKABLE bool restoreDataset1();
    Q_INVOKABLE bool restoreDataset2();

    Q_INVOKABLE bool removeDataset1Duplicates();
    Q_INVOKABLE bool removeDataset2Duplicates();

    Q_INVOKABLE bool removeDataset1MissingRows();
    Q_INVOKABLE bool removeDataset2MissingRows();

    Q_INVOKABLE bool fillDataset1MissingWithMean(const QString &columnName);
    Q_INVOKABLE bool fillDataset2MissingWithMean(const QString &columnName);

    Q_INVOKABLE bool fillDataset1MissingWithMedian(const QString &columnName);
    Q_INVOKABLE bool fillDataset2MissingWithMedian(const QString &columnName);

    Q_INVOKABLE bool fillDataset1MissingWithMode(const QString &columnName);
    Q_INVOKABLE bool fillDataset2MissingWithMode(const QString &columnName);

    Q_INVOKABLE bool analyzeDataset1OutliersAllColumns(
        const QString &method,
        double parameter
        );

    Q_INVOKABLE bool analyzeDataset2OutliersAllColumns(
        const QString &method,
        double parameter
        );

    // Eski IQR Remove çağrılarını bozmaz.
    Q_INVOKABLE bool removeDataset1Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE bool removeDataset2Outliers(
        const QString &columnName,
        double multiplier = 1.5
        );

    // Gereksinimdeki IQR / Z-Score + Keep / Mark / Remove.
    Q_INVOKABLE bool applyDataset1OutlierAction(
        const QString &columnName,
        const QString &method,
        const QString &action,
        double parameter
        );

    Q_INVOKABLE bool applyDataset2OutlierAction(
        const QString &columnName,
        const QString &method,
        const QString &action,
        double parameter
        );

    Q_INVOKABLE void clearDataset1OutlierCleaning();
    Q_INVOKABLE void clearDataset2OutlierCleaning();

    Q_INVOKABLE void generateMappings();
    Q_INVOKABLE void clearMappings();
    Q_INVOKABLE QVariantList getSuggestedMappings() const;

    Q_INVOKABLE bool analyzeColumns(
        const QString &sourceColumn,
        const QString &targetColumn
        );

    Q_INVOKABLE void clearAnalysis();
    Q_INVOKABLE bool compareDatasets(const QVariantList &mappings);
    Q_INVOKABLE void clearDatasetComparison();

    Q_INVOKABLE bool analyzeDataset1Eda(
        const QString &columnName
        );

    Q_INVOKABLE bool analyzeDataset2Eda(
        const QString &columnName
        );

    Q_INVOKABLE void clearDataset1Eda();
    Q_INVOKABLE void clearDataset2Eda();

    Q_INVOKABLE bool analyzeDataset1Correlation(
        const QString &firstColumnName,
        const QString &secondColumnName
        );

    Q_INVOKABLE bool analyzeDataset2Correlation(
        const QString &firstColumnName,
        const QString &secondColumnName
        );

    Q_INVOKABLE void clearDataset1Correlation();
    Q_INVOKABLE void clearDataset2Correlation();

    // =====================================================
    // VISUALIZATION
    // =====================================================

    Q_INVOKABLE QVariantMap createDataset1Histogram(
        const QString &columnName,
        int binCount = 10
        );

    Q_INVOKABLE QVariantMap createDataset2Histogram(
        const QString &columnName,
        int binCount = 10
        );

    Q_INVOKABLE QVariantMap createDataset1BoxPlot(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE QVariantMap createDataset2BoxPlot(
        const QString &columnName,
        double multiplier = 1.5
        );

    Q_INVOKABLE QVariantMap createDataset1TimeSeries(
        const QString &xColumnName,
        const QString &yColumnName
        );

    Q_INVOKABLE QVariantMap createDataset2TimeSeries(
        const QString &xColumnName,
        const QString &yColumnName
        );

    Q_INVOKABLE QVariantMap createDataset1Distribution(
        const QString &columnName,
        int binCount = 10
        );

    Q_INVOKABLE QVariantMap createDataset2Distribution(
        const QString &columnName,
        int binCount = 10
        );

    Q_INVOKABLE QVariantMap createDataset1CorrelationMatrix();
    Q_INVOKABLE QVariantMap createDataset2CorrelationMatrix();

    Q_INVOKABLE QVariantMap createDatasetComparisonChart(
        const QString &sourceColumnName,
        const QString &targetColumnName
        );

    // =====================================================
    // EXPORT
    // =====================================================

    Q_INVOKABLE bool exportDataset1ToCsv(const QString &filePath);
    Q_INVOKABLE bool exportDataset2ToCsv(const QString &filePath);

    Q_INVOKABLE bool exportDataset1ToJson(const QString &filePath);
    Q_INVOKABLE bool exportDataset2ToJson(const QString &filePath);

    Q_INVOKABLE bool exportDataset1ToXlsx(const QString &filePath);
    Q_INVOKABLE bool exportDataset2ToXlsx(const QString &filePath);

    Q_INVOKABLE bool removeDataset1Column(const QString &columnName);
    Q_INVOKABLE bool removeDataset2Column(const QString &columnName);

    Q_INVOKABLE QString saveChartImage(const QString &base64Data, const QString &chartTypePrefix);

    Q_INVOKABLE bool analyzeDataset1Quality();
    Q_INVOKABLE bool analyzeDataset2Quality();

    Q_INVOKABLE void clearDataset1Quality();
    Q_INVOKABLE void clearDataset2Quality();

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

    Q_INVOKABLE bool loadRawMetadata(const QString &filePath);
    Q_INVOKABLE bool loadRawDataFile(const QString &filePath);
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
    void datasetComparisonChanged();

    void dataset1EdaChanged();
    void dataset2EdaChanged();

    void dataset1CorrelationChanged();
    void dataset2CorrelationChanged();

    void dataset1QualityChanged();
    void dataset2QualityChanged();

    void dataset1OutlierChanged();
    void dataset2OutlierChanged();

    void dataset1OutlierCleaningChanged();
    void dataset2OutlierCleaningChanged();

    void rawMetadataChanged();
    void rawDataChanged();
    void rawParseChanged();

private:
    ExcelParser m_parser1;
    ExcelParser m_parser2;
    ExcelParser m_rawMetadataParser;

    RawDataParser m_rawDataParser;

    DataSet m_dataset1;
    DataSet m_dataset2;

    DataSet m_originalDataset1;
    DataSet m_originalDataset2;

    bool m_dataset1Modified = false;
    bool m_dataset2Modified = false;

    ColumnModel m_dataset1ColumnModel;
    ColumnModel m_dataset2ColumnModel;
    MappingModel m_mappingModel;
    ParameterModel m_parameterModel;

    ComparisonEngine m_comparisonEngine;
    AnalysisEngine m_analysisEngine;
    EdaEngine m_edaEngine;
    CleaningEngine m_cleaningEngine;
    VisualizationEngine m_visualizationEngine;
    ExportEngine m_exportEngine;

    QVariantMap m_analysisResult;
    bool m_analysisAvailable = false;

    QVariantMap m_datasetComparisonResult;
    bool m_datasetComparisonAvailable = false;

    QVariantMap m_dataset1EdaResult;
    QVariantMap m_dataset2EdaResult;
    bool m_dataset1EdaAvailable = false;
    bool m_dataset2EdaAvailable = false;

    QVariantMap m_dataset1CorrelationResult;
    QVariantMap m_dataset2CorrelationResult;
    bool m_dataset1CorrelationAvailable = false;
    bool m_dataset2CorrelationAvailable = false;

    QVariantMap m_dataset1QualityResult;
    QVariantMap m_dataset2QualityResult;
    bool m_dataset1QualityAvailable = false;
    bool m_dataset2QualityAvailable = false;

    QVariantMap m_dataset1OutlierResult;
    QVariantMap m_dataset2OutlierResult;
    bool m_dataset1OutlierAvailable = false;
    bool m_dataset2OutlierAvailable = false;

    QVariantMap m_dataset1OutlierCleaningResult;
    QVariantMap m_dataset2OutlierCleaningResult;

    QList<ParameterDefinition> m_rawParameterDefinitions;
    QByteArray m_rawData;

    QString m_rawMetadataFilePath;
    QString m_rawDataFilePath;
    QStringList m_rawWarnings;

    bool m_rawMetadataLoaded = false;
    bool m_rawDataLoaded = false;
    bool m_rawParseAvailable = false;

    QString m_lastError;

    QString normalizeFilePath(const QString &filePath) const;

    void tryGenerateMappings();

    void setError(const QString &message);
    void clearError();

    QVariantMap statisticsToVariantMap(
        const StatisticsResult &statistics
        ) const;



    QVariantMap histogramToVariantMap(
        const HistogramResult &result
        ) const;

    QVariantMap boxPlotToVariantMap(
        const BoxPlotResult &result
        ) const;

    QVariantMap timeSeriesToVariantMap(
        const TimeSeriesResult &result
        ) const;

    QVariantMap distributionToVariantMap(
        const DistributionResult &result
        ) const;

    QVariantMap correlationMatrixToVariantMap(
        const CorrelationMatrixResult &result
        ) const;

    QVariantMap comparisonChartToVariantMap(
        const ComparisonChartResult &result
        ) const;




};

#endif // APPCONTROLLER_H