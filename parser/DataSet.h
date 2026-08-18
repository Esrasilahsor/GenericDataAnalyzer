#ifndef DATASET_H
#define DATASET_H

#include <QString>
#include <QVector>

#include "ColumnInfo.h"

class DataSet
{
public:
    DataSet();

    QString name() const;
    void setName(const QString &name);

    QString filePath() const;
    void setFilePath(const QString &filePath);

    QString sheetName() const;
    void setSheetName(const QString &sheetName);

    void addColumn(const ColumnInfo &column);

    void setColumns(
        const QVector<ColumnInfo> &columns
        );

    QVector<ColumnInfo> columns() const;

    int columnCount() const;
    int rowCount() const;

    bool isEmpty() const;

    const ColumnInfo *findColumn(
        const QString &columnName
        ) const;

    void clear();

private:
    QString m_name;
    QString m_filePath;
    QString m_sheetName;

    QVector<ColumnInfo> m_columns;
};

#endif // DATASET_H