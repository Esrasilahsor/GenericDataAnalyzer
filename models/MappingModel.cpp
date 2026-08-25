#include "MappingModel.h"

MappingModel::MappingModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MappingModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
    {
        return 0;
    }

    return m_mappings.size();
}

QVariant MappingModel::data(
    const QModelIndex &index,
    int role
    ) const
{
    if (!index.isValid())
    {
        return QVariant();
    }

    if (index.row() < 0 || index.row() >= m_mappings.size())
    {
        return QVariant();
    }

    const ColumnMapping &mapping =
        m_mappings.at(index.row());

    switch (role)
    {
    case SourceColumnRole:
        return mapping.sourceColumn;

    case TargetColumnRole:
        return mapping.targetColumn;

    case SimilarityScoreRole:
        return mapping.similarityScore;

    case AcceptedRole:
        return mapping.accepted;

    default:
        return QVariant();
    }
}

bool MappingModel::setData(
    const QModelIndex &index,
    const QVariant &value,
    int role
    )
{
    if (!index.isValid())
    {
        return false;
    }

    if (index.row() < 0 || index.row() >= m_mappings.size())
    {
        return false;
    }

    ColumnMapping &mapping =
        m_mappings[index.row()];

    if (role == AcceptedRole)
    {
        mapping.accepted =
            value.toBool();

        emit dataChanged(
            index,
            index,
            { AcceptedRole }
            );

        return true;
    }

    return false;
}

Qt::ItemFlags MappingModel::flags(
    const QModelIndex &index
    ) const
{
    if (!index.isValid())
    {
        return Qt::NoItemFlags;
    }

    return Qt::ItemIsEnabled
           | Qt::ItemIsSelectable
           | Qt::ItemIsEditable;
}

QHash<int, QByteArray> MappingModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[SourceColumnRole] =
        "sourceColumn";

    roles[TargetColumnRole] =
        "targetColumn";

    roles[SimilarityScoreRole] =
        "similarityScore";

    roles[AcceptedRole] =
        "accepted";

    return roles;
}

void MappingModel::setMappings(
    const QVector<ColumnMapping> &mappings
    )
{
    beginResetModel();

    m_mappings = mappings;

    endResetModel();

    emit countChanged();
}

void MappingModel::addMapping(
    const ColumnMapping &mapping
    )
{
    const int newRow =
        m_mappings.size();

    beginInsertRows(
        QModelIndex(),
        newRow,
        newRow
        );

    m_mappings.append(mapping);

    endInsertRows();

    emit countChanged();
}

void MappingModel::addMapping(
    const QString &sourceColumn,
    const QString &targetColumn,
    double similarityScore,
    bool accepted
    )
{
    ColumnMapping mapping;
    mapping.sourceColumn = sourceColumn;
    mapping.targetColumn = targetColumn;
    mapping.similarityScore = similarityScore;
    mapping.accepted = accepted;

    addMapping(mapping);
}

void MappingModel::removeMapping(int index)
{
    if (index < 0 || index >= m_mappings.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_mappings.removeAt(index);
    endRemoveRows();
    emit countChanged();
}

void MappingModel::remove(int index)
{
    removeMapping(index);
}

void MappingModel::clear()
{
    if (m_mappings.isEmpty())
    {
        return;
    }

    beginResetModel();

    m_mappings.clear();

    endResetModel();

    emit countChanged();
}

int MappingModel::count() const
{
    return m_mappings.size();
}

void MappingModel::setAccepted(
    int index,
    bool accepted
    )
{
    if (index < 0 || index >= m_mappings.size())
    {
        return;
    }

    QModelIndex modelIndex =
        createIndex(index, 0);

    setData(
        modelIndex,
        accepted,
        AcceptedRole
        );
}

QVariantMap MappingModel::get(int index) const
{
    if (index < 0 || index >= m_mappings.size())
    {
        return QVariantMap();
    }

    const ColumnMapping &m = m_mappings.at(index);
    QVariantMap map;
    map[QStringLiteral("sourceColumn")] = m.sourceColumn;
    map[QStringLiteral("targetColumn")] = m.targetColumn;
    map[QStringLiteral("similarityScore")] = m.similarityScore;
    map[QStringLiteral("accepted")] = m.accepted;
    return map;
}