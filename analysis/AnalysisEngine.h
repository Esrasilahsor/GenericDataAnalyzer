#ifndef ANALYSISENGINE_H
#define ANALYSISENGINE_H

#include <QString>
#include <QStringList>
#include <QVector>
#include <QVariant>

#include "../parser/DataSet.h"
#include "../parser/ColumnInfo.h"
#include "Statistics.h"

struct ColumnAnalysisResult
{
    bool success = false;
    QString columnName;
    QString errorMessage;
    StatisticsResult statistics;
};

struct ColumnOutlierAnalysisResult
{
    bool success = false;
    QString columnName;
    QString errorMessage;
    IqrOutlierResult outlierResult;
};

struct ZScoreOutlierResult
{
    bool success = false;
    QString columnName;
    QString errorMessage;

    int validValueCount = 0;
    double mean = 0.0;
    double standardDeviation = 0.0;
    double threshold = 3.0;

    int outlierCount = 0;
    double outlierPercentage = 0.0;

    QVector<double> outlierValues;
    QVector<int> outlierRowIndexes;
};

struct ColumnComparisonResult
{
    bool success = false;

    QString sourceColumnName;
    QString targetColumnName;
    QString errorMessage;

    StatisticsResult sourceStatistics;
    StatisticsResult targetStatistics;

    double meanDifference = 0.0;
    double medianDifference = 0.0;
    double minimumDifference = 0.0;
    double maximumDifference = 0.0;
    double rangeDifference = 0.0;
    double varianceDifference = 0.0;
    double standardDeviationDifference = 0.0;
    double q1Difference = 0.0;
    double q3Difference = 0.0;
    double iqrDifference = 0.0;
};

struct DatasetQualityResult
{
    bool success = false;
    QString errorMessage;

    int rowCount = 0;
    int columnCount = 0;

    int totalMissingValues = 0;
    double missingPercentage = 0.0;
    int columnsWithMissingValues = 0;

    int duplicateRowCount = 0;
    double duplicatePercentage = 0.0;

    int constantColumnCount = 0;
    int numericColumnCount = 0;
    int nonNumericColumnCount = 0;

    QStringList columnsWithMissing;
    QStringList constantColumns;
};

class AnalysisEngine
{
public:
    AnalysisEngine();

    ColumnAnalysisResult analyzeColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;

    ColumnOutlierAnalysisResult analyzeColumnOutliers(
        const DataSet &dataSet,
        const QString &columnName,
        double multiplier = 1.5
        ) const;

    ZScoreOutlierResult analyzeColumnZScoreOutliers(
        const DataSet &dataSet,
        const QString &columnName,
        double threshold = 3.0
        ) const;

    QVector<int> findIqrOutlierRowIndexes(
        const DataSet &dataSet,
        const QString &columnName,
        double multiplier = 1.5
        ) const;

    QVector<int> findZScoreOutlierRowIndexes(
        const DataSet &dataSet,
        const QString &columnName,
        double threshold = 3.0
        ) const;

    ColumnComparisonResult compareColumns(
        const DataSet &sourceDataSet,
        const QString &sourceColumnName,
        const DataSet &targetDataSet,
        const QString &targetColumnName
        ) const;

    DatasetQualityResult analyzeDataQuality(
        const DataSet &dataSet
        ) const;

    QVector<int> findDuplicateRowIndexes(
        const DataSet &dataSet
        ) const;

    QVector<int> findRowsWithMissingValues(
        const DataSet &dataSet
        ) const;

private:
    const ColumnInfo *findColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;

    bool isColumnNumeric(
        const ColumnInfo &column
        ) const;

    int calculateDuplicateRowCount(
        const DataSet &dataSet
        ) const;

    bool isMissingValue(
        const QVariant &value
        ) const;

    Statistics m_statistics;
};

#endif // ANALYSISENGINE_H