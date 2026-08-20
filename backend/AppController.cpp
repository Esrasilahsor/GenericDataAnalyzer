#include "AppController.h"

#include "../raw/FileRawDataSource.h"

#include <QUrl>
#include <QMap>

#include <algorithm>
#include <cmath>

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
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// DUPLICATE CLEANING
// =========================================================

bool AppController::removeDataset1Duplicates()
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QVector<int> rows =
        m_analysisEngine.findDuplicateRowIndexes(m_dataset1);

    if (rows.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 does not contain duplicate rows."));
        return false;
    }

    if (!m_dataset1.removeRows(rows))
    {
        setError(QStringLiteral("Dataset 1 duplicate rows could not be removed."));
        return false;
    }

    m_dataset1Modified = true;
    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2Duplicates()
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QVector<int> rows =
        m_analysisEngine.findDuplicateRowIndexes(m_dataset2);

    if (rows.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 does not contain duplicate rows."));
        return false;
    }

    if (!m_dataset2.removeRows(rows))
    {
        setError(QStringLiteral("Dataset 2 duplicate rows could not be removed."));
        return false;
    }

    m_dataset2Modified = true;
    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// MISSING ROW CLEANING
// =========================================================

bool AppController::removeDataset1MissingRows()
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QVector<int> rows =
        m_analysisEngine.findRowsWithMissingValues(m_dataset1);

    if (rows.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 does not contain rows with missing values."));
        return false;
    }

    if (!m_dataset1.removeRows(rows))
    {
        setError(QStringLiteral("Dataset 1 rows with missing values could not be removed."));
        return false;
    }

    m_dataset1Modified = true;
    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2MissingRows()
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QVector<int> rows =
        m_analysisEngine.findRowsWithMissingValues(m_dataset2);

    if (rows.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 does not contain rows with missing values."));
        return false;
    }

    if (!m_dataset2.removeRows(rows))
    {
        setError(QStringLiteral("Dataset 2 rows with missing values could not be removed."));
        return false;
    }

    m_dataset2Modified = true;
    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// MISSING FILL WRAPPERS
// =========================================================

bool AppController::fillDataset1MissingWithMean(const QString &columnName)
{
    return fillMissingWithMean(
        m_dataset1,
        m_dataset1ColumnModel,
        columnName,
        true
        );
}

bool AppController::fillDataset2MissingWithMean(const QString &columnName)
{
    return fillMissingWithMean(
        m_dataset2,
        m_dataset2ColumnModel,
        columnName,
        false
        );
}

bool AppController::fillDataset1MissingWithMedian(const QString &columnName)
{
    return fillMissingWithMedian(
        m_dataset1,
        m_dataset1ColumnModel,
        columnName,
        true
        );
}

bool AppController::fillDataset2MissingWithMedian(const QString &columnName)
{
    return fillMissingWithMedian(
        m_dataset2,
        m_dataset2ColumnModel,
        columnName,
        false
        );
}

bool AppController::fillDataset1MissingWithMode(const QString &columnName)
{
    return fillMissingWithMode(
        m_dataset1,
        m_dataset1ColumnModel,
        columnName,
        true
        );
}

bool AppController::fillDataset2MissingWithMode(const QString &columnName)
{
    return fillMissingWithMode(
        m_dataset2,
        m_dataset2ColumnModel,
        columnName,
        false
        );
}

bool AppController::fillMissingWithMean(
    DataSet &dataSet,
    ColumnModel &columnModel,
    const QString &columnName,
    bool dataset1
    )
{
    clearError();

    if (dataSet.isEmpty())
    {
        setError(dataset1
                     ? QStringLiteral("Dataset 1 is not loaded.")
                     : QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnInfo *column = dataSet.findColumn(columnName);

    if (!column)
    {
        setError(QStringLiteral("Selected column was not found."));
        return false;
    }

    if (!column->isNumeric())
    {
        setError(QStringLiteral("Mean filling can only be applied to numeric columns."));
        return false;
    }

    QVector<QVariant> values = column->values();

    double total = 0.0;
    int validCount = 0;
    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;
        const double number = value.toDouble(&ok);

        if (ok && std::isfinite(number))
        {
            total += number;
            ++validCount;
        }
    }

    if (missingCount == 0)
    {
        setError(QStringLiteral("Selected column does not contain missing values."));
        return false;
    }

    if (validCount == 0)
    {
        setError(QStringLiteral("Mean cannot be calculated."));
        return false;
    }

    const double mean = total / static_cast<double>(validCount);

    for (int i = 0; i < values.size(); ++i)
    {
        const QVariant &value = values.at(i);

        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
            values[i] = mean;
    }

    if (!dataSet.setColumnValues(columnName, values))
    {
        setError(QStringLiteral("Column could not be updated."));
        return false;
    }

    if (dataset1)
        m_dataset1Modified = true;
    else
        m_dataset2Modified = true;

    columnModel.setColumns(dataSet.columns());

    if (dataset1)
    {
        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1OutlierCleaning();
        emit dataset1Changed();
    }
    else
    {
        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2OutlierCleaning();
        emit dataset2Changed();
    }

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

bool AppController::fillMissingWithMedian(
    DataSet &dataSet,
    ColumnModel &columnModel,
    const QString &columnName,
    bool dataset1
    )
{
    clearError();

    if (dataSet.isEmpty())
    {
        setError(dataset1
                     ? QStringLiteral("Dataset 1 is not loaded.")
                     : QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnInfo *column = dataSet.findColumn(columnName);

    if (!column)
    {
        setError(QStringLiteral("Selected column was not found."));
        return false;
    }

    if (!column->isNumeric())
    {
        setError(QStringLiteral("Median filling can only be applied to numeric columns."));
        return false;
    }

    QVector<QVariant> values = column->values();
    QVector<double> numericValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;
        const double number = value.toDouble(&ok);

        if (ok && std::isfinite(number))
            numericValues.append(number);
    }

    if (missingCount == 0)
    {
        setError(QStringLiteral("Selected column does not contain missing values."));
        return false;
    }

    if (numericValues.isEmpty())
    {
        setError(QStringLiteral("Median cannot be calculated."));
        return false;
    }

    std::sort(numericValues.begin(), numericValues.end());

    const int size = numericValues.size();
    const int middle = size / 2;

    const double median =
        (size % 2 == 0)
            ? (numericValues[middle - 1] + numericValues[middle]) / 2.0
            : numericValues[middle];

    for (int i = 0; i < values.size(); ++i)
    {
        const QVariant &value = values.at(i);

        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
            values[i] = median;
    }

    if (!dataSet.setColumnValues(columnName, values))
    {
        setError(QStringLiteral("Column could not be updated."));
        return false;
    }

    if (dataset1)
        m_dataset1Modified = true;
    else
        m_dataset2Modified = true;

    columnModel.setColumns(dataSet.columns());

    if (dataset1)
    {
        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1OutlierCleaning();
        emit dataset1Changed();
    }
    else
    {
        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2OutlierCleaning();
        emit dataset2Changed();
    }

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

bool AppController::fillMissingWithMode(
    DataSet &dataSet,
    ColumnModel &columnModel,
    const QString &columnName,
    bool dataset1
    )
{
    clearError();

    if (dataSet.isEmpty())
    {
        setError(dataset1
                     ? QStringLiteral("Dataset 1 is not loaded.")
                     : QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnInfo *column = dataSet.findColumn(columnName);

    if (!column)
    {
        setError(QStringLiteral("Selected column was not found."));
        return false;
    }

    QVector<QVariant> values = column->values();

    QMap<QString, int> frequency;
    QMap<QString, QVariant> originalValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
        {
            ++missingCount;
            continue;
        }

        const QString key =
            QString::number(static_cast<int>(value.type())) +
            QStringLiteral(":") +
            value.toString();

        frequency[key] += 1;
        originalValues.insert(key, value);
    }

    if (missingCount == 0)
    {
        setError(QStringLiteral("Selected column does not contain missing values."));
        return false;
    }

    if (frequency.isEmpty())
    {
        setError(QStringLiteral("Mode cannot be calculated."));
        return false;
    }

    QString modeKey;
    int maxCount = -1;

    for (auto it = frequency.constBegin();
         it != frequency.constEnd();
         ++it)
    {
        if (it.value() > maxCount)
        {
            maxCount = it.value();
            modeKey = it.key();
        }
    }

    const QVariant modeValue = originalValues.value(modeKey);

    for (int i = 0; i < values.size(); ++i)
    {
        const QVariant &value = values.at(i);

        const bool missing =
            !value.isValid() ||
            value.isNull() ||
            (value.type() == QVariant::String &&
             value.toString().trimmed().isEmpty());

        if (missing)
            values[i] = modeValue;
    }

    if (!dataSet.setColumnValues(columnName, values))
    {
        setError(QStringLiteral("Column could not be updated."));
        return false;
    }

    if (dataset1)
        m_dataset1Modified = true;
    else
        m_dataset2Modified = true;

    columnModel.setColumns(dataSet.columns());

    if (dataset1)
    {
        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1OutlierCleaning();
        emit dataset1Changed();
    }
    else
    {
        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2OutlierCleaning();
        emit dataset2Changed();
    }

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

// =========================================================
// OUTLIER CLEANING
// =========================================================

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
    return applyOutlierAction(
        m_dataset1,
        m_dataset1ColumnModel,
        m_dataset1OutlierCleaningResult,
        columnName,
        method,
        action,
        parameter,
        true
        );
}

bool AppController::applyDataset2OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    return applyOutlierAction(
        m_dataset2,
        m_dataset2ColumnModel,
        m_dataset2OutlierCleaningResult,
        columnName,
        method,
        action,
        parameter,
        false
        );
}

bool AppController::applyOutlierAction(
    DataSet &dataSet,
    ColumnModel &columnModel,
    QVariantMap &cleaningResult,
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter,
    bool dataset1
    )
{
    clearError();

    if (!cleaningResult.isEmpty())
    {
        cleaningResult.clear();

        if (dataset1)
            emit dataset1OutlierCleaningChanged();
        else
            emit dataset2OutlierCleaningChanged();
    }

    if (dataSet.isEmpty())
    {
        setError(dataset1
                     ? QStringLiteral("Dataset 1 is not loaded.")
                     : QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    if (!std::isfinite(parameter) || parameter <= 0.0)
    {
        setError(QStringLiteral("Outlier parameter must be a finite positive value."));
        return false;
    }

    const ColumnInfo *column = dataSet.findColumn(columnName);

    if (!column)
    {
        setError(QStringLiteral("Selected column was not found."));
        return false;
    }

    if (!column->isNumeric())
    {
        setError(QStringLiteral("Outlier operations can only be applied to numeric columns."));
        return false;
    }

    QVector<int> outlierRows;
    QVariantList outlierValues;
    QVariantMap resultMap;

    resultMap.insert(QStringLiteral("columnName"), columnName);
    resultMap.insert(QStringLiteral("method"), method);
    resultMap.insert(QStringLiteral("action"), action);
    resultMap.insert(QStringLiteral("parameter"), parameter);

    if (method.compare(QStringLiteral("IQR"), Qt::CaseInsensitive) == 0)
    {
        const ColumnOutlierAnalysisResult result =
            m_analysisEngine.analyzeColumnOutliers(
                dataSet,
                columnName,
                parameter
                );

        if (!result.success)
        {
            setError(result.errorMessage);
            return false;
        }

        outlierRows =
            m_analysisEngine.findIqrOutlierRowIndexes(
                dataSet,
                columnName,
                parameter
                );

        for (double value : result.outlierResult.outlierValues)
            outlierValues.append(value);

        resultMap.insert(
            QStringLiteral("validValueCount"),
            result.outlierResult.validValueCount
            );

        resultMap.insert(
            QStringLiteral("lowerBound"),
            result.outlierResult.lowerBound
            );

        resultMap.insert(
            QStringLiteral("upperBound"),
            result.outlierResult.upperBound
            );

        resultMap.insert(
            QStringLiteral("outlierPercentage"),
            result.outlierResult.outlierPercentage
            );
    }
    else if (method.compare(
                 QStringLiteral("Z-Score"),
                 Qt::CaseInsensitive) == 0)
    {
        const ZScoreOutlierResult result =
            m_analysisEngine.analyzeColumnZScoreOutliers(
                dataSet,
                columnName,
                parameter
                );

        if (!result.success)
        {
            setError(result.errorMessage);
            return false;
        }

        outlierRows = result.outlierRowIndexes;

        for (double value : result.outlierValues)
            outlierValues.append(value);

        resultMap.insert(
            QStringLiteral("validValueCount"),
            result.validValueCount
            );

        resultMap.insert(
            QStringLiteral("mean"),
            result.mean
            );

        resultMap.insert(
            QStringLiteral("standardDeviation"),
            result.standardDeviation
            );

        resultMap.insert(
            QStringLiteral("threshold"),
            result.threshold
            );

        resultMap.insert(
            QStringLiteral("outlierPercentage"),
            result.outlierPercentage
            );
    }
    else
    {
        setError(QStringLiteral("Unknown outlier detection method."));
        return false;
    }

    QVariantList rowList;

    for (int index : outlierRows)
        rowList.append(index + 1);

    resultMap.insert(QStringLiteral("outlierCount"), outlierRows.size());
    resultMap.insert(QStringLiteral("outlierValues"), outlierValues);
    resultMap.insert(QStringLiteral("markedRows"), rowList);

    if (action.compare(
            QStringLiteral("Keep"),
            Qt::CaseInsensitive) == 0)
    {
        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral("Outliers were detected and kept unchanged.")
            );

        cleaningResult = resultMap;

        if (dataset1)
            emit dataset1OutlierCleaningChanged();
        else
            emit dataset2OutlierCleaningChanged();

        return true;
    }

    if (action.compare(
            QStringLiteral("Mark"),
            Qt::CaseInsensitive) == 0)
    {
        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral("Outliers were marked. Dataset values were not changed.")
            );

        cleaningResult = resultMap;

        if (dataset1)
            emit dataset1OutlierCleaningChanged();
        else
            emit dataset2OutlierCleaningChanged();

        return true;
    }

    if (action.compare(
            QStringLiteral("Remove"),
            Qt::CaseInsensitive) == 0)
    {
        if (outlierRows.isEmpty())
        {
            setError(QStringLiteral("Selected column does not contain outliers."));
            return false;
        }

        if (!dataSet.removeRows(outlierRows))
        {
            setError(QStringLiteral("Outlier rows could not be removed."));
            return false;
        }

        if (dataset1)
            m_dataset1Modified = true;
        else
            m_dataset2Modified = true;

        columnModel.setColumns(dataSet.columns());

        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral("%1 outlier row(s) removed.")
                .arg(outlierRows.size())
            );

        cleaningResult = resultMap;

        if (dataset1)
        {
            clearDataset1Quality();
            clearDataset1Outliers();
            clearAnalysis();

            emit dataset1Changed();
            emit dataset1OutlierCleaningChanged();
        }
        else
        {
            clearDataset2Quality();
            clearDataset2Outliers();
            clearAnalysis();

            emit dataset2Changed();
            emit dataset2OutlierCleaningChanged();
        }

        tryGenerateMappings();
        return true;
    }

    setError(QStringLiteral("Unknown outlier action."));
    return false;
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
// QUALITY
// =========================================================

bool AppController::analyzeDataset1Quality()
{
    clearError();
    clearDataset1Quality();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const DatasetQualityResult result =
        m_analysisEngine.analyzeDataQuality(m_dataset1);

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1QualityResult = qualityToVariantMap(result);
    m_dataset1QualityAvailable = true;

    emit dataset1QualityChanged();

    return true;
}

bool AppController::analyzeDataset2Quality()
{
    clearError();
    clearDataset2Quality();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const DatasetQualityResult result =
        m_analysisEngine.analyzeDataQuality(m_dataset2);

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2QualityResult = qualityToVariantMap(result);
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

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const ColumnOutlierAnalysisResult result =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1OutlierResult =
        outlierToVariantMap(result);

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

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnOutlierAnalysisResult result =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2OutlierResult =
        outlierToVariantMap(result);

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

QVariantMap AppController::qualityToVariantMap(
    const DatasetQualityResult &quality
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("rowCount"), quality.rowCount);
    map.insert(QStringLiteral("columnCount"), quality.columnCount);
    map.insert(QStringLiteral("totalMissingValues"), quality.totalMissingValues);
    map.insert(QStringLiteral("missingPercentage"), quality.missingPercentage);

    map.insert(
        QStringLiteral("columnsWithMissingValues"),
        quality.columnsWithMissingValues
        );

    map.insert(
        QStringLiteral("columnsWithMissing"),
        quality.columnsWithMissing
        );

    map.insert(QStringLiteral("duplicateRowCount"), quality.duplicateRowCount);
    map.insert(QStringLiteral("duplicatePercentage"), quality.duplicatePercentage);

    map.insert(
        QStringLiteral("constantColumnCount"),
        quality.constantColumnCount
        );

    map.insert(
        QStringLiteral("constantColumns"),
        quality.constantColumns
        );

    map.insert(
        QStringLiteral("numericColumnCount"),
        quality.numericColumnCount
        );

    map.insert(
        QStringLiteral("nonNumericColumnCount"),
        quality.nonNumericColumnCount
        );

    return map;
}

QVariantMap AppController::outlierToVariantMap(
    const ColumnOutlierAnalysisResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("columnName"), result.columnName);

    map.insert(
        QStringLiteral("validValueCount"),
        result.outlierResult.validValueCount
        );

    map.insert(QStringLiteral("q1"), result.outlierResult.q1);
    map.insert(QStringLiteral("q3"), result.outlierResult.q3);
    map.insert(QStringLiteral("iqr"), result.outlierResult.iqr);

    map.insert(
        QStringLiteral("lowerBound"),
        result.outlierResult.lowerBound
        );

    map.insert(
        QStringLiteral("upperBound"),
        result.outlierResult.upperBound
        );

    map.insert(
        QStringLiteral("outlierCount"),
        result.outlierResult.outlierCount
        );

    map.insert(
        QStringLiteral("outlierPercentage"),
        result.outlierResult.outlierPercentage
        );

    QVariantList outlierValues;

    for (double value : result.outlierResult.outlierValues)
        outlierValues.append(value);

    map.insert(QStringLiteral("outlierValues"), outlierValues);

    return map;
}