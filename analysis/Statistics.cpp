#include "Statistics.h"

#include <algorithm>
#include <cmath>

Statistics::Statistics()
{
}

StatisticsResult Statistics::calculate(
    const QVector<QVariant> &values
    ) const
{
    StatisticsResult result;

    QVector<double> numericValues =
        extractNumericValues(values);

    if (numericValues.isEmpty())
    {
        return result;
    }

    result.count =
        numericValues.size();

    result.mean =
        calculateMean(
            numericValues
            );

    result.median =
        calculateMedian(
            numericValues
            );

    auto minMax =
        std::minmax_element(
            numericValues.begin(),
            numericValues.end()
            );

    result.minimum =
        *minMax.first;

    result.maximum =
        *minMax.second;

    result.range =
        result.maximum
        -
        result.minimum;

    result.variance =
        calculateVariance(
            numericValues,
            result.mean
            );

    result.standardDeviation =
        calculateStandardDeviation(
            result.variance
            );

    result.q1 =
        calculateQuantile(
            numericValues,
            0.25
            );

    result.q3 =
        calculateQuantile(
            numericValues,
            0.75
            );

    result.iqr =
        result.q3
        -
        result.q1;

    return result;
}

QVector<double> Statistics::extractNumericValues(
    const QVector<QVariant> &values
    ) const
{
    QVector<double> numericValues;

    for (const QVariant &value : values)
    {
        if (!value.isValid() || value.isNull())
        {
            continue;
        }

        bool ok = false;

        double numericValue =
            value.toDouble(&ok);

        if (ok)
        {
            numericValues.append(
                numericValue
                );
        }
    }

    return numericValues;
}

double Statistics::calculateMean(
    const QVector<double> &values
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }

    double total = 0.0;

    for (double value : values)
    {
        total += value;
    }

    return total
           /
           static_cast<double>(
               values.size()
               );
}

double Statistics::calculateMedian(
    QVector<double> values
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }

    std::sort(
        values.begin(),
        values.end()
        );

    int size =
        values.size();

    int middleIndex =
        size / 2;

    if (size % 2 == 0)
    {
        return (
                   values[middleIndex - 1]
                   +
                   values[middleIndex]
                   ) / 2.0;
    }

    return values[middleIndex];
}

double Statistics::calculateVariance(
    const QVector<double> &values,
    double mean
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }

    double totalSquaredDifference =
        0.0;

    for (double value : values)
    {
        double difference =
            value - mean;

        totalSquaredDifference +=
            difference * difference;
    }

    /*
     * Şimdilik population variance kullanıyoruz.
     *
     * Yani:
     *
     * variance =
     * toplam karesel fark / N
     */
    return totalSquaredDifference
           /
           static_cast<double>(
               values.size()
               );
}

double Statistics::calculateStandardDeviation(
    double variance
    ) const
{
    if (variance < 0.0)
    {
        return 0.0;
    }

    return std::sqrt(
        variance
        );
}

double Statistics::calculateQuantile(
    QVector<double> values,
    double quantile
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }

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

    double position =
        quantile
        *
        static_cast<double>(
            values.size() - 1
            );

    int lowerIndex =
        static_cast<int>(
            std::floor(position)
            );

    int upperIndex =
        static_cast<int>(
            std::ceil(position)
            );

    if (lowerIndex == upperIndex)
    {
        return values[lowerIndex];
    }

    double fraction =
        position
        -
        static_cast<double>(
            lowerIndex
            );

    return values[lowerIndex]
           +
           (
               values[upperIndex]
               -
               values[lowerIndex]
               )
               * fraction;
}