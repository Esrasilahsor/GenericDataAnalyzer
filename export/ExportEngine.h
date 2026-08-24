#ifndef EXPORTENGINE_H
#define EXPORTENGINE_H

#include <QString>

#include "../parser/DataSet.h"

struct ExportResult
{
    bool success = false;
    QString filePath;
    QString errorMessage;
};

class ExportEngine
{
public:
    ExportEngine();

    ExportResult exportDataSetToCsv(
        const DataSet &dataSet,
        const QString &filePath
        ) const;

    ExportResult exportDataSetToJson(
        const DataSet &dataSet,
        const QString &filePath
        ) const;

    ExportResult exportDataSetToXlsx(
        const DataSet &dataSet,
        const QString &filePath
        ) const;

private:
    QString normalizeCsvValue(
        const QString &value
        ) const;
};

#endif // EXPORTENGINE_H