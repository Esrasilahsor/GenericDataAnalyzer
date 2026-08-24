#include "FileRawDataSource.h"

#include <QFile>
#include <QFileInfo>


FileRawDataSource::FileRawDataSource(
    const QString &filePath)
    : m_filePath(filePath)
{
}


void FileRawDataSource::setFilePath(
    const QString &filePath)
{
    m_filePath = filePath;
}


QString FileRawDataSource::filePath() const
{
    return m_filePath;
}


RawDataSourceResult
FileRawDataSource::read()
{
    const QString path =
        m_filePath.trimmed();

    if (path.isEmpty()) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file path is empty."));
    }


    const QFileInfo fileInfo(path);


    if (!fileInfo.exists()) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file does not exist: %1")
                .arg(path));
    }


    if (!fileInfo.isFile()) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data source is not a file."));
    }


    const qint64 fileSize =
        fileInfo.size();


    if (fileSize <= 0) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file is empty."));
    }


    if (fileSize > MaxFileSize) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file exceeds the maximum supported size of %1 MB.")
                .arg(
                    MaxFileSize /
                    (1024LL * 1024LL)));
    }


    QFile file(path);


    if (!file.open(
            QIODevice::ReadOnly)) {

        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file could not be opened: %1")
                .arg(file.errorString()));
    }


    const QByteArray data =
        file.readAll();


    if (file.error() != QFileDevice::NoError) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data file could not be read completely: %1")
                .arg(file.errorString()));
    }


    if (data.isEmpty()) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data source returned no bytes."));
    }


    if (data.size() != fileSize) {
        return RawDataSourceResult::error(
            QStringLiteral(
                "Raw data size mismatch. Expected %1 bytes, read %2 bytes.")
                .arg(fileSize)
                .arg(data.size()));
    }


    return RawDataSourceResult::ok(data);
}