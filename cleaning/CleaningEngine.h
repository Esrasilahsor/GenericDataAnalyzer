#ifndef CLEANINGENGINE_H
#define CLEANINGENGINE_H

#include <QString>
#include <QVariantMap>

#include "../parser/DataSet.h"
#include "../analysis/AnalysisEngine.h"


struct CleaningResult
{
    bool success = false;
    bool modified = false;

    QString errorMessage;
    QString message;

    QVariantMap details;
};


class CleaningEngine
{
public:
    CleaningEngine();

    // =====================================================
    // ROW CLEANING
    // =====================================================

    CleaningResult removeDuplicateRows(
        DataSet &dataSet
        ) const;

    CleaningResult removeRowsWithMissingValues(
        DataSet &dataSet
        ) const;


    // =====================================================
    // MISSING VALUE CLEANING
    // =====================================================

    CleaningResult fillMissingWithMean(
        DataSet &dataSet,
        const QString &columnName
        ) const;

    CleaningResult fillMissingWithMedian(
        DataSet &dataSet,
        const QString &columnName
        ) const;

    CleaningResult fillMissingWithMode(
        DataSet &dataSet,
        const QString &columnName
        ) const;


    // =====================================================
    // OUTLIER CLEANING
    // =====================================================

    CleaningResult applyOutlierAction(
        DataSet &dataSet,
        const QString &columnName,
        const QString &method,
        const QString &action,
        double parameter
        ) const;


private:
    bool isMissingValue(
        const QVariant &value
        ) const;

    AnalysisEngine m_analysisEngine;
};


#endif // CLEANINGENGINE_H