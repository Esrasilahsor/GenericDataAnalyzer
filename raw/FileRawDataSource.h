#ifndef FILERAWDATASOURCE_H
#define FILERAWDATASOURCE_H

#include <QString>

#include "IRawDataSource.h"

class FileRawDataSource : public IRawDataSource
{
public:
    explicit FileRawDataSource(
        const QString &filePath);

    void setFilePath(
        const QString &filePath);

    QString filePath() const;

    RawDataSourceResult read() override;

private:
    QString m_filePath;

    static constexpr qint64 MaxFileSize =
        64LL * 1024LL * 1024LL;
};

#endif // FILERAWDATASOURCE_H