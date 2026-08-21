#include "EdaEngine.h"

EdaEngine::EdaEngine()
{
}

EdaOperationResult EdaEngine::analyzeSummary(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    EdaOperationResult operationResult;

    if (dataSet.isEmpty())
    {
        operationResult.errorMessage =
            QStringLiteral("Dataset is not loaded.");
        return operationResult;
    }

    if (columnName.trimmed().isEmpty())
    {
        operationResult.errorMessage =
            QStringLiteral("EDA column name is empty.");
        return operationResult;
    }

    const ColumnAnalysisResult result =
        m_analysisEngine.analyzeColumn(
            dataSet,
            columnName
            );

    if (!result.success)
    {
        operationResult.errorMessage =
            result.errorMessage;
        return operationResult;
    }

    QVariantMap resultMap =
        statisticsToVariantMap(
            result.statistics
            );

    resultMap.insert(
        QStringLiteral("columnName"),
        result.columnName
        );

    resultMap.insert(
        QStringLiteral("datasetName"),
        dataSet.name()
        );

    operationResult.success = true;
    operationResult.data = resultMap;

    return operationResult;
}

EdaOperationResult EdaEngine::analyzeCorrelation(
    const DataSet &dataSet,
    const QString &firstColumnName,
    const QString &secondColumnName
    ) const
{
    EdaOperationResult operationResult;

    if (dataSet.isEmpty())
    {
        operationResult.errorMessage =
            QStringLiteral("Dataset is not loaded.");
        return operationResult;
    }

    const CorrelationResult result =
        m_analysisEngine.calculateCorrelation(
            dataSet,
            firstColumnName,
            secondColumnName
            );

    if (!result.success)
    {
        operationResult.errorMessage =
            result.errorMessage;
        return operationResult;
    }

    QVariantMap resultMap;

    resultMap.insert(
        QStringLiteral("firstColumnName"),
        result.firstColumnName
        );

    resultMap.insert(
        QStringLiteral("secondColumnName"),
        result.secondColumnName
        );

    resultMap.insert(
        QStringLiteral("pairedValueCount"),
        result.pairedValueCount
        );

    resultMap.insert(
        QStringLiteral("correlation"),
        result.correlation
        );

    operationResult.success = true;
    operationResult.data = resultMap;

    return operationResult;
}

EdaOperationResult EdaEngine::analyzeQuality(
    const DataSet &dataSet
    ) const
{
    EdaOperationResult operationResult;

    if (dataSet.isEmpty())
    {
        operationResult.errorMessage =
            QStringLiteral("Dataset is not loaded.");
        return operationResult;
    }

    const DatasetQualityResult result =
        m_analysisEngine.analyzeDataQuality(
            dataSet
            );

    if (!result.success)
    {
        operationResult.errorMessage =
            result.errorMessage;
        return operationResult;
    }

    operationResult.success = true;
    operationResult.data =
        qualityToVariantMap(
            result
            );

    return operationResult;
}

EdaOperationResult EdaEngine::analyzeOutliers(
    const DataSet &dataSet,
    const QString &columnName,
    double multiplier
    ) const
{
    EdaOperationResult operationResult;

    if (dataSet.isEmpty())
    {
        operationResult.errorMessage =
            QStringLiteral("Dataset is not loaded.");
        return operationResult;
    }

    const ColumnOutlierAnalysisResult result =
        m_analysisEngine.analyzeColumnOutliers(
            dataSet,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        operationResult.errorMessage =
            result.errorMessage;
        return operationResult;
    }

    operationResult.success = true;
    operationResult.data =
        outlierToVariantMap(
            result
            );

    return operationResult;
}

QVariantMap EdaEngine::statisticsToVariantMap(
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
    map.insert(QStringLiteral("standardDeviation"), statistics.standardDeviation);
    map.insert(QStringLiteral("q1"), statistics.q1);
    map.insert(QStringLiteral("q3"), statistics.q3);
    map.insert(QStringLiteral("iqr"), statistics.iqr);

    return map;
}

QVariantMap EdaEngine::qualityToVariantMap(
    const DatasetQualityResult &quality
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("rowCount"), quality.rowCount);
    map.insert(QStringLiteral("columnCount"), quality.columnCount);
    map.insert(QStringLiteral("totalMissingValues"), quality.totalMissingValues);
    map.insert(QStringLiteral("missingPercentage"), quality.missingPercentage);
    map.insert(QStringLiteral("columnsWithMissingValues"), quality.columnsWithMissingValues);
    map.insert(QStringLiteral("columnsWithMissing"), quality.columnsWithMissing);
    map.insert(QStringLiteral("duplicateRowCount"), quality.duplicateRowCount);
    map.insert(QStringLiteral("duplicatePercentage"), quality.duplicatePercentage);
    map.insert(QStringLiteral("constantColumnCount"), quality.constantColumnCount);
    map.insert(QStringLiteral("constantColumns"), quality.constantColumns);
    map.insert(QStringLiteral("numericColumnCount"), quality.numericColumnCount);
    map.insert(QStringLiteral("nonNumericColumnCount"), quality.nonNumericColumnCount);

    return map;
}

QVariantMap EdaEngine::outlierToVariantMap(
    const ColumnOutlierAnalysisResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("validValueCount"), result.outlierResult.validValueCount);
    map.insert(QStringLiteral("q1"), result.outlierResult.q1);
    map.insert(QStringLiteral("q3"), result.outlierResult.q3);
    map.insert(QStringLiteral("iqr"), result.outlierResult.iqr);
    map.insert(QStringLiteral("lowerBound"), result.outlierResult.lowerBound);
    map.insert(QStringLiteral("upperBound"), result.outlierResult.upperBound);
    map.insert(QStringLiteral("outlierCount"), result.outlierResult.outlierCount);
    map.insert(QStringLiteral("outlierPercentage"), result.outlierResult.outlierPercentage);

    QVariantList outlierValues;

    for (double value : result.outlierResult.outlierValues)
        outlierValues.append(value);

    map.insert(QStringLiteral("outlierValues"), outlierValues);

    return map;
}