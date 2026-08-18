#ifndef STATISTICS_H
#define STATISTICS_H

#include <QVector>
#include <QVariant>

struct StatisticsResult
{
    int count = 0;

    double mean = 0.0;
    double median = 0.0;

    double minimum = 0.0;
    double maximum = 0.0;
    double range = 0.0;

    double variance = 0.0;
    double standardDeviation = 0.0;

    double q1 = 0.0;
    double q3 = 0.0;
    double iqr = 0.0;
};

class Statistics
{
public:
    Statistics();

    StatisticsResult calculate(
        const QVector<QVariant> &values
        ) const;

private:
    QVector<double> extractNumericValues(
        const QVector<QVariant> &values
        ) const;

    double calculateMean(
        const QVector<double> &values
        ) const;

    double calculateMedian(
        QVector<double> values
        ) const;

    double calculateVariance(
        const QVector<double> &values,
        double mean
        ) const;

    double calculateStandardDeviation(
        double variance
        ) const;

    double calculateQuantile(
        QVector<double> values,
        double quantile
        ) const;
};

#endif // STATISTICS_H