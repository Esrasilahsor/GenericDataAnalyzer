#include "Statistics.h"

#include <algorithm>
#include <cmath>


Statistics::Statistics()
{
}


// =========================================================
// BASIC STATISTICS
// =========================================================

StatisticsResult Statistics::calculate(
    const QVector<QVariant> &values
    ) const
{
    StatisticsResult result;

    const QVector<double> numericValues =
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


    const auto minMax =
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


// =========================================================
// IQR OUTLIER ANALYSIS
// =========================================================

IqrOutlierResult Statistics::calculateIqrOutliers(
    const QVector<QVariant> &values,
    double multiplier
    ) const
{
    IqrOutlierResult result;


    // -----------------------------------------------------
    // MULTIPLIER CHECK
    // -----------------------------------------------------

    if (!std::isfinite(multiplier) ||
        multiplier <= 0.0)
    {
        result.errorMessage =
            QStringLiteral(
                "IQR multiplier must be a positive finite number."
                );

        return result;
    }


    // -----------------------------------------------------
    // NUMERIC VALUES
    // -----------------------------------------------------

    const QVector<double> numericValues =
        extractNumericValues(
            values
            );


    result.validValueCount =
        numericValues.size();


    /*
     * IQR hesabı teknik olarak daha az değerle de
     * yapılabilir fakat outlier analizi açısından
     * çok küçük örneklem güvenilir değildir.
     *
     * En az 4 geçerli numeric değer istiyoruz.
     */
    if (numericValues.size() < 4)
    {
        result.errorMessage =
            QStringLiteral(
                "At least 4 valid numeric values are required for IQR outlier analysis."
                );

        return result;
    }


    // -----------------------------------------------------
    // QUARTILES
    // -----------------------------------------------------

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


    // -----------------------------------------------------
    // IQR VALIDATION
    // -----------------------------------------------------

    if (!std::isfinite(result.iqr) ||
        result.iqr < 0.0)
    {
        result.errorMessage =
            QStringLiteral(
                "Invalid IQR value was calculated."
                );

        return result;
    }


    // -----------------------------------------------------
    // BOUNDS
    // -----------------------------------------------------

    result.lowerBound =
        result.q1
        -
        multiplier
            *
            result.iqr;


    result.upperBound =
        result.q3
        +
        multiplier
            *
            result.iqr;


    if (!std::isfinite(result.lowerBound) ||
        !std::isfinite(result.upperBound))
    {
        result.errorMessage =
            QStringLiteral(
                "IQR outlier bounds are not finite."
                );

        return result;
    }


    // -----------------------------------------------------
    // OUTLIER DETECTION
    // -----------------------------------------------------

    for (double value : numericValues)
    {
        if (value < result.lowerBound ||
            value > result.upperBound)
        {
            result.outlierValues.append(
                value
                );
        }
    }


    result.outlierCount =
        result.outlierValues.size();


    if (result.validValueCount > 0)
    {
        result.outlierPercentage =
            (
                static_cast<double>(
                    result.outlierCount
                    )
                /
                static_cast<double>(
                    result.validValueCount
                    )
                )
            *
            100.0;
    }


    result.success =
        true;


    return result;
}


// =========================================================
// NUMERIC EXTRACTION
// =========================================================

QVector<double> Statistics::extractNumericValues(
    const QVector<QVariant> &values
    ) const
{
    QVector<double> numericValues;

    numericValues.reserve(
        values.size()
        );


    for (const QVariant &value :
         values)
    {
        if (!value.isValid() ||
            value.isNull())
        {
            continue;
        }


        bool ok = false;


        const double numericValue =
            value.toDouble(
                &ok
                );


        /*
         * QVariant dönüşmüş olsa bile NaN / INF
         * kabul etmiyoruz.
         */
        if (!ok ||
            !std::isfinite(numericValue))
        {
            continue;
        }


        numericValues.append(
            numericValue
            );
    }


    return numericValues;
}


// =========================================================
// MEAN
// =========================================================

double Statistics::calculateMean(
    const QVector<double> &values
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }


    double total =
        0.0;


    for (double value :
         values)
    {
        total +=
            value;
    }


    return total
           /
           static_cast<double>(
               values.size()
               );
}


// =========================================================
// MEDIAN
// =========================================================

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


    const int size =
        values.size();


    const int middleIndex =
        size / 2;


    if (size % 2 == 0)
    {
        return (
                   values[middleIndex - 1]
                   +
                   values[middleIndex]
                   )
               /
               2.0;
    }


    return values[middleIndex];
}


// =========================================================
// VARIANCE
// =========================================================

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


    for (double value :
         values)
    {
        const double difference =
            value
            -
            mean;


        totalSquaredDifference +=
            difference
            *
            difference;
    }


    /*
     * Population variance:
     *
     * variance = sum / N
     */
    return totalSquaredDifference
           /
           static_cast<double>(
               values.size()
               );
}


// =========================================================
// STANDARD DEVIATION
// =========================================================

double Statistics::calculateStandardDeviation(
    double variance
    ) const
{
    if (!std::isfinite(variance) ||
        variance < 0.0)
    {
        return 0.0;
    }


    return std::sqrt(
        variance
        );
}


// =========================================================
// QUANTILE
// =========================================================

double Statistics::calculateQuantile(
    QVector<double> values,
    double quantile
    ) const
{
    if (values.isEmpty())
    {
        return 0.0;
    }


    if (!std::isfinite(quantile))
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


    const double position =
        quantile
        *
        static_cast<double>(
            values.size() - 1
            );


    const int lowerIndex =
        static_cast<int>(
            std::floor(
                position
                )
            );


    const int upperIndex =
        static_cast<int>(
            std::ceil(
                position
                )
            );


    if (lowerIndex == upperIndex)
    {
        return values.at(
            lowerIndex
            );
    }


    const double fraction =
        position
        -
        static_cast<double>(
            lowerIndex
            );


    return values.at(
               lowerIndex
               )
           +
           (
               values.at(
                   upperIndex
                   )
               -
               values.at(
                   lowerIndex
                   )
               )
               *
               fraction;
}