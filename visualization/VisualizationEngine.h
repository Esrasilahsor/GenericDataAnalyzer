#ifndef VISUALIZATIONENGINE_H
#define VISUALIZATIONENGINE_H

#include <QString>
#include <QStringList>
#include <QVector>

#include "../parser/DataSet.h"
#include "../parser/ColumnInfo.h"


// =========================================================
// HISTOGRAM RESULT
// =========================================================

struct HistogramResult
{
    bool success = false;

    QString columnName;
    QString errorMessage;

    int validValueCount = 0;
    int binCount = 0;

    double minimum = 0.0;
    double maximum = 0.0;
    double binWidth = 0.0;

    QVector<double> binLowerBounds;
    QVector<double> binUpperBounds;

    QVector<int> frequencies;
};


// =========================================================
// BOX PLOT RESULT
// =========================================================

struct BoxPlotResult
{
    bool success = false;

    QString columnName;
    QString errorMessage;

    int validValueCount = 0;

    double minimum = 0.0;
    double q1 = 0.0;
    double median = 0.0;
    double q3 = 0.0;
    double maximum = 0.0;

    double iqr = 0.0;

    double lowerBound = 0.0;
    double upperBound = 0.0;

    double lowerWhisker = 0.0;
    double upperWhisker = 0.0;

    int outlierCount = 0;

    QVector<double> outlierValues;
};


// =========================================================
// TIME SERIES RESULT
// =========================================================

struct TimeSeriesResult
{
    bool success = false;

    QString xColumnName;
    QString yColumnName;
    QString errorMessage;

    int pointCount = 0;

    QVector<double> xValues;
    QVector<double> yValues;
};


// =========================================================
// DISTRIBUTION RESULT
// =========================================================

struct DistributionResult
{
    bool success = false;

    QString columnName;
    QString errorMessage;

    int validValueCount = 0;
    int binCount = 0;

    QVector<double> centers;
    QVector<double> relativeFrequencies;
};


// =========================================================
// CORRELATION MATRIX RESULT
// =========================================================

struct CorrelationMatrixResult
{
    bool success = false;

    QString errorMessage;

    int columnCount = 0;

    QStringList columnNames;

    /*
     * Row-major flattened matrix.
     *
     * index = row * columnCount + column
     */
    QVector<double> values;
};


// =========================================================
// DATASET COMPARISON CHART RESULT (TREND / LINE)
// =========================================================

struct ComparisonChartResult
{
    bool success = false;

    QString sourceColumnName;
    QString targetColumnName;
    QString errorMessage;

    int pointCount = 0;

    QVector<double> indexes;
    QVector<double> sourceValues;
    QVector<double> targetValues;
};


// =========================================================
// DATASET COMPARISON DISTRIBUTION RESULT
// =========================================================

struct ComparisonDistributionResult
{
    bool success = false;

    QString sourceColumnName;
    QString targetColumnName;
    QString errorMessage;

    int sourceValidCount = 0;
    int targetValidCount = 0;
    int binCount = 0;

    double minimum = 0.0;
    double maximum = 0.0;
    double binWidth = 0.0;

    QVector<double> centers;
    QVector<double> sourceFrequencies;
    QVector<double> targetFrequencies;
    QVector<double> sourceDensities;
    QVector<double> targetDensities;
};


// =========================================================
// BAR CHART RESULT
// =========================================================

struct BarChartResult
{
    bool success = false;

    QString categoryColumnName;
    QString valueColumnName;
    QString aggregation; // Mean, Sum, Count, Min, Max
    QString errorMessage;

    int categoryCount = 0;

    QStringList labels;
    QVector<double> values;
};


// =========================================================
// VISUALIZATION ENGINE
// =========================================================

class VisualizationEngine
{
public:
    VisualizationEngine();


    // =====================================================
    // HISTOGRAM
    // =====================================================

    HistogramResult createHistogram(
        const DataSet &dataSet,
        const QString &columnName,
        int binCount = 10
        ) const;


    // =====================================================
    // BOX PLOT
    // =====================================================

    BoxPlotResult createBoxPlot(
        const DataSet &dataSet,
        const QString &columnName,
        double multiplier = 1.5
        ) const;


    // =====================================================
    // TIME SERIES
    // =====================================================

    TimeSeriesResult createTimeSeries(
        const DataSet &dataSet,
        const QString &xColumnName,
        const QString &yColumnName
        ) const;


    // =====================================================
    // DISTRIBUTION
    // =====================================================

    DistributionResult createDistribution(
        const DataSet &dataSet,
        const QString &columnName,
        int binCount = 10
        ) const;


    // =====================================================
    // CORRELATION MATRIX
    // =====================================================

    CorrelationMatrixResult createCorrelationMatrix(
        const DataSet &dataSet
        ) const;


    // =====================================================
    // DATASET COMPARISON CHART
    // =====================================================

    // =====================================================
    // DATASET COMPARISON CHART (TREND / LINE)
    // =====================================================

    ComparisonChartResult createComparisonChart(
        const DataSet &sourceDataSet,
        const QString &sourceColumnName,
        const DataSet &targetDataSet,
        const QString &targetColumnName
        ) const;


    // =====================================================
    // DATASET COMPARISON DISTRIBUTION
    // =====================================================

    ComparisonDistributionResult createComparisonDistribution(
        const DataSet &sourceDataSet,
        const QString &sourceColumnName,
        const DataSet &targetDataSet,
        const QString &targetColumnName,
        int binCount = 25
        ) const;


    // =====================================================
    // BAR CHART (Category + Value + Aggregation)
    // =====================================================

    BarChartResult createBarChart(
        const DataSet &dataSet,
        const QString &categoryColumnName,
        const QString &valueColumnName,
        const QString &aggregation = QStringLiteral("Mean")
        ) const;


private:

    // =====================================================
    // COLUMN FIND
    // =====================================================

    const ColumnInfo *findColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;


    // =====================================================
    // NUMERIC EXTRACTION
    // =====================================================

    QVector<double> extractNumericValues(
        const ColumnInfo &column
        ) const;


    // =====================================================
    // BASIC CALCULATIONS
    // =====================================================

    double calculateMedian(
        QVector<double> values
        ) const;

    double calculateQuantile(
        QVector<double> values,
        double quantile
        ) const;


    // =====================================================
    // CORRELATION
    // =====================================================

    bool calculatePearsonCorrelation(
        const ColumnInfo &firstColumn,
        const ColumnInfo &secondColumn,
        double *correlation
        ) const;


    // =====================================================
    // VALUE HELPERS
    // =====================================================

    bool variantToFiniteDouble(
        const QVariant &value,
        double *number
        ) const;
};


#endif // VISUALIZATIONENGINE_H