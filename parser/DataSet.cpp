#include "DataSet.h"

DataSet::DataSet()
{
}

QString DataSet::name() const
{
    return m_name;
}

void DataSet::setName(const QString &name)
{
    m_name = name;
}

QString DataSet::filePath() const
{
    return m_filePath;
}

void DataSet::setFilePath(
    const QString &filePath
    )
{
    m_filePath = filePath;
}

QString DataSet::sheetName() const
{
    return m_sheetName;
}

void DataSet::setSheetName(
    const QString &sheetName
    )
{
    m_sheetName = sheetName;
}

void DataSet::addColumn(
    const ColumnInfo &column
    )
{
    m_columns.append(column);
}

void DataSet::setColumns(
    const QVector<ColumnInfo> &columns
    )
{
    m_columns = columns;
}

QVector<ColumnInfo> DataSet::columns() const
{
    return m_columns;
}

int DataSet::columnCount() const
{
    return m_columns.size();
}

int DataSet::rowCount() const
{
    if (m_columns.isEmpty())
    {
        return 0;
    }

    return m_columns.first().valueCount();
}

bool DataSet::isEmpty() const
{
    return m_columns.isEmpty();
}

const ColumnInfo *DataSet::findColumn(
    const QString &columnName
    ) const
{
    for (const ColumnInfo &column : m_columns)
    {
        if (column.name() == columnName)
        {
            return &column;
        }
    }

    return nullptr;
}

void DataSet::clear()
{
    m_name.clear();
    m_filePath.clear();
    m_sheetName.clear();

    m_columns.clear();
}