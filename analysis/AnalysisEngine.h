#ifndef ANALYSISENGINE_H
#define ANALYSISENGINE_H

#include <QString>

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
// İKİ SÜTUN KARŞILAŞTIRMA SONUCU
// =========================================================

struct ColumnComparisonResult
{
    bool success = false;

    QString sourceColumnName;
    QString targetColumnName;

    QString errorMessage;

    // Dataset 1 istatistikleri
    StatisticsResult sourceStatistics;

    // Dataset 2 istatistikleri
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
// ANALYSIS ENGINE
// =========================================================

class AnalysisEngine
{
public:
    AnalysisEngine();

    // -----------------------------------------------------
    // TEK SÜTUN ANALİZİ
    // -----------------------------------------------------

    ColumnAnalysisResult analyzeColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;


    // -----------------------------------------------------
    // İKİ DATASET ARASINDA SÜTUN KARŞILAŞTIRMA
    // -----------------------------------------------------

    ColumnComparisonResult compareColumns(
        const DataSet &sourceDataSet,
        const QString &sourceColumnName,

        const DataSet &targetDataSet,
        const QString &targetColumnName
        ) const;


private:

    // -----------------------------------------------------
    // SÜTUN BULMA
    // -----------------------------------------------------

    const ColumnInfo *findColumn(
        const DataSet &dataSet,
        const QString &columnName
        ) const;


    // -----------------------------------------------------
    // NUMERIC KONTROL
    // -----------------------------------------------------

    bool isColumnNumeric(
        const ColumnInfo &column
        ) const;


    // -----------------------------------------------------
    // STATISTICS ENGINE
    // -----------------------------------------------------

    Statistics m_statistics;
};

#endif // ANALYSISENGINE_H