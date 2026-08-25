#include "ColumnInfo.h"

ColumnInfo::ColumnInfo()
    : m_dataType(DataType::Unknown),
    m_missingCount(0),
    m_missingPercentage(0.0),
    m_uniqueCount(0)
{
}

ColumnInfo::ColumnInfo(const QString &name)
    : m_name(name),
    m_originalName(name),
    m_dataType(DataType::Unknown),
    m_missingCount(0),
    m_missingPercentage(0.0),
    m_uniqueCount(0)
{
}

QString ColumnInfo::name() const
{
    return m_name;
}

void ColumnInfo::setName(const QString &name)
{
    m_name = name;
}

QString ColumnInfo::originalName() const
{
    return m_originalName;
}

void ColumnInfo::setOriginalName(const QString &originalName)
{
    m_originalName = originalName;
}

ColumnInfo::DataType ColumnInfo::dataType() const
{
    return m_dataType;
}

void ColumnInfo::setDataType(DataType type)
{
    m_dataType = type;
}

QVector<QVariant> ColumnInfo::values() const
{
    return m_values;
}

void ColumnInfo::setValues(const QVector<QVariant> &values)
{
    m_values = values;
}

void ColumnInfo::addValue(const QVariant &value)
{
    m_values.append(value);
}

int ColumnInfo::valueCount() const
{
    return m_values.size();
}

int ColumnInfo::missingCount() const
{
    return m_missingCount;
}

void ColumnInfo::setMissingCount(int count)
{
    m_missingCount = count;
}

double ColumnInfo::missingPercentage() const
{
    return m_missingPercentage;
}

void ColumnInfo::setMissingPercentage(double percentage)
{
    m_missingPercentage = percentage;
}

int ColumnInfo::uniqueCount() const
{
    return m_uniqueCount;
}

void ColumnInfo::setUniqueCount(int count)
{
    m_uniqueCount = count;
}

bool ColumnInfo::isNumeric() const
{
    return m_dataType == DataType::Integer
           || m_dataType == DataType::Double;
}