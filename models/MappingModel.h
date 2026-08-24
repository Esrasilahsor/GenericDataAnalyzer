#ifndef MAPPINGMODEL_H
#define MAPPINGMODEL_H

#include <QAbstractListModel>
#include <QString>
#include <QVector>
#include <QHash>
#include <QByteArray>
#include <QVariant>

struct ColumnMapping
{
    QString sourceColumn;
    QString targetColumn;

    double similarityScore;

    bool accepted;
};

class MappingModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(
        int count
            READ count
                NOTIFY countChanged
        )

public:
    enum MappingRoles
    {
        SourceColumnRole = Qt::UserRole + 1,
        TargetColumnRole,
        SimilarityScoreRole,
        AcceptedRole
    };

    explicit MappingModel(QObject *parent = nullptr);

    int rowCount(
        const QModelIndex &parent = QModelIndex()
        ) const override;

    QVariant data(
        const QModelIndex &index,
        int role = Qt::DisplayRole
        ) const override;

    bool setData(
        const QModelIndex &index,
        const QVariant &value,
        int role
        ) override;

    Qt::ItemFlags flags(
        const QModelIndex &index
        ) const override;

    QHash<int, QByteArray> roleNames() const override;

    void setMappings(
        const QVector<ColumnMapping> &mappings
        );

    void addMapping(
        const ColumnMapping &mapping
        );

    void clear();

    int count() const;

    Q_INVOKABLE void setAccepted(
        int index,
        bool accepted
        );

    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void countChanged();

private:
    QVector<ColumnMapping> m_mappings;
};

#endif // MAPPINGMODEL_H