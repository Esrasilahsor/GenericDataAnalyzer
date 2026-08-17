#ifndef EXCELPARSER_H
#define EXCELPARSER_H

#include <QString>
#include <QVariant>

#include "DataSet.h"

class ExcelParser
{
public:
    ExcelParser();

    bool loadFile(const QString &filePath);

    DataSet dataSet() const;

    QString lastError() const;

private:
    DataSet m_dataSet;
    QString m_lastError;

    ColumnInfo::DataType detectColumnType(
        const QVector<QVariant> &values) const;

    bool isMissingValue(const QVariant &value) const;

    int calculateMissingCount(
        const QVector<QVariant> &values) const;

    int calculateUniqueCount(
        const QVector<QVariant> &values) const;
};

#endif // EXCELPARSER_H