#ifndef PARAMETERMODEL_H
#define PARAMETERMODEL_H

#include <QAbstractListModel>
#include <QVector>

#include "../parser/ParserTypes.h"

class ParameterModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        DataNameRole = Qt::UserRole + 1,
        ValueRole,
        RawValueRole,
        DisplayValueRole,
        DataTypeRole,
        UnitRole,
        InfoRole,
        StatusRole,
        ErrorMessageRole,
        WarningsRole,
        ValidRole
    };

    Q_PROPERTY(int count READ count NOTIFY countChanged)

    explicit ParameterModel(
        QObject *parent = nullptr);

    int rowCount(
        const QModelIndex &parent =
        QModelIndex()) const override;

    QVariant data(
        const QModelIndex &index,
        int role =
        Qt::DisplayRole) const override;

    QHash<int, QByteArray>
    roleNames() const override;

    Q_INVOKABLE int count() const;
    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void countChanged();

public:
    // =====================================================
    // DATA MANAGEMENT
    // =====================================================

    void setParameters(
        const QList<ParsedParameter> &parameters);

    void clear();

    int parameterCount() const;

    bool isEmpty() const;


    // =====================================================
    // SAFE ACCESS
    // =====================================================

    const ParsedParameter *parameterAt(
        int index) const;

private:
    QVector<ParsedParameter> m_parameters;
};

#endif // PARAMETERMODEL_H