#ifndef COLUMNMODEL_H
#define COLUMNMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QVariant>
#include <QHash>
#include <QByteArray>
#include <QString>

#include "../parser/ColumnInfo.h"

class ColumnModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ColumnRoles
    {
        NameRole = Qt::UserRole + 1,
        OriginalNameRole,
        DataTypeRole,
        MissingCountRole,
        MissingPercentageRole,
        UniqueCountRole,
        IsNumericRole
    };

    explicit ColumnModel(QObject *parent = nullptr);

    int rowCount(
        const QModelIndex &parent = QModelIndex()
        ) const override;

    QVariant data(
        const QModelIndex &index,
        int role = Qt::DisplayRole
        ) const override;

    QHash<int, QByteArray> roleNames() const override;

    void setColumns(const QVector<ColumnInfo> &columns);

    void clear();

    Q_INVOKABLE int count() const;

private:
    QVector<ColumnInfo> m_columns;

    QString dataTypeToString(
        ColumnInfo::DataType type
        ) const;
};

#endif // COLUMNMODEL_H