#include "AppController.h"

#include <QUrl>

// =========================================================
// CONSTRUCTOR
// =========================================================

AppController::AppController(QObject *parent)
    : QObject(parent),
    m_dataset1ColumnModel(this),
    m_dataset2ColumnModel(this),
    m_mappingModel(this)
{
}


// =========================================================
// DATASET GETTERS
// =========================================================

QString AppController::dataset1Name() const
{
    return m_dataset1.name();
}

QString AppController::dataset2Name() const
{
    return m_dataset2.name();
}

int AppController::dataset1RowCount() const
{
    return m_dataset1.rowCount();
}

int AppController::dataset2RowCount() const
{
    return m_dataset2.rowCount();
}

int AppController::dataset1ColumnCount() const
{
    return m_dataset1.columnCount();
}

int AppController::dataset2ColumnCount() const
{
    return m_dataset2.columnCount();
}

QString AppController::dataset1SheetName() const
{
    return m_dataset1.sheetName();
}

QString AppController::dataset2SheetName() const
{
    return m_dataset2.sheetName();
}


// =========================================================
// ERROR
// =========================================================

QString AppController::lastError() const
{
    return m_lastError;
}


// =========================================================
// MODELS
// =========================================================

ColumnModel *AppController::dataset1ColumnModel()
{
    return &m_dataset1ColumnModel;
}

ColumnModel *AppController::dataset2ColumnModel()
{
    return &m_dataset2ColumnModel;
}

MappingModel *AppController::mappingModel()
{
    return &m_mappingModel;
}


// =========================================================
// ANALYSIS GETTERS
// =========================================================

QVariantMap AppController::analysisResult() const
{
    return m_analysisResult;
}

bool AppController::analysisAvailable() const
{
    return m_analysisAvailable;
}


// =========================================================
// DATASET 1 LOAD
// =========================================================

bool AppController::loadDataset1(
    const QString &filePath
    )
{
    m_lastError.clear();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (!m_parser1.loadFile(normalizedPath))
    {
        m_dataset1.clear();

        m_dataset1ColumnModel.clear();

        m_mappingModel.clear();

        clearAnalysis();

        m_lastError =
            m_parser1.lastError();

        emit errorChanged();
        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset1 =
        m_parser1.dataSet();

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    emit dataset1Changed();

    clearAnalysis();

    tryGenerateMappings();

    return true;
}


// =========================================================
// DATASET 2 LOAD
// =========================================================

bool AppController::loadDataset2(
    const QString &filePath
    )
{
    m_lastError.clear();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (!m_parser2.loadFile(normalizedPath))
    {
        m_dataset2.clear();

        m_dataset2ColumnModel.clear();

        m_mappingModel.clear();

        clearAnalysis();

        m_lastError =
            m_parser2.lastError();

        emit errorChanged();
        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset2 =
        m_parser2.dataSet();

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    emit dataset2Changed();

    clearAnalysis();

    tryGenerateMappings();

    return true;
}


// =========================================================
// GENERATE MAPPINGS
// =========================================================

void AppController::generateMappings()
{
    if (
        m_dataset1.isEmpty()
        ||
        m_dataset2.isEmpty()
        )
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

    m_mappingModel.setMappings(
        mappings
        );

    clearAnalysis();

    emit mappingsChanged();
}


// =========================================================
// CLEAR MAPPINGS
// =========================================================

void AppController::clearMappings()
{
    m_mappingModel.clear();

    clearAnalysis();

    emit mappingsChanged();
}


// =========================================================
// ANALYZE TWO COLUMNS
// =========================================================

bool AppController::analyzeColumns(
    const QString &sourceColumn,
    const QString &targetColumn
    )
{
    m_lastError.clear();

    clearAnalysis();

    // -----------------------------------------------------
    // Dataset kontrolü
    // -----------------------------------------------------

    if (m_dataset1.isEmpty())
    {
        m_lastError =
            "Dataset 1 is not loaded.";

        emit errorChanged();

        return false;
    }

    if (m_dataset2.isEmpty())
    {
        m_lastError =
            "Dataset 2 is not loaded.";

        emit errorChanged();

        return false;
    }

    // -----------------------------------------------------
    // Column name kontrolü
    // -----------------------------------------------------

    if (sourceColumn.trimmed().isEmpty())
    {
        m_lastError =
            "Dataset 1 column is empty.";

        emit errorChanged();

        return false;
    }

    if (targetColumn.trimmed().isEmpty())
    {
        m_lastError =
            "Dataset 2 column is empty.";

        emit errorChanged();

        return false;
    }

    // -----------------------------------------------------
    // AnalysisEngine çağrısı
    // -----------------------------------------------------

    const ColumnComparisonResult result =
        m_analysisEngine.compareColumns(
            m_dataset1,
            sourceColumn,

            m_dataset2,
            targetColumn
            );

    if (!result.success)
    {
        m_lastError =
            result.errorMessage;

        emit errorChanged();

        return false;
    }

    // =====================================================
    // RESULT MAP
    // =====================================================

    QVariantMap resultMap;

    resultMap.insert(
        "sourceColumn",
        result.sourceColumnName
        );

    resultMap.insert(
        "targetColumn",
        result.targetColumnName
        );

    // -----------------------------------------------------
    // Dataset 1 statistics
    // -----------------------------------------------------

    resultMap.insert(
        "sourceStatistics",
        statisticsToVariantMap(
            result.sourceStatistics
            )
        );

    // -----------------------------------------------------
    // Dataset 2 statistics
    // -----------------------------------------------------

    resultMap.insert(
        "targetStatistics",
        statisticsToVariantMap(
            result.targetStatistics
            )
        );

    // -----------------------------------------------------
    // Differences
    // -----------------------------------------------------

    resultMap.insert(
        "meanDifference",
        result.meanDifference
        );

    resultMap.insert(
        "medianDifference",
        result.medianDifference
        );

    resultMap.insert(
        "minimumDifference",
        result.minimumDifference
        );

    resultMap.insert(
        "maximumDifference",
        result.maximumDifference
        );

    resultMap.insert(
        "rangeDifference",
        result.rangeDifference
        );

    resultMap.insert(
        "varianceDifference",
        result.varianceDifference
        );

    resultMap.insert(
        "standardDeviationDifference",
        result.standardDeviationDifference
        );

    resultMap.insert(
        "q1Difference",
        result.q1Difference
        );

    resultMap.insert(
        "q3Difference",
        result.q3Difference
        );

    resultMap.insert(
        "iqrDifference",
        result.iqrDifference
        );

    m_analysisResult =
        resultMap;

    m_analysisAvailable =
        true;

    emit analysisResultChanged();

    return true;
}


// =========================================================
// CLEAR ANALYSIS
// =========================================================

void AppController::clearAnalysis()
{
    const bool hadAnalysis =
        m_analysisAvailable
        ||
        !m_analysisResult.isEmpty();

    m_analysisResult.clear();

    m_analysisAvailable =
        false;

    if (hadAnalysis)
    {
        emit analysisResultChanged();
    }
}


// =========================================================
// NORMALIZE FILE PATH
// =========================================================

QString AppController::normalizeFilePath(
    const QString &filePath
    ) const
{
    const QUrl url(filePath);

    if (url.isLocalFile())
    {
        return url.toLocalFile();
    }

    return filePath;
}


// =========================================================
// AUTO MAPPING
// =========================================================

void AppController::tryGenerateMappings()
{
    if (
        m_dataset1.isEmpty()
        ||
        m_dataset2.isEmpty()
        )
    {
        m_mappingModel.clear();

        emit mappingsChanged();

        return;
    }

    generateMappings();
}


// =========================================================
// STATISTICS -> QVARIANTMAP
// =========================================================

QVariantMap AppController::statisticsToVariantMap(
    const StatisticsResult &statistics
    ) const
{
    QVariantMap map;

    map.insert(
        "count",
        statistics.count
        );

    map.insert(
        "mean",
        statistics.mean
        );

    map.insert(
        "median",
        statistics.median
        );

    map.insert(
        "minimum",
        statistics.minimum
        );

    map.insert(
        "maximum",
        statistics.maximum
        );

    map.insert(
        "range",
        statistics.range
        );

    map.insert(
        "variance",
        statistics.variance
        );

    map.insert(
        "standardDeviation",
        statistics.standardDeviation
        );

    map.insert(
        "q1",
        statistics.q1
        );

    map.insert(
        "q3",
        statistics.q3
        );

    map.insert(
        "iqr",
        statistics.iqr
        );

    return map;
}