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
// CREATE DATASET COMPARISON DISTRIBUTION
// =========================================================

ComparisonDistributionResult VisualizationEngine::createComparisonDistribution(
    const DataSet &sourceDataSet,
    const QString &sourceColumnName,
    const DataSet &targetDataSet,
    const QString &targetColumnName,
    int binCount
    ) const
{
    ComparisonDistributionResult result;

    result.sourceColumnName = sourceColumnName.trimmed();
    result.targetColumnName = targetColumnName.trimmed();

    if (sourceDataSet.isEmpty() || targetDataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Comparison dataset is empty.");
        return result;
    }

    const ColumnInfo *sourceColumn = findColumn(sourceDataSet, result.sourceColumnName);
    const ColumnInfo *targetColumn = findColumn(targetDataSet, result.targetColumnName);

    if (!sourceColumn || !targetColumn)
    {
        result.errorMessage = QStringLiteral("Comparison column was not found.");
        return result;
    }

    if (!sourceColumn->isNumeric() || !targetColumn->isNumeric())
    {
        result.errorMessage = QStringLiteral("Comparison distribution requires numeric columns.");
        return result;
    }

    const QVector<double> sourceValues = extractNumericValues(*sourceColumn);
    const QVector<double> targetValues = extractNumericValues(*targetColumn);

    result.sourceValidCount = sourceValues.size();
    result.targetValidCount = targetValues.size();

    if (result.sourceValidCount <= 0 && result.targetValidCount <= 0)
    {
        result.errorMessage = QStringLiteral("No valid numeric values found for distribution comparison.");
        return result;
    }

    double globalMin = 0.0;
    double globalMax = 0.0;
    bool hasMinMax = false;

    if (!sourceValues.isEmpty())
    {
        double min1 = sourceValues.at(0);
        double max1 = sourceValues.at(0);
        for (double v : sourceValues)
        {
            if (v < min1) min1 = v;
            if (v > max1) max1 = v;
        }
        globalMin = min1;
        globalMax = max1;
        hasMinMax = true;
    }

    if (!targetValues.isEmpty())
    {
        double min2 = targetValues.at(0);
        double max2 = targetValues.at(0);
        for (double v : targetValues)
        {
            if (v < min2) min2 = v;
            if (v > max2) max2 = v;
        }
        if (hasMinMax)
        {
            globalMin = std::min(globalMin, min2);
            globalMax = std::max(globalMax, max2);
        }
        else
        {
            globalMin = min2;
            globalMax = max2;
            hasMinMax = true;
        }
    }

    if (globalMin == globalMax)
    {
        globalMin -= 1.0;
        globalMax += 1.0;
    }

    const int actualBinCount = std::max(5, std::min(binCount, 100));
    const double binWidth = (globalMax - globalMin) / static_cast<double>(actualBinCount);

    result.binCount = actualBinCount;
    result.minimum = globalMin;
    result.maximum = globalMax;
    result.binWidth = binWidth;

    result.centers.resize(actualBinCount);
    result.sourceFrequencies.resize(actualBinCount);
    result.targetFrequencies.resize(actualBinCount);
    result.sourceDensities.resize(actualBinCount);
    result.targetDensities.resize(actualBinCount);

    for (int i = 0; i < actualBinCount; ++i)
    {
        result.centers[i] = globalMin + (static_cast<double>(i) + 0.5) * binWidth;
        result.sourceFrequencies[i] = 0.0;
        result.targetFrequencies[i] = 0.0;
        result.sourceDensities[i] = 0.0;
        result.targetDensities[i] = 0.0;
    }

    for (double v : sourceValues)
    {
        int binIndex = static_cast<int>((v - globalMin) / binWidth);
        if (binIndex < 0) binIndex = 0;
        if (binIndex >= actualBinCount) binIndex = actualBinCount - 1;
        result.sourceFrequencies[binIndex] += 1.0;
    }

    for (double v : targetValues)
    {
        int binIndex = static_cast<int>((v - globalMin) / binWidth);
        if (binIndex < 0) binIndex = 0;
        if (binIndex >= actualBinCount) binIndex = actualBinCount - 1;
        result.targetFrequencies[binIndex] += 1.0;
    }

    for (int i = 0; i < actualBinCount; ++i)
    {
        if (result.sourceValidCount > 0)
        {
            result.sourceDensities[i] = result.sourceFrequencies[i] / static_cast<double>(result.sourceValidCount);
        }
        if (result.targetValidCount > 0)
        {
            result.targetDensities[i] = result.targetFrequencies[i] / static_cast<double>(result.targetValidCount);
        }
    }

    result.success = true;
    return result;
}


// =========================================================
// CREATE BAR CHART
// =========================================================

BarChartResult VisualizationEngine::createBarChart(
    const DataSet &dataSet,
    const QString &categoryColumnName,
    const QString &valueColumnName,
    const QString &aggregation
    ) const
{
    BarChartResult result;

    result.categoryColumnName = categoryColumnName.trimmed();
    result.valueColumnName = valueColumnName.trimmed();
    result.aggregation = aggregation.trimmed();
    if (result.aggregation.isEmpty())
    {
        result.aggregation = QStringLiteral("Mean");
    }

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (result.categoryColumnName.isEmpty())
    {
        result.errorMessage = QStringLiteral("Category column name is empty.");
        return result;
    }

    const ColumnInfo *categoryColumn = findColumn(dataSet, result.categoryColumnName);
    if (!categoryColumn)
    {
        result.errorMessage = QStringLiteral("Category column was not found.");
        return result;
    }

    const bool isCount = (result.aggregation.compare(QLatin1String("Count"), Qt::CaseInsensitive) == 0 ||
                          result.aggregation.compare(QLatin1String("Sayım"), Qt::CaseInsensitive) == 0);

    const ColumnInfo *valueColumn = nullptr;
    if (!result.valueColumnName.isEmpty())
    {
        valueColumn = findColumn(dataSet, result.valueColumnName);
    }

    if (!isCount)
    {
        if (result.valueColumnName.isEmpty())
        {
            result.errorMessage = QStringLiteral("Value column is required for aggregation.");
            return result;
        }

        if (!valueColumn)
        {
            result.errorMessage = QStringLiteral("Value column was not found.");
            return result;
        }

        if (!valueColumn->isNumeric())
        {
            result.errorMessage = QStringLiteral("Value column must be numeric.");
            return result;
        }
    }

    const QVector<QVariant> catRawValues = categoryColumn->values();
    const QVector<QVariant> valRawValues = valueColumn ? valueColumn->values() : QVector<QVariant>();
    const int rowCount = catRawValues.size();

    QVector<QString> categoryList;
    QHash<QString, QVector<double>> groupedValues;

    for (int row = 0; row < rowCount; ++row)
    {
        const QVariant &catVar = catRawValues.at(row);
        if (!catVar.isValid() || catVar.isNull())
        {
            continue;
        }

        const QString catLabel = catVar.toString().trimmed();
        if (catLabel.isEmpty())
        {
            continue;
        }

        if (!groupedValues.contains(catLabel))
        {
            // Limit to at most 100 distinct categories to prevent UI overload
            if (categoryList.size() >= 100)
            {
                continue;
            }
            categoryList.append(catLabel);
        }

        if (isCount)
        {
            if (valueColumn && row < valRawValues.size())
            {
                double dummy = 0.0;
                if (variantToFiniteDouble(valRawValues.at(row), &dummy))
                {
                    groupedValues[catLabel].append(1.0);
                }
            }
            else
            {
                groupedValues[catLabel].append(1.0);
            }
        }
        else
        {
            if (row < valRawValues.size())
            {
                double numVal = 0.0;
                if (variantToFiniteDouble(valRawValues.at(row), &numVal))
                {
                    groupedValues[catLabel].append(numVal);
                }
            }
        }
    }

    for (const QString &cat : categoryList)
    {
        const QVector<double> &vals = groupedValues.value(cat);
        if (vals.isEmpty())
        {
            continue;
        }

        double aggVal = 0.0;
        if (result.aggregation.compare(QLatin1String("Sum"), Qt::CaseInsensitive) == 0 ||
            result.aggregation.compare(QLatin1String("Toplam"), Qt::CaseInsensitive) == 0)
        {
            double sum = 0.0;
            for (double v : vals) sum += v;
            aggVal = sum;
        }
        else if (isCount)
        {
            aggVal = static_cast<double>(vals.size());
        }
        else if (result.aggregation.compare(QLatin1String("Min"), Qt::CaseInsensitive) == 0 ||
                 result.aggregation.compare(QLatin1String("Minimum"), Qt::CaseInsensitive) == 0)
        {
            double minV = vals.first();
            for (double v : vals) if (v < minV) minV = v;
            aggVal = minV;
        }
        else if (result.aggregation.compare(QLatin1String("Max"), Qt::CaseInsensitive) == 0 ||
                 result.aggregation.compare(QLatin1String("Maksimum"), Qt::CaseInsensitive) == 0)
        {
            double maxV = vals.first();
            for (double v : vals) if (v > maxV) maxV = v;
            aggVal = maxV;
        }
        else
        {
            // Default: Mean (Average)
            double sum = 0.0;
            for (double v : vals) sum += v;
            aggVal = sum / vals.size();
        }

        result.labels.append(cat);
        result.values.append(aggVal);
    }

    result.categoryCount = result.labels.size();

    if (result.categoryCount <= 0)
    {
        result.errorMessage = QStringLiteral("No valid data found for bar chart aggregation.");
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