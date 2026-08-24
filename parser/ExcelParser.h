#ifndef EXCELPARSER_H
#define EXCELPARSER_H

#include <QString>
#include <QStringList>
#include <QList>

#include "DataSet.h"
#include "ParserTypes.h"


class ExcelParser
{
public:
    ExcelParser();

    // =====================================================
    // NORMAL DATASET PARSING
    // Supports: .xlsx, .csv, .txt
    // =====================================================

    bool loadFile(
        const QString &filePath);

    const DataSet &dataSet() const;

    QString lastError() const;


    // =====================================================
    // RAW DATA PARAMETER METADATA PARSING
    // =====================================================

    QList<ParameterDefinition> loadParameterDefinitions(
        const QString &filePath,
        QStringList *errors = nullptr,
        QStringList *warnings = nullptr);

private:
    bool loadExcelDataSet(
        const QString &filePath);

    bool loadDelimitedDataSet(
        const QString &filePath);

    DataSet m_dataSet;

    QString m_lastError;
};


#endif // EXCELPARSER_H