#include "VisualizationEngine.h"

#include <algorithm>
#include <cmath>


VisualizationEngine::VisualizationEngine()
{
}


// =========================================================
// CREATE HISTOGRAM
// =========================================================

HistogramResult VisualizationEngine::createHistogram(
    const DataSet &dataSet,
    const QString &columnName,
    int binCount
    ) const
{
    HistogramResult result;

    result.columnName = columnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is empty.");
        return result;
    }

    if (columnName.trimmed().isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Histogram column name is empty.");
        return result;
    }

    if (binCount <= 0)
    {
        result.errorMessage =
            QStringLiteral("Histogram bin count must be greater than zero.");
        return result;
    }

    const ColumnInfo *column =
        findColumn(dataSet, columnName);

    if (!column)
    {
        result.errorMessage =
            QStringLiteral("Histogram column was not found.");
        return result;
    }

    if (!column->isNumeric())
    {
        result.errorMessage =
            QStringLiteral("Histogram can only be created for numeric columns.");
        return result;
    }

    const QVector<double> numericValues =
        extractNumericValues(*column);

    result.validValueCount =
        numericValues.size();

    if (numericValues.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Column does not contain valid numeric values.");
        return result;
    }

    const auto minMax =
        std::minmax_element(
            numericValues.begin(),
            numericValues.end()
            );

    result.minimum = *minMax.first;
    result.maximum = *minMax.second;

    if (result.minimum == result.maximum)
    {
        result.binCount = 1;
        result.binWidth = 0.0;

        result.binLowerBounds.append(result.minimum);
        result.binUpperBounds.append(result.maximum);
        result.frequencies.append(numericValues.size());

        result.success = true;
        return result;
    }

    result.binCount =
        std::min(
            binCount,
            numericValues.size()
            );

    result.binWidth =
        (result.maximum - result.minimum) /
        static_cast<double>(result.binCount);

    if (!std::isfinite(result.binWidth) ||
        result.binWidth <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("Histogram bin width could not be calculated.");
        return result;
    }

    result.frequencies.fill(
        0,
        result.binCount
        );

    result.binLowerBounds.reserve(
        result.binCount
        );

    result.binUpperBounds.reserve(
        result.binCount
        );

    for (int i = 0; i < result.binCount; ++i)
    {
        const double lower =
            result.minimum +
            static_cast<double>(i) *
                result.binWidth;

        double upper =
            lower +
            result.binWidth;

        if (i == result.binCount - 1)
            upper = result.maximum;

        result.binLowerBounds.append(lower);
        result.binUpperBounds.append(upper);
    }

    for (double value : numericValues)
    {
        int index =
            static_cast<int>(
                std::floor(
                    (value - result.minimum) /
                    result.binWidth
                    )
                );

        if (index >= result.binCount)
            index = result.binCount - 1;

        if (index < 0)
            index = 0;

        ++result.frequencies[index];
    }

    result.success = true;
    return result;
}


// =========================================================
// CREATE BOX PLOT
// =========================================================

BoxPlotResult VisualizationEngine::createBoxPlot(
    const DataSet &dataSet,
    const QString &columnName,
    double multiplier
    ) const
{
    BoxPlotResult result;

    result.columnName = columnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is empty.");
        return result;
    }

    if (columnName.trimmed().isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Box plot column name is empty.");
        return result;
    }

    if (!std::isfinite(multiplier) ||
        multiplier <= 0.0)
    {
        result.errorMessage =
            QStringLiteral("Box plot IQR multiplier must be a finite positive value.");
        return result;
    }

    const ColumnInfo *column =
        findColumn(dataSet, columnName);

    if (!column)
    {
        result.errorMessage =
            QStringLiteral("Box plot column was not found.");
        return result;
    }

    if (!column->isNumeric())
    {
        result.errorMessage =
            QStringLiteral("Box plot can only be created for numeric columns.");
        return result;
    }

    QVector<double> numericValues =
        extractNumericValues(*column);

    result.validValueCount =
        numericValues.size();

    if (numericValues.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Column does not contain valid numeric values.");
        return result;
    }

    std::sort(
        numericValues.begin(),
        numericValues.end()
        );

    result.minimum =
        numericValues.first();

    result.maximum =
        numericValues.last();

    result.q1 =
        calculateQuantile(
            numericValues,
            0.25
            );

    result.median =
        calculateMedian(
            numericValues
            );

    result.q3 =
        calculateQuantile(
            numericValues,
            0.75
            );

    result.iqr =
        result.q3 -
        result.q1;

    result.lowerBound =
        result.q1 -
        multiplier *
            result.iqr;

    result.upperBound =
        result.q3 +
        multiplier *
            result.iqr;

    if (!std::isfinite(result.lowerBound) ||
        !std::isfinite(result.upperBound))
    {
        result.errorMessage =
            QStringLiteral("Box plot bounds could not be calculated.");
        return result;
    }

    result.lowerWhisker =
        result.minimum;

    result.upperWhisker =
        result.maximum;

    bool lowerWhiskerFound = false;
    bool upperWhiskerFound = false;

    for (double value : numericValues)
    {
        if (value < result.lowerBound ||
            value > result.upperBound)
        {
            result.outlierValues.append(value);
            continue;
        }

        if (!lowerWhiskerFound)
        {
            result.lowerWhisker = value;
            lowerWhiskerFound = true;
        }

        result.upperWhisker = value;
        upperWhiskerFound = true;
    }

    if (!lowerWhiskerFound ||
        !upperWhiskerFound)
    {
        result.errorMessage =
            QStringLiteral("Box plot whiskers could not be calculated.");
        return result;
    }

    result.outlierCount =
        result.outlierValues.size();

    result.success = true;
    return result;
}


// =========================================================
// CREATE TIME SERIES
// =========================================================

TimeSeriesResult VisualizationEngine::createTimeSeries(
    const DataSet &dataSet,
    const QString &xColumnName,
    const QString &yColumnName
    ) const
{
    TimeSeriesResult result;

    result.xColumnName = xColumnName;
    result.yColumnName = yColumnName;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is empty.");
        return result;
    }

    QString actualY = yColumnName.trimmed();
    QString actualX = xColumnName.trimmed();

    if (actualY.isEmpty() && !actualX.isEmpty())
    {
        actualY = actualX;
        actualX.clear();
    }

    const ColumnInfo *yColumn = findColumn(dataSet, actualY);
    if (!yColumn && !actualX.isEmpty())
    {
        yColumn = findColumn(dataSet, actualX);
        actualX.clear();
    }

    if (!yColumn)
    {
        result.errorMessage =
            QStringLiteral("Time series column was not found.");
        return result;
    }

    if (!yColumn->isNumeric())
    {
        result.errorMessage =
            QStringLiteral("Time series Y column must be numeric.");
        return result;
    }

    const ColumnInfo *xColumn = actualX.isEmpty() ? nullptr : findColumn(dataSet, actualX);
    const QVector<QVariant> yRawValues = yColumn->values();
    const QVector<QVariant> xRawValues = (xColumn && xColumn != yColumn) ? xColumn->values() : QVector<QVariant>();

    const int rowCount = xRawValues.isEmpty() ? yRawValues.size() : std::min(xRawValues.size(), yRawValues.size());

    for (int row = 0; row < rowCount; ++row)
    {
        double x = static_cast<double>(row + 1);
        double y = 0.0;

        if (!xRawValues.isEmpty())
        {
            double parsedX = 0.0;
            if (variantToFiniteDouble(xRawValues.at(row), &parsedX))
            {
                x = parsedX;
            }
        }

        if (!variantToFiniteDouble(
                yRawValues.at(row),
                &y))
        {
            continue;
        }

        result.xValues.append(x);
        result.yValues.append(y);
    }

    result.pointCount =
        result.yValues.size();

    if (result.pointCount <= 0)
    {
        result.errorMessage =
            QStringLiteral("Time series does not contain valid points.");
        return result;
    }

    result.success = true;
    return result;
}


// =========================================================
// CREATE DISTRIBUTION
// =========================================================

DistributionResult VisualizationEngine::createDistribution(
    const DataSet &dataSet,
    const QString &columnName,
    int binCount
    ) const
{
    DistributionResult result;

    result.columnName = columnName;

    const HistogramResult histogram =
        createHistogram(
            dataSet,
            columnName,
            binCount
            );

    if (!histogram.success)
    {
        result.errorMessage =
            histogram.errorMessage;
        return result;
    }

    result.validValueCount =
        histogram.validValueCount;

    result.binCount =
        histogram.binCount;

    result.centers.reserve(
        histogram.binCount
        );

    result.relativeFrequencies.reserve(
        histogram.binCount
        );

    for (int i = 0; i < histogram.binCount; ++i)
    {
        const double lower =
            histogram.binLowerBounds.at(i);

        const double upper =
            histogram.binUpperBounds.at(i);

        const double center =
            (lower + upper) /
            2.0;

        result.centers.append(center);

        const double relativeFrequency =
            histogram.validValueCount > 0
                ? static_cast<double>(
                      histogram.frequencies.at(i)
                      ) /
                      static_cast<double>(
                          histogram.validValueCount
                          )
                : 0.0;

        result.relativeFrequencies.append(
            relativeFrequency
            );
    }

    result.success = true;
    return result;
}


// =========================================================
// CREATE CORRELATION MATRIX
// =========================================================

CorrelationMatrixResult VisualizationEngine::createCorrelationMatrix(
    const DataSet &dataSet
    ) const
{
    CorrelationMatrixResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is empty.");
        return result;
    }

    const QVector<ColumnInfo> columns =
        dataSet.columns();

    QVector<const ColumnInfo *> numericColumns;

    for (const ColumnInfo &column : columns)
    {
        if (column.isNumeric())
        {
            numericColumns.append(
                &column
                );

            result.columnNames.append(
                column.name()
                );
        }
    }

    result.columnCount =
        numericColumns.size();

    if (result.columnCount <= 0)
    {
        result.errorMessage =
            QStringLiteral("Dataset does not contain numeric columns.");
        return result;
    }

    result.values.reserve(
        result.columnCount *
        result.columnCount
        );

    for (int row = 0;
         row < result.columnCount;
         ++row)
    {
        for (int column = 0;
             column < result.columnCount;
             ++column)
        {
            if (row == column)
            {
                result.values.append(1.0);
                continue;
            }

            double correlation = 0.0;

            if (!calculatePearsonCorrelation(
                    *numericColumns.at(row),
                    *numericColumns.at(column),
                    &correlation))
            {
                /*
                 * Pairwise calculation mümkün değilse matrix
                 * kullanılabilir kalmalı. Bu hücreyi 0 yapıyoruz.
                 */
                correlation = 0.0;
            }

            result.values.append(
                correlation
                );
        }
    }

    result.success = true;
    return result;
}


// =========================================================
// CREATE DATASET COMPARISON CHART
// =========================================================

ComparisonChartResult VisualizationEngine::createComparisonChart(
    const DataSet &sourceDataSet,
    const QString &sourceColumnName,
    const DataSet &targetDataSet,
    const QString &targetColumnName
    ) const
{
    ComparisonChartResult result;

    result.sourceColumnName =
        sourceColumnName;

    result.targetColumnName =
        targetColumnName;

    if (sourceDataSet.isEmpty() ||
        targetDataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Comparison dataset is empty.");
        return result;
    }

    const ColumnInfo *sourceColumn =
        findColumn(
            sourceDataSet,
            sourceColumnName
            );

    const ColumnInfo *targetColumn =
        findColumn(
            targetDataSet,
            targetColumnName
            );

    if (!sourceColumn || !targetColumn)
    {
        result.errorMessage =
            QStringLiteral("Comparison column was not found.");
        return result;
    }

    if (!sourceColumn->isNumeric() ||
        !targetColumn->isNumeric())
    {
        result.errorMessage =
            QStringLiteral("Comparison chart requires numeric columns.");
        return result;
    }

    const QVector<QVariant> sourceRawValues =
        sourceColumn->values();

    const QVector<QVariant> targetRawValues =
        targetColumn->values();

    const int pairedRowCount =
        std::min(
            sourceRawValues.size(),
            targetRawValues.size()
            );

    for (int row = 0;
         row < pairedRowCount;
         ++row)
    {
        double sourceValue = 0.0;
        double targetValue = 0.0;

        if (!variantToFiniteDouble(
                sourceRawValues.at(row),
                &sourceValue))
        {
            continue;
        }

        if (!variantToFiniteDouble(
                targetRawValues.at(row),
                &targetValue))
        {
            continue;
        }

        result.indexes.append(
            static_cast<double>(
                row + 1
                )
            );

        result.sourceValues.append(
            sourceValue
            );

        result.targetValues.append(
            targetValue
            );
    }

    result.pointCount =
        result.indexes.size();

    if (result.pointCount <= 0)
    {
        result.errorMessage =
            QStringLiteral("Comparison chart does not contain valid paired points.");
        return result;
    }

    result.success = true;
    return result;
}


// =========================================================
// FIND COLUMN
// =========================================================

const ColumnInfo *VisualizationEngine::findColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    if (columnName.trimmed().isEmpty())
        return nullptr;

    return dataSet.findColumn(
        columnName
        );
}


// =========================================================
// EXTRACT NUMERIC VALUES
// =========================================================

QVector<double> VisualizationEngine::extractNumericValues(
    const ColumnInfo &column
    ) const
{
    QVector<double> numericValues;

    const QVector<QVariant> values =
        column.values();

    numericValues.reserve(
        values.size()
        );

    for (const QVariant &value : values)
    {
        double number = 0.0;

        if (!variantToFiniteDouble(
                value,
                &number))
        {
            continue;
        }

        numericValues.append(
            number
            );
    }

    return numericValues;
}


// =========================================================
// MEDIAN
// =========================================================

double VisualizationEngine::calculateMedian(
    QVector<double> values
    ) const
{
    if (values.isEmpty())
        return 0.0;

    std::sort(
        values.begin(),
        values.end()
        );

    const int size =
        values.size();

    const int middle =
        size / 2;

    if (size % 2 == 0)
    {
        return (
                   values.at(middle - 1) +
                   values.at(middle)
                   ) /
               2.0;
    }

    return values.at(
        middle
        );
}


// =========================================================
// QUANTILE
// =========================================================

double VisualizationEngine::calculateQuantile(
    QVector<double> values,
    double quantile
    ) const
{
    if (values.isEmpty())
        return 0.0;

    if (!std::isfinite(quantile))
        return 0.0;

    if (quantile <= 0.0)
    {
        return *std::min_element(
            values.begin(),
            values.end()
            );
    }

    if (quantile >= 1.0)
    {
        return *std::max_element(
            values.begin(),
            values.end()
            );
    }

    std::sort(
        values.begin(),
        values.end()
        );

    const double position =
        quantile *
        static_cast<double>(
            values.size() - 1
            );

    const int lowerIndex =
        static_cast<int>(
            std::floor(position)
            );

    const int upperIndex =
        static_cast<int>(
            std::ceil(position)
            );

    if (lowerIndex == upperIndex)
        return values.at(lowerIndex);

    const double fraction =
        position -
        static_cast<double>(
            lowerIndex
            );

    return values.at(lowerIndex) +
           (
               values.at(upperIndex) -
               values.at(lowerIndex)
               ) *
               fraction;
}


// =========================================================
// PEARSON CORRELATION
// =========================================================

bool VisualizationEngine::calculatePearsonCorrelation(
    const ColumnInfo &firstColumn,
    const ColumnInfo &secondColumn,
    double *correlation
    ) const
{
    if (!correlation)
        return false;

    const QVector<QVariant> firstValues =
        firstColumn.values();

    const QVector<QVariant> secondValues =
        secondColumn.values();

    const int rowCount =
        std::min(
            firstValues.size(),
            secondValues.size()
            );

    QVector<double> xValues;
    QVector<double> yValues;

    for (int row = 0;
         row < rowCount;
         ++row)
    {
        double x = 0.0;
        double y = 0.0;

        if (!variantToFiniteDouble(
                firstValues.at(row),
                &x))
        {
            continue;
        }

        if (!variantToFiniteDouble(
                secondValues.at(row),
                &y))
        {
            continue;
        }

        xValues.append(x);
        yValues.append(y);
    }

    if (xValues.size() < 2)
        return false;

    double xTotal = 0.0;
    double yTotal = 0.0;

    for (int i = 0;
         i < xValues.size();
         ++i)
    {
        xTotal += xValues.at(i);
        yTotal += yValues.at(i);
    }

    const double xMean =
        xTotal /
        static_cast<double>(
            xValues.size()
            );

    const double yMean =
        yTotal /
        static_cast<double>(
            yValues.size()
            );

    double covarianceTotal = 0.0;
    double xSquaredTotal = 0.0;
    double ySquaredTotal = 0.0;

    for (int i = 0;
         i < xValues.size();
         ++i)
    {
        const double xDifference =
            xValues.at(i) -
            xMean;

        const double yDifference =
            yValues.at(i) -
            yMean;

        covarianceTotal +=
            xDifference *
            yDifference;

        xSquaredTotal +=
            xDifference *
            xDifference;

        ySquaredTotal +=
            yDifference *
            yDifference;
    }

    const double denominator =
        std::sqrt(
            xSquaredTotal *
            ySquaredTotal
            );

    if (!std::isfinite(denominator) ||
        denominator <= 0.0)
    {
        return false;
    }

    *correlation =
        covarianceTotal /
        denominator;

    if (!std::isfinite(*correlation))
        return false;

    if (*correlation > 1.0)
        *correlation = 1.0;

    if (*correlation < -1.0)
        *correlation = -1.0;

    return true;
}


// =========================================================
// VARIANT TO FINITE DOUBLE
// =========================================================

bool VisualizationEngine::variantToFiniteDouble(
    const QVariant &value,
    double *number
    ) const
{
    if (!number)
        return false;

    if (!value.isValid() ||
        value.isNull())
    {
        return false;
    }

    if (value.type() == QVariant::String &&
        value.toString().trimmed().isEmpty())
    {
        return false;
    }

    bool ok = false;

    const double converted =
        value.toDouble(
            &ok
            );

    if (!ok ||
        !std::isfinite(converted))
    {
        return false;
    }

    *number = converted;
    return true;
}