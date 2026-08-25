#include "ColumnModel.h"

ColumnModel::ColumnModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ColumnModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
    {
        return 0;
    }

    return m_columns.size();
}

QVariant ColumnModel::data(
    const QModelIndex &index,
    int role
    ) const
{
    if (!index.isValid())
    {
        return QVariant();
    }

    if (index.row() < 0 || index.row() >= m_columns.size())
    {
        return QVariant();
    }

    const ColumnInfo &column = m_columns.at(index.row());

    switch (role)
    {
    case NameRole:
        return column.name();

    case OriginalNameRole:
        return column.originalName();

    case DataTypeRole:
        return dataTypeToString(column.dataType());

    case MissingCountRole:
        return column.missingCount();

    case MissingPercentageRole:
        return column.missingPercentage();

    case UniqueCountRole:
        return column.uniqueCount();

    case IsNumericRole:
        return column.isNumeric();

    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ColumnModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[NameRole] = "name";
    roles[OriginalNameRole] = "originalName";
    roles[DataTypeRole] = "dataType";
    roles[MissingCountRole] = "missingCount";
    roles[MissingPercentageRole] = "missingPercentage";
    roles[UniqueCountRole] = "uniqueCount";
    roles[IsNumericRole] = "isNumeric";

    return roles;
}

void ColumnModel::setColumns(
    const QVector<ColumnInfo> &columns
    )
{
    beginResetModel();

    m_columns = columns;

    endResetModel();
}

void ColumnModel::clear()
{
    beginResetModel();

    m_columns.clear();

    endResetModel();
}

int ColumnModel::count() const
{
    return m_columns.size();
}

QVariantMap ColumnModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_columns.size())
        return map;

    const ColumnInfo &col = m_columns.at(index);
    map[QStringLiteral("name")] = col.name();
    map[QStringLiteral("originalName")] = col.originalName();
    map[QStringLiteral("dataType")] = dataTypeToString(col.dataType());
    map[QStringLiteral("missingCount")] = col.missingCount();
    map[QStringLiteral("missingPercentage")] = col.missingPercentage();
    map[QStringLiteral("uniqueCount")] = col.uniqueCount();
    map[QStringLiteral("isNumeric")] = col.isNumeric();
    return map;
}

bool ColumnModel::isNumeric(int index) const
{
    if (index < 0 || index >= m_columns.size())
        return false;
    return m_columns.at(index).isNumeric();
}

bool ColumnModel::isColumnNumeric(const QString &name) const
{
    for (const ColumnInfo &col : m_columns)
    {
        if (col.name().compare(name, Qt::CaseInsensitive) == 0 ||
            col.originalName().compare(name, Qt::CaseInsensitive) == 0)
        {
            return col.isNumeric();
        }
    }
    return false;
}

QString ColumnModel::dataTypeToString(
    ColumnInfo::DataType type
    ) const
{
    switch (type)
    {
    case ColumnInfo::DataType::Integer:
        return "Integer";

    case ColumnInfo::DataType::Double:
        return "Double";

    case ColumnInfo::DataType::String:
        return "String";

    case ColumnInfo::DataType::Boolean:
        return "Boolean";

    case ColumnInfo::DataType::DateTime:
        return "DateTime";

    case ColumnInfo::DataType::Unknown:
    default:
        return "Unknown";
    }
}