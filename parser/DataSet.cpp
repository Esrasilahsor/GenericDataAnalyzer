#include "DataSet.h"

#include <QSet>


DataSet::DataSet()
{
}


// =========================================================
// NAME
// =========================================================

QString DataSet::name() const
{
    return m_name;
}


void DataSet::setName(
    const QString &name
    )
{
    m_name =
        name;
}


// =========================================================
// FILE PATH
// =========================================================

QString DataSet::filePath() const
{
    return m_filePath;
}


void DataSet::setFilePath(
    const QString &filePath
    )
{
    m_filePath =
        filePath;
}


// =========================================================
// SHEET NAME
// =========================================================

QString DataSet::sheetName() const
{
    return m_sheetName;
}


void DataSet::setSheetName(
    const QString &sheetName
    )
{
    m_sheetName =
        sheetName;
}


// =========================================================
// ADD COLUMN
// =========================================================

void DataSet::addColumn(
    const ColumnInfo &column
    )
{
    m_columns.append(
        column
        );
}


// =========================================================
// SET COLUMNS
// =========================================================

void DataSet::setColumns(
    const QVector<ColumnInfo> &columns
    )
{
    m_columns =
        columns;
}


// =========================================================
// GET COLUMNS
// =========================================================

QVector<ColumnInfo> DataSet::columns() const
{
    return m_columns;
}


// =========================================================
// SET COLUMN VALUES
// =========================================================

bool DataSet::setColumnValues(
    const QString &columnName,
    const QVector<QVariant> &values
    )
{
    // -----------------------------------------------------
    // Temel kontroller
    // -----------------------------------------------------

    if (columnName.trimmed().isEmpty())
    {
        return false;
    }


    if (m_columns.isEmpty())
    {
        return false;
    }


    // -----------------------------------------------------
    // Satır sayısı korunmalı
    //
    // Mean/Median/Mode doldurma işlemleri satır silmez.
    // Sadece mevcut hücreleri değiştirir.
    // -----------------------------------------------------

    const int currentRowCount =
        rowCount();


    if (values.size() != currentRowCount)
    {
        return false;
    }


    // -----------------------------------------------------
    // İlgili sütunu bul
    // -----------------------------------------------------

    for (ColumnInfo &column :
         m_columns)
    {
        if (column.name() !=
            columnName)
        {
            continue;
        }


        // -------------------------------------------------
        // Değerleri güncelle
        // -------------------------------------------------

        column.setValues(
            values
            );


        // -------------------------------------------------
        // Missing / Unique metadata artık değişmiş olabilir.
        // -------------------------------------------------

        refreshColumnMetadata(
            column
            );


        return true;
    }


    return false;
}


// =========================================================
// COLUMN COUNT
// =========================================================

int DataSet::columnCount() const
{
    return m_columns.size();
}


// =========================================================
// ROW COUNT
// =========================================================

int DataSet::rowCount() const
{
    if (m_columns.isEmpty())
    {
        return 0;
    }


    return m_columns.first()
        .valueCount();
}


// =========================================================
// EMPTY
// =========================================================

bool DataSet::isEmpty() const
{
    return m_columns.isEmpty();
}


// =========================================================
// FIND COLUMN
// =========================================================

const ColumnInfo *DataSet::findColumn(
    const QString &columnName
    ) const
{
    for (const ColumnInfo &column :
         m_columns)
    {
        if (column.name() ==
            columnName)
        {
            return &column;
        }
    }


    return nullptr;
}


// =========================================================
// REMOVE ROWS
// =========================================================

bool DataSet::removeRows(
    const QVector<int> &rowIndexes
    )
{
    if (m_columns.isEmpty())
    {
        return false;
    }


    if (rowIndexes.isEmpty())
    {
        return false;
    }


    const int currentRowCount =
        rowCount();


    if (currentRowCount <= 0)
    {
        return false;
    }


    // =====================================================
    // VALID INDEX SET
    // =====================================================

    QSet<int> indexesToRemove;


    for (int index :
         rowIndexes)
    {
        if (index < 0 ||
            index >= currentRowCount)
        {
            continue;
        }


        indexesToRemove.insert(
            index
            );
    }


    if (indexesToRemove.isEmpty())
    {
        return false;
    }


    // =====================================================
    // BÜTÜN SÜTUNLARDAN AYNI SATIRLARI KALDIR
    // =====================================================

    for (ColumnInfo &column :
         m_columns)
    {
        const QVector<QVariant> oldValues =
            column.values();


        QVector<QVariant> newValues;


        const int expectedSize =
            qMax(
                0,
                oldValues.size()
                    -
                    indexesToRemove.size()
                );


        newValues.reserve(
            expectedSize
            );


        for (int row = 0;
             row < oldValues.size();
             ++row)
        {
            if (indexesToRemove.contains(
                    row))
            {
                continue;
            }


            newValues.append(
                oldValues.at(row)
                );
        }


        column.setValues(
            newValues
            );


        refreshColumnMetadata(
            column
            );
    }


    return true;
}


// =========================================================
// REFRESH COLUMN METADATA
// =========================================================

void DataSet::refreshColumnMetadata(
    ColumnInfo &column
    )
{
    const QVector<QVariant> values =
        column.values();


    int missingCount =
        0;


    QSet<QString> uniqueValues;


    for (const QVariant &value :
         values)
    {
        // -------------------------------------------------
        // Missing kontrolü
        // -------------------------------------------------

        const bool missing =
            !value.isValid()
            ||
            value.isNull()
            ||
            (
                value.type() ==
                    QVariant::String
                &&
                value.toString()
                    .trimmed()
                    .isEmpty()
                );


        if (missing)
        {
            ++missingCount;

            continue;
        }


        // -------------------------------------------------
        // Unique kontrolü
        // -------------------------------------------------

        const QString uniqueKey =
            QString::number(
                static_cast<int>(
                    value.type()
                    )
                )
            +
            QStringLiteral(":")
            +
            value.toString();


        uniqueValues.insert(
            uniqueKey
            );
    }


    // =====================================================
    // MISSING COUNT
    // =====================================================

    column.setMissingCount(
        missingCount
        );


    // =====================================================
    // MISSING PERCENTAGE
    // =====================================================

    if (!values.isEmpty())
    {
        column.setMissingPercentage(
            (
                static_cast<double>(
                    missingCount
                    )
                /
                static_cast<double>(
                    values.size()
                    )
                )
            *
            100.0
            );
    }
    else
    {
        column.setMissingPercentage(
            0.0
            );
    }


    // =====================================================
    // UNIQUE COUNT
    // =====================================================

    column.setUniqueCount(
        uniqueValues.size()
        );
}


// =========================================================
// CLEAR
// =========================================================

void DataSet::clear()
{
    m_name.clear();
    m_filePath.clear();
    m_sheetName.clear();

    m_columns.clear();
}