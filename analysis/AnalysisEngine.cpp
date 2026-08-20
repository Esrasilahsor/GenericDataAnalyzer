#include "AnalysisEngine.h"

#include <QByteArray>
#include <QDataStream>
#include <QIODevice>
#include <QSet>
#include <QVariant>

#include <limits>


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

    result.columnName =
        columnName;


    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset is empty."
                );

        return result;
    }


    const ColumnInfo *column =
        findColumn(
            dataSet,
            columnName
            );


    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Column not found."
                );

        return result;
    }


    if (!isColumnNumeric(*column))
    {
        result.errorMessage =
            QStringLiteral(
                "Column is not numeric."
                );

        return result;
    }


    result.statistics =
        m_statistics.calculate(
            column->values()
            );


    if (result.statistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Column does not contain valid numeric values."
                );

        return result;
    }


    result.success =
        true;


    return result;
}


// =========================================================
// IQR OUTLIER ANALİZİ
// =========================================================

ColumnOutlierAnalysisResult
AnalysisEngine::analyzeColumnOutliers(
    const DataSet &dataSet,
    const QString &columnName,
    double multiplier
    ) const
{
    ColumnOutlierAnalysisResult result;

    result.columnName =
        columnName;


    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset is empty."
                );

        return result;
    }


    if (columnName.trimmed().isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Column name is empty."
                );

        return result;
    }


    const ColumnInfo *column =
        findColumn(
            dataSet,
            columnName
            );


    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Column not found."
                );

        return result;
    }


    if (!isColumnNumeric(*column))
    {
        result.errorMessage =
            QStringLiteral(
                "Outlier analysis can only be performed on numeric columns."
                );

        return result;
    }


    result.outlierResult =
        m_statistics.calculateIqrOutliers(
            column->values(),
            multiplier
            );


    if (!result.outlierResult.success)
    {
        result.errorMessage =
            result.outlierResult.errorMessage;

        return result;
    }


    result.success =
        true;


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


    if (sourceDataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 1 is empty."
                );

        return result;
    }


    if (targetDataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 2 is empty."
                );

        return result;
    }


    const ColumnInfo *sourceColumn =
        findColumn(
            sourceDataSet,
            sourceColumnName
            );


    if (!sourceColumn)
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 1 column not found."
                );

        return result;
    }


    const ColumnInfo *targetColumn =
        findColumn(
            targetDataSet,
            targetColumnName
            );


    if (!targetColumn)
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 2 column not found."
                );

        return result;
    }


    if (!isColumnNumeric(*sourceColumn))
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 1 column is not numeric."
                );

        return result;
    }


    if (!isColumnNumeric(*targetColumn))
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 2 column is not numeric."
                );

        return result;
    }


    result.sourceStatistics =
        m_statistics.calculate(
            sourceColumn->values()
            );


    result.targetStatistics =
        m_statistics.calculate(
            targetColumn->values()
            );


    if (result.sourceStatistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 1 column does not contain numeric values."
                );

        return result;
    }


    if (result.targetStatistics.count <= 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset 2 column does not contain numeric values."
                );

        return result;
    }


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


    result.success =
        true;


    return result;
}


// =========================================================
// DATA QUALITY
// =========================================================

DatasetQualityResult AnalysisEngine::analyzeDataQuality(
    const DataSet &dataSet
    ) const
{
    DatasetQualityResult result;


    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset is empty."
                );

        return result;
    }


    const QVector<ColumnInfo> columns =
        dataSet.columns();


    result.rowCount =
        dataSet.rowCount();


    result.columnCount =
        columns.size();


    if (result.columnCount <= 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Dataset contains no columns."
                );

        return result;
    }


    qint64 totalMissingValues =
        0;


    for (const ColumnInfo &column :
         columns)
    {
        const int missingCount =
            column.missingCount();


        if (missingCount > 0)
        {
            totalMissingValues +=
                static_cast<qint64>(
                    missingCount
                    );


            ++result.columnsWithMissingValues;


            result.columnsWithMissing.append(
                column.name()
                );
        }


        if (column.uniqueCount() == 1)
        {
            ++result.constantColumnCount;


            result.constantColumns.append(
                column.name()
                );
        }


        if (column.isNumeric())
        {
            ++result.numericColumnCount;
        }
        else
        {
            ++result.nonNumericColumnCount;
        }
    }


    if (totalMissingValues >
        static_cast<qint64>(
            std::numeric_limits<int>::max()
            ))
    {
        result.totalMissingValues =
            std::numeric_limits<int>::max();
    }
    else
    {
        result.totalMissingValues =
            static_cast<int>(
                totalMissingValues
                );
    }


    const qint64 totalCellCount =
        static_cast<qint64>(
            result.rowCount
            )
        *
        static_cast<qint64>(
            result.columnCount
            );


    if (totalCellCount > 0)
    {
        result.missingPercentage =
            (
                static_cast<double>(
                    totalMissingValues
                    )
                /
                static_cast<double>(
                    totalCellCount
                    )
                )
            *
            100.0;
    }


    result.duplicateRowCount =
        calculateDuplicateRowCount(
            dataSet
            );


    if (result.rowCount > 0)
    {
        result.duplicatePercentage =
            (
                static_cast<double>(
                    result.duplicateRowCount
                    )
                /
                static_cast<double>(
                    result.rowCount
                    )
                )
            *
            100.0;
    }


    result.success =
        true;


    return result;
}


// =========================================================
// FIND DUPLICATE ROW INDEXES
// =========================================================

QVector<int> AnalysisEngine::findDuplicateRowIndexes(
    const DataSet &dataSet
    ) const
{
    QVector<int> duplicateIndexes;


    if (dataSet.isEmpty())
    {
        return duplicateIndexes;
    }


    const QVector<ColumnInfo> columns =
        dataSet.columns();


    if (columns.isEmpty())
    {
        return duplicateIndexes;
    }


    const int rowCount =
        dataSet.rowCount();


    if (rowCount <= 1)
    {
        return duplicateIndexes;
    }


    QSet<QByteArray> uniqueRows;


    for (int row = 0;
         row < rowCount;
         ++row)
    {
        QByteArray rowSignature;


        QDataStream stream(
            &rowSignature,
            QIODevice::WriteOnly
            );


        stream.setVersion(
            QDataStream::Qt_5_15
            );


        for (const ColumnInfo &column :
             columns)
        {
            const QVector<QVariant> values =
                column.values();


            if (row >= 0 &&
                row < values.size())
            {
                stream
                    << values.at(row);
            }
            else
            {
                stream
                    << QVariant();
            }
        }


        if (uniqueRows.contains(
                rowSignature))
        {
            duplicateIndexes.append(
                row
                );
        }
        else
        {
            uniqueRows.insert(
                rowSignature
                );
        }
    }


    return duplicateIndexes;
}


// =========================================================
// FIND ROWS WITH MISSING VALUES
// =========================================================

QVector<int> AnalysisEngine::findRowsWithMissingValues(
    const DataSet &dataSet
    ) const
{
    QVector<int> missingRowIndexes;


    if (dataSet.isEmpty())
    {
        return missingRowIndexes;
    }


    const QVector<ColumnInfo> columns =
        dataSet.columns();


    if (columns.isEmpty())
    {
        return missingRowIndexes;
    }


    const int rowCount =
        dataSet.rowCount();


    if (rowCount <= 0)
    {
        return missingRowIndexes;
    }


    for (int row = 0;
         row < rowCount;
         ++row)
    {
        bool rowHasMissingValue =
            false;


        for (const ColumnInfo &column :
             columns)
        {
            const QVector<QVariant> values =
                column.values();


            /*
             * Eğer bir sütun beklenenden kısa ise
             * o hücre missing kabul edilir.
             */
            if (row < 0 ||
                row >= values.size())
            {
                rowHasMissingValue =
                    true;

                break;
            }


            if (isMissingValue(
                    values.at(row)))
            {
                rowHasMissingValue =
                    true;

                break;
            }
        }


        if (rowHasMissingValue)
        {
            missingRowIndexes.append(
                row
                );
        }
    }


    return missingRowIndexes;
}


// =========================================================
// DUPLICATE ROW COUNT
// =========================================================

int AnalysisEngine::calculateDuplicateRowCount(
    const DataSet &dataSet
    ) const
{
    return findDuplicateRowIndexes(
               dataSet
               ).size();
}


// =========================================================
// MISSING VALUE CONTROL
// =========================================================

bool AnalysisEngine::isMissingValue(
    const QVariant &value
    ) const
{
    if (!value.isValid() ||
        value.isNull())
    {
        return true;
    }


    /*
     * Boş string de missing kabul edilir.
     */
    if (value.type() == QVariant::String)
    {
        if (value.toString()
                .trimmed()
                .isEmpty())
        {
            return true;
        }
    }


    return false;
}


// =========================================================
// FIND COLUMN
// =========================================================

const ColumnInfo *AnalysisEngine::findColumn(
    const DataSet &dataSet,
    const QString &columnName
    ) const
{
    if (columnName.trimmed().isEmpty())
    {
        return nullptr;
    }


    return dataSet.findColumn(
        columnName
        );
}


// =========================================================
// NUMERIC CONTROL
// =========================================================

bool AnalysisEngine::isColumnNumeric(
    const ColumnInfo &column
    ) const
{
    return column.isNumeric();
}