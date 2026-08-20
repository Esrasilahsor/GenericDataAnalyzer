#ifndef STATISTICS_H
#define STATISTICS_H

#include <QVector>
#include <QVariant>


// =========================================================
// BASIC STATISTICS RESULT
// =========================================================

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


// =========================================================
// IQR OUTLIER RESULT
// =========================================================

struct IqrOutlierResult
{
    bool success = false;

    QString errorMessage;

    int validValueCount = 0;

    double q1 = 0.0;
    double q3 = 0.0;
    double iqr = 0.0;

    double lowerBound = 0.0;
    double upperBound = 0.0;

    int outlierCount = 0;
    double outlierPercentage = 0.0;

    /*
     * Outlier olan orijinal değerleri tutuyoruz.
     *
     * Şimdilik sadece analiz için kullanacağız.
     * Cleaning fazında index bilgisi de ekleyeceğiz.
     */
    QVector<double> outlierValues;
};


// =========================================================
// STATISTICS
// =========================================================

class Statistics
{
public:
    Statistics();

    // =====================================================
    // BASIC STATISTICS
    // =====================================================

    StatisticsResult calculate(
        const QVector<QVariant> &values
        ) const;


    // =====================================================
    // IQR OUTLIER ANALYSIS
    // =====================================================

    IqrOutlierResult calculateIqrOutliers(
        const QVector<QVariant> &values,
        double multiplier = 1.5
        ) const;


private:

    // =====================================================
    // NUMERIC EXTRACTION
    // =====================================================

    QVector<double> extractNumericValues(
        const QVector<QVariant> &values
        ) const;


    // =====================================================
    // BASIC CALCULATIONS
    // =====================================================

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