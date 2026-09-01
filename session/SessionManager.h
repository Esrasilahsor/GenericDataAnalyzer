#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QString>
#include <QVariantMap>
#include <QJsonObject>
#include <QStandardPaths>

#include "../parser/DataSet.h"

class SessionManager
{
public:
    SessionManager();
    ~SessionManager();

    // Paths
    QString sessionDirectory() const;
    QString sessionFilePath() const;
    QString snapshotFilePath(int datasetIndex) const;

    QString historyDirectory() const;
    QString historyFilePath() const;

    // Load & Save
    bool loadSession();
    bool saveSession();
    void clearSession();

    // Dataset 1 & 2 Metadata
    void setDataset1Info(bool loaded, const QString &filePath, const QString &fileName, int rowCount, int columnCount);
    void setDataset2Info(bool loaded, const QString &filePath, const QString &fileName, int rowCount, int columnCount);
    void clearDataset1Info();
    void clearDataset2Info();

    bool isDataset1Restorable() const;
    bool isDataset2Restorable() const;

    QString dataset1FilePath() const;
    QString dataset2FilePath() const;
    QString dataset1FileName() const;
    QString dataset2FileName() const;

    // Raw Metadata & Data Paths
    void setRawPaths(const QString &metadataPath, const QString &dataPath);
    QString rawMetadataPath() const;
    QString rawDataPath() const;

    // Analysis Session
    void setAnalysisSession(const QVariantMap &analysisData, const QString &ds1Path, const QString &ds2Path);
    QVariantMap getAnalysisSession() const;
    bool isAnalysisCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const;
    void invalidateAnalysisSession();

    // Cleaning Session & Snapshots
    void setCleaningSession(const QVariantMap &cleaningData, const QString &ds1Path, const QString &ds2Path);
    QVariantMap getCleaningSession() const;
    bool isCleaningCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const;
    void invalidateCleaningSession();

    bool saveCleaningSnapshot(int datasetIndex, const DataSet &workingDataSet);
    bool loadCleaningSnapshot(int datasetIndex, DataSet &outDataSet) const;
    void removeCleaningSnapshot(int datasetIndex);

    // Visualization Session
    void setVisualizationSession(const QVariantMap &visData, const QString &ds1Path, const QString &ds2Path);
    QVariantMap getVisualizationSession() const;
    bool isVisualizationCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const;
    void invalidateVisualizationSession();

    // Comparison Session
    void setComparisonSession(const QVariantMap &compData, const QString &ds1Path, const QString &ds2Path);
    QVariantMap getComparisonSession() const;
    bool isComparisonCompatible(const QString &currentDs1Path, const QString &currentDs2Path) const;
    void invalidateComparisonSession();

private:
    void ensureDirectoryExists() const;

    int m_version = 1;
    QJsonObject m_sessionObject;
};

#endif // SESSIONMANAGER_H
