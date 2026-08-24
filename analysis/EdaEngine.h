#ifndef EDAENGINE_H
#define EDAENGINE_H

#include <QString>
#include <QVariantMap>

#include "../parser/DataSet.h"
#include "AnalysisEngine.h"

struct EdaOperationResult
{
    bool success = false;
    QString errorMessage;
    QVariantMap data;
};

class EdaEngine
{
public:
    EdaEngine();

    EdaOperationResult analyzeSummary(
        const DataSet &dataSet,
        const QString &columnName
        ) const;

    EdaOperationResult analyzeCorrelation(
        const DataSet &dataSet,
        const QString &firstColumnName,
        const QString &secondColumnName
        ) const;

    EdaOperationResult analyzeQuality(
        const DataSet &dataSet
        ) const;

    EdaOperationResult analyzeOutliers(
        const DataSet &dataSet,
        const QString &columnName,
        double multiplier = 1.5
        ) const;

private:
    QVariantMap statisticsToVariantMap(
        const StatisticsResult &statistics
        ) const;

    QVariantMap qualityToVariantMap(
        const DatasetQualityResult &quality
        ) const;

    QVariantMap outlierToVariantMap(
        const ColumnOutlierAnalysisResult &result
        ) const;

    AnalysisEngine m_analysisEngine;
};

#endif // EDAENGINE_H