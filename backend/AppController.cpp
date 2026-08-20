#include "AppController.h"

#include "../raw/FileRawDataSource.h"

#include <QUrl>
#include <algorithm>
#include <QMap>
#include <cmath>


// =========================================================
// CONSTRUCTOR
// =========================================================

AppController::AppController(QObject *parent)
    : QObject(parent),
    m_dataset1ColumnModel(this),
    m_dataset2ColumnModel(this),
    m_mappingModel(this),
    m_parameterModel(this)
{
}


// =========================================================
// DATASET GETTERS
// =========================================================

QString AppController::dataset1Name() const
{
    return m_dataset1.name();
}

QString AppController::dataset2Name() const
{
    return m_dataset2.name();
}

int AppController::dataset1RowCount() const
{
    return m_dataset1.rowCount();
}

int AppController::dataset2RowCount() const
{
    return m_dataset2.rowCount();
}

int AppController::dataset1ColumnCount() const
{
    return m_dataset1.columnCount();
}

int AppController::dataset2ColumnCount() const
{
    return m_dataset2.columnCount();
}

QString AppController::dataset1SheetName() const
{
    return m_dataset1.sheetName();
}

QString AppController::dataset2SheetName() const
{
    return m_dataset2.sheetName();
}

bool AppController::dataset1Modified() const
{
    return m_dataset1Modified;
}

bool AppController::dataset2Modified() const
{
    return m_dataset2Modified;
}


// =========================================================
// ERROR
// =========================================================

QString AppController::lastError() const
{
    return m_lastError;
}


// =========================================================
// MODELS
// =========================================================

ColumnModel *AppController::dataset1ColumnModel()
{
    return &m_dataset1ColumnModel;
}

ColumnModel *AppController::dataset2ColumnModel()
{
    return &m_dataset2ColumnModel;
}

MappingModel *AppController::mappingModel()
{
    return &m_mappingModel;
}

ParameterModel *AppController::parameterModel()
{
    return &m_parameterModel;
}


// =========================================================
// COMPARISON GETTERS
// =========================================================

QVariantMap AppController::analysisResult() const
{
    return m_analysisResult;
}

bool AppController::analysisAvailable() const
{
    return m_analysisAvailable;
}


// =========================================================
// QUALITY GETTERS
// =========================================================

QVariantMap AppController::dataset1QualityResult() const
{
    return m_dataset1QualityResult;
}

QVariantMap AppController::dataset2QualityResult() const
{
    return m_dataset2QualityResult;
}

bool AppController::dataset1QualityAvailable() const
{
    return m_dataset1QualityAvailable;
}

bool AppController::dataset2QualityAvailable() const
{
    return m_dataset2QualityAvailable;
}


// =========================================================
// OUTLIER GETTERS
// =========================================================

QVariantMap AppController::dataset1OutlierResult() const
{
    return m_dataset1OutlierResult;
}

QVariantMap AppController::dataset2OutlierResult() const
{
    return m_dataset2OutlierResult;
}

bool AppController::dataset1OutlierAvailable() const
{
    return m_dataset1OutlierAvailable;
}

bool AppController::dataset2OutlierAvailable() const
{
    return m_dataset2OutlierAvailable;
}


// =========================================================
// RAW GETTERS
// =========================================================

bool AppController::rawMetadataLoaded() const
{
    return m_rawMetadataLoaded;
}

bool AppController::rawDataLoaded() const
{
    return m_rawDataLoaded;
}

bool AppController::rawParseAvailable() const
{
    return m_rawParseAvailable;
}

int AppController::rawParameterDefinitionCount() const
{
    return m_rawParameterDefinitions.size();
}

int AppController::rawDataByteCount() const
{
    return m_rawData.size();
}

QString AppController::rawMetadataFilePath() const
{
    return m_rawMetadataFilePath;
}

QString AppController::rawDataFilePath() const
{
    return m_rawDataFilePath;
}

QStringList AppController::rawWarnings() const
{
    return m_rawWarnings;
}


// =========================================================
// DATASET 1 LOAD
// =========================================================

bool AppController::loadDataset1(
    const QString &filePath)
{
    clearError();

    clearDataset1Quality();
    clearDataset1Outliers();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset1.clear();
        m_originalDataset1.clear();

        m_dataset1Modified = false;

        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();

        clearAnalysis();

        setError(
            QStringLiteral(
                "Dataset 1 file path is empty."
                )
            );

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser1.loadFile(normalizedPath))
    {
        m_dataset1.clear();
        m_originalDataset1.clear();

        m_dataset1Modified = false;

        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();

        clearAnalysis();

        setError(
            m_parser1.lastError()
            );

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset1 =
        m_parser1.dataSet();

    // Orijinal kopya değiştirilmeyecek.
    m_originalDataset1 =
        m_dataset1;

    m_dataset1Modified =
        false;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    emit dataset1Changed();

    clearAnalysis();

    tryGenerateMappings();

    return true;
}


// =========================================================
// DATASET 2 LOAD
// =========================================================

bool AppController::loadDataset2(
    const QString &filePath)
{
    clearError();

    clearDataset2Quality();
    clearDataset2Outliers();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset2.clear();
        m_originalDataset2.clear();

        m_dataset2Modified = false;

        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();

        clearAnalysis();

        setError(
            QStringLiteral(
                "Dataset 2 file path is empty."
                )
            );

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser2.loadFile(normalizedPath))
    {
        m_dataset2.clear();
        m_originalDataset2.clear();

        m_dataset2Modified = false;

        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();

        clearAnalysis();

        setError(
            m_parser2.lastError()
            );

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset2 =
        m_parser2.dataSet();

    m_originalDataset2 =
        m_dataset2;

    m_dataset2Modified =
        false;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    emit dataset2Changed();

    clearAnalysis();

    tryGenerateMappings();

    return true;
}


// =========================================================
// RESTORE DATASET 1
// =========================================================

bool AppController::restoreDataset1()
{
    clearError();

    if (m_originalDataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 original data is not available."
                )
            );

        return false;
    }

    m_dataset1 =
        m_originalDataset1;

    m_dataset1Modified =
        false;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// RESTORE DATASET 2
// =========================================================

bool AppController::restoreDataset2()
{
    clearError();

    if (m_originalDataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 original data is not available."
                )
            );

        return false;
    }

    m_dataset2 =
        m_originalDataset2;

    m_dataset2Modified =
        false;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// REMOVE DATASET 1 DUPLICATES
// =========================================================

bool AppController::removeDataset1Duplicates()
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 is not loaded."
                )
            );

        return false;
    }

    const QVector<int> duplicateIndexes =
        m_analysisEngine.findDuplicateRowIndexes(
            m_dataset1
            );

    if (duplicateIndexes.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 does not contain duplicate rows."
                )
            );

        return false;
    }

    if (!m_dataset1.removeRows(
            duplicateIndexes))
    {
        setError(
            QStringLiteral(
                "Dataset 1 duplicate rows could not be removed."
                )
            );

        return false;
    }

    m_dataset1Modified =
        true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// REMOVE DATASET 2 DUPLICATES
// =========================================================

bool AppController::removeDataset2Duplicates()
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 is not loaded."
                )
            );

        return false;
    }

    const QVector<int> duplicateIndexes =
        m_analysisEngine.findDuplicateRowIndexes(
            m_dataset2
            );

    if (duplicateIndexes.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 does not contain duplicate rows."
                )
            );

        return false;
    }

    if (!m_dataset2.removeRows(
            duplicateIndexes))
    {
        setError(
            QStringLiteral(
                "Dataset 2 duplicate rows could not be removed."
                )
            );

        return false;
    }

    m_dataset2Modified =
        true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// REMOVE DATASET 1 MISSING ROWS
// =========================================================

bool AppController::removeDataset1MissingRows()
{
    clearError();

    // -----------------------------------------------------
    // Dataset kontrolü
    // -----------------------------------------------------

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 is not loaded."
                )
            );

        return false;
    }

    // -----------------------------------------------------
    // Missing bulunan satır indexlerini al
    // -----------------------------------------------------

    const QVector<int> missingRowIndexes =
        m_analysisEngine.findRowsWithMissingValues(
            m_dataset1
            );

    // -----------------------------------------------------
    // Missing satır yoksa dataset'e dokunma
    // -----------------------------------------------------

    if (missingRowIndexes.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 does not contain rows with missing values."
                )
            );

        return false;
    }

    // -----------------------------------------------------
    // Working dataset üzerinde temizleme
    //
    // Original dataset kesinlikle değişmez.
    // -----------------------------------------------------

    if (!m_dataset1.removeRows(
            missingRowIndexes))
    {
        setError(
            QStringLiteral(
                "Dataset 1 rows with missing values could not be removed."
                )
            );

        return false;
    }

    // -----------------------------------------------------
    // Working dataset değişti.
    // -----------------------------------------------------

    m_dataset1Modified =
        true;

    // -----------------------------------------------------
    // Column model yeniden oluşturulur.
    // -----------------------------------------------------

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    // -----------------------------------------------------
    // Eski analiz sonuçları artık geçerli değildir.
    // -----------------------------------------------------

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    // -----------------------------------------------------
    // Dataset değiştiği için mapping de yenilenir.
    // -----------------------------------------------------

    tryGenerateMappings();

    return true;
}


// =========================================================
// REMOVE DATASET 2 MISSING ROWS
// =========================================================

bool AppController::removeDataset2MissingRows()
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 is not loaded."
                )
            );

        return false;
    }

    const QVector<int> missingRowIndexes =
        m_analysisEngine.findRowsWithMissingValues(
            m_dataset2
            );

    if (missingRowIndexes.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 does not contain rows with missing values."
                )
            );

        return false;
    }

    if (!m_dataset2.removeRows(
            missingRowIndexes))
    {
        setError(
            QStringLiteral(
                "Dataset 2 rows with missing values could not be removed."
                )
            );

        return false;
    }

    m_dataset2Modified =
        true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// FILL DATASET 1 MISSING VALUES WITH MEAN
// =========================================================

bool AppController::fillDataset1MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral("Dataset 1 is not loaded.")
            );

        return false;
    }

    const ColumnInfo *column =
        m_dataset1.findColumn(columnName);

    if (!column)
    {
        setError(
            QStringLiteral("Dataset 1 column was not found.")
            );

        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            QStringLiteral(
                "Mean filling can only be applied to numeric columns."
                )
            );

        return false;
    }

    QVector<QVariant> values =
        column->values();

    double total = 0.0;
    int validCount = 0;
    int missingCount = 0;

    // -----------------------------------------------------
    // MEAN HESAPLA
    // -----------------------------------------------------

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        const double numericValue =
            value.toDouble(&ok);

        if (ok)
        {
            total += numericValue;
            ++validCount;
        }
    }

    if (missingCount == 0)
    {
        setError(
            QStringLiteral(
                "Selected column does not contain missing values."
                )
            );

        return false;
    }

    if (validCount == 0)
    {
        setError(
            QStringLiteral(
                "Mean cannot be calculated because the column "
                "does not contain valid numeric values."
                )
            );

        return false;
    }

    const double mean =
        total / static_cast<double>(validCount);

    // -----------------------------------------------------
    // MISSING DEĞERLERİ MEAN İLE DOLDUR
    // -----------------------------------------------------

    for (int i = 0; i < values.size(); ++i)
    {
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            values[i] = mean;
        }
    }

    // -----------------------------------------------------
    // WORKING DATASET'İ GÜNCELLE
    // -----------------------------------------------------

    if (!m_dataset1.setColumnValues(
            columnName,
            values))
    {
        setError(
            QStringLiteral(
                "Dataset 1 column could not be updated."
                )
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    // Eski analizler artık geçerli değil.
    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// FILL DATASET 2 MISSING VALUES WITH MEAN
// =========================================================

bool AppController::fillDataset2MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral("Dataset 2 is not loaded.")
            );

        return false;
    }

    const ColumnInfo *column =
        m_dataset2.findColumn(columnName);

    if (!column)
    {
        setError(
            QStringLiteral("Dataset 2 column was not found.")
            );

        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            QStringLiteral(
                "Mean filling can only be applied to numeric columns."
                )
            );

        return false;
    }

    QVector<QVariant> values =
        column->values();

    double total = 0.0;
    int validCount = 0;
    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        const double numericValue =
            value.toDouble(&ok);

        if (ok)
        {
            total += numericValue;
            ++validCount;
        }
    }

    if (missingCount == 0)
    {
        setError(
            QStringLiteral(
                "Selected column does not contain missing values."
                )
            );

        return false;
    }

    if (validCount == 0)
    {
        setError(
            QStringLiteral(
                "Mean cannot be calculated because the column "
                "does not contain valid numeric values."
                )
            );

        return false;
    }

    const double mean =
        total / static_cast<double>(validCount);

    for (int i = 0; i < values.size(); ++i)
    {
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            values[i] = mean;
        }
    }

    if (!m_dataset2.setColumnValues(
            columnName,
            values))
    {
        setError(
            QStringLiteral(
                "Dataset 2 column could not be updated."
                )
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// FILL DATASET 1 MISSING WITH MEDIAN
// =========================================================

bool AppController::fillDataset1MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError("Dataset 1 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset1.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 1 column was not found.");
        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            "Median filling can only be applied to numeric columns."
            );

        return false;
    }

    QVector<QVariant> values =
        column->values();

    QVector<double> numericValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        double number =
            value.toDouble(&ok);

        if (ok)
            numericValues.append(number);
    }

    if (missingCount == 0)
    {
        setError(
            "Selected column does not contain missing values."
            );

        return false;
    }

    if (numericValues.isEmpty())
    {
        setError(
            "Median cannot be calculated."
            );

        return false;
    }

    std::sort(
        numericValues.begin(),
        numericValues.end()
        );

    double median = 0.0;

    int size =
        numericValues.size();

    int middle =
        size / 2;

    if (size % 2 == 0)
    {
        median =
            (
                numericValues[middle - 1]
                +
                numericValues[middle]
                )
            /
            2.0;
    }
    else
    {
        median =
            numericValues[middle];
    }

    for (int i = 0;
         i < values.size();
         ++i)
    {
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
            values[i] = median;
    }

    if (!m_dataset1.setColumnValues(
            columnName,
            values))
    {
        setError(
            "Dataset 1 column could not be updated."
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// FILL DATASET 2 MISSING WITH MEDIAN
// =========================================================

bool AppController::fillDataset2MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError("Dataset 2 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset2.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 2 column was not found.");
        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            "Median filling can only be applied to numeric columns."
            );

        return false;
    }

    QVector<QVariant> values =
        column->values();

    QVector<double> numericValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
        {
            ++missingCount;
            continue;
        }

        bool ok = false;

        double number =
            value.toDouble(&ok);

        if (ok)
            numericValues.append(number);
    }

    if (missingCount == 0)
    {
        setError(
            "Selected column does not contain missing values."
            );

        return false;
    }

    if (numericValues.isEmpty())
    {
        setError(
            "Median cannot be calculated."
            );

        return false;
    }

    std::sort(
        numericValues.begin(),
        numericValues.end()
        );

    double median = 0.0;

    int size =
        numericValues.size();

    int middle =
        size / 2;

    if (size % 2 == 0)
    {
        median =
            (
                numericValues[middle - 1]
                +
                numericValues[middle]
                )
            /
            2.0;
    }
    else
    {
        median =
            numericValues[middle];
    }

    for (int i = 0;
         i < values.size();
         ++i)
    {
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
            values[i] = median;
    }

    if (!m_dataset2.setColumnValues(
            columnName,
            values))
    {
        setError(
            "Dataset 2 column could not be updated."
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// FILL DATASET 1 MISSING WITH MODE
// =========================================================

bool AppController::fillDataset1MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError("Dataset 1 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset1.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 1 column was not found.");
        return false;
    }

    QVector<QVariant> values =
        column->values();

    QMap<QString, int> frequency;
    QMap<QString, QVariant> originalValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
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
            ":"
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
        setError(
            "Selected column does not contain missing values."
            );

        return false;
    }

    if (frequency.isEmpty())
    {
        setError(
            "Mode cannot be calculated."
            );

        return false;
    }

    QString modeKey;
    int maxCount = -1;

    for (auto it = frequency.constBegin();
         it != frequency.constEnd();
         ++it)
    {
        if (it.value() > maxCount)
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
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
            values[i] = modeValue;
    }

    if (!m_dataset1.setColumnValues(
            columnName,
            values))
    {
        setError(
            "Dataset 1 column could not be updated."
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


// =========================================================
// FILL DATASET 2 MISSING WITH MODE
// =========================================================

bool AppController::fillDataset2MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError("Dataset 2 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset2.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 2 column was not found.");
        return false;
    }

    QVector<QVariant> values =
        column->values();

    QMap<QString, int> frequency;
    QMap<QString, QVariant> originalValues;

    int missingCount = 0;

    for (const QVariant &value : values)
    {
        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
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
            ":"
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
        setError(
            "Selected column does not contain missing values."
            );

        return false;
    }

    if (frequency.isEmpty())
    {
        setError(
            "Mode cannot be calculated."
            );

        return false;
    }

    QString modeKey;
    int maxCount = -1;

    for (auto it = frequency.constBegin();
         it != frequency.constEnd();
         ++it)
    {
        if (it.value() > maxCount)
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
        const QVariant &value =
            values.at(i);

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() == QVariant::String
                &&
                value.toString().trimmed().isEmpty()
                );

        if (missing)
            values[i] = modeValue;
    }

    if (!m_dataset2.setColumnValues(
            columnName,
            values))
    {
        setError(
            "Dataset 2 column could not be updated."
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// REMOVE DATASET 1 OUTLIERS
// =========================================================

bool AppController::removeDataset1Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError("Dataset 1 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset1.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 1 column was not found.");
        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            "Outlier cleaning can only be applied to numeric columns."
            );
        return false;
    }

    const ColumnOutlierAnalysisResult analysis =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!analysis.success)
    {
        setError(analysis.errorMessage);
        return false;
    }

    if (analysis.outlierResult.outlierCount <= 0)
    {
        setError(
            "Selected column does not contain outliers."
            );
        return false;
    }

    const double lowerBound =
        analysis.outlierResult.lowerBound;

    const double upperBound =
        analysis.outlierResult.upperBound;

    const QVector<QVariant> values =
        column->values();

    QVector<int> rowsToRemove;

    for (int row = 0;
         row < values.size();
         ++row)
    {
        const QVariant &value =
            values.at(row);

        if (!value.isValid() ||
            value.isNull())
        {
            continue;
        }

        if (value.type() == QVariant::String &&
            value.toString().trimmed().isEmpty())
        {
            continue;
        }

        bool ok = false;

        const double numericValue =
            value.toDouble(&ok);

        if (!ok ||
            !std::isfinite(numericValue))
        {
            continue;
        }

        if (numericValue < lowerBound ||
            numericValue > upperBound)
        {
            rowsToRemove.append(row);
        }
    }

    if (rowsToRemove.isEmpty())
    {
        setError(
            "No removable outlier rows were found."
            );
        return false;
    }

    if (!m_dataset1.removeRows(rowsToRemove))
    {
        setError(
            "Dataset 1 outlier rows could not be removed."
            );
        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}


bool AppController::removeDataset2Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError("Dataset 2 is not loaded.");
        return false;
    }

    const ColumnInfo *column =
        m_dataset2.findColumn(columnName);

    if (!column)
    {
        setError("Dataset 2 column was not found.");
        return false;
    }

    if (!column->isNumeric())
    {
        setError(
            "Outlier cleaning can only be applied to numeric columns."
            );
        return false;
    }

    const ColumnOutlierAnalysisResult analysis =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!analysis.success)
    {
        setError(analysis.errorMessage);
        return false;
    }

    if (analysis.outlierResult.outlierCount <= 0)
    {
        setError(
            "Selected column does not contain outliers."
            );
        return false;
    }

    const double lowerBound =
        analysis.outlierResult.lowerBound;

    const double upperBound =
        analysis.outlierResult.upperBound;

    const QVector<QVariant> values =
        column->values();

    QVector<int> rowsToRemove;

    for (int row = 0;
         row < values.size();
         ++row)
    {
        const QVariant &value =
            values.at(row);

        if (!value.isValid() ||
            value.isNull())
        {
            continue;
        }

        if (value.type() == QVariant::String &&
            value.toString().trimmed().isEmpty())
        {
            continue;
        }

        bool ok = false;

        const double numericValue =
            value.toDouble(&ok);

        if (!ok ||
            !std::isfinite(numericValue))
        {
            continue;
        }

        if (numericValue < lowerBound ||
            numericValue > upperBound)
        {
            rowsToRemove.append(row);
        }
    }

    if (rowsToRemove.isEmpty())
    {
        setError(
            "No removable outlier rows were found."
            );
        return false;
    }

    if (!m_dataset2.removeRows(rowsToRemove))
    {
        setError(
            "Dataset 2 outlier rows could not be removed."
            );
        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

// =========================================================
// GENERATE MAPPINGS
// =========================================================

void AppController::generateMappings()
{
    if (m_dataset1.isEmpty() ||
        m_dataset2.isEmpty())
    {
        m_mappingModel.clear();

        clearAnalysis();

        emit mappingsChanged();

        return;
    }

    const QVector<ColumnMapping> mappings =
        m_comparisonEngine.suggestMappings(
            m_dataset1,
            m_dataset2
            );

    m_mappingModel.setMappings(
        mappings
        );

    clearAnalysis();

    emit mappingsChanged();
}


// =========================================================
// CLEAR MAPPINGS
// =========================================================

void AppController::clearMappings()
{
    m_mappingModel.clear();

    clearAnalysis();

    emit mappingsChanged();
}


// =========================================================
// ANALYZE COLUMNS
// =========================================================

bool AppController::analyzeColumns(
    const QString &sourceColumn,
    const QString &targetColumn)
{
    clearError();

    clearAnalysis();

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 is not loaded."
                )
            );

        return false;
    }

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 is not loaded."
                )
            );

        return false;
    }

    if (sourceColumn.trimmed().isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 column is empty."
                )
            );

        return false;
    }

    if (targetColumn.trimmed().isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 column is empty."
                )
            );

        return false;
    }

    const ColumnComparisonResult result =
        m_analysisEngine.compareColumns(
            m_dataset1,
            sourceColumn,
            m_dataset2,
            targetColumn
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    QVariantMap resultMap;

    resultMap.insert(
        QStringLiteral("sourceColumn"),
        result.sourceColumnName
        );

    resultMap.insert(
        QStringLiteral("targetColumn"),
        result.targetColumnName
        );

    resultMap.insert(
        QStringLiteral("sourceStatistics"),
        statisticsToVariantMap(
            result.sourceStatistics
            )
        );

    resultMap.insert(
        QStringLiteral("targetStatistics"),
        statisticsToVariantMap(
            result.targetStatistics
            )
        );

    resultMap.insert(
        QStringLiteral("meanDifference"),
        result.meanDifference
        );

    resultMap.insert(
        QStringLiteral("medianDifference"),
        result.medianDifference
        );

    resultMap.insert(
        QStringLiteral("minimumDifference"),
        result.minimumDifference
        );

    resultMap.insert(
        QStringLiteral("maximumDifference"),
        result.maximumDifference
        );

    resultMap.insert(
        QStringLiteral("rangeDifference"),
        result.rangeDifference
        );

    resultMap.insert(
        QStringLiteral("varianceDifference"),
        result.varianceDifference
        );

    resultMap.insert(
        QStringLiteral(
            "standardDeviationDifference"
            ),
        result.standardDeviationDifference
        );

    resultMap.insert(
        QStringLiteral("q1Difference"),
        result.q1Difference
        );

    resultMap.insert(
        QStringLiteral("q3Difference"),
        result.q3Difference
        );

    resultMap.insert(
        QStringLiteral("iqrDifference"),
        result.iqrDifference
        );

    m_analysisResult =
        resultMap;

    m_analysisAvailable =
        true;

    emit analysisResultChanged();

    return true;
}


// =========================================================
// CLEAR ANALYSIS
// =========================================================

void AppController::clearAnalysis()
{
    const bool hadAnalysis =
        m_analysisAvailable ||
        !m_analysisResult.isEmpty();

    m_analysisResult.clear();

    m_analysisAvailable =
        false;

    if (hadAnalysis)
    {
        emit analysisResultChanged();
    }
}


// =========================================================
// QUALITY - DATASET 1
// =========================================================

bool AppController::analyzeDataset1Quality()
{
    clearError();

    clearDataset1Quality();

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 is not loaded."
                )
            );

        return false;
    }

    const DatasetQualityResult result =
        m_analysisEngine.analyzeDataQuality(
            m_dataset1
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1QualityResult =
        qualityToVariantMap(
            result
            );

    m_dataset1QualityAvailable =
        true;

    emit dataset1QualityChanged();

    return true;
}


// =========================================================
// QUALITY - DATASET 2
// =========================================================

bool AppController::analyzeDataset2Quality()
{
    clearError();

    clearDataset2Quality();

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 is not loaded."
                )
            );

        return false;
    }

    const DatasetQualityResult result =
        m_analysisEngine.analyzeDataQuality(
            m_dataset2
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2QualityResult =
        qualityToVariantMap(
            result
            );

    m_dataset2QualityAvailable =
        true;

    emit dataset2QualityChanged();

    return true;
}


// =========================================================
// CLEAR QUALITY
// =========================================================

void AppController::clearDataset1Quality()
{
    const bool hadResult =
        m_dataset1QualityAvailable ||
        !m_dataset1QualityResult.isEmpty();

    m_dataset1QualityResult.clear();

    m_dataset1QualityAvailable =
        false;

    if (hadResult)
    {
        emit dataset1QualityChanged();
    }
}

void AppController::clearDataset2Quality()
{
    const bool hadResult =
        m_dataset2QualityAvailable ||
        !m_dataset2QualityResult.isEmpty();

    m_dataset2QualityResult.clear();

    m_dataset2QualityAvailable =
        false;

    if (hadResult)
    {
        emit dataset2QualityChanged();
    }
}


// =========================================================
// OUTLIER ANALYSIS - DATASET 1
// =========================================================

bool AppController::analyzeDataset1Outliers(
    const QString &columnName,
    double multiplier)
{
    clearError();

    clearDataset1Outliers();

    if (m_dataset1.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 1 is not loaded."
                )
            );

        return false;
    }

    const ColumnOutlierAnalysisResult result =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1OutlierResult =
        outlierToVariantMap(
            result
            );

    m_dataset1OutlierAvailable =
        true;

    emit dataset1OutlierChanged();

    return true;
}


// =========================================================
// OUTLIER ANALYSIS - DATASET 2
// =========================================================

bool AppController::analyzeDataset2Outliers(
    const QString &columnName,
    double multiplier)
{
    clearError();

    clearDataset2Outliers();

    if (m_dataset2.isEmpty())
    {
        setError(
            QStringLiteral(
                "Dataset 2 is not loaded."
                )
            );

        return false;
    }

    const ColumnOutlierAnalysisResult result =
        m_analysisEngine.analyzeColumnOutliers(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2OutlierResult =
        outlierToVariantMap(
            result
            );

    m_dataset2OutlierAvailable =
        true;

    emit dataset2OutlierChanged();

    return true;
}


// =========================================================
// CLEAR OUTLIER
// =========================================================

void AppController::clearDataset1Outliers()
{
    const bool hadResult =
        m_dataset1OutlierAvailable ||
        !m_dataset1OutlierResult.isEmpty();

    m_dataset1OutlierResult.clear();

    m_dataset1OutlierAvailable =
        false;

    if (hadResult)
    {
        emit dataset1OutlierChanged();
    }
}

void AppController::clearDataset2Outliers()
{
    const bool hadResult =
        m_dataset2OutlierAvailable ||
        !m_dataset2OutlierResult.isEmpty();

    m_dataset2OutlierResult.clear();

    m_dataset2OutlierAvailable =
        false;

    if (hadResult)
    {
        emit dataset2OutlierChanged();
    }
}


// =========================================================
// LOAD RAW METADATA
// =========================================================

bool AppController::loadRawMetadata(
    const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(
            filePath
            );

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawParameterDefinitions.clear();

        m_rawMetadataLoaded = false;

        m_rawMetadataFilePath.clear();

        m_rawWarnings.clear();

        clearRawParse();

        setError(
            QStringLiteral(
                "Raw metadata file path is empty."
                )
            );

        emit rawMetadataChanged();

        return false;
    }

    QStringList errors;
    QStringList warnings;

    const QList<ParameterDefinition> definitions =
        m_rawMetadataParser.loadParameterDefinitions(
            normalizedPath,
            &errors,
            &warnings
            );

    if (!errors.isEmpty() ||
        definitions.isEmpty())
    {
        m_rawParameterDefinitions.clear();

        m_rawMetadataLoaded = false;

        m_rawMetadataFilePath.clear();

        m_rawWarnings =
            warnings;

        clearRawParse();

        if (!errors.isEmpty())
        {
            setError(
                errors.join(
                    QStringLiteral("\n")
                    )
                );
        }
        else
        {
            setError(
                QStringLiteral(
                    "No valid raw parameter definitions were found."
                    )
                );
        }

        emit rawMetadataChanged();

        return false;
    }

    m_rawParameterDefinitions =
        definitions;

    m_rawWarnings =
        warnings;

    m_rawMetadataFilePath =
        normalizedPath;

    m_rawMetadataLoaded =
        true;

    clearRawParse();

    emit rawMetadataChanged();

    return true;
}


// =========================================================
// LOAD RAW DATA
// =========================================================

bool AppController::loadRawDataFile(
    const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(
            filePath
            );

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawData.clear();

        m_rawDataLoaded = false;

        m_rawDataFilePath.clear();

        clearRawParse();

        setError(
            QStringLiteral(
                "Raw data file path is empty."
                )
            );

        emit rawDataChanged();

        return false;
    }

    FileRawDataSource source(
        normalizedPath
        );

    const RawDataSourceResult result =
        source.read();

    if (!result.success)
    {
        m_rawData.clear();

        m_rawDataLoaded = false;

        m_rawDataFilePath.clear();

        clearRawParse();

        setError(
            result.errorMessage
            );

        emit rawDataChanged();

        return false;
    }

    m_rawData =
        result.data;

    m_rawDataFilePath =
        normalizedPath;

    m_rawDataLoaded =
        true;

    clearRawParse();

    emit rawDataChanged();

    return true;
}


// =========================================================
// PARSE RAW DATA
// =========================================================

bool AppController::parseRawData()
{
    clearError();

    clearRawParse();

    if (!m_rawMetadataLoaded ||
        m_rawParameterDefinitions.isEmpty())
    {
        setError(
            QStringLiteral(
                "Raw metadata is not loaded."
                )
            );

        return false;
    }

    if (!m_rawDataLoaded ||
        m_rawData.isEmpty())
    {
        setError(
            QStringLiteral(
                "Raw data is not loaded."
                )
            );

        return false;
    }

    const QList<ParsedParameter> parsedParameters =
        m_rawDataParser.parse(
            m_rawData,
            m_rawParameterDefinitions
            );

    if (parsedParameters.isEmpty())
    {
        setError(
            QStringLiteral(
                "Raw data parser produced no results."
                )
            );

        return false;
    }

    m_parameterModel.setParameters(
        parsedParameters
        );

    bool hasSuccessfulParameter =
        false;

    bool hasErrorParameter =
        false;

    for (const ParsedParameter &parameter :
         parsedParameters)
    {
        if (parameter.parsedSuccessfully())
        {
            hasSuccessfulParameter = true;
        }

        if (parameter.hasError())
        {
            hasErrorParameter = true;
        }
    }

    if (!hasSuccessfulParameter)
    {
        m_parameterModel.clear();

        m_rawParseAvailable =
            false;

        setError(
            QStringLiteral(
                "None of the raw parameters could be parsed successfully."
                )
            );

        emit rawParseChanged();

        return false;
    }

    m_rawParseAvailable =
        true;

    emit rawParseChanged();

    if (hasErrorParameter)
    {
        setError(
            QStringLiteral(
                "Raw data was parsed, but one or more parameters contain errors."
                )
            );
    }

    return true;
}


// =========================================================
// CLEAR RAW
// =========================================================

void AppController::clearRawMetadata()
{
    const bool hadData =
        m_rawMetadataLoaded ||
        !m_rawParameterDefinitions.isEmpty() ||
        !m_rawMetadataFilePath.isEmpty() ||
        !m_rawWarnings.isEmpty();

    m_rawParameterDefinitions.clear();

    m_rawMetadataFilePath.clear();

    m_rawWarnings.clear();

    m_rawMetadataLoaded =
        false;

    clearRawParse();

    if (hadData)
    {
        emit rawMetadataChanged();
    }
}

void AppController::clearRawData()
{
    const bool hadData =
        m_rawDataLoaded ||
        !m_rawData.isEmpty() ||
        !m_rawDataFilePath.isEmpty();

    m_rawData.clear();

    m_rawDataFilePath.clear();

    m_rawDataLoaded =
        false;

    clearRawParse();

    if (hadData)
    {
        emit rawDataChanged();
    }
}

void AppController::clearRawParse()
{
    const bool hadResults =
        m_rawParseAvailable ||
        !m_parameterModel.isEmpty();

    m_parameterModel.clear();

    m_rawParseAvailable =
        false;

    if (hadResults)
    {
        emit rawParseChanged();
    }
}


// =========================================================
// HELPERS
// =========================================================

QString AppController::normalizeFilePath(
    const QString &filePath) const
{
    if (filePath.trimmed().isEmpty())
    {
        return QString();
    }

    const QUrl url(
        filePath
        );

    if (url.isLocalFile())
    {
        return url.toLocalFile();
    }

    return filePath;
}


void AppController::tryGenerateMappings()
{
    if (m_dataset1.isEmpty() ||
        m_dataset2.isEmpty())
    {
        m_mappingModel.clear();

        emit mappingsChanged();

        return;
    }

    generateMappings();
}


void AppController::setError(
    const QString &message)
{
    if (m_lastError == message)
    {
        return;
    }

    m_lastError =
        message;

    emit errorChanged();
}


void AppController::clearError()
{
    if (m_lastError.isEmpty())
    {
        return;
    }

    m_lastError.clear();

    emit errorChanged();
}


// =========================================================
// STATISTICS -> MAP
// =========================================================

QVariantMap AppController::statisticsToVariantMap(
    const StatisticsResult &statistics) const
{
    QVariantMap map;

    map.insert("count", statistics.count);
    map.insert("mean", statistics.mean);
    map.insert("median", statistics.median);
    map.insert("minimum", statistics.minimum);
    map.insert("maximum", statistics.maximum);
    map.insert("range", statistics.range);
    map.insert("variance", statistics.variance);

    map.insert(
        "standardDeviation",
        statistics.standardDeviation
        );

    map.insert("q1", statistics.q1);
    map.insert("q3", statistics.q3);
    map.insert("iqr", statistics.iqr);

    return map;
}


// =========================================================
// QUALITY -> MAP
// =========================================================

QVariantMap AppController::qualityToVariantMap(
    const DatasetQualityResult &quality) const
{
    QVariantMap map;

    map.insert(
        "rowCount",
        quality.rowCount
        );

    map.insert(
        "columnCount",
        quality.columnCount
        );

    map.insert(
        "totalMissingValues",
        quality.totalMissingValues
        );

    map.insert(
        "missingPercentage",
        quality.missingPercentage
        );

    map.insert(
        "columnsWithMissingValues",
        quality.columnsWithMissingValues
        );

    map.insert(
        "columnsWithMissing",
        quality.columnsWithMissing
        );

    map.insert(
        "duplicateRowCount",
        quality.duplicateRowCount
        );

    map.insert(
        "duplicatePercentage",
        quality.duplicatePercentage
        );

    map.insert(
        "constantColumnCount",
        quality.constantColumnCount
        );

    map.insert(
        "constantColumns",
        quality.constantColumns
        );

    map.insert(
        "numericColumnCount",
        quality.numericColumnCount
        );

    map.insert(
        "nonNumericColumnCount",
        quality.nonNumericColumnCount
        );

    return map;
}


// =========================================================
// OUTLIER -> MAP
// =========================================================

QVariantMap AppController::outlierToVariantMap(
    const ColumnOutlierAnalysisResult &result) const
{
    QVariantMap map;

    map.insert(
        "columnName",
        result.columnName
        );

    map.insert(
        "validValueCount",
        result.outlierResult.validValueCount
        );

    map.insert(
        "q1",
        result.outlierResult.q1
        );

    map.insert(
        "q3",
        result.outlierResult.q3
        );

    map.insert(
        "iqr",
        result.outlierResult.iqr
        );

    map.insert(
        "lowerBound",
        result.outlierResult.lowerBound
        );

    map.insert(
        "upperBound",
        result.outlierResult.upperBound
        );

    map.insert(
        "outlierCount",
        result.outlierResult.outlierCount
        );

    map.insert(
        "outlierPercentage",
        result.outlierResult.outlierPercentage
        );

    QVariantList outlierValues;

    outlierValues.reserve(
        result.outlierResult.outlierValues.size()
        );

    for (double value :
         result.outlierResult.outlierValues)
    {
        outlierValues.append(
            value
            );
    }

    map.insert(
        "outlierValues",
        outlierValues
        );

    return map;
}