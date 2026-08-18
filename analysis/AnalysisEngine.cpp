#include "AnalysisEngine.h"

// =========================================================
// CONSTRUCTOR
// =========================================================

AnalysisEngine::AnalysisEngine()
{
}


// =========================================================
// TEK SÜTUN ANALİZİ
// =========================================================

ColumnAnalysisResult AnalysisEngine::analyzeColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    ColumnAnalysisResult result;

    result.columnName = columnName;

    // -----------------------------------------------------
    // Sütunu bul
    // -----------------------------------------------------

    const ColumnInfo *column =
        findColumn(
            dataSet,
            columnName
            );

    if (!column)
    {
        result.success = false;
        result.errorMessage =
            "Column not found.";

        return result;
    }

    // -----------------------------------------------------
    // Numeric kontrolü
    // -----------------------------------------------------

    if (!isColumnNumeric(*column))
    {
        result.success = false;
        result.errorMessage =
            "Column is not numeric.";

        return result;
    }

    // -----------------------------------------------------
    // İstatistikleri hesapla
    // -----------------------------------------------------

    result.statistics =
        m_statistics.calculate(
            column->values()
            );

    result.success = true;

    return result;
}


// =========================================================
// İKİ SÜTUN KARŞILAŞTIRMA
// =========================================================

ColumnComparisonResult AnalysisEngine::compareColumns(
    const DataSet &sourceDataSet,
    const QString &sourceColumnName,

    const DataSet &targetDataSet,
    const QString &targetColumnName
    ) const
{
    ColumnComparisonResult result;

    result.sourceColumnName =
        sourceColumnName;

    result.targetColumnName =
        targetColumnName;

    // -----------------------------------------------------
    // DATASET 1 SÜTUNUNU BUL
    // -----------------------------------------------------

    const ColumnInfo *sourceColumn =
        findColumn(
            sourceDataSet,
            sourceColumnName
            );

    if (!sourceColumn)
    {
        result.success = false;

        result.errorMessage =
            "Dataset 1 column not found.";

        return result;
    }

    // -----------------------------------------------------
    // DATASET 2 SÜTUNUNU BUL
    // -----------------------------------------------------

    const ColumnInfo *targetColumn =
        findColumn(
            targetDataSet,
            targetColumnName
            );

    if (!targetColumn)
    {
        result.success = false;

        result.errorMessage =
            "Dataset 2 column not found.";

        return result;
    }

    // -----------------------------------------------------
    // DATASET 1 NUMERIC KONTROLÜ
    // -----------------------------------------------------

    if (!isColumnNumeric(*sourceColumn))
    {
        result.success = false;

        result.errorMessage =
            "Dataset 1 column is not numeric.";

        return result;
    }

    // -----------------------------------------------------
    // DATASET 2 NUMERIC KONTROLÜ
    // -----------------------------------------------------

    if (!isColumnNumeric(*targetColumn))
    {
        result.success = false;

        result.errorMessage =
            "Dataset 2 column is not numeric.";

        return result;
    }

    // -----------------------------------------------------
    // DATASET 1 İSTATİSTİKLERİ
    // -----------------------------------------------------

    result.sourceStatistics =
        m_statistics.calculate(
            sourceColumn->values()
            );

    // -----------------------------------------------------
    // DATASET 2 İSTATİSTİKLERİ
    // -----------------------------------------------------

    result.targetStatistics =
        m_statistics.calculate(
            targetColumn->values()
            );

    // -----------------------------------------------------
    // VERİ KONTROLÜ
    // -----------------------------------------------------

    if (result.sourceStatistics.count == 0)
    {
        result.success = false;

        result.errorMessage =
            "Dataset 1 column does not contain numeric values.";

        return result;
    }

    if (result.targetStatistics.count == 0)
    {
        result.success = false;

        result.errorMessage =
            "Dataset 2 column does not contain numeric values.";

        return result;
    }

    // =====================================================
    // DIFFERENCES
    //
    // Her zaman:
    //
    // Dataset 2 - Dataset 1
    // =====================================================

    result.meanDifference =
        result.targetStatistics.mean
        -
        result.sourceStatistics.mean;

    result.medianDifference =
        result.targetStatistics.median
        -
        result.sourceStatistics.median;

    result.minimumDifference =
        result.targetStatistics.minimum
        -
        result.sourceStatistics.minimum;

    result.maximumDifference =
        result.targetStatistics.maximum
        -
        result.sourceStatistics.maximum;

    result.rangeDifference =
        result.targetStatistics.range
        -
        result.sourceStatistics.range;

    result.varianceDifference =
        result.targetStatistics.variance
        -
        result.sourceStatistics.variance;

    result.standardDeviationDifference =
        result.targetStatistics.standardDeviation
        -
        result.sourceStatistics.standardDeviation;

    result.q1Difference =
        result.targetStatistics.q1
        -
        result.sourceStatistics.q1;

    result.q3Difference =
        result.targetStatistics.q3
        -
        result.sourceStatistics.q3;

    result.iqrDifference =
        result.targetStatistics.iqr
        -
        result.sourceStatistics.iqr;

    // -----------------------------------------------------
    // BAŞARILI
    // -----------------------------------------------------

    result.success = true;

    return result;
}


// =========================================================
// SÜTUN BULMA
// =========================================================

const ColumnInfo *AnalysisEngine::findColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    return dataSet.findColumn(
        columnName
        );
}


// =========================================================
// NUMERIC KONTROL
// =========================================================

bool AnalysisEngine::isColumnNumeric(
    const ColumnInfo &column
    ) const
{
    return column.isNumeric();
}