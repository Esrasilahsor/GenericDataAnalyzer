#ifndef RAWDATASOURCERESULT_H
#define RAWDATASOURCERESULT_H

#include <QByteArray>
#include <QString>

struct RawDataSourceResult
{
    bool success = false;
    QByteArray data;
    QString errorMessage;

    static RawDataSourceResult ok(const QByteArray &rawData)
    {
        RawDataSourceResult result;
        result.success = true;
        result.data = rawData;
        return result;
    }

    static RawDataSourceResult error(const QString &message)
    {
        RawDataSourceResult result;
        result.success = false;
        result.errorMessage = message;
        return result;
    }
};

#endif // RAWDATASOURCERESULT_H