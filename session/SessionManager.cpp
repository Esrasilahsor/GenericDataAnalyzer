#include "SessionManager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QDateTime>
#include <QDebug>

#include "../export/ExportEngine.h"
#include "../parser/ExcelParser.h"

SessionManager::SessionManager()
{
    ensureDirectoryExists();
}

SessionManager::~SessionManager()
{
}

QString SessionManager::sessionDirectory() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return QDir(base).filePath(QStringLiteral("session"));
}

QString SessionManager::sessionFilePath() const
{
    return QDir(sessionDirectory()).filePath(QStringLiteral("last_session.json"));
}

QString SessionManager::snapshotFilePath(int datasetIndex) const
{
    return QDir(sessionDirectory()).filePath(QStringLiteral("dataset%1_cleaned_snapshot.csv").arg(datasetIndex));
}

QString SessionManager::historyDirectory() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    return QDir(base).filePath(QStringLiteral("history"));
}

QString SessionManager::historyFilePath() const
{
    return QDir(historyDirectory()).filePath(QStringLiteral("cleaning_history.json"));
}

void SessionManager::ensureDirectoryExists() const
{
    const QString sessionDir = sessionDirectory();
    QDir sessionQDir(sessionDir);
    if (!sessionQDir.exists())
    {
        sessionQDir.mkpath(QStringLiteral("."));
    }

    const QString histDir = historyDirectory();
    QDir histQDir(histDir);
    if (!histQDir.exists())
    {
        histQDir.mkpath(QStringLiteral("."));
    }
}

bool SessionManager::loadSession()
{
    const QString filePath = sessionFilePath();
    if (!QFileInfo::exists(filePath))
    {
        return false;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        return false;
    }

    const QByteArray data = file.readAll();
    file.close();

    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject())
    {
        qWarning() << "[SessionManager] Failed to parse session JSON:" << error.errorString();
        return false;
    }

    const QJsonObject obj = doc.object();
    if (obj.value(QStringLiteral("version")).toInt() != m_version)
    {
        qWarning() << "[SessionManager] Unsupported session version:" << obj.value(QStringLiteral("version")).toInt();
        return false;
    }

    m_sessionObject = obj;
    return true;
}

bool SessionManager::saveSession()
{
    ensureDirectoryExists();

    m_sessionObject.insert(QStringLiteral("version"), m_version);
    m_sessionObject.insert(QStringLiteral("timestamp"), QDateTime::currentDateTime().toString(Qt::ISODate));

    QFile file(sessionFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
    {
        qWarning() << "[SessionManager] Could not open session file for writing:" << file.errorString();
        return false;
    }

    const QJsonDocument doc(m_sessionObject);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();

    return true;
}

void SessionManager::clearSession()
{
    m_sessionObject = QJsonObject();
    QFile::remove(sessionFilePath());
    removeCleaningSnapshot(1);
    removeCleaningSnapshot(2);
}

// =========================================================
// DATASET METADATA
// =========================================================

void SessionManager::setDataset1Info(bool loaded, const QString &filePath, const QString &fileName, int rowCount, int columnCount)
{
    QJsonObject dsObj;
    dsObj.insert(QStringLiteral("loaded"), loaded);
    dsObj.insert(QStringLiteral("filePath"), filePath);
    dsObj.insert(QStringLiteral("fileName"), fileName);
    dsObj.insert(QStringLiteral("rowCount"), rowCount);
    dsObj.insert(QStringLiteral("columnCount"), columnCount);

    m_sessionObject.insert(QStringLiteral("dataset1"), dsObj);
}

void SessionManager::setDataset2Info(bool loaded, const QString &filePath, const QString &fileName, int rowCount, int columnCount)
{
    QJsonObject dsObj;
    dsObj.insert(QStringLiteral("loaded"), loaded);
    dsObj.insert(QStringLiteral("filePath"), filePath);
    dsObj.insert(QStringLiteral("fileName"), fileName);
    dsObj.insert(QStringLiteral("rowCount"), rowCount);
    dsObj.insert(QStringLiteral("columnCount"), columnCount);

    m_sessionObject.insert(QStringLiteral("dataset2"), dsObj);
}

void SessionManager::clearDataset1Info()
{
    m_sessionObject.remove(QStringLiteral("dataset1"));
    removeCleaningSnapshot(1);
}

void SessionManager::clearDataset2Info()
{
    m_sessionObject.remove(QStringLiteral("dataset2"));
    removeCleaningSnapshot(2);
}

bool SessionManager::isDataset1Restorable() const
{
    const QJsonObject dsObj = m_sessionObject.value(QStringLiteral("dataset1")).toObject();
    if (!dsObj.value(QStringLiteral("loaded")).toBool())
        return false;

    const QString path = dsObj.value(QStringLiteral("filePath")).toString().trimmed();
    return !path.isEmpty() && QFileInfo::exists(path);
}

bool SessionManager::isDataset2Restorable() const
{
    const QJsonObject dsObj = m_sessionObject.value(QStringLiteral("dataset2")).toObject();
    if (!dsObj.value(QStringLiteral("loaded")).toBool())
        return false;

    const QString path = dsObj.value(QStringLiteral("filePath")).toString().trimmed();
    return !path.isEmpty() && QFileInfo::exists(path);
}

QString SessionManager::dataset1FilePath() const
{
    return m_sessionObject.value(QStringLiteral("dataset1")).toObject().value(QStringLiteral("filePath")).toString();
}

QString SessionManager::dataset2FilePath() const
{
    return m_sessionObject.value(QStringLiteral("dataset2")).toObject().value(QStringLiteral("filePath")).toString();
}

QString SessionManager::dataset1FileName() const
{
    return m_sessionObject.value(QStringLiteral("dataset1")).toObject().value(QStringLiteral("fileName")).toString();
}

QString SessionManager::dataset2FileName() const
{
    return m_sessionObject.value(QStringLiteral("dataset2")).toObject().value(QStringLiteral("fileName")).toString();
}

void SessionManager::setRawPaths(const QString &metadataPath, const QString &dataPath)
{
    QJsonObject rawObj;
    rawObj.insert(QStringLiteral("metadataPath"), metadataPath);
    rawObj.insert(QStringLiteral("dataPath"), dataPath);
    m_sessionObject.insert(QStringLiteral("raw"), rawObj);
}

QString SessionManager::rawMetadataPath() const
{
    return m_sessionObject.value(QStringLiteral("raw")).toObject().value(QStringLiteral("metadataPath")).toString();
}

QString SessionManager::rawDataPath() const
{
    return m_sessionObject.value(QStringLiteral("raw")).toObject().value(QStringLiteral("dataPath")).toString();
}

// =========================================================
// ANALYSIS SESSION
// =========================================================

void SessionManager::setAnalysisSession(const QVariantMap &analysisData, const QString &ds1Path, const QString &ds2Path)
{
    QJsonObject obj = QJsonObject::fromVariantMap(analysisData);
    obj.insert(QStringLiteral("available"), true);
    obj.insert(QStringLiteral("dataset1FilePath"), ds1Path);
    obj.insert(QStringLiteral("dataset2FilePath"), ds2Path);

    m_sessionObject.insert(QStringLiteral("analysis"), obj);
}

QVariantMap SessionManager::getAnalysisSession() const
{
    return m_sessionObject.value(QStringLiteral("analysis")).toObject().toVariantMap();
}

bool SessionManager::isAnalysisCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const
{
    const QJsonObject obj = m_sessionObject.value(QStringLiteral("analysis")).toObject();
    if (!obj.value(QStringLiteral("available")).toBool())
        return false;

    const QString savedDs1 = obj.value(QStringLiteral("dataset1FilePath")).toString().trimmed();
    const QString savedDs2 = obj.value(QStringLiteral("dataset2FilePath")).toString().trimmed();

    if (savedDs1.isEmpty() && savedDs2.isEmpty())
        return false;

    if (!savedDs1.isEmpty() && (currentDs1Path.trimmed().isEmpty() || savedDs1 != currentDs1Path.trimmed()))
        return false;

    if (!savedDs2.isEmpty() && (currentDs2Path.trimmed().isEmpty() || savedDs2 != currentDs2Path.trimmed()))
        return false;

    return true;
}

void SessionManager::invalidateAnalysisSession()
{
    m_sessionObject.remove(QStringLiteral("analysis"));
}

// =========================================================
// CLEANING SESSION
// =========================================================

void SessionManager::setCleaningSession(const QVariantMap &cleaningData, const QString &ds1Path, const QString &ds2Path)
{
    QJsonObject obj = QJsonObject::fromVariantMap(cleaningData);
    obj.insert(QStringLiteral("available"), true);
    obj.insert(QStringLiteral("dataset1FilePath"), ds1Path);
    obj.insert(QStringLiteral("dataset2FilePath"), ds2Path);

    m_sessionObject.insert(QStringLiteral("cleaning"), obj);
}

QVariantMap SessionManager::getCleaningSession() const
{
    return m_sessionObject.value(QStringLiteral("cleaning")).toObject().toVariantMap();
}

bool SessionManager::isCleaningCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const
{
    const QJsonObject obj = m_sessionObject.value(QStringLiteral("cleaning")).toObject();
    if (!obj.value(QStringLiteral("available")).toBool())
        return false;

    const QString savedDs1 = obj.value(QStringLiteral("dataset1FilePath")).toString().trimmed();
    const QString savedDs2 = obj.value(QStringLiteral("dataset2FilePath")).toString().trimmed();

    if (savedDs1.isEmpty() && savedDs2.isEmpty())
        return false;

    if (!savedDs1.isEmpty() && (currentDs1Path.trimmed().isEmpty() || savedDs1 != currentDs1Path.trimmed()))
        return false;

    if (!savedDs2.isEmpty() && (currentDs2Path.trimmed().isEmpty() || savedDs2 != currentDs2Path.trimmed()))
        return false;

    const bool ds1Mod = obj.value(QStringLiteral("dataset1Modified")).toBool();
    const bool ds2Mod = obj.value(QStringLiteral("dataset2Modified")).toBool();

    if (!ds1Mod && !ds2Mod)
        return false;

    if (ds1Mod && !QFileInfo::exists(snapshotFilePath(1)))
        return false;

    if (ds2Mod && !QFileInfo::exists(snapshotFilePath(2)))
        return false;

    return true;
}

void SessionManager::invalidateCleaningSession()
{
    m_sessionObject.remove(QStringLiteral("cleaning"));
    removeCleaningSnapshot(1);
    removeCleaningSnapshot(2);
}

bool SessionManager::saveCleaningSnapshot(int datasetIndex, const DataSet &workingDataSet)
{
    ensureDirectoryExists();
    const QString path = snapshotFilePath(datasetIndex);
    ExportEngine exporter;
    const ExportResult result = exporter.exportDataSetToCsv(workingDataSet, path);
    return result.success;
}

bool SessionManager::loadCleaningSnapshot(int datasetIndex, DataSet &outDataSet) const
{
    const QString path = snapshotFilePath(datasetIndex);
    if (!QFileInfo::exists(path))
        return false;

    ExcelParser parser;
    if (!parser.loadFile(path))
        return false;

    outDataSet = parser.dataSet();
    if (outDataSet.isEmpty())
        return false;

    QString origName;
    if (datasetIndex == 1)
    {
        origName = dataset1FileName().trimmed();
        if (origName.isEmpty())
            origName = dataset1FilePath().trimmed();
    }
    else
    {
        origName = dataset2FileName().trimmed();
        if (origName.isEmpty())
            origName = dataset2FilePath().trimmed();
    }

    QString baseName = QFileInfo(origName).completeBaseName();
    if (baseName.isEmpty())
        baseName = QFileInfo(origName).baseName();
    if (baseName.endsWith(QStringLiteral("_cleaned_snapshot")))
        baseName.chop(QStringLiteral("_cleaned_snapshot").length());
    if (baseName.isEmpty())
        baseName = QStringLiteral("dataset%1").arg(datasetIndex);

    outDataSet.setName(QStringLiteral("%1_cleaned_snapshot").arg(baseName));
    return true;
}

void SessionManager::removeCleaningSnapshot(int datasetIndex)
{
    const QString path = snapshotFilePath(datasetIndex);
    if (QFileInfo::exists(path))
    {
        QFile::remove(path);
    }
}

// =========================================================
// VISUALIZATION SESSION
// =========================================================

void SessionManager::setVisualizationSession(const QVariantMap &visData, const QString &ds1Path, const QString &ds2Path)
{
    QJsonObject obj = QJsonObject::fromVariantMap(visData);
    obj.insert(QStringLiteral("available"), true);
    obj.insert(QStringLiteral("dataset1FilePath"), ds1Path);
    obj.insert(QStringLiteral("dataset2FilePath"), ds2Path);

    m_sessionObject.insert(QStringLiteral("visualization"), obj);
}

QVariantMap SessionManager::getVisualizationSession() const
{
    return m_sessionObject.value(QStringLiteral("visualization")).toObject().toVariantMap();
}

bool SessionManager::isVisualizationCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const
{
    const QJsonObject obj = m_sessionObject.value(QStringLiteral("visualization")).toObject();
    if (!obj.value(QStringLiteral("available")).toBool())
        return false;

    const QString savedDs1 = obj.value(QStringLiteral("dataset1FilePath")).toString().trimmed();
    const QString savedDs2 = obj.value(QStringLiteral("dataset2FilePath")).toString().trimmed();

    if (savedDs1.isEmpty() && savedDs2.isEmpty())
        return false;

    if (!savedDs1.isEmpty() && (currentDs1Path.trimmed().isEmpty() || savedDs1 != currentDs1Path.trimmed()))
        return false;

    if (!savedDs2.isEmpty() && (currentDs2Path.trimmed().isEmpty() || savedDs2 != currentDs2Path.trimmed()))
        return false;

    return true;
}

void SessionManager::invalidateVisualizationSession()
{
    m_sessionObject.remove(QStringLiteral("visualization"));
}

// =========================================================
// COMPARISON SESSION
// =========================================================

void SessionManager::setComparisonSession(const QVariantMap &compData, const QString &ds1Path, const QString &ds2Path)
{
    QJsonObject obj = QJsonObject::fromVariantMap(compData);
    obj.insert(QStringLiteral("available"), true);
    obj.insert(QStringLiteral("dataset1FilePath"), ds1Path);
    obj.insert(QStringLiteral("dataset2FilePath"), ds2Path);

    m_sessionObject.insert(QStringLiteral("comparison"), obj);
}

QVariantMap SessionManager::getComparisonSession() const
{
    return m_sessionObject.value(QStringLiteral("comparison")).toObject().toVariantMap();
}

bool SessionManager::isComparisonCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const
{
    const QJsonObject obj = m_sessionObject.value(QStringLiteral("comparison")).toObject();
    if (!obj.value(QStringLiteral("available")).toBool())
        return false;

    const QString savedDs1 = obj.value(QStringLiteral("dataset1FilePath")).toString().trimmed();
    const QString savedDs2 = obj.value(QStringLiteral("dataset2FilePath")).toString().trimmed();

    if (savedDs1.isEmpty() && savedDs2.isEmpty())
        return false;

    if (!savedDs1.isEmpty() && (currentDs1Path.trimmed().isEmpty() || savedDs1 != currentDs1Path.trimmed()))
        return false;

    if (!savedDs2.isEmpty() && (currentDs2Path.trimmed().isEmpty() || savedDs2 != currentDs2Path.trimmed()))
        return false;

    return true;
}

void SessionManager::invalidateComparisonSession()
{
    m_sessionObject.remove(QStringLiteral("comparison"));
}
