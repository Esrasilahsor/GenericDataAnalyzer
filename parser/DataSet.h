#ifndef DATASET_H
#define DATASET_H

#include <QString>
#include <QVector>

#include "ColumnInfo.h"


class DataSet
{
public:
    DataSet();


    // =====================================================
    // DATASET INFO
    // =====================================================

    QString name() const;
    void setName(const QString &name);

    QString filePath() const;
    void setFilePath(const QString &filePath);

    QString sheetName() const;
    void setSheetName(const QString &sheetName);


    // =====================================================
    // COLUMNS
    // =====================================================

    void addColumn(
        const ColumnInfo &column
        );

    void setColumns(
        const QVector<ColumnInfo> &columns
        );

    QVector<ColumnInfo> columns() const;


    // =====================================================
    // COLUMN VALUE UPDATE
    //
    // Cleaning işlemlerinde bir sütunun değerlerini
    // güvenli şekilde güncellemek için kullanılır.
    //
    // Mean / Median / Mode gibi bütün doldurma işlemleri
    // bu fonksiyonu kullanabilir.
    // =====================================================

    bool setColumnValues(
        const QString &columnName,
        const QVector<QVariant> &values
        );


    // =====================================================
    // COUNTS
    // =====================================================

    int columnCount() const;
    int rowCount() const;


    // =====================================================
    // STATE
    // =====================================================

    bool isEmpty() const;


    // =====================================================
    // FIND COLUMN
    // =====================================================

    const ColumnInfo *findColumn(
        const QString &columnName
        ) const;


    // =====================================================
    // GENERIC ROW REMOVAL
    // =====================================================

    bool removeRows(
        const QVector<int> &rowIndexes
        );

    bool removeColumn(
        const QString &columnName
        );


    // =====================================================
    // CLEAR
    // =====================================================

    void clear();


private:

    QString m_name;
    QString m_filePath;
    QString m_sheetName;

    QVector<ColumnInfo> m_columns;


    // =====================================================
    // HELPERS
    // =====================================================

    void refreshColumnMetadata(
        ColumnInfo &column
        );
};


#endif // DATASET_H