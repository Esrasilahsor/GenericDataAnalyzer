#include "ParameterModel.h"


ParameterModel::ParameterModel(
    QObject *parent)
    : QAbstractListModel(parent)
{
}


// =========================================================
// ROW COUNT
// =========================================================

int ParameterModel::rowCount(
    const QModelIndex &parent) const
{
    /*
     * List model olduğu için child item yok.
     */
    if (parent.isValid())
        return 0;

    return m_parameters.size();
}


// =========================================================
// DATA
// =========================================================

QVariant ParameterModel::data(
    const QModelIndex &index,
    int role) const
{
    /*
     * QML yanlış index gönderirse kesinlikle
     * QVector dışına çıkmıyoruz.
     */
    if (!index.isValid())
        return QVariant();

    const int row =
        index.row();

    if (row < 0 ||
        row >= m_parameters.size()) {

        return QVariant();
    }


    const ParsedParameter &parameter =
        m_parameters.at(row);


    switch (role) {

    case DataNameRole:
        return parameter.dataName;

    case ValueRole:
        return parameter.value;

    case RawValueRole:
        return parameter.rawValue;

    case DisplayValueRole:
        return parameter.displayValue;

    case DataTypeRole:
        return parameter.dataType;

    case UnitRole:
        return parameter.unit;

    case InfoRole:
        return parameter.info;

    case StatusRole:
        return ParseStatusUtils::toString(
            parameter.status);

    case ErrorMessageRole:
        return parameter.errorMessage;

    case WarningsRole:
        return parameter.warnings;

    case ValidRole:
        return parameter.parsedSuccessfully();

    default:
        return QVariant();
    }
}


// =========================================================
// ROLE NAMES
// =========================================================

QHash<int, QByteArray>
ParameterModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[DataNameRole] =
        "dataName";

    roles[ValueRole] =
        "value";

    roles[RawValueRole] =
        "rawValue";

    roles[DisplayValueRole] =
        "displayValue";

    roles[DataTypeRole] =
        "dataType";

    roles[UnitRole] =
        "unit";

    roles[InfoRole] =
        "info";

    roles[StatusRole] =
        "status";

    roles[ErrorMessageRole] =
        "errorMessage";

    roles[WarningsRole] =
        "warnings";

    roles[ValidRole] =
        "valid";

    return roles;
}


// =========================================================
// SET PARAMETERS
// =========================================================

void ParameterModel::setParameters(
    const QList<ParsedParameter> &parameters)
{
    beginResetModel();

    m_parameters.clear();

    m_parameters.reserve(
        parameters.size());


    for (const ParsedParameter &parameter :
         parameters) {

        m_parameters.append(
            parameter);
    }


    endResetModel();
}


// =========================================================
// CLEAR
// =========================================================

void ParameterModel::clear()
{
    if (m_parameters.isEmpty())
        return;

    beginResetModel();

    m_parameters.clear();

    endResetModel();
}


// =========================================================
// COUNT
// =========================================================

int ParameterModel::parameterCount() const
{
    return m_parameters.size();
}


// =========================================================
// EMPTY
// =========================================================

bool ParameterModel::isEmpty() const
{
    return m_parameters.isEmpty();
}


// =========================================================
// SAFE ACCESS
// =========================================================

const ParsedParameter *
ParameterModel::parameterAt(
    int index) const
{
    if (index < 0 ||
        index >= m_parameters.size()) {

        return nullptr;
    }

    return &m_parameters.at(index);
}