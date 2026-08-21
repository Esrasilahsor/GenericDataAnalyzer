#include "AppController.h"

#include "../raw/FileRawDataSource.h"

#include <QUrl>

AppController::AppController(QObject *parent)
    : QObject(parent),
    m_dataset1ColumnModel(this),
    m_dataset2ColumnModel(this),
    m_mappingModel(this),
    m_parameterModel(this)
{
}

// =========================================================
// GETTERS
// =========================================================

QString AppController::dataset1Name() const { return m_dataset1.name(); }
QString AppController::dataset2Name() const { return m_dataset2.name(); }

int AppController::dataset1RowCount() const { return m_dataset1.rowCount(); }
int AppController::dataset2RowCount() const { return m_dataset2.rowCount(); }

int AppController::dataset1ColumnCount() const { return m_dataset1.columnCount(); }
int AppController::dataset2ColumnCount() const { return m_dataset2.columnCount(); }

QString AppController::dataset1SheetName() const { return m_dataset1.sheetName(); }
QString AppController::dataset2SheetName() const { return m_dataset2.sheetName(); }

bool AppController::dataset1Modified() const { return m_dataset1Modified; }
bool AppController::dataset2Modified() const { return m_dataset2Modified; }

QString AppController::lastError() const { return m_lastError; }

ColumnModel *AppController::dataset1ColumnModel() { return &m_dataset1ColumnModel; }
ColumnModel *AppController::dataset2ColumnModel() { return &m_dataset2ColumnModel; }
MappingModel *AppController::mappingModel() { return &m_mappingModel; }
ParameterModel *AppController::parameterModel() { return &m_parameterModel; }

QVariantMap AppController::analysisResult() const { return m_analysisResult; }
bool AppController::analysisAvailable() const { return m_analysisAvailable; }

QVariantMap AppController::dataset1EdaResult() const { return m_dataset1EdaResult; }
QVariantMap AppController::dataset2EdaResult() const { return m_dataset2EdaResult; }

bool AppController::dataset1EdaAvailable() const { return m_dataset1EdaAvailable; }
bool AppController::dataset2EdaAvailable() const { return m_dataset2EdaAvailable; }

QVariantMap AppController::dataset1CorrelationResult() const { return m_dataset1CorrelationResult; }
QVariantMap AppController::dataset2CorrelationResult() const { return m_dataset2CorrelationResult; }

bool AppController::dataset1CorrelationAvailable() const { return m_dataset1CorrelationAvailable; }
bool AppController::dataset2CorrelationAvailable() const { return m_dataset2CorrelationAvailable; }

QVariantMap AppController::dataset1QualityResult() const { return m_dataset1QualityResult; }
QVariantMap AppController::dataset2QualityResult() const { return m_dataset2QualityResult; }

bool AppController::dataset1QualityAvailable() const { return m_dataset1QualityAvailable; }
bool AppController::dataset2QualityAvailable() const { return m_dataset2QualityAvailable; }

QVariantMap AppController::dataset1OutlierResult() const { return m_dataset1OutlierResult; }
QVariantMap AppController::dataset2OutlierResult() const { return m_dataset2OutlierResult; }

bool AppController::dataset1OutlierAvailable() const { return m_dataset1OutlierAvailable; }
bool AppController::dataset2OutlierAvailable() const { return m_dataset2OutlierAvailable; }

QVariantMap AppController::dataset1OutlierCleaningResult() const
{
    return m_dataset1OutlierCleaningResult;
}

QVariantMap AppController::dataset2OutlierCleaningResult() const
{
    return m_dataset2OutlierCleaningResult;
}

bool AppController::rawMetadataLoaded() const { return m_rawMetadataLoaded; }
bool AppController::rawDataLoaded() const { return m_rawDataLoaded; }
bool AppController::rawParseAvailable() const { return m_rawParseAvailable; }

int AppController::rawParameterDefinitionCount() const
{
    return m_rawParameterDefinitions.size();
}

int AppController::rawDataByteCount() const
{
    return m_rawData.size();
}

QString AppController::rawMetadataFilePath() const
{
    return m_rawMetadataFilePath;
}

QString AppController::rawDataFilePath() const
{
    return m_rawDataFilePath;
}

QStringList AppController::rawWarnings() const
{
    return m_rawWarnings;
}

// =========================================================
// DATASET LOAD
// =========================================================

bool AppController::loadDataset1(const QString &filePath)
{
    clearError();

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset1.clear();
        m_originalDataset1.clear();
        m_dataset1Modified = false;
        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(QStringLiteral("Dataset 1 file path is empty."));

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser1.loadFile(normalizedPath))
    {
        m_dataset1.clear();
        m_originalDataset1.clear();
        m_dataset1Modified = false;
        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(m_parser1.lastError());

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset1 = m_parser1.dataSet();
    m_originalDataset1 = m_dataset1;
    m_dataset1Modified = false;

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    emit dataset1Changed();

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

bool AppController::loadDataset2(const QString &filePath)
{
    clearError();

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset2.clear();
        m_originalDataset2.clear();
        m_dataset2Modified = false;
        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(QStringLiteral("Dataset 2 file path is empty."));

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser2.loadFile(normalizedPath))
    {
        m_dataset2.clear();
        m_originalDataset2.clear();
        m_dataset2Modified = false;
        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(m_parser2.lastError());

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset2 = m_parser2.dataSet();
    m_originalDataset2 = m_dataset2;
    m_dataset2Modified = false;

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    emit dataset2Changed();

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

// =========================================================
// RESTORE ORIGINAL
// =========================================================

bool AppController::restoreDataset1()
{
    clearError();

    if (m_originalDataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 original data is not available."));
        return false;
    }

    m_dataset1 = m_originalDataset1;
    m_dataset1Modified = false;

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::restoreDataset2()
{
    clearError();

    if (m_originalDataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 original data is not available."));
        return false;
    }

    m_dataset2 = m_originalDataset2;
    m_dataset2Modified = false;

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// CLEANING
// =========================================================

bool AppController::removeDataset1Duplicates()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeDuplicateRows(
            m_dataset1
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2Duplicates()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeDuplicateRows(
            m_dataset2
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset1MissingRows()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeRowsWithMissingValues(
            m_dataset1
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2MissingRows()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeRowsWithMissingValues(
            m_dataset2
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMean(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMean(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMedian(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMedian(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMode(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMode(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset1Outliers(
    const QString &columnName,
    double multiplier
    )
{
    return applyDataset1OutlierAction(
        columnName,
        QStringLiteral("IQR"),
        QStringLiteral("Remove"),
        multiplier
        );
}

bool AppController::removeDataset2Outliers(
    const QString &columnName,
    double multiplier
    )
{
    return applyDataset2OutlierAction(
        columnName,
        QStringLiteral("IQR"),
        QStringLiteral("Remove"),
        multiplier
        );
}

bool AppController::applyDataset1OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    clearError();
    clearDataset1OutlierCleaning();

    const CleaningResult result =
        m_cleaningEngine.applyOutlierAction(
            m_dataset1,
            columnName,
            method,
            action,
            parameter
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1OutlierCleaningResult =
        result.details;

    if (result.modified)
    {
        m_dataset1Modified = true;

        m_dataset1ColumnModel.setColumns(
            m_dataset1.columns()
            );

        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1Eda();
        clearDataset1Correlation();
        clearAnalysis();

        emit dataset1Changed();

        tryGenerateMappings();
    }

    emit dataset1OutlierCleaningChanged();

    return true;
}

bool AppController::applyDataset2OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    clearError();
    clearDataset2OutlierCleaning();

    const CleaningResult result =
        m_cleaningEngine.applyOutlierAction(
            m_dataset2,
            columnName,
            method,
            action,
            parameter
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2OutlierCleaningResult =
        result.details;

    if (result.modified)
    {
        m_dataset2Modified = true;

        m_dataset2ColumnModel.setColumns(
            m_dataset2.columns()
            );

        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2Eda();
        clearDataset2Correlation();
        clearAnalysis();

        emit dataset2Changed();

        tryGenerateMappings();
    }

    emit dataset2OutlierCleaningChanged();

    return true;
}

void AppController::clearDataset1OutlierCleaning()
{
    if (m_dataset1OutlierCleaningResult.isEmpty())
        return;

    m_dataset1OutlierCleaningResult.clear();

    emit dataset1OutlierCleaningChanged();
}

void AppController::clearDataset2OutlierCleaning()
{
    if (m_dataset2OutlierCleaningResult.isEmpty())
        return;

    m_dataset2OutlierCleaningResult.clear();

    emit dataset2OutlierCleaningChanged();
}

// =========================================================
// MAPPING
// =========================================================

void AppController::generateMappings()
{
    if (m_dataset1.isEmpty() || m_dataset2.isEmpty())
    {
        m_mappingModel.clear();
        clearAnalysis();
        emit mappingsChanged();
        return;
    }

    const QVector<ColumnMapping> mappings =
        m_comparisonEngine.suggestMappings(
            m_dataset1,
            m_dataset2
            );

    m_mappingModel.setMappings(mappings);

    clearAnalysis();
    emit mappingsChanged();
}

void AppController::clearMappings()
{
    m_mappingModel.clear();
    clearAnalysis();
    emit mappingsChanged();
}

// =========================================================
// COMPARISON
// =========================================================

bool AppController::analyzeColumns(
    const QString &sourceColumn,
    const QString &targetColumn
    )
{
    clearError();
    clearAnalysis();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnComparisonResult result =
        m_analysisEngine.compareColumns(
            m_dataset1,
            sourceColumn,
            m_dataset2,
            targetColumn
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    QVariantMap resultMap;

    resultMap.insert(QStringLiteral("sourceColumn"), result.sourceColumnName);
    resultMap.insert(QStringLiteral("targetColumn"), result.targetColumnName);

    resultMap.insert(
        QStringLiteral("sourceStatistics"),
        statisticsToVariantMap(result.sourceStatistics)
        );

    resultMap.insert(
        QStringLiteral("targetStatistics"),
        statisticsToVariantMap(result.targetStatistics)
        );

    resultMap.insert(QStringLiteral("meanDifference"), result.meanDifference);
    resultMap.insert(QStringLiteral("medianDifference"), result.medianDifference);
    resultMap.insert(QStringLiteral("minimumDifference"), result.minimumDifference);
    resultMap.insert(QStringLiteral("maximumDifference"), result.maximumDifference);
    resultMap.insert(QStringLiteral("rangeDifference"), result.rangeDifference);
    resultMap.insert(QStringLiteral("varianceDifference"), result.varianceDifference);

    resultMap.insert(
        QStringLiteral("standardDeviationDifference"),
        result.standardDeviationDifference
        );

    resultMap.insert(QStringLiteral("q1Difference"), result.q1Difference);
    resultMap.insert(QStringLiteral("q3Difference"), result.q3Difference);
    resultMap.insert(QStringLiteral("iqrDifference"), result.iqrDifference);

    m_analysisResult = resultMap;
    m_analysisAvailable = true;

    emit analysisResultChanged();

    return true;
}

void AppController::clearAnalysis()
{
    const bool hadAnalysis =
        m_analysisAvailable ||
        !m_analysisResult.isEmpty();

    m_analysisResult.clear();
    m_analysisAvailable = false;

    if (hadAnalysis)
        emit analysisResultChanged();
}

// =========================================================
// EDA SUMMARY
// =========================================================

bool AppController::analyzeDataset1Eda(
    const QString &columnName
    )
{
    clearError();
    clearDataset1Eda();

    const EdaOperationResult result =
        m_edaEngine.analyzeSummary(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1EdaResult = result.data;
    m_dataset1EdaAvailable = true;

    emit dataset1EdaChanged();

    return true;
}

bool AppController::analyzeDataset2Eda(
    const QString &columnName
    )
{
    clearError();
    clearDataset2Eda();

    const EdaOperationResult result =
        m_edaEngine.analyzeSummary(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2EdaResult = result.data;
    m_dataset2EdaAvailable = true;

    emit dataset2EdaChanged();

    return true;
}

void AppController::clearDataset1Eda()
{
    const bool hadResult =
        m_dataset1EdaAvailable ||
        !m_dataset1EdaResult.isEmpty();

    m_dataset1EdaResult.clear();
    m_dataset1EdaAvailable = false;

    if (hadResult)
        emit dataset1EdaChanged();
}

void AppController::clearDataset2Eda()
{
    const bool hadResult =
        m_dataset2EdaAvailable ||
        !m_dataset2EdaResult.isEmpty();

    m_dataset2EdaResult.clear();
    m_dataset2EdaAvailable = false;

    if (hadResult)
        emit dataset2EdaChanged();
}

// =========================================================
// CORRELATION ANALYSIS
// =========================================================

bool AppController::analyzeDataset1Correlation(
    const QString &firstColumnName,
    const QString &secondColumnName
    )
{
    clearError();
    clearDataset1Correlation();

    const EdaOperationResult result =
        m_edaEngine.analyzeCorrelation(
            m_dataset1,
            firstColumnName,
            secondColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1CorrelationResult = result.data;
    m_dataset1CorrelationAvailable = true;

    emit dataset1CorrelationChanged();

    return true;
}

bool AppController::analyzeDataset2Correlation(
    const QString &firstColumnName,
    const QString &secondColumnName
    )
{
    clearError();
    clearDataset2Correlation();

    const EdaOperationResult result =
        m_edaEngine.analyzeCorrelation(
            m_dataset2,
            firstColumnName,
            secondColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2CorrelationResult = result.data;
    m_dataset2CorrelationAvailable = true;

    emit dataset2CorrelationChanged();

    return true;
}

void AppController::clearDataset1Correlation()
{
    const bool hadResult =
        m_dataset1CorrelationAvailable ||
        !m_dataset1CorrelationResult.isEmpty();

    m_dataset1CorrelationResult.clear();
    m_dataset1CorrelationAvailable = false;

    if (hadResult)
        emit dataset1CorrelationChanged();
}

void AppController::clearDataset2Correlation()
{
    const bool hadResult =
        m_dataset2CorrelationAvailable ||
        !m_dataset2CorrelationResult.isEmpty();

    m_dataset2CorrelationResult.clear();
    m_dataset2CorrelationAvailable = false;

    if (hadResult)
        emit dataset2CorrelationChanged();
}

// =========================================================
// VISUALIZATION
// =========================================================

QVariantMap AppController::createDataset1Histogram(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const HistogramResult result =
        m_visualizationEngine.createHistogram(
            m_dataset1,
            columnName,
            binCount
            );

    if (!result.success)
        setError(result.errorMessage);

    return histogramToVariantMap(result);
}

QVariantMap AppController::createDataset2Histogram(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const HistogramResult result =
        m_visualizationEngine.createHistogram(
            m_dataset2,
            columnName,
            binCount
            );

    if (!result.success)
        setError(result.errorMessage);

    return histogramToVariantMap(result);
}

QVariantMap AppController::createDataset1BoxPlot(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    const BoxPlotResult result =
        m_visualizationEngine.createBoxPlot(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
        setError(result.errorMessage);

    return boxPlotToVariantMap(result);
}

QVariantMap AppController::createDataset2BoxPlot(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    const BoxPlotResult result =
        m_visualizationEngine.createBoxPlot(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
        setError(result.errorMessage);

    return boxPlotToVariantMap(result);
}

QVariantMap AppController::createDataset1TimeSeries(
    const QString &xColumnName,
    const QString &yColumnName
    )
{
    clearError();

    const TimeSeriesResult result =
        m_visualizationEngine.createTimeSeries(
            m_dataset1,
            xColumnName,
            yColumnName
            );

    if (!result.success)
        setError(result.errorMessage);

    return timeSeriesToVariantMap(result);
}

QVariantMap AppController::createDataset2TimeSeries(
    const QString &xColumnName,
    const QString &yColumnName
    )
{
    clearError();

    const TimeSeriesResult result =
        m_visualizationEngine.createTimeSeries(
            m_dataset2,
            xColumnName,
            yColumnName
            );

    if (!result.success)
        setError(result.errorMessage);

    return timeSeriesToVariantMap(result);
}

QVariantMap AppController::createDataset1Distribution(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const DistributionResult result =
        m_visualizationEngine.createDistribution(
            m_dataset1,
            columnName,
            binCount
            );

    if (!result.success)
        setError(result.errorMessage);

    return distributionToVariantMap(result);
}

QVariantMap AppController::createDataset2Distribution(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const DistributionResult result =
        m_visualizationEngine.createDistribution(
            m_dataset2,
            columnName,
            binCount
            );

    if (!result.success)
        setError(result.errorMessage);

    return distributionToVariantMap(result);
}

QVariantMap AppController::createDataset1CorrelationMatrix()
{
    clearError();

    const CorrelationMatrixResult result =
        m_visualizationEngine.createCorrelationMatrix(
            m_dataset1
            );

    if (!result.success)
        setError(result.errorMessage);

    return correlationMatrixToVariantMap(result);
}

QVariantMap AppController::createDataset2CorrelationMatrix()
{
    clearError();

    const CorrelationMatrixResult result =
        m_visualizationEngine.createCorrelationMatrix(
            m_dataset2
            );

    if (!result.success)
        setError(result.errorMessage);

    return correlationMatrixToVariantMap(result);
}

QVariantMap AppController::createDatasetComparisonChart(
    const QString &sourceColumnName,
    const QString &targetColumnName
    )
{
    clearError();

    const ComparisonChartResult result =
        m_visualizationEngine.createComparisonChart(
            m_dataset1,
            sourceColumnName,
            m_dataset2,
            targetColumnName
            );

    if (!result.success)
        setError(result.errorMessage);

    return comparisonChartToVariantMap(result);
}

// =========================================================
// EXPORT
// =========================================================

bool AppController::exportDataset1ToCsv(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToCsv(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

bool AppController::exportDataset2ToCsv(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToCsv(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

bool AppController::exportDataset1ToJson(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToJson(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

bool AppController::exportDataset2ToJson(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToJson(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

bool AppController::exportDataset1ToXlsx(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToXlsx(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

bool AppController::exportDataset2ToXlsx(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);

    const ExportResult result =
        m_exportEngine.exportDataSetToXlsx(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    return true;
}

// =========================================================
// QUALITY
// =========================================================

bool AppController::analyzeDataset1Quality()
{
    clearError();
    clearDataset1Quality();

    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset1
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1QualityResult = result.data;
    m_dataset1QualityAvailable = true;

    emit dataset1QualityChanged();

    return true;
}

bool AppController::analyzeDataset2Quality()
{
    clearError();
    clearDataset2Quality();

    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset2
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2QualityResult = result.data;
    m_dataset2QualityAvailable = true;

    emit dataset2QualityChanged();

    return true;
}

void AppController::clearDataset1Quality()
{
    const bool hadResult =
        m_dataset1QualityAvailable ||
        !m_dataset1QualityResult.isEmpty();

    m_dataset1QualityResult.clear();
    m_dataset1QualityAvailable = false;

    if (hadResult)
        emit dataset1QualityChanged();
}

void AppController::clearDataset2Quality()
{
    const bool hadResult =
        m_dataset2QualityAvailable ||
        !m_dataset2QualityResult.isEmpty();

    m_dataset2QualityResult.clear();
    m_dataset2QualityAvailable = false;

    if (hadResult)
        emit dataset2QualityChanged();
}

// =========================================================
// IQR OUTLIER ANALYSIS
// =========================================================

bool AppController::analyzeDataset1Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();
    clearDataset1Outliers();

    const EdaOperationResult result =
        m_edaEngine.analyzeOutliers(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1OutlierResult = result.data;
    m_dataset1OutlierAvailable = true;

    emit dataset1OutlierChanged();

    return true;
}

bool AppController::analyzeDataset2Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();
    clearDataset2Outliers();

    const EdaOperationResult result =
        m_edaEngine.analyzeOutliers(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2OutlierResult = result.data;
    m_dataset2OutlierAvailable = true;

    emit dataset2OutlierChanged();

    return true;
}

void AppController::clearDataset1Outliers()
{
    const bool hadResult =
        m_dataset1OutlierAvailable ||
        !m_dataset1OutlierResult.isEmpty();

    m_dataset1OutlierResult.clear();
    m_dataset1OutlierAvailable = false;

    if (hadResult)
        emit dataset1OutlierChanged();
}

void AppController::clearDataset2Outliers()
{
    const bool hadResult =
        m_dataset2OutlierAvailable ||
        !m_dataset2OutlierResult.isEmpty();

    m_dataset2OutlierResult.clear();
    m_dataset2OutlierAvailable = false;

    if (hadResult)
        emit dataset2OutlierChanged();
}

// =========================================================
// RAW DATA
// =========================================================

bool AppController::loadRawMetadata(const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawParameterDefinitions.clear();
        m_rawMetadataLoaded = false;
        m_rawMetadataFilePath.clear();
        m_rawWarnings.clear();

        clearRawParse();

        setError(QStringLiteral("Raw metadata file path is empty."));
        emit rawMetadataChanged();

        return false;
    }

    QStringList errors;
    QStringList warnings;

    const QList<ParameterDefinition> definitions =
        m_rawMetadataParser.loadParameterDefinitions(
            normalizedPath,
            &errors,
            &warnings
            );

    if (!errors.isEmpty() || definitions.isEmpty())
    {
        m_rawParameterDefinitions.clear();
        m_rawMetadataLoaded = false;
        m_rawMetadataFilePath.clear();
        m_rawWarnings = warnings;

        clearRawParse();

        if (!errors.isEmpty())
            setError(errors.join(QStringLiteral("\n")));
        else
            setError(QStringLiteral("No valid raw parameter definitions were found."));

        emit rawMetadataChanged();
        return false;
    }

    m_rawParameterDefinitions = definitions;
    m_rawWarnings = warnings;
    m_rawMetadataFilePath = normalizedPath;
    m_rawMetadataLoaded = true;

    clearRawParse();
    emit rawMetadataChanged();

    return true;
}

bool AppController::loadRawDataFile(const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawData.clear();
        m_rawDataLoaded = false;
        m_rawDataFilePath.clear();

        clearRawParse();

        setError(QStringLiteral("Raw data file path is empty."));
        emit rawDataChanged();

        return false;
    }

    FileRawDataSource source(normalizedPath);

    const RawDataSourceResult result =
        source.read();

    if (!result.success)
    {
        m_rawData.clear();
        m_rawDataLoaded = false;
        m_rawDataFilePath.clear();

        clearRawParse();

        setError(result.errorMessage);
        emit rawDataChanged();

        return false;
    }

    m_rawData = result.data;
    m_rawDataFilePath = normalizedPath;
    m_rawDataLoaded = true;

    clearRawParse();
    emit rawDataChanged();

    return true;
}

bool AppController::parseRawData()
{
    clearError();
    clearRawParse();

    if (!m_rawMetadataLoaded ||
        m_rawParameterDefinitions.isEmpty())
    {
        setError(QStringLiteral("Raw metadata is not loaded."));
        return false;
    }

    if (!m_rawDataLoaded ||
        m_rawData.isEmpty())
    {
        setError(QStringLiteral("Raw data is not loaded."));
        return false;
    }

    const QList<ParsedParameter> parsedParameters =
        m_rawDataParser.parse(
            m_rawData,
            m_rawParameterDefinitions
            );

    if (parsedParameters.isEmpty())
    {
        setError(QStringLiteral("Raw data parser produced no results."));
        return false;
    }

    m_parameterModel.setParameters(parsedParameters);

    bool hasSuccessfulParameter = false;
    bool hasErrorParameter = false;

    for (const ParsedParameter &parameter : parsedParameters)
    {
        if (parameter.parsedSuccessfully())
            hasSuccessfulParameter = true;

        if (parameter.hasError())
            hasErrorParameter = true;
    }

    if (!hasSuccessfulParameter)
    {
        m_parameterModel.clear();
        m_rawParseAvailable = false;

        setError(
            QStringLiteral(
                "None of the raw parameters could be parsed successfully."
                )
            );

        emit rawParseChanged();
        return false;
    }

    m_rawParseAvailable = true;
    emit rawParseChanged();

    if (hasErrorParameter)
    {
        setError(
            QStringLiteral(
                "Raw data was parsed, but one or more parameters contain errors."
                )
            );
    }

    return true;
}

void AppController::clearRawMetadata()
{
    const bool hadData =
        m_rawMetadataLoaded ||
        !m_rawParameterDefinitions.isEmpty() ||
        !m_rawMetadataFilePath.isEmpty() ||
        !m_rawWarnings.isEmpty();

    m_rawParameterDefinitions.clear();
    m_rawMetadataFilePath.clear();
    m_rawWarnings.clear();
    m_rawMetadataLoaded = false;

    clearRawParse();

    if (hadData)
        emit rawMetadataChanged();
}

void AppController::clearRawData()
{
    const bool hadData =
        m_rawDataLoaded ||
        !m_rawData.isEmpty() ||
        !m_rawDataFilePath.isEmpty();

    m_rawData.clear();
    m_rawDataFilePath.clear();
    m_rawDataLoaded = false;

    clearRawParse();

    if (hadData)
        emit rawDataChanged();
}

void AppController::clearRawParse()
{
    const bool hadResults =
        m_rawParseAvailable ||
        !m_parameterModel.isEmpty();

    m_parameterModel.clear();
    m_rawParseAvailable = false;

    if (hadResults)
        emit rawParseChanged();
}

// =========================================================
// HELPERS
// =========================================================

QVariantMap AppController::histogramToVariantMap(
    const HistogramResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("binCount"), result.binCount);
    map.insert(QStringLiteral("minimum"), result.minimum);
    map.insert(QStringLiteral("maximum"), result.maximum);
    map.insert(QStringLiteral("binWidth"), result.binWidth);

    QVariantList lowerBounds;
    QVariantList upperBounds;
    QVariantList frequencies;

    for (double value : result.binLowerBounds)
        lowerBounds.append(value);

    for (double value : result.binUpperBounds)
        upperBounds.append(value);

    for (int value : result.frequencies)
        frequencies.append(value);

    map.insert(QStringLiteral("binLowerBounds"), lowerBounds);
    map.insert(QStringLiteral("binUpperBounds"), upperBounds);
    map.insert(QStringLiteral("frequencies"), frequencies);

    return map;
}

QVariantMap AppController::boxPlotToVariantMap(
    const BoxPlotResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("minimum"), result.minimum);
    map.insert(QStringLiteral("q1"), result.q1);
    map.insert(QStringLiteral("median"), result.median);
    map.insert(QStringLiteral("q3"), result.q3);
    map.insert(QStringLiteral("maximum"), result.maximum);
    map.insert(QStringLiteral("iqr"), result.iqr);
    map.insert(QStringLiteral("lowerBound"), result.lowerBound);
    map.insert(QStringLiteral("upperBound"), result.upperBound);
    map.insert(QStringLiteral("lowerWhisker"), result.lowerWhisker);
    map.insert(QStringLiteral("upperWhisker"), result.upperWhisker);
    map.insert(QStringLiteral("outlierCount"), result.outlierCount);

    QVariantList outliers;

    for (double value : result.outlierValues)
        outliers.append(value);

    map.insert(QStringLiteral("outlierValues"), outliers);

    return map;
}

QVariantMap AppController::timeSeriesToVariantMap(
    const TimeSeriesResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("xColumnName"), result.xColumnName);
    map.insert(QStringLiteral("yColumnName"), result.yColumnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("pointCount"), result.pointCount);

    QVariantList xValues;
    QVariantList yValues;

    for (double value : result.xValues)
        xValues.append(value);

    for (double value : result.yValues)
        yValues.append(value);

    map.insert(QStringLiteral("xValues"), xValues);
    map.insert(QStringLiteral("yValues"), yValues);

    return map;
}

QVariantMap AppController::distributionToVariantMap(
    const DistributionResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("binCount"), result.binCount);

    QVariantList centers;
    QVariantList relativeFrequencies;

    for (double value : result.centers)
        centers.append(value);

    for (double value : result.relativeFrequencies)
        relativeFrequencies.append(value);

    map.insert(QStringLiteral("centers"), centers);
    map.insert(QStringLiteral("relativeFrequencies"), relativeFrequencies);

    return map;
}

QVariantMap AppController::correlationMatrixToVariantMap(
    const CorrelationMatrixResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("columnCount"), result.columnCount);
    map.insert(QStringLiteral("columnNames"), result.columnNames);

    QVariantList values;

    for (double value : result.values)
        values.append(value);

    map.insert(QStringLiteral("values"), values);

    return map;
}

QVariantMap AppController::comparisonChartToVariantMap(
    const ComparisonChartResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("sourceColumnName"), result.sourceColumnName);
    map.insert(QStringLiteral("targetColumnName"), result.targetColumnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("pointCount"), result.pointCount);

    QVariantList indexes;
    QVariantList sourceValues;
    QVariantList targetValues;

    for (double value : result.indexes)
        indexes.append(value);

    for (double value : result.sourceValues)
        sourceValues.append(value);

    for (double value : result.targetValues)
        targetValues.append(value);

    map.insert(QStringLiteral("indexes"), indexes);
    map.insert(QStringLiteral("sourceValues"), sourceValues);
    map.insert(QStringLiteral("targetValues"), targetValues);

    return map;
}

QString AppController::normalizeFilePath(
    const QString &filePath
    ) const
{
    if (filePath.trimmed().isEmpty())
        return QString();

    const QUrl url(filePath);

    if (url.isLocalFile())
        return url.toLocalFile();

    return filePath;
}

void AppController::tryGenerateMappings()
{
    if (m_dataset1.isEmpty() ||
        m_dataset2.isEmpty())
    {
        m_mappingModel.clear();
        emit mappingsChanged();
        return;
    }

    generateMappings();
}

void AppController::setError(
    const QString &message
    )
{
    if (m_lastError == message)
        return;

    m_lastError = message;
    emit errorChanged();
}

void AppController::clearError()
{
    if (m_lastError.isEmpty())
        return;

    m_lastError.clear();
    emit errorChanged();
}

QVariantMap AppController::statisticsToVariantMap(
    const StatisticsResult &statistics
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("count"), statistics.count);
    map.insert(QStringLiteral("mean"), statistics.mean);
    map.insert(QStringLiteral("median"), statistics.median);
    map.insert(QStringLiteral("minimum"), statistics.minimum);
    map.insert(QStringLiteral("maximum"), statistics.maximum);
    map.insert(QStringLiteral("range"), statistics.range);
    map.insert(QStringLiteral("variance"), statistics.variance);

    map.insert(
        QStringLiteral("standardDeviation"),
        statistics.standardDeviation
        );

    map.insert(QStringLiteral("q1"), statistics.q1);
    map.insert(QStringLiteral("q3"), statistics.q3);
    map.insert(QStringLiteral("iqr"), statistics.iqr);

    return map;
}
