#ifndef ANALYSISENGINE_H
#define ANALYSISENGINE_H

#include <QString>
#include <QStringList>
#include <QVector>

#include "../parser/DataSet.h"
#include "../parser/ColumnInfo.h"

#include "Statistics.h"


// =========================================================
// TEK SÜTUN ANALİZ SONUCU
// =========================================================

struct ColumnAnalysisResult
{
    bool success = false;

    QString columnName;
    QString errorMessage;

    StatisticsResult statistics;
};


// =========================================================
// TEK SÜTUN OUTLIER ANALİZ SONUCU
// =========================================================

struct ColumnOutlierAnalysisResult
{
    bool success = false;

    QString columnName;
    QString errorMessage;

    IqrOutlierResult outlierResult;
};


// =========================================================
// İKİ SÜTUN KARŞILAŞTIRMA SONUCU
// =========================================================

struct ColumnComparisonResult
{
    bool success = false;

    QString sourceColumnName;
    QString targetColumnName;

    QString errorMessage;

    StatisticsResult sourceStatistics;
    StatisticsResult targetStatistics;

    // Dataset 2 - Dataset 1

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


// =========================================================
// DATASET QUALITY SONUCU
// =========================================================

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


// =========================================================
// ANALYSIS ENGINE
// =========================================================

class AnalysisEngine
{
public:

    AnalysisEngine();


    // =====================================================
    // TEK SÜTUN ANALİZİ
    // =====================================================

    ColumnAnalysisResult analyzeColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;


    // =====================================================
    // IQR OUTLIER ANALİZİ
    // =====================================================

    ColumnOutlierAnalysisResult analyzeColumnOutliers(
        const DataSet &dataSet,
        const QString &columnName,
        double multiplier = 1.5
        ) const;


    // =====================================================
    // İKİ SÜTUN KARŞILAŞTIRMA
    // =====================================================

    ColumnComparisonResult compareColumns(
        const DataSet &sourceDataSet,
        const QString &sourceColumnName,

        const DataSet &targetDataSet,
        const QString &targetColumnName
        ) const;


    // =====================================================
    // DATA QUALITY
    // =====================================================

    DatasetQualityResult analyzeDataQuality(
        const DataSet &dataSet
        ) const;


    // =====================================================
    // DUPLICATE SATIR INDEXLERİ
    // =====================================================

    QVector<int> findDuplicateRowIndexes(
        const DataSet &dataSet
        ) const;


    // =====================================================
    // MISSING SATIR INDEXLERİ
    //
    // Satırdaki herhangi bir sütunda missing varsa
    // ilgili satır indexi döndürülür.
    // =====================================================

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