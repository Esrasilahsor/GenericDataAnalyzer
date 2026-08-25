#include "CleaningEngine.h"

#include <QMap>

#include <algorithm>
#include <cmath>


CleaningEngine::CleaningEngine()
{
}


// =========================================================
// REMOVE DUPLICATE ROWS
// =========================================================

CleaningResult CleaningEngine::removeDuplicateRows(
    DataSet &dataSet
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    const QVector<int> rows =
        m_analysisEngine.findDuplicateRowIndexes(
            dataSet
            );

    if (rows.isEmpty())
    {
        result.success = true;
        result.modified = false;
        result.message = QStringLiteral("Tekrarlanan kayıt bulunmuyor (zaten temiz).");
        result.details.insert(QStringLiteral("removedRowCount"), 0);
        return result;
    }

    if (!dataSet.removeRows(rows))
    {
        result.errorMessage =
            QStringLiteral(
                "Duplicate rows could not be removed."
                );

        return result;
    }

    result.success = true;
    result.modified = true;

    result.message =
        QStringLiteral("%1 duplicate row(s) removed.")
            .arg(rows.size());

    result.details.insert(
        QStringLiteral("removedRowCount"),
        rows.size()
        );

    return result;
}


// =========================================================
// REMOVE ROWS WITH MISSING VALUES
// =========================================================

CleaningResult CleaningEngine::removeRowsWithMissingValues(
    DataSet &dataSet
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    const QVector<int> rows =
        m_analysisEngine.findRowsWithMissingValues(
            dataSet
            );

    if (rows.isEmpty())
    {
        result.success = true;
        result.modified = false;
        result.message = QStringLiteral("Eksik değerli satır bulunmuyor (zaten temiz).");
        result.details.insert(QStringLiteral("removedRowCount"), 0);
        return result;
    }

    if (!dataSet.removeRows(rows))
    {
        result.errorMessage =
            QStringLiteral(
                "Rows with missing values could not be removed."
                );

        return result;
    }

    result.success = true;
    result.modified = true;

    result.message =
        QStringLiteral(
            "%1 row(s) with missing values removed."
            )
            .arg(rows.size());

    result.details.insert(
        QStringLiteral("removedRowCount"),
        rows.size()
        );

    return result;
}


// =========================================================
// FILL MISSING WITH MEAN
// =========================================================

CleaningResult CleaningEngine::fillMissingWithMean(
    DataSet &dataSet,
    const QString &columnName
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    const ColumnInfo *column =
        dataSet.findColumn(
            columnName
            );

    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column was not found."
                );

        return result;
    }

    if (!column->isNumeric())
    {
        result.errorMessage =
            QStringLiteral(
                "Mean filling can only be applied to numeric columns."
                );

        return result;
    }

    QVector<QVariant> values =
        column->values();

    double total = 0.0;
    int validCount = 0;
    int missingCount = 0;

    for (const QVariant &value :
         values)
    {
        if (isMissingValue(value))
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        const double number =
            value.toDouble(
                &ok
                );

        if (ok &&
            std::isfinite(number))
        {
            total += number;
            ++validCount;
        }
    }

    if (missingCount == 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column does not contain missing values."
                );

        return result;
    }

    if (validCount == 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Mean cannot be calculated."
                );

        return result;
    }

    const double mean =
        total /
        static_cast<double>(
            validCount
            );

    for (int i = 0;
         i < values.size();
         ++i)
    {
        if (isMissingValue(
                values.at(i)))
        {
            values[i] = mean;
        }
    }

    if (!dataSet.setColumnValues(
            columnName,
            values
            ))
    {
        result.errorMessage =
            QStringLiteral(
                "Column could not be updated."
                );

        return result;
    }

    result.success = true;
    result.modified = true;

    result.message =
        QStringLiteral(
            "%1 missing value(s) filled with mean."
            )
            .arg(missingCount);

    result.details.insert(
        QStringLiteral("columnName"),
        columnName
        );

    result.details.insert(
        QStringLiteral("filledCount"),
        missingCount
        );

    result.details.insert(
        QStringLiteral("fillValue"),
        mean
        );

    return result;
}


// =========================================================
// FILL MISSING WITH MEDIAN
// =========================================================

CleaningResult CleaningEngine::fillMissingWithMedian(
    DataSet &dataSet,
    const QString &columnName
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    const ColumnInfo *column =
        dataSet.findColumn(
            columnName
            );

    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column was not found."
                );

        return result;
    }

    if (!column->isNumeric())
    {
        result.errorMessage =
            QStringLiteral(
                "Median filling can only be applied to numeric columns."
                );

        return result;
    }

    QVector<QVariant> values =
        column->values();

    QVector<double> numericValues;

    int missingCount = 0;

    for (const QVariant &value :
         values)
    {
        if (isMissingValue(value))
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        const double number =
            value.toDouble(
                &ok
                );

        if (ok &&
            std::isfinite(number))
        {
            numericValues.append(
                number
                );
        }
    }

    if (missingCount == 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column does not contain missing values."
                );

        return result;
    }

    if (numericValues.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Median cannot be calculated."
                );

        return result;
    }

    std::sort(
        numericValues.begin(),
        numericValues.end()
        );

    const int size =
        numericValues.size();

    const int middle =
        size / 2;

    const double median =
        size % 2 == 0
            ? (
                  numericValues.at(
                      middle - 1
                      )
                  +
                  numericValues.at(
                      middle
                      )
                  )
                  / 2.0
            : numericValues.at(
                  middle
                  );

    for (int i = 0;
         i < values.size();
         ++i)
    {
        if (isMissingValue(
                values.at(i)))
        {
            values[i] = median;
        }
    }

    if (!dataSet.setColumnValues(
            columnName,
            values
            ))
    {
        result.errorMessage =
            QStringLiteral(
                "Column could not be updated."
                );

        return result;
    }

    result.success = true;
    result.modified = true;

    result.message =
        QStringLiteral(
            "%1 missing value(s) filled with median."
            )
            .arg(missingCount);

    result.details.insert(
        QStringLiteral("columnName"),
        columnName
        );

    result.details.insert(
        QStringLiteral("filledCount"),
        missingCount
        );

    result.details.insert(
        QStringLiteral("fillValue"),
        median
        );

    return result;
}


// =========================================================
// FILL MISSING WITH MODE
// =========================================================

CleaningResult CleaningEngine::fillMissingWithMode(
    DataSet &dataSet,
    const QString &columnName
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    const ColumnInfo *column =
        dataSet.findColumn(
            columnName
            );

    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column was not found."
                );

        return result;
    }

    QVector<QVariant> values =
        column->values();

    QMap<QString, int> frequency;
    QMap<QString, QVariant> originalValues;

    int missingCount = 0;

    for (const QVariant &value :
         values)
    {
        if (isMissingValue(value))
        {
            ++missingCount;
            continue;
        }

        const QString key =
            QString::number(
                static_cast<int>(
                    value.type()
                    )
                )
            +
            QStringLiteral(":")
            +
            value.toString();

        frequency[key] += 1;

        originalValues.insert(
            key,
            value
            );
    }

    if (missingCount == 0)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column does not contain missing values."
                );

        return result;
    }

    if (frequency.isEmpty())
    {
        result.errorMessage =
            QStringLiteral(
                "Mode cannot be calculated."
                );

        return result;
    }

    QString modeKey;
    int maxCount = -1;

    for (auto it =
         frequency.constBegin();
         it != frequency.constEnd();
         ++it)
    {
        if (it.value() >
            maxCount)
        {
            maxCount =
                it.value();

            modeKey =
                it.key();
        }
    }

    const QVariant modeValue =
        originalValues.value(
            modeKey
            );

    for (int i = 0;
         i < values.size();
         ++i)
    {
        if (isMissingValue(
                values.at(i)))
        {
            values[i] =
                modeValue;
        }
    }

    if (!dataSet.setColumnValues(
            columnName,
            values
            ))
    {
        result.errorMessage =
            QStringLiteral(
                "Column could not be updated."
                );

        return result;
    }

    result.success = true;
    result.modified = true;

    result.message =
        QStringLiteral(
            "%1 missing value(s) filled with mode."
            )
            .arg(missingCount);

    result.details.insert(
        QStringLiteral("columnName"),
        columnName
        );

    result.details.insert(
        QStringLiteral("filledCount"),
        missingCount
        );

    result.details.insert(
        QStringLiteral("fillValue"),
        modeValue
        );

    return result;
}


// =========================================================
// OUTLIER ACTION
// =========================================================

CleaningResult CleaningEngine::applyOutlierAction(
    DataSet &dataSet,
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    ) const
{
    CleaningResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset is not loaded.");

        return result;
    }

    if (!std::isfinite(parameter) ||
        parameter <= 0.0)
    {
        result.errorMessage =
            QStringLiteral(
                "Outlier parameter must be a finite positive value."
                );

        return result;
    }

    const ColumnInfo *column =
        dataSet.findColumn(
            columnName
            );

    if (!column)
    {
        result.errorMessage =
            QStringLiteral(
                "Selected column was not found."
                );

        return result;
    }

    if (!column->isNumeric())
    {
        result.errorMessage =
            QStringLiteral(
                "Outlier operations can only be applied to numeric columns."
                );

        return result;
    }

    QVector<int> outlierRows;
    QVariantList outlierValues;
    QVariantMap resultMap;

    resultMap.insert(
        QStringLiteral("columnName"),
        columnName
        );

    resultMap.insert(
        QStringLiteral("method"),
        method
        );

    resultMap.insert(
        QStringLiteral("action"),
        action
        );

    resultMap.insert(
        QStringLiteral("parameter"),
        parameter
        );

    if (method.compare(
            QStringLiteral("IQR"),
            Qt::CaseInsensitive
            ) == 0)
    {
        const ColumnOutlierAnalysisResult analysisResult =
            m_analysisEngine.analyzeColumnOutliers(
                dataSet,
                columnName,
                parameter
                );

        if (!analysisResult.success)
        {
            result.errorMessage =
                analysisResult.errorMessage;

            return result;
        }

        outlierRows =
            m_analysisEngine.findIqrOutlierRowIndexes(
                dataSet,
                columnName,
                parameter
                );

        for (double value :
             analysisResult.outlierResult.outlierValues)
        {
            outlierValues.append(
                value
                );
        }

        resultMap.insert(
            QStringLiteral("validValueCount"),
            analysisResult.outlierResult.validValueCount
            );

        resultMap.insert(
            QStringLiteral("lowerBound"),
            analysisResult.outlierResult.lowerBound
            );

        resultMap.insert(
            QStringLiteral("upperBound"),
            analysisResult.outlierResult.upperBound
            );

        resultMap.insert(
            QStringLiteral("outlierPercentage"),
            analysisResult.outlierResult.outlierPercentage
            );
    }
    else if (method.compare(
                 QStringLiteral("Z-Score"),
                 Qt::CaseInsensitive
                 ) == 0)
    {
        const ZScoreOutlierResult analysisResult =
            m_analysisEngine.analyzeColumnZScoreOutliers(
                dataSet,
                columnName,
                parameter
                );

        if (!analysisResult.success)
        {
            result.errorMessage =
                analysisResult.errorMessage;

            return result;
        }

        outlierRows =
            analysisResult.outlierRowIndexes;

        for (double value :
             analysisResult.outlierValues)
        {
            outlierValues.append(
                value
                );
        }

        resultMap.insert(
            QStringLiteral("validValueCount"),
            analysisResult.validValueCount
            );

        resultMap.insert(
            QStringLiteral("mean"),
            analysisResult.mean
            );

        resultMap.insert(
            QStringLiteral("standardDeviation"),
            analysisResult.standardDeviation
            );

        resultMap.insert(
            QStringLiteral("threshold"),
            analysisResult.threshold
            );

        resultMap.insert(
            QStringLiteral("outlierPercentage"),
            analysisResult.outlierPercentage
            );
    }
    else
    {
        result.errorMessage =
            QStringLiteral(
                "Unknown outlier detection method."
                );

        return result;
    }

    QVariantList rowList;

    for (int index :
         outlierRows)
    {
        rowList.append(
            index + 1
            );
    }

    resultMap.insert(
        QStringLiteral("outlierCount"),
        outlierRows.size()
        );

    resultMap.insert(
        QStringLiteral("outlierValues"),
        outlierValues
        );

    resultMap.insert(
        QStringLiteral("markedRows"),
        rowList
        );

    if (action.compare(
            QStringLiteral("Keep"),
            Qt::CaseInsensitive
            ) == 0)
    {
        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral(
                "Outliers were detected and kept unchanged."
                )
            );

        result.success = true;
        result.modified = false;
        result.message =
            resultMap.value(
                         QStringLiteral("message")
                         ).toString();

        result.details =
            resultMap;

        return result;
    }

    if (action.compare(
            QStringLiteral("Mark"),
            Qt::CaseInsensitive
            ) == 0)
    {
        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral(
                "Outliers were marked. Dataset values were not changed."
                )
            );

        result.success = true;
        result.modified = false;
        result.message =
            resultMap.value(
                         QStringLiteral("message")
                         ).toString();

        result.details =
            resultMap;

        return result;
    }

    if (action.compare(
            QStringLiteral("Remove"),
            Qt::CaseInsensitive
            ) == 0)
    {
        if (outlierRows.isEmpty())
        {
            result.success = true;
            result.modified = false;
            result.message = QStringLiteral("Aykırı değer bulunmuyor (zaten temiz).");
            result.details = resultMap;
            return result;
        }

        if (!dataSet.removeRows(
                outlierRows
                ))
        {
            result.errorMessage =
                QStringLiteral(
                    "Outlier rows could not be removed."
                    );

            return result;
        }

        resultMap.insert(
            QStringLiteral("message"),
            QStringLiteral(
                "%1 outlier row(s) removed."
                )
                .arg(
                    outlierRows.size()
                    )
            );

        result.success = true;
        result.modified = true;
        result.message =
            resultMap.value(
                         QStringLiteral("message")
                         ).toString();

        result.details =
            resultMap;

        return result;
    }

    result.errorMessage =
        QStringLiteral(
            "Unknown outlier action."
            );

    return result;
}


// =========================================================
// MISSING VALUE CHECK
// =========================================================

bool CleaningEngine::isMissingValue(
    const QVariant &value
    ) const
{
    return
        !value.isValid()
        ||
        value.isNull()
        ||
        (
            value.type() == QVariant::String
            &&
            value.toString().trimmed().isEmpty()
            );
}