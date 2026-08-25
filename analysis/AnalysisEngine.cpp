#include "AnalysisEngine.h"

#include <QByteArray>
#include <QDataStream>
#include <QIODevice>
#include <QSet>
#include <QVariant>

#include <algorithm>
#include <cmath>
#include <limits>

AnalysisEngine::AnalysisEngine()
{
}

ColumnAnalysisResult AnalysisEngine::analyzeColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    ColumnAnalysisResult result;
    result.columnName = columnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    const ColumnInfo *column = findColumn(dataSet, columnName);

    if (!column)
    {
        result.errorMessage = QStringLiteral("Column not found.");
        return result;
    }

    if (!isColumnNumeric(*column))
    {
        result.errorMessage = QStringLiteral("Column is not numeric.");
        return result;
    }

    result.statistics = m_statistics.calculate(column->values());

    if (result.statistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral("Column does not contain valid numeric values.");
        return result;
    }

    result.success = true;
    return result;
}

ColumnOutlierAnalysisResult AnalysisEngine::analyzeColumnOutliers(
    const DataSet &dataSet,
    const QString &columnName,
    double multiplier
    ) const
{
    ColumnOutlierAnalysisResult result;
    result.columnName = columnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (columnName.trimmed().isEmpty())
    {
        result.errorMessage = QStringLiteral("Column name is empty.");
        return result;
    }

    if (!std::isfinite(multiplier) || multiplier <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("IQR multiplier must be a finite positive value.");
        return result;
    }

    const ColumnInfo *column = findColumn(dataSet, columnName);

    if (!column)
    {
        result.errorMessage = QStringLiteral("Column not found.");
        return result;
    }

    if (!isColumnNumeric(*column))
    {
        result.errorMessage =
            QStringLiteral("Outlier analysis can only be performed on numeric columns.");
        return result;
    }

    result.outlierResult =
        m_statistics.calculateIqrOutliers(column->values(), multiplier);

    if (!result.outlierResult.success)
    {
        result.errorMessage = result.outlierResult.errorMessage;
        return result;
    }

    result.success = true;
    return result;
}

ZScoreOutlierResult AnalysisEngine::analyzeColumnZScoreOutliers(
    const DataSet &dataSet,
    const QString &columnName,
    double threshold
    ) const
{
    ZScoreOutlierResult result;
    result.columnName = columnName;
    result.threshold = threshold;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (columnName.trimmed().isEmpty())
    {
        result.errorMessage = QStringLiteral("Column name is empty.");
        return result;
    }

    if (!std::isfinite(threshold) || threshold <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("Z-Score threshold must be a finite positive value.");
        return result;
    }

    const ColumnInfo *column = findColumn(dataSet, columnName);

    if (!column)
    {
        result.errorMessage = QStringLiteral("Column not found.");
        return result;
    }

    if (!isColumnNumeric(*column))
    {
        result.errorMessage =
            QStringLiteral("Z-Score analysis can only be performed on numeric columns.");
        return result;
    }

    const QVector<QVariant> values = column->values();

    QVector<double> numericValues;
    numericValues.reserve(values.size());

    for (const QVariant &value : values)
    {
        if (isMissingValue(value))
            continue;

        bool ok = false;
        const double number = value.toDouble(&ok);

        if (ok && std::isfinite(number))
            numericValues.append(number);
    }

    result.validValueCount = numericValues.size();

    if (numericValues.size() < 2)
    {
        result.errorMessage =
            QStringLiteral("At least two valid numeric values are required for Z-Score analysis.");
        return result;
    }

    double total = 0.0;
    for (double value : numericValues)
        total += value;

    result.mean =
        total / static_cast<double>(numericValues.size());

    double squaredDifferenceTotal = 0.0;

    for (double value : numericValues)
    {
        const double difference = value - result.mean;
        squaredDifferenceTotal += difference * difference;
    }

    const double variance =
        squaredDifferenceTotal /
        static_cast<double>(numericValues.size());

    result.standardDeviation = std::sqrt(variance);

    if (!std::isfinite(result.standardDeviation) ||
        result.standardDeviation <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("Z-Score cannot be calculated because standard deviation is zero.");
        return result;
    }

    for (int row = 0; row < values.size(); ++row)
    {
        const QVariant &value = values.at(row);

        if (isMissingValue(value))
            continue;

        bool ok = false;
        const double number = value.toDouble(&ok);

        if (!ok || !std::isfinite(number))
            continue;

        const double zScore =
            (number - result.mean) / result.standardDeviation;

        if (std::fabs(zScore) > threshold)
        {
            result.outlierValues.append(number);
            result.outlierRowIndexes.append(row);
        }
    }

    result.outlierCount = result.outlierValues.size();

    if (result.validValueCount > 0)
    {
        result.outlierPercentage =
            static_cast<double>(result.outlierCount) /
            static_cast<double>(result.validValueCount) *
            100.0;
    }

    result.success = true;
    return result;
}

QVector<int> AnalysisEngine::findIqrOutlierRowIndexes(
    const DataSet &dataSet,
    const QString &columnName,
    double multiplier
    ) const
{
    QVector<int> indexes;

    const ColumnOutlierAnalysisResult analysis =
        analyzeColumnOutliers(dataSet, columnName, multiplier);

    if (!analysis.success)
        return indexes;

    const ColumnInfo *column = findColumn(dataSet, columnName);

    if (!column)
        return indexes;

    const QVector<QVariant> values = column->values();

    for (int row = 0; row < values.size(); ++row)
    {
        const QVariant &value = values.at(row);

        if (isMissingValue(value))
            continue;

        bool ok = false;
        const double number = value.toDouble(&ok);

        if (!ok || !std::isfinite(number))
            continue;

        if (number < analysis.outlierResult.lowerBound ||
            number > analysis.outlierResult.upperBound)
        {
            indexes.append(row);
        }
    }

    return indexes;
}

QVector<int> AnalysisEngine::findZScoreOutlierRowIndexes(
    const DataSet &dataSet,
    const QString &columnName,
    double threshold
    ) const
{
    const ZScoreOutlierResult result =
        analyzeColumnZScoreOutliers(dataSet, columnName, threshold);

    if (!result.success)
        return QVector<int>();

    return result.outlierRowIndexes;
}

CorrelationResult AnalysisEngine::calculateCorrelation(
    const DataSet &dataSet,
    const QString &firstColumnName,
    const QString &secondColumnName
    ) const
{
    CorrelationResult result;
    result.firstColumnName = firstColumnName;
    result.secondColumnName = secondColumnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (firstColumnName.trimmed().isEmpty() ||
        secondColumnName.trimmed().isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Correlation column name is empty.");
        return result;
    }

    const ColumnInfo *firstColumn =
        findColumn(dataSet, firstColumnName);

    const ColumnInfo *secondColumn =
        findColumn(dataSet, secondColumnName);

    if (!firstColumn || !secondColumn)
    {
        result.errorMessage =
            QStringLiteral("Correlation column not found.");
        return result;
    }

    if (!isColumnNumeric(*firstColumn) ||
        !isColumnNumeric(*secondColumn))
    {
        result.errorMessage =
            QStringLiteral("Correlation can only be calculated between numeric columns.");
        return result;
    }

    const QVector<QVariant> firstValues =
        firstColumn->values();

    const QVector<QVariant> secondValues =
        secondColumn->values();

    const int rowCount =
        std::min(firstValues.size(), secondValues.size());

    QVector<double> xValues;
    QVector<double> yValues;

    xValues.reserve(rowCount);
    yValues.reserve(rowCount);

    for (int row = 0; row < rowCount; ++row)
    {
        const QVariant &firstValue = firstValues.at(row);
        const QVariant &secondValue = secondValues.at(row);

        if (isMissingValue(firstValue) ||
            isMissingValue(secondValue))
        {
            continue;
        }

        bool firstOk = false;
        bool secondOk = false;

        const double x =
            firstValue.toDouble(&firstOk);

        const double y =
            secondValue.toDouble(&secondOk);

        if (!firstOk || !secondOk ||
            !std::isfinite(x) || !std::isfinite(y))
        {
            continue;
        }

        xValues.append(x);
        yValues.append(y);
    }

    result.pairedValueCount = xValues.size();

    if (result.pairedValueCount < 2)
    {
        result.errorMessage =
            QStringLiteral("At least two valid paired numeric values are required for correlation.");
        return result;
    }

    double xTotal = 0.0;
    double yTotal = 0.0;

    for (int i = 0; i < result.pairedValueCount; ++i)
    {
        xTotal += xValues.at(i);
        yTotal += yValues.at(i);
    }

    const double xMean =
        xTotal / static_cast<double>(result.pairedValueCount);

    const double yMean =
        yTotal / static_cast<double>(result.pairedValueCount);

    double covarianceTotal = 0.0;
    double xSquaredTotal = 0.0;
    double ySquaredTotal = 0.0;

    for (int i = 0; i < result.pairedValueCount; ++i)
    {
        const double xDifference =
            xValues.at(i) - xMean;

        const double yDifference =
            yValues.at(i) - yMean;

        covarianceTotal +=
            xDifference * yDifference;

        xSquaredTotal +=
            xDifference * xDifference;

        ySquaredTotal +=
            yDifference * yDifference;
    }

    const double denominator =
        std::sqrt(xSquaredTotal * ySquaredTotal);

    if (!std::isfinite(denominator) ||
        denominator <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("Correlation cannot be calculated because at least one column is constant.");
        return result;
    }

    result.correlation =
        covarianceTotal / denominator;

    if (!std::isfinite(result.correlation))
    {
        result.errorMessage =
            QStringLiteral("Correlation calculation produced an invalid result.");
        return result;
    }

    if (result.correlation > 1.0)
        result.correlation = 1.0;
    else if (result.correlation < -1.0)
        result.correlation = -1.0;

    result.success = true;
    return result;
}

ColumnComparisonResult AnalysisEngine::compareColumns(
    const DataSet &sourceDataSet,
    const QString &sourceColumnName,
    const DataSet &targetDataSet,
    const QString &targetColumnName
    ) const
{
    ColumnComparisonResult result;

    result.sourceColumnName = sourceColumnName;
    result.targetColumnName = targetColumnName;

    if (sourceDataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset 1 is empty.");
        return result;
    }

    if (targetDataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset 2 is empty.");
        return result;
    }

    const ColumnInfo *sourceColumn =
        findColumn(sourceDataSet, sourceColumnName);

    const ColumnInfo *targetColumn =
        findColumn(targetDataSet, targetColumnName);

    if (!sourceColumn)
    {
        result.errorMessage = QStringLiteral("Dataset 1 column not found.");
        return result;
    }

    if (!targetColumn)
    {
        result.errorMessage = QStringLiteral("Dataset 2 column not found.");
        return result;
    }

    if (!isColumnNumeric(*sourceColumn))
    {
        result.errorMessage = QStringLiteral("Dataset 1 column is not numeric.");
        return result;
    }

    if (!isColumnNumeric(*targetColumn))
    {
        result.errorMessage = QStringLiteral("Dataset 2 column is not numeric.");
        return result;
    }

    result.sourceStatistics =
        m_statistics.calculate(sourceColumn->values());

    result.targetStatistics =
        m_statistics.calculate(targetColumn->values());

    if (result.sourceStatistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral("Dataset 1 column does not contain numeric values.");
        return result;
    }

    if (result.targetStatistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral("Dataset 2 column does not contain numeric values.");
        return result;
    }

    result.meanDifference =
        result.targetStatistics.mean - result.sourceStatistics.mean;

    result.medianDifference =
        result.targetStatistics.median - result.sourceStatistics.median;

    result.minimumDifference =
        result.targetStatistics.minimum - result.sourceStatistics.minimum;

    result.maximumDifference =
        result.targetStatistics.maximum - result.sourceStatistics.maximum;

    result.rangeDifference =
        result.targetStatistics.range - result.sourceStatistics.range;

    result.varianceDifference =
        result.targetStatistics.variance - result.sourceStatistics.variance;

    result.standardDeviationDifference =
        result.targetStatistics.standardDeviation -
        result.sourceStatistics.standardDeviation;

    result.q1Difference =
        result.targetStatistics.q1 - result.sourceStatistics.q1;

    result.q3Difference =
        result.targetStatistics.q3 - result.sourceStatistics.q3;

    result.iqrDifference =
        result.targetStatistics.iqr - result.sourceStatistics.iqr;

    result.success = true;
    return result;
}

DatasetQualityResult AnalysisEngine::analyzeDataQuality(
    const DataSet &dataSet
    ) const
{
    DatasetQualityResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    const QVector<ColumnInfo> columns = dataSet.columns();

    result.rowCount = dataSet.rowCount();
    result.columnCount = columns.size();

    if (result.columnCount <= 0)
    {
        result.errorMessage =
            QStringLiteral("Dataset contains no columns.");
        return result;
    }

    qint64 totalMissingValues = 0;

    for (const ColumnInfo &column : columns)
    {
        const int missingCount = column.missingCount();

        if (missingCount > 0)
        {
            totalMissingValues += static_cast<qint64>(missingCount);
            ++result.columnsWithMissingValues;
            result.columnsWithMissing.append(column.name());
        }

        if (column.uniqueCount() == 1)
        {
            ++result.constantColumnCount;
            result.constantColumns.append(column.name());
        }

        if (column.isNumeric())
            ++result.numericColumnCount;
        else
            ++result.nonNumericColumnCount;
    }

    if (totalMissingValues >
        static_cast<qint64>(std::numeric_limits<int>::max()))
    {
        result.totalMissingValues = std::numeric_limits<int>::max();
    }
    else
    {
        result.totalMissingValues =
            static_cast<int>(totalMissingValues);
    }

    const qint64 totalCellCount =
        static_cast<qint64>(result.rowCount) *
        static_cast<qint64>(result.columnCount);

    if (totalCellCount > 0)
    {
        result.missingPercentage =
            static_cast<double>(totalMissingValues) /
            static_cast<double>(totalCellCount) *
            100.0;
    }

    result.duplicateRowCount =
        calculateDuplicateRowCount(dataSet);

    if (result.rowCount > 0)
    {
        result.duplicatePercentage =
            static_cast<double>(result.duplicateRowCount) /
            static_cast<double>(result.rowCount) *
            100.0;
    }

    result.success = true;
    return result;
}

QVector<int> AnalysisEngine::findDuplicateRowIndexes(
    const DataSet &dataSet
    ) const
{
    QVector<int> duplicateIndexes;

    if (dataSet.isEmpty())
        return duplicateIndexes;

    const QVector<ColumnInfo> columns = dataSet.columns();

    if (columns.isEmpty())
        return duplicateIndexes;

    const int rowCount = dataSet.rowCount();

    if (rowCount <= 1)
        return duplicateIndexes;

    QSet<QByteArray> uniqueRows;

    for (int row = 0; row < rowCount; ++row)
    {
        QByteArray rowSignature;
        QDataStream stream(&rowSignature, QIODevice::WriteOnly);
        stream.setVersion(QDataStream::Qt_5_15);

        for (const ColumnInfo &column : columns)
        {
            const QVector<QVariant> values = column.values();

            if (row >= 0 && row < values.size())
                stream << values.at(row);
            else
                stream << QVariant();
        }

        if (uniqueRows.contains(rowSignature))
            duplicateIndexes.append(row);
        else
            uniqueRows.insert(rowSignature);
    }

    return duplicateIndexes;
}

QVector<int> AnalysisEngine::findRowsWithMissingValues(
    const DataSet &dataSet
    ) const
{
    QVector<int> missingRowIndexes;

    if (dataSet.isEmpty())
        return missingRowIndexes;

    const QVector<ColumnInfo> columns = dataSet.columns();

    if (columns.isEmpty())
        return missingRowIndexes;

    const int rowCount = dataSet.rowCount();

    for (int row = 0; row < rowCount; ++row)
    {
        bool rowHasMissing = false;

        for (const ColumnInfo &column : columns)
        {
            const QVector<QVariant> values = column.values();

            if (row < 0 || row >= values.size() ||
                isMissingValue(values.at(row)))
            {
                rowHasMissing = true;
                break;
            }
        }

        if (rowHasMissing)
            missingRowIndexes.append(row);
    }

    return missingRowIndexes;
}

int AnalysisEngine::calculateDuplicateRowCount(
    const DataSet &dataSet
    ) const
{
    return findDuplicateRowIndexes(dataSet).size();
}

bool AnalysisEngine::isMissingValue(
    const QVariant &value
    ) const
{
    if (!value.isValid() || value.isNull())
        return true;

    if (value.type() == QVariant::String &&
        value.toString().trimmed().isEmpty())
    {
        return true;
    }

    return false;
}

const ColumnInfo *AnalysisEngine::findColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    if (columnName.trimmed().isEmpty())
        return nullptr;

    return dataSet.findColumn(columnName);
}

bool AnalysisEngine::isColumnNumeric(
    const ColumnInfo &column
    ) const
{
    return column.isNumeric();
}