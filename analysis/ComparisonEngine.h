#ifndef COMPARISONENGINE_H
#define COMPARISONENGINE_H

#include <QString>
#include <QVector>

#include "../parser/DataSet.h"
#include "../models/MappingModel.h"

class ComparisonEngine
{
public:
    ComparisonEngine();

    QVector<ColumnMapping> suggestMappings(
        const DataSet &sourceDataSet,
        const DataSet &targetDataSet
        ) const;

    double calculateSimilarity(
        const QString &source,
        const QString &target
        ) const;

    QString normalizeColumnName(
        const QString &columnName
        ) const;

private:
    int levenshteinDistance(
        const QString &first,
        const QString &second
        ) const;

    double calculateLevenshteinSimilarity(
        const QString &first,
        const QString &second
        ) const;

    double calculateTokenSimilarity(
        const QString &first,
        const QString &second
        ) const;

    bool areTypesCompatible(
        ColumnInfo::DataType sourceType,
        ColumnInfo::DataType targetType
        ) const;

    double applyTypeCompatibilityBonus(
        double similarityScore,
        ColumnInfo::DataType sourceType,
        ColumnInfo::DataType targetType
        ) const;
};

#endif // COMPARISONENGINE_H