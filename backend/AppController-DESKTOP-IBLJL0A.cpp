#include "AppController.h"
#include <QCoreApplication>
#include <QDir>
#include <QUrl>
#include <QVariantList>
#include <QDateTime>
#include <QImage>
#include <QSet>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFileInfo>
#include <QElapsedTimer>
#include <QDebug>
#include <cmath>

#include "../raw/FileRawDataSource.h"

AppController::AppController(QObject *parent)
    : QObject(parent),
    m_dataset1ColumnModel(this),
    m_dataset2ColumnModel(this),
    m_mappingModel(this),
    m_parameterModel(this)
{
    QElapsedTimer constructorTimer;
    constructorTimer.start();

    qRegisterMetaType<DataSet>("DataSet");
    qRegisterMetaType<CleaningResult>("CleaningResult");
    qRegisterMetaType<CleaningTask>("CleaningTask");
    qRegisterMetaType<QList<QList<ParsedParameter>>>("QList<QList<ParsedParameter>>");
    qRegisterMetaType<QList<ParsedParameter>>("QList<ParsedParameter>");

    loadSettings();

    qInfo() << "[STARTUP] AppController constructor total:" << constructorTimer.elapsed() << "ms";
}

AppController::~AppController()
{
    if (m_rawParserThread)
    {
        if (m_rawParserWorker)
        {
            m_rawParserWorker->cancel();
        }
        if (m_rawParserThread->isRunning())
        {
            m_rawParserThread->quit();
            m_rawParserThread->wait(3000);
        }
    }

    if (m_cleaningThread)
    {
        if (m_cleaningWorker)
        {
            m_cleaningWorker->cancel();
        }
        if (m_cleaningThread->isRunning())
        {
            m_cleaningThread->quit();
            m_cleaningThread->wait(3000);
        }
    }

    saveCurrentSession();
}

// =========================================================
// GETTERS
// =========================================================

QString AppController::dataset1Name() const { return m_dataset1.name(); }
QString AppController::dataset2Name() const { return m_dataset2.name(); }
QString AppController::dataDirectory() const
{
    const QString current = QDir::currentPath();
    const QStringList candidatePaths = {
        current + QStringLiteral("/data"),
        current + QStringLiteral("/../data"),
        current + QStringLiteral("/../../data"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/data"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../data"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../data"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../data")
    };

    for (const QString &path : candidatePaths)
    {
        QDir dir(path);
        if (dir.exists())
        {
            return dir.absolutePath();
        }
    }

    return current;
}

int AppController::dataset1RowCount() const { return m_dataset1.rowCount(); }
int AppController::dataset2RowCount() const { return m_dataset2.rowCount(); }

int AppController::dataset1ColumnCount() const { return m_dataset1.columnCount(); }
int AppController::dataset2ColumnCount() const { return m_dataset2.columnCount(); }

QString AppController::dataset1SheetName() const { return m_dataset1.sheetName(); }
QString AppController::dataset2SheetName() const { return m_dataset2.sheetName(); }

bool AppController::dataset1Modified() const { return m_dataset1Modified; }
bool AppController::dataset2Modified() const { return m_dataset2Modified; }

bool AppController::cleaningCompleted() const
{
    return m_cleaningSkipped || m_dataset1Modified || m_dataset2Modified;
}

void AppController::setCleaningCompleted(bool completed)
{
    if (m_cleaningSkipped != completed)
    {
        m_cleaningSkipped = completed;
        emit cleaningCompletedChanged();
    }
}

void AppController::skipCleaning()
{
    m_cleaningSkipped = true;
    emit cleaningCompletedChanged();
}

QString AppController::lastError() const { return m_lastError; }

ColumnModel *AppController::dataset1ColumnModel() { return &m_dataset1ColumnModel; }
ColumnModel *AppController::dataset2ColumnModel() { return &m_dataset2ColumnModel; }
MappingModel *AppController::mappingModel() { return &m_mappingModel; }
ParameterModel *AppController::parameterModel() { return &m_parameterModel; }

QVariantMap AppController::analysisResult() const { return m_analysisResult; }
bool AppController::analysisAvailable() const { return m_analysisAvailable; }

QVariantMap AppController::datasetComparisonResult() const { return m_datasetComparisonResult; }
bool AppController::datasetComparisonAvailable() const { return m_datasetComparisonAvailable; }

bool AppController::visualizationAvailable() const { return m_visualizationAvailable; }

void AppController::setVisualizationAvailable(bool available)
{
    if (m_visualizationAvailable != available)
    {
        m_visualizationAvailable = available;
        emit visualizationChanged();
    }
}

QVariantMap AppController::dataset1EdaResult() const { return m_dataset1EdaResult; }
QVariantMap AppController::dataset2EdaResult() const { return m_dataset2EdaResult; }

bool AppController::dataset1EdaAvailable() const { return m_dataset1EdaAvailable; }
bool AppController::dataset2EdaAvailable() const { return m_dataset2EdaAvailable; }

QVariantMap AppController::dataset1CorrelationResult() const { return m_dataset1CorrelationResult; }
QVariantMap AppController::dataset2CorrelationResult() const { return m_dataset2CorrelationResult; }

bool AppController::dataset1CorrelationAvailable() const { return m_dataset1CorrelationAvailable; }
bool AppController::dataset2CorrelationAvailable() const { return m_dataset2CorrelationAvailable; }

QVariantMap AppController::dataset1QualityResult() const { return m_dataset1QualityResult; }
QVariantMap AppController::dataset2QualityResult() const { return m_dataset2QualityResult; }

bool AppController::dataset1QualityAvailable() const { return m_dataset1QualityAvailable; }
bool AppController::dataset2QualityAvailable() const { return m_dataset2QualityAvailable; }

QVariantMap AppController::dataset1OutlierResult() const { return m_dataset1OutlierResult; }
QVariantMap AppController::dataset2OutlierResult() const { return m_dataset2OutlierResult; }

bool AppController::dataset1OutlierAvailable() const { return m_dataset1OutlierAvailable; }
bool AppController::dataset2OutlierAvailable() const { return m_dataset2OutlierAvailable; }

QVariantMap AppController::dataset1OutlierCleaningResult() const
{
    return m_dataset1OutlierCleaningResult;
}

QVariantMap AppController::dataset2OutlierCleaningResult() const
{
    return m_dataset2OutlierCleaningResult;
}

bool AppController::rawMetadataLoaded() const { return m_rawMetadataLoaded; }
bool AppController::rawDataLoaded() const { return m_rawDataLoaded; }
bool AppController::rawParseAvailable() const { return m_rawParseAvailable; }

int AppController::rawParameterDefinitionCount() const
{
    return m_rawParameterDefinitions.size();
}

int AppController::rawDataByteCount() const
{
    return m_rawData.size();
}

static QVariantMap cleaningTaskToMap(const CleaningTask &task)
{
    QVariantMap m;
    m.insert(QStringLiteral("operation"), static_cast<int>(task.operation));
    m.insert(QStringLiteral("datasetIndex"), task.datasetIndex);
    m.insert(QStringLiteral("columnName"), task.columnName);
    m.insert(QStringLiteral("method"), task.method);
    m.insert(QStringLiteral("action"), task.action);
    m.insert(QStringLiteral("parameter"), task.parameter);
    m.insert(QStringLiteral("targetColumns"), task.targetColumns);
    QVariantList flags;
    for (bool f : task.numericFlags) flags.append(f);
    m.insert(QStringLiteral("numericFlags"), flags);
    m.insert(QStringLiteral("bulkAction"), task.bulkAction);
    return m;
}

static CleaningTask mapToCleaningTask(const QVariantMap &m)
{
    CleaningTask task;
    task.operation = static_cast<CleaningTask::OperationType>(m.value(QStringLiteral("operation")).toInt());
    task.datasetIndex = m.value(QStringLiteral("datasetIndex")).toInt();
    task.columnName = m.value(QStringLiteral("columnName")).toString();
    task.method = m.value(QStringLiteral("method")).toString();
    task.action = m.value(QStringLiteral("action")).toString();
    task.parameter = m.value(QStringLiteral("parameter")).toDouble();
    task.targetColumns = m.value(QStringLiteral("targetColumns")).toStringList();
    const QVariantList flags = m.value(QStringLiteral("numericFlags")).toList();
    for (const QVariant &f : flags) task.numericFlags.append(f.toBool());
    task.bulkAction = m.value(QStringLiteral("bulkAction")).toString();
    return task;
}

static QVariantList tasksToVariantList(const QList<CleaningTask> &tasks)
{
    QVariantList list;
    for (const CleaningTask &t : tasks)
    {
        list.append(cleaningTaskToMap(t));
    }
    return list;
}

static QList<CleaningTask> variantListToTasks(const QVariantList &list)
{
    QList<CleaningTask> tasks;
    for (const QVariant &v : list)
    {
        tasks.append(mapToCleaningTask(v.toMap()));
    }
    return tasks;
}

bool AppController::dataset1HasMissingCleaning() const { return !m_dataset1MissingTasks.isEmpty(); }
bool AppController::dataset2HasMissingCleaning() const { return !m_dataset2MissingTasks.isEmpty(); }
bool AppController::dataset1HasOutlierCleaning() const { return !m_dataset1OutlierTasks.isEmpty(); }
bool AppController::dataset2HasOutlierCleaning() const { return !m_dataset2OutlierTasks.isEmpty(); }

bool AppController::rawParsing() const { return m_rawParsing; }
int AppController::rawParseProgress() const { return m_rawParseProgress; }
bool AppController::cleaningBusy() const { return m_cleaningBusy; }
int AppController::cleaningProgress() const { return m_cleaningProgress; }
QString AppController::cleaningStatusText() const { return m_cleaningStatusText; }

int AppController::activeCleaningDataset() const
{
    return m_cleaningBusy ? m_currentCleaningTask.datasetIndex : 0;
}

QString AppController::activeCleaningOperation() const
{
    if (!m_cleaningBusy)
        return QString();

    switch (m_currentCleaningTask.operation)
    {
    case CleaningTask::BulkMissing:
    case CleaningTask::RemoveMissingRows:
    case CleaningTask::FillMissingMean:
    case CleaningTask::FillMissingMedian:
    case CleaningTask::FillMissingMode:
        return QStringLiteral("missing");

    case CleaningTask::BulkOutliers:
        return QStringLiteral("outliers");

    case CleaningTask::ApplyOutlierAction:
        return QStringLiteral("single_outlier");

    case CleaningTask::RemoveDuplicates:
        return QStringLiteral("duplicates");

    case CleaningTask::RemoveColumn:
        return QStringLiteral("column");

    default:
        return QString();
    }
}

QString AppController::activeCleaningColumn() const
{
    return m_cleaningBusy ? m_currentCleaningTask.columnName : QString();
}

QString AppController::rawMetadataFilePath() const
{
    return m_rawMetadataFilePath;
}

QString AppController::rawDataFilePath() const
{
    return m_rawDataFilePath;
}

QStringList AppController::rawWarnings() const
{
    return m_rawWarnings;
}

QVariantList AppController::recentActivities() const
{
    return m_recentActivities;
}

QVariantList AppController::recentFiles() const
{
    return m_recentFiles;
}

QString AppController::lastDataset1Path() const
{
    return m_lastDataset1Path;
}

QString AppController::lastDataset2Path() const
{
    return m_lastDataset2Path;
}

bool AppController::hasPreviousSession() const
{
    return hasRestorableSession() ||
           (!m_lastDataset1Path.isEmpty() && QFileInfo::exists(m_lastDataset1Path)) ||
           (!m_lastDataset2Path.isEmpty() && QFileInfo::exists(m_lastDataset2Path));
}

bool AppController::sessionRestored() const
{
    return m_sessionRestoreDecision == 1;
}

bool AppController::sessionChoiceHandled() const
{
    return m_sessionRestoreDecision != 0 || m_datasetsChangedSinceStartup;
}

bool AppController::datasetsChangedSinceStartup() const
{
    return m_datasetsChangedSinceStartup;
}

bool AppController::autoRestoreEnabled() const
{
    return m_autoRestoreEnabled;
}

void AppController::setAutoRestoreEnabled(bool enabled)
{
    if (m_autoRestoreEnabled != enabled)
    {
        m_autoRestoreEnabled = enabled;
        emit autoRestoreEnabledChanged();
        saveSettings();
    }
}

void AppController::loadSettings()
{
    QElapsedTimer settingsTimer;
    settingsTimer.start();

    QSettings settings;

    m_lastDataset1Path = settings.value(QStringLiteral("session/lastDataset1Path")).toString();
    m_lastDataset2Path = settings.value(QStringLiteral("session/lastDataset2Path")).toString();
    m_lastRawMetadataPath = settings.value(QStringLiteral("session/lastRawMetadataPath")).toString();
    m_lastRawDataPath = settings.value(QStringLiteral("session/lastRawDataPath")).toString();
    m_autoRestoreEnabled = settings.value(QStringLiteral("session/autoRestoreEnabled"), true).toBool();

    m_sessionManager.loadSession();

    if (m_lastDataset1Path.isEmpty())
        m_lastDataset1Path = m_sessionManager.dataset1FilePath();
    if (m_lastDataset2Path.isEmpty())
        m_lastDataset2Path = m_sessionManager.dataset2FilePath();
    if (m_lastRawMetadataPath.isEmpty())
        m_lastRawMetadataPath = m_sessionManager.rawMetadataPath();
    if (m_lastRawDataPath.isEmpty())
        m_lastRawDataPath = m_sessionManager.rawDataPath();

    const QString actsJson = settings.value(QStringLiteral("history/recentActivities")).toString();
    if (!actsJson.isEmpty())
    {
        const QJsonDocument doc = QJsonDocument::fromJson(actsJson.toUtf8());
        if (doc.isArray())
        {
            m_recentActivities = doc.array().toVariantList();
        }
    }

    const QString filesJson = settings.value(QStringLiteral("history/recentFiles")).toString();
    if (!filesJson.isEmpty())
    {
        const QJsonDocument doc = QJsonDocument::fromJson(filesJson.toUtf8());
        if (doc.isArray())
        {
            m_recentFiles = doc.array().toVariantList();
        }
    }

    qInfo() << "[STARTUP] Settings & history loaded:" << settingsTimer.elapsed() << "ms";
}

void AppController::saveSettings()
{
    QSettings settings;

    settings.setValue(QStringLiteral("session/lastDataset1Path"), m_lastDataset1Path);
    settings.setValue(QStringLiteral("session/lastDataset2Path"), m_lastDataset2Path);
    settings.setValue(QStringLiteral("session/lastRawMetadataPath"), m_lastRawMetadataPath);
    settings.setValue(QStringLiteral("session/lastRawDataPath"), m_lastRawDataPath);
    settings.setValue(QStringLiteral("session/autoRestoreEnabled"), m_autoRestoreEnabled);

    const QJsonDocument docActs(QJsonArray::fromVariantList(m_recentActivities));
    settings.setValue(QStringLiteral("history/recentActivities"), QString::fromUtf8(docActs.toJson(QJsonDocument::Compact)));

    const QJsonDocument docFiles(QJsonArray::fromVariantList(m_recentFiles));
    settings.setValue(QStringLiteral("history/recentFiles"), QString::fromUtf8(docFiles.toJson(QJsonDocument::Compact)));
}

void AppController::recordActivity(const QString &title, const QString &detail, const QString &category)
{
    QVariantMap act;
    act[QStringLiteral("title")] = title;
    act[QStringLiteral("detail")] = detail;
    act[QStringLiteral("category")] = category;
    act[QStringLiteral("timestamp")] = QDateTime::currentDateTime().toString(QStringLiteral("dd.MM.yyyy hh:mm:ss"));
    act[QStringLiteral("timeShort")] = QDateTime::currentDateTime().toString(QStringLiteral("hh:mm:ss"));

    m_recentActivities.prepend(act);
    if (m_recentActivities.size() > 50)
    {
        m_recentActivities = m_recentActivities.mid(0, 50);
    }

    emit recentActivitiesChanged();
    saveSettings();
}

void AppController::addRecentFile(const QString &filePath, const QString &type, int rowCount, int colCount)
{
    if (filePath.trimmed().isEmpty())
        return;

    const QString norm = normalizeFilePath(filePath);
    const QFileInfo info(norm);
    if (!info.exists())
        return;

    for (int i = 0; i < m_recentFiles.size(); ++i)
    {
        const QVariantMap item = m_recentFiles.at(i).toMap();
        if (item.value(QStringLiteral("path")).toString() == norm)
        {
            m_recentFiles.removeAt(i);
            break;
        }
    }

    QVariantMap fileItem;
    fileItem[QStringLiteral("name")] = info.fileName();
    fileItem[QStringLiteral("path")] = norm;
    fileItem[QStringLiteral("type")] = type;
    fileItem[QStringLiteral("rowCount")] = rowCount;
    fileItem[QStringLiteral("columnCount")] = colCount;
    fileItem[QStringLiteral("size")] = QStringLiteral("%1 KB").arg(info.size() / 1024);
    fileItem[QStringLiteral("timestamp")] = QDateTime::currentDateTime().toString(QStringLiteral("dd.MM.yyyy hh:mm"));

    m_recentFiles.prepend(fileItem);
    if (m_recentFiles.size() > 15)
    {
        m_recentFiles = m_recentFiles.mid(0, 15);
    }

    emit recentFilesChanged();
    saveSettings();
}

void AppController::clearRecentActivities()
{
    m_recentActivities.clear();
    emit recentActivitiesChanged();
    saveSettings();
}

void AppController::clearRecentFiles()
{
    m_recentFiles.clear();
    emit recentFilesChanged();
    saveSettings();
}

bool AppController::autoRestoreDatasets()
{
    m_restoringSession = true;
    m_datasetsChangedSinceStartup = false;

    QElapsedTimer totalRestoreTimer;
    totalRestoreTimer.start();

    bool restoredAny = false;

    m_sessionManager.loadSession();

    // 1. Restore Dataset 1
    QString ds1Path = m_lastDataset1Path.trimmed();
    if (ds1Path.isEmpty())
        ds1Path = m_sessionManager.dataset1FilePath().trimmed();

    ds1Path = normalizeFilePath(ds1Path);
    if (!ds1Path.isEmpty() && QFileInfo::exists(ds1Path))
    {
        QElapsedTimer ds1Timer;
        ds1Timer.start();
        if (loadDataset1(ds1Path))
        {
            restoredAny = true;
            qInfo() << "[STARTUP][AutoRestore] Dataset 1 restored:" << ds1Path << "in" << ds1Timer.elapsed() << "ms";
        }
    }

    // 2. Restore Dataset 2
    QString ds2Path = m_lastDataset2Path.trimmed();
    if (ds2Path.isEmpty())
        ds2Path = m_sessionManager.dataset2FilePath().trimmed();

    ds2Path = normalizeFilePath(ds2Path);
    if (!ds2Path.isEmpty() && QFileInfo::exists(ds2Path))
    {
        QElapsedTimer ds2Timer;
        ds2Timer.start();
        if (loadDataset2(ds2Path))
        {
            restoredAny = true;
            qInfo() << "[STARTUP][AutoRestore] Dataset 2 restored:" << ds2Path << "in" << ds2Timer.elapsed() << "ms";
        }
    }

    // 3. Restore Raw Metadata
    QString rawMetaPath = m_lastRawMetadataPath.trimmed();
    if (rawMetaPath.isEmpty())
        rawMetaPath = m_sessionManager.rawMetadataPath().trimmed();

    rawMetaPath = normalizeFilePath(rawMetaPath);
    if (!rawMetaPath.isEmpty() && QFileInfo::exists(rawMetaPath))
    {
        if (loadRawMetadata(rawMetaPath))
        {
            restoredAny = true;
            qInfo() << "[STARTUP][AutoRestore] Raw Metadata restored:" << rawMetaPath;
        }
    }

    // 4. Restore Raw Data
    QString rawDataPath = m_lastRawDataPath.trimmed();
    if (rawDataPath.isEmpty())
        rawDataPath = m_sessionManager.rawDataPath().trimmed();

    rawDataPath = normalizeFilePath(rawDataPath);
    if (!rawDataPath.isEmpty() && QFileInfo::exists(rawDataPath))
    {
        if (loadRawDataFile(rawDataPath))
        {
            restoredAny = true;
            qInfo() << "[STARTUP][AutoRestore] Raw Data restored:" << rawDataPath;
        }
    }

    m_restoringSession = false;
    m_datasetsChangedSinceStartup = false;

    // Do NOT automatically apply Analysis, Cleaning, Comparison states.
    // They will remain preserved in m_sessionManager for the user to restore via "Restore Last Session".
    m_sessionRestoreDecision = 0; // Unapplied/Ready

    emit lastSessionChanged();
    emit datasetsChangedSinceStartupChanged();
    emit sessionAvailabilityChanged();
    emit sessionRestoreDecisionChanged();

    qInfo() << "[STARTUP][AutoRestore] Total autoRestoreDatasets:" << totalRestoreTimer.elapsed() << "ms";
    return restoredAny;
}

bool AppController::restoreLastSession()
{
    m_restoringSession = true;

    QElapsedTimer totalRestoreTimer;
    totalRestoreTimer.start();

    bool restoredAny = false;

    m_sessionManager.loadSession();

    // 1. Ensure Dataset 1 is loaded
    if (m_dataset1.isEmpty())
    {
        QString ds1Path = m_lastDataset1Path.trimmed();
        if (ds1Path.isEmpty())
            ds1Path = m_sessionManager.dataset1FilePath().trimmed();

        ds1Path = normalizeFilePath(ds1Path);
        if (!ds1Path.isEmpty() && QFileInfo::exists(ds1Path))
        {
            if (loadDataset1(ds1Path))
            {
                restoredAny = true;
            }
        }
    }

    // 2. Ensure Dataset 2 is loaded
    if (m_dataset2.isEmpty())
    {
        QString ds2Path = m_lastDataset2Path.trimmed();
        if (ds2Path.isEmpty())
            ds2Path = m_sessionManager.dataset2FilePath().trimmed();

        ds2Path = normalizeFilePath(ds2Path);
        if (!ds2Path.isEmpty() && QFileInfo::exists(ds2Path))
        {
            if (loadDataset2(ds2Path))
            {
                restoredAny = true;
            }
        }
    }

    // 3. Ensure Raw Metadata & Data are loaded
    if (!m_rawMetadataLoaded)
    {
        QString rawMetaPath = m_lastRawMetadataPath.trimmed();
        if (rawMetaPath.isEmpty())
            rawMetaPath = m_sessionManager.rawMetadataPath().trimmed();

        rawMetaPath = normalizeFilePath(rawMetaPath);
        if (!rawMetaPath.isEmpty() && QFileInfo::exists(rawMetaPath))
        {
            if (loadRawMetadata(rawMetaPath))
            {
                restoredAny = true;
            }
        }
    }

    if (!m_rawDataLoaded)
    {
        QString rawDataPath = m_lastRawDataPath.trimmed();
        if (rawDataPath.isEmpty())
            rawDataPath = m_sessionManager.rawDataPath().trimmed();

        rawDataPath = normalizeFilePath(rawDataPath);
        if (!rawDataPath.isEmpty() && QFileInfo::exists(rawDataPath))
        {
            if (loadRawDataFile(rawDataPath))
            {
                restoredAny = true;
            }
        }
    }
    // 4. Restore operational session states: Cleaning first, then Analysis, then Comparison
    bool cleaningRestored = restoreCleaningSession();
    bool analysisRestored = restoreAnalysisSession();
    bool comparisonRestored = restoreComparisonSession();

    if (analysisRestored || cleaningRestored || comparisonRestored)
    {
        restoredAny = true;
    }

    m_restoringSession = false;

    if (restoredAny)
    {
        m_sessionRestoreDecision = 1; // Restored
        recordActivity(tr("Session Restored"),
                       tr("Previous workspace state and dataset analysis restored"),
                       tr("Session"));
    }

    emit lastSessionChanged();
    emit sessionAvailabilityChanged();
    emit sessionRestoreDecisionChanged();

    qInfo() << "[Session] Total restoreLastSession:" << totalRestoreTimer.elapsed() << "ms, result:" << restoredAny;
    return restoredAny;
}

bool AppController::hasRestorableAnalysisSession() const
{
    return m_sessionManager.isAnalysisCompatible(m_lastDataset1Path, m_lastDataset2Path);
}

bool AppController::hasRestorableCleaningSession() const
{
    return m_sessionManager.isCleaningCompatible(m_lastDataset1Path, m_lastDataset2Path);
}

bool AppController::hasRestorableVisualizationSession() const
{
    return m_sessionManager.isVisualizationCompatible(m_lastDataset1Path, m_lastDataset2Path);
}

bool AppController::hasRestorableComparisonSession() const
{
    return m_sessionManager.isComparisonCompatible(m_lastDataset1Path, m_lastDataset2Path);
}

bool AppController::hasRestorableSession() const
{
    if (m_datasetsChangedSinceStartup)
        return false;

    return hasRestorableAnalysisSession() ||
           hasRestorableCleaningSession() ||
           hasRestorableVisualizationSession() ||
           hasRestorableComparisonSession();
}

int AppController::sessionRestoreDecision() const
{
    return m_sessionRestoreDecision;
}

void AppController::setSessionRestoreDecision(int decision)
{
    if (m_sessionRestoreDecision != decision)
    {
        m_sessionRestoreDecision = decision;
        emit sessionRestoreDecisionChanged();
    }
}

void AppController::applyGlobalRestoreDecision(bool restore)
{
    if (restore)
    {
        m_sessionRestoreDecision = 1; // Restore
        restoreCleaningSession();
        restoreAnalysisSession();
        restoreComparisonSession();
        recordActivity(tr("Session Restored"),
                       tr("Previous workspace state and dataset analysis restored"),
                       tr("Session"));
    }
    else
    {
        m_sessionRestoreDecision = 2; // StartFresh
        dismissAnalysisSession();
        dismissCleaningSession();
        dismissVisualizationSession();
        dismissComparisonSession();
    }

    emit sessionRestoreDecisionChanged();
    emit sessionAvailabilityChanged();
}

bool AppController::restoreAnalysisSession()
{
    if (!hasRestorableAnalysisSession())
        return false;

    const QVariantMap data = m_sessionManager.getAnalysisSession();

    if (data.contains(QStringLiteral("dataset1EdaResult")))
    {
        m_dataset1EdaResult = data.value(QStringLiteral("dataset1EdaResult")).toMap();
        m_dataset1EdaAvailable = !m_dataset1EdaResult.isEmpty();
        emit dataset1EdaChanged();
    }

    if (data.contains(QStringLiteral("dataset2EdaResult")))
    {
        m_dataset2EdaResult = data.value(QStringLiteral("dataset2EdaResult")).toMap();
        m_dataset2EdaAvailable = !m_dataset2EdaResult.isEmpty();
        emit dataset2EdaChanged();
    }

    if (data.contains(QStringLiteral("dataset1CorrelationResult")))
    {
        m_dataset1CorrelationResult = data.value(QStringLiteral("dataset1CorrelationResult")).toMap();
        m_dataset1CorrelationAvailable = !m_dataset1CorrelationResult.isEmpty();
        emit dataset1CorrelationChanged();
    }

    if (data.contains(QStringLiteral("dataset2CorrelationResult")))
    {
        m_dataset2CorrelationResult = data.value(QStringLiteral("dataset2CorrelationResult")).toMap();
        m_dataset2CorrelationAvailable = !m_dataset2CorrelationResult.isEmpty();
        emit dataset2CorrelationChanged();
    }

    if (data.contains(QStringLiteral("dataset1OutlierResult")))
    {
        m_dataset1OutlierResult = data.value(QStringLiteral("dataset1OutlierResult")).toMap();
        m_dataset1OutlierAvailable = !m_dataset1OutlierResult.isEmpty();
        emit dataset1OutlierChanged();
    }

    if (data.contains(QStringLiteral("dataset2OutlierResult")))
    {
        m_dataset2OutlierResult = data.value(QStringLiteral("dataset2OutlierResult")).toMap();
        m_dataset2OutlierAvailable = !m_dataset2OutlierResult.isEmpty();
        emit dataset2OutlierChanged();
    }

    if (data.contains(QStringLiteral("comparisonResult")))
    {
        m_datasetComparisonResult = data.value(QStringLiteral("comparisonResult")).toMap();
        m_datasetComparisonAvailable = !m_datasetComparisonResult.isEmpty();
        emit datasetComparisonChanged();
    }

    emit sessionAvailabilityChanged();
    return true;
}

bool AppController::restoreCleaningSession()
{
    if (!hasRestorableCleaningSession())
        return false;

    const QVariantMap data = m_sessionManager.getCleaningSession();

    m_dataset1MissingTasks = variantListToTasks(data.value(QStringLiteral("dataset1MissingTasks")).toList());
    m_dataset1OutlierTasks = variantListToTasks(data.value(QStringLiteral("dataset1OutlierTasks")).toList());
    m_dataset1OtherTasks = variantListToTasks(data.value(QStringLiteral("dataset1OtherTasks")).toList());
    m_dataset2MissingTasks = variantListToTasks(data.value(QStringLiteral("dataset2MissingTasks")).toList());
    m_dataset2OutlierTasks = variantListToTasks(data.value(QStringLiteral("dataset2OutlierTasks")).toList());
    m_dataset2OtherTasks = variantListToTasks(data.value(QStringLiteral("dataset2OtherTasks")).toList());

    if (data.value(QStringLiteral("dataset1Modified")).toBool())
    {
        DataSet workingDs;
        if (m_sessionManager.loadCleaningSnapshot(1, workingDs))
        {
            QString origName = m_sessionManager.dataset1FileName().trimmed();
            if (origName.isEmpty())
                origName = m_lastDataset1Path.trimmed();
            if (origName.isEmpty())
                origName = m_sessionManager.dataset1FilePath().trimmed();

            QString baseName = QFileInfo(origName).completeBaseName();
            if (baseName.isEmpty())
                baseName = QFileInfo(origName).baseName();
            if (baseName.endsWith(QStringLiteral("_cleaned_snapshot")))
                baseName.chop(QStringLiteral("_cleaned_snapshot").length());
            if (baseName.isEmpty())
                baseName = QStringLiteral("dataset1");

            workingDs.setName(QStringLiteral("%1_cleaned_snapshot").arg(baseName));

            m_dataset1 = workingDs;
            m_dataset1Modified = true;
            m_dataset1ColumnModel.setColumns(m_dataset1.columns());
            m_dataset1OutlierCleaningResult = data.value(QStringLiteral("dataset1OutlierCleaningResult")).toMap();
            analyzeDataset1Quality();
            emit dataset1Changed();
            emit dataset1OutlierCleaningChanged();
            emit dataset1CleaningStateChanged();
        }
    }

    if (data.value(QStringLiteral("dataset2Modified")).toBool())
    {
        DataSet workingDs;
        if (m_sessionManager.loadCleaningSnapshot(2, workingDs))
        {
            QString origName = m_sessionManager.dataset2FileName().trimmed();
            if (origName.isEmpty())
                origName = m_lastDataset2Path.trimmed();
            if (origName.isEmpty())
                origName = m_sessionManager.dataset2FilePath().trimmed();

            QString baseName = QFileInfo(origName).completeBaseName();
            if (baseName.isEmpty())
                baseName = QFileInfo(origName).baseName();
            if (baseName.endsWith(QStringLiteral("_cleaned_snapshot")))
                baseName.chop(QStringLiteral("_cleaned_snapshot").length());
            if (baseName.isEmpty())
                baseName = QStringLiteral("dataset2");

            workingDs.setName(QStringLiteral("%1_cleaned_snapshot").arg(baseName));

            m_dataset2 = workingDs;
            m_dataset2Modified = true;
            m_dataset2ColumnModel.setColumns(m_dataset2.columns());
            m_dataset2OutlierCleaningResult = data.value(QStringLiteral("dataset2OutlierCleaningResult")).toMap();
            analyzeDataset2Quality();
            emit dataset2Changed();
            emit dataset2OutlierCleaningChanged();
            emit dataset2CleaningStateChanged();
        }
    }

    emit cleaningCompletedChanged();
    emit sessionAvailabilityChanged();
    return true;
}

QVariantMap AppController::getSavedVisualizationSession() const
{
    return m_sessionManager.getVisualizationSession();
}

void AppController::saveVisualizationSession(const QVariantMap &visData)
{
    m_sessionManager.setVisualizationSession(visData, m_lastDataset1Path, m_lastDataset2Path);
    m_sessionManager.saveSession();
    emit sessionAvailabilityChanged();
}

void AppController::dismissAnalysisSession()
{
    m_sessionManager.invalidateAnalysisSession();
    m_sessionManager.saveSession();
    emit sessionAvailabilityChanged();
}

void AppController::dismissCleaningSession()
{
    m_sessionManager.invalidateCleaningSession();
    m_sessionManager.saveSession();
    emit sessionAvailabilityChanged();
}

void AppController::dismissVisualizationSession()
{
    m_sessionManager.invalidateVisualizationSession();
    m_sessionManager.saveSession();
    emit sessionAvailabilityChanged();
}

bool AppController::restoreComparisonSession()
{
    if (!hasRestorableComparisonSession())
        return false;

    const QVariantMap data = m_sessionManager.getComparisonSession();
    if (data.contains(QStringLiteral("comparisonResult")))
    {
        m_datasetComparisonResult = data.value(QStringLiteral("comparisonResult")).toMap();
        m_datasetComparisonAvailable = !m_datasetComparisonResult.isEmpty();
        emit datasetComparisonChanged();
    }

    emit sessionAvailabilityChanged();
    return true;
}

QVariantMap AppController::getSavedComparisonSession() const
{
    return m_sessionManager.getComparisonSession();
}

void AppController::saveComparisonSession(const QVariantMap &compData)
{
    if (m_restoringSession)
        return;

    m_sessionManager.setComparisonSession(compData, m_lastDataset1Path, m_lastDataset2Path);
    m_sessionManager.saveSession();
    qInfo() << "[SESSION] Comparison state updated";
    emit sessionAvailabilityChanged();
}

void AppController::dismissComparisonSession()
{
    m_sessionManager.invalidateComparisonSession();
    m_sessionManager.saveSession();
    emit sessionAvailabilityChanged();
}

void AppController::saveCurrentAnalysisSession()
{
    if (m_restoringSession)
        return;

    QVariantMap map;
    if (m_dataset1EdaAvailable) map.insert(QStringLiteral("dataset1EdaResult"), m_dataset1EdaResult);
    if (m_dataset2EdaAvailable) map.insert(QStringLiteral("dataset2EdaResult"), m_dataset2EdaResult);
    if (m_dataset1CorrelationAvailable) map.insert(QStringLiteral("dataset1CorrelationResult"), m_dataset1CorrelationResult);
    if (m_dataset2CorrelationAvailable) map.insert(QStringLiteral("dataset2CorrelationResult"), m_dataset2CorrelationResult);
    if (m_dataset1OutlierAvailable) map.insert(QStringLiteral("dataset1OutlierResult"), m_dataset1OutlierResult);
    if (m_dataset2OutlierAvailable) map.insert(QStringLiteral("dataset2OutlierResult"), m_dataset2OutlierResult);
    if (m_datasetComparisonAvailable) map.insert(QStringLiteral("comparisonResult"), m_datasetComparisonResult);

    if (!map.isEmpty())
    {
        m_sessionManager.setAnalysisSession(map, m_lastDataset1Path, m_lastDataset2Path);
        m_sessionManager.saveSession();
    }
}

void AppController::saveCurrentCleaningSession()
{
    if (m_restoringSession)
        return;

    QVariantMap map;
    map.insert(QStringLiteral("dataset1Modified"), m_dataset1Modified);
    map.insert(QStringLiteral("dataset2Modified"), m_dataset2Modified);
    map.insert(QStringLiteral("dataset1OutlierCleaningResult"), m_dataset1OutlierCleaningResult);
    map.insert(QStringLiteral("dataset2OutlierCleaningResult"), m_dataset2OutlierCleaningResult);

    map.insert(QStringLiteral("dataset1MissingTasks"), tasksToVariantList(m_dataset1MissingTasks));
    map.insert(QStringLiteral("dataset1OutlierTasks"), tasksToVariantList(m_dataset1OutlierTasks));
    map.insert(QStringLiteral("dataset1OtherTasks"), tasksToVariantList(m_dataset1OtherTasks));
    map.insert(QStringLiteral("dataset2MissingTasks"), tasksToVariantList(m_dataset2MissingTasks));
    map.insert(QStringLiteral("dataset2OutlierTasks"), tasksToVariantList(m_dataset2OutlierTasks));
    map.insert(QStringLiteral("dataset2OtherTasks"), tasksToVariantList(m_dataset2OtherTasks));

    if (m_dataset1Modified)
        m_sessionManager.saveCleaningSnapshot(1, m_dataset1);
    else
        m_sessionManager.removeCleaningSnapshot(1);

    if (m_dataset2Modified)
        m_sessionManager.saveCleaningSnapshot(2, m_dataset2);
    else
        m_sessionManager.removeCleaningSnapshot(2);

    if (m_dataset1Modified || m_dataset2Modified)
    {
        m_sessionManager.setCleaningSession(map, m_lastDataset1Path, m_lastDataset2Path);
        m_sessionManager.saveSession();
    }
    else
    {
        m_sessionManager.invalidateCleaningSession();
        m_sessionManager.saveSession();
    }
}

void AppController::saveCurrentSession()
{
    if (m_restoringSession)
        return;

    if (!m_dataset1.isEmpty())
    {
        m_sessionManager.setDataset1Info(true, m_lastDataset1Path, m_dataset1.name(), m_dataset1.rowCount(), m_dataset1.columnCount());
    }
    else if (!m_lastDataset1Path.isEmpty() && QFileInfo::exists(m_lastDataset1Path))
    {
        m_sessionManager.setDataset1Info(true, m_lastDataset1Path, QFileInfo(m_lastDataset1Path).fileName(), 0, 0);
    }
    else
    {
        m_sessionManager.clearDataset1Info();
    }

    if (!m_dataset2.isEmpty())
    {
        m_sessionManager.setDataset2Info(true, m_lastDataset2Path, m_dataset2.name(), m_dataset2.rowCount(), m_dataset2.columnCount());
    }
    else if (!m_lastDataset2Path.isEmpty() && QFileInfo::exists(m_lastDataset2Path))
    {
        m_sessionManager.setDataset2Info(true, m_lastDataset2Path, QFileInfo(m_lastDataset2Path).fileName(), 0, 0);
    }
    else
    {
        m_sessionManager.clearDataset2Info();
    }

    m_sessionManager.setRawPaths(m_lastRawMetadataPath, m_lastRawDataPath);

    saveCurrentAnalysisSession();
    saveCurrentCleaningSession();

    m_sessionManager.saveSession();
    saveSettings();
}

bool AppController::loadRecentFileAsDataset(int datasetIndex, const QString &filePath)
{
    if (datasetIndex == 1)
    {
        return loadDataset1(filePath);
    }
    else if (datasetIndex == 2)
    {
        return loadDataset2(filePath);
    }
    return false;
}

// =========================================================
// DATASET LOAD
// =========================================================

bool AppController::loadDataset1(const QString &filePath)
{
    QElapsedTimer ds1TotalTimer;
    ds1TotalTimer.start();

    clearError();

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        clearDataset1();
        setError(QStringLiteral("Dataset 1 file path is empty."));
        return false;
    }

    QElapsedTimer parseTimer;
    parseTimer.start();
    if (!m_parser1.loadFile(normalizedPath))
    {
        setError(m_parser1.lastError());
        return false;
    }
    qInfo() << "[STARTUP][Dataset1] File read & parse (Excel/CSV):" << parseTimer.elapsed() << "ms"
            << QString("(Rows: %1, Cols: %2)").arg(m_parser1.dataSet().rowCount()).arg(m_parser1.dataSet().columnCount());

    m_dataset1 = m_parser1.dataSet();
    m_originalDataset1 = m_dataset1;
    m_dataset1Modified = false;
    m_dataset1MissingTasks.clear();
    m_dataset1OutlierTasks.clear();
    m_dataset1OtherTasks.clear();
    emit dataset1CleaningStateChanged();

    QElapsedTimer colModelTimer;
    colModelTimer.start();
    m_dataset1ColumnModel.setColumns(m_dataset1.columns());
    qInfo() << "[STARTUP][Dataset1] Column model setColumns:" << colModelTimer.elapsed() << "ms";

    QElapsedTimer qualityTimer;
    qualityTimer.start();
    analyzeDataset1Quality();
    qInfo() << "[STARTUP][Dataset1] Quality & Outliers analysis total:" << qualityTimer.elapsed() << "ms";

    m_lastDataset1Path = normalizedPath;
    addRecentFile(normalizedPath, tr("Dataset 1 (Excel/CSV)"), m_dataset1.rowCount(), m_dataset1.columnCount());
    recordActivity(tr("Dataset 1 Loaded"),
                   tr("%1 (%2 rows, %3 columns)").arg(m_dataset1.name()).arg(m_dataset1.rowCount()).arg(m_dataset1.columnCount()),
                   tr("Import"));
    emit lastSessionChanged();
    saveSettings();

    if (!m_restoringSession)
    {
        m_datasetsChangedSinceStartup = true;
        m_sessionRestoreDecision = 2;
        dismissAnalysisSession();
        dismissCleaningSession();
        dismissVisualizationSession();
        dismissComparisonSession();
        m_sessionManager.setDataset1Info(true, normalizedPath, m_dataset1.name(), m_dataset1.rowCount(), m_dataset1.columnCount());
        m_sessionManager.saveSession();
        emit datasetsChangedSinceStartupChanged();
        emit sessionRestoreDecisionChanged();
        qInfo() << "[SESSION] Dataset1 changed -> session updated";
    }
    emit sessionAvailabilityChanged();

    emit dataset1Changed();

    clearAnalysis();
    tryGenerateMappings();

    qInfo() << "[STARTUP][Dataset1] Total loadDataset1:" << ds1TotalTimer.elapsed() << "ms";
    return true;
}

bool AppController::loadDataset2(const QString &filePath)
{
    QElapsedTimer ds2TotalTimer;
    ds2TotalTimer.start();

    clearError();

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        clearDataset2();
        setError(QStringLiteral("Dataset 2 file path is empty."));
        return false;
    }

    QElapsedTimer parseTimer;
    parseTimer.start();
    if (!m_parser2.loadFile(normalizedPath))
    {
        setError(m_parser2.lastError());
        return false;
    }
    qInfo() << "[STARTUP][Dataset2] File read & parse (Excel/CSV):" << parseTimer.elapsed() << "ms"
            << QString("(Rows: %1, Cols: %2)").arg(m_parser2.dataSet().rowCount()).arg(m_parser2.dataSet().columnCount());

    m_dataset2 = m_parser2.dataSet();
    m_originalDataset2 = m_dataset2;
    m_dataset2Modified = false;
    m_dataset2MissingTasks.clear();
    m_dataset2OutlierTasks.clear();
    m_dataset2OtherTasks.clear();
    emit dataset2CleaningStateChanged();

    QElapsedTimer colModelTimer;
    colModelTimer.start();
    m_dataset2ColumnModel.setColumns(m_dataset2.columns());
    qInfo() << "[STARTUP][Dataset2] Column model setColumns:" << colModelTimer.elapsed() << "ms";

    QElapsedTimer qualityTimer;
    qualityTimer.start();
    analyzeDataset2Quality();
    qInfo() << "[STARTUP][Dataset2] Quality & Outliers analysis total:" << qualityTimer.elapsed() << "ms";

    m_lastDataset2Path = normalizedPath;
    addRecentFile(normalizedPath, tr("Dataset 2 (Excel/CSV)"), m_dataset2.rowCount(), m_dataset2.columnCount());
    recordActivity(tr("Dataset 2 Loaded"),
                   tr("%1 (%2 rows, %3 columns)").arg(m_dataset2.name()).arg(m_dataset2.rowCount()).arg(m_dataset2.columnCount()),
                   tr("Import"));
    emit lastSessionChanged();
    saveSettings();

    if (!m_restoringSession)
    {
        m_datasetsChangedSinceStartup = true;
        m_sessionRestoreDecision = 2;
        dismissAnalysisSession();
        dismissCleaningSession();
        dismissVisualizationSession();
        dismissComparisonSession();
        m_sessionManager.setDataset2Info(true, normalizedPath, m_dataset2.name(), m_dataset2.rowCount(), m_dataset2.columnCount());
        m_sessionManager.saveSession();
        emit datasetsChangedSinceStartupChanged();
        emit sessionRestoreDecisionChanged();
        qInfo() << "[SESSION] Dataset2 changed -> session updated";
    }
    emit sessionAvailabilityChanged();

    emit dataset2Changed();

    clearAnalysis();
    tryGenerateMappings();

    qInfo() << "[STARTUP][Dataset2] Total loadDataset2:" << ds2TotalTimer.elapsed() << "ms";
    return true;
}

void AppController::clearDataset1()
{
    clearError();
    m_dataset1.clear();
    m_originalDataset1.clear();
    m_dataset1Modified = false;
    m_dataset1MissingTasks.clear();
    m_dataset1OutlierTasks.clear();
    m_dataset1OtherTasks.clear();
    emit dataset1CleaningStateChanged();
    m_dataset1ColumnModel.clear();
    m_mappingModel.clear();
    m_lastDataset1Path.clear();

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    if (!m_restoringSession)
    {
        m_datasetsChangedSinceStartup = true;
        m_sessionRestoreDecision = 2;
        dismissAnalysisSession();
        dismissCleaningSession();
        dismissVisualizationSession();
        dismissComparisonSession();
        m_sessionManager.setDataset1Info(false, QString(), QString(), 0, 0);
        m_sessionManager.saveSession();
        emit datasetsChangedSinceStartupChanged();
        emit sessionRestoreDecisionChanged();
    }
    emit sessionAvailabilityChanged();

    emit dataset1Changed();
    emit lastSessionChanged();
    saveSettings();
}

void AppController::clearDataset2()
{
    clearError();
    m_dataset2.clear();
    m_originalDataset2.clear();
    m_dataset2Modified = false;
    m_dataset2MissingTasks.clear();
    m_dataset2OutlierTasks.clear();
    m_dataset2OtherTasks.clear();
    emit dataset2CleaningStateChanged();
    m_dataset2ColumnModel.clear();
    m_mappingModel.clear();
    m_lastDataset2Path.clear();

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    if (!m_restoringSession)
    {
        m_datasetsChangedSinceStartup = true;
        m_sessionRestoreDecision = 2;
        dismissAnalysisSession();
        dismissCleaningSession();
        dismissVisualizationSession();
        dismissComparisonSession();
        m_sessionManager.setDataset2Info(false, QString(), QString(), 0, 0);
        m_sessionManager.saveSession();
        emit datasetsChangedSinceStartupChanged();
        emit sessionRestoreDecisionChanged();
    }
    emit sessionAvailabilityChanged();

    emit dataset2Changed();
    emit lastSessionChanged();
    saveSettings();
    emit mappingsChanged();
}

// =========================================================
// RESTORE ORIGINAL
// =========================================================

bool AppController::restoreDataset1()
{
    clearError();

    if (m_originalDataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 original data is not available."));
        return false;
    }

    m_dataset1 = m_originalDataset1;
    m_dataset1Modified = false;
    m_dataset1MissingTasks.clear();
    m_dataset1OutlierTasks.clear();
    m_dataset1OtherTasks.clear();

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    analyzeDataset1Quality();

    m_sessionManager.removeCleaningSnapshot(1);
    saveCurrentCleaningSession();
    emit sessionAvailabilityChanged();

    emit dataset1Changed();
    emit dataset1CleaningStateChanged();

    tryGenerateMappings();
    recordActivity(tr("Dataset 1 Reset"), tr("Reverted to original data"), tr("Cleaning"));

    return true;
}

bool AppController::restoreDataset2()
{
    clearError();

    if (m_originalDataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 original data is not available."));
        return false;
    }

    m_dataset2 = m_originalDataset2;
    m_dataset2Modified = false;
    m_dataset2MissingTasks.clear();
    m_dataset2OutlierTasks.clear();
    m_dataset2OtherTasks.clear();

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    analyzeDataset2Quality();

    m_sessionManager.removeCleaningSnapshot(2);
    saveCurrentCleaningSession();
    emit sessionAvailabilityChanged();

    emit dataset2Changed();
    emit dataset2CleaningStateChanged();

    tryGenerateMappings();
    recordActivity(tr("Dataset 2 Reset"), tr("Reverted to original data"), tr("Cleaning"));

    return true;
}

bool AppController::applyCleaningTaskSynchronous(DataSet &dataSet, const CleaningTask &task)
{
    if (dataSet.isEmpty())
        return false;

    switch (task.operation)
    {
    case CleaningTask::RemoveDuplicates:
        m_cleaningEngine.removeDuplicateRows(dataSet);
        return true;

    case CleaningTask::RemoveMissingRows:
        m_cleaningEngine.removeRowsWithMissingValues(dataSet);
        return true;

    case CleaningTask::FillMissingMean:
        m_cleaningEngine.fillMissingWithMean(dataSet, task.columnName);
        return true;

    case CleaningTask::FillMissingMedian:
        m_cleaningEngine.fillMissingWithMedian(dataSet, task.columnName);
        return true;

    case CleaningTask::FillMissingMode:
        m_cleaningEngine.fillMissingWithMode(dataSet, task.columnName);
        return true;

    case CleaningTask::RemoveColumn:
        dataSet.removeColumn(task.columnName);
        return true;

    case CleaningTask::ApplyOutlierAction:
        m_cleaningEngine.applyOutlierAction(dataSet, task.columnName, task.method, task.action, task.parameter);
        return true;

    case CleaningTask::BulkMissing:
    {
        const QString act = task.bulkAction;
        if (act == QLatin1String("Drop Rows") || act == QString::fromUtf8("Satırları Sil") || act == QLatin1String("Drop Missing Rows"))
        {
            m_cleaningEngine.removeRowsWithMissingValues(dataSet);
        }
        else if (act == QLatin1String("Drop Column") || act == QString::fromUtf8("Sütunu Sil") || act == QLatin1String("Remove Column") || act == QLatin1String("Delete Column"))
        {
            for (const QString &col : task.targetColumns)
            {
                dataSet.removeColumn(col);
            }
        }
        else
        {
            const int total = task.targetColumns.size();
            for (int i = 0; i < total; ++i)
            {
                const QString &col = task.targetColumns.at(i);
                const bool isNum = (i < task.numericFlags.size()) ? task.numericFlags.at(i) : false;
                if ((act.contains(QLatin1String("Mean")) || act.contains(QString::fromUtf8("Ortalama"))) && isNum)
                {
                    m_cleaningEngine.fillMissingWithMean(dataSet, col);
                }
                else if ((act.contains(QLatin1String("Median")) || act.contains(QString::fromUtf8("Medyan"))) && isNum)
                {
                    m_cleaningEngine.fillMissingWithMedian(dataSet, col);
                }
                else if (act.contains(QLatin1String("Mode")) || act.contains(QString::fromUtf8("Mod")))
                {
                    m_cleaningEngine.fillMissingWithMode(dataSet, col);
                }
            }
        }
        return true;
    }

    case CleaningTask::BulkOutliers:
    {
        for (const QString &col : task.targetColumns)
        {
            m_cleaningEngine.applyOutlierAction(dataSet, col, task.method, task.action, task.parameter);
        }
        return true;
    }

    default:
        return false;
    }
}

bool AppController::rebuildDataset1()
{
    clearError();
    if (m_originalDataset1.isEmpty())
        return false;

    m_dataset1 = m_originalDataset1;

    for (const CleaningTask &task : m_dataset1OtherTasks)
    {
        applyCleaningTaskSynchronous(m_dataset1, task);
    }
    for (const CleaningTask &task : m_dataset1MissingTasks)
    {
        applyCleaningTaskSynchronous(m_dataset1, task);
    }
    for (const CleaningTask &task : m_dataset1OutlierTasks)
    {
        applyCleaningTaskSynchronous(m_dataset1, task);
    }

    m_dataset1Modified = (!m_dataset1OtherTasks.isEmpty() ||
                          !m_dataset1MissingTasks.isEmpty() ||
                          !m_dataset1OutlierTasks.isEmpty());

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    analyzeDataset1Quality();

    emit dataset1Changed();
    emit dataset1CleaningStateChanged();

    tryGenerateMappings();
    saveCurrentCleaningSession();
    emit sessionAvailabilityChanged();

    return true;
}

bool AppController::rebuildDataset2()
{
    clearError();
    if (m_originalDataset2.isEmpty())
        return false;

    m_dataset2 = m_originalDataset2;

    for (const CleaningTask &task : m_dataset2OtherTasks)
    {
        applyCleaningTaskSynchronous(m_dataset2, task);
    }
    for (const CleaningTask &task : m_dataset2MissingTasks)
    {
        applyCleaningTaskSynchronous(m_dataset2, task);
    }
    for (const CleaningTask &task : m_dataset2OutlierTasks)
    {
        applyCleaningTaskSynchronous(m_dataset2, task);
    }

    m_dataset2Modified = (!m_dataset2OtherTasks.isEmpty() ||
                          !m_dataset2MissingTasks.isEmpty() ||
                          !m_dataset2OutlierTasks.isEmpty());

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    analyzeDataset2Quality();

    emit dataset2Changed();
    emit dataset2CleaningStateChanged();

    tryGenerateMappings();
    saveCurrentCleaningSession();
    emit sessionAvailabilityChanged();

    return true;
}

bool AppController::resetDataset1Missing()
{
    if (m_cleaningBusy)
    {
        setError(QStringLiteral("A cleaning task is currently running."));
        return false;
    }

    if (m_dataset1MissingTasks.isEmpty())
        return true;

    m_dataset1MissingTasks.clear();
    bool ok = rebuildDataset1();
    if (ok)
    {
        recordActivity(tr("Dataset 1 Reset Missing"), tr("Missing value cleaning reverted"), tr("Cleaning"));
    }
    return ok;
}

bool AppController::resetDataset2Missing()
{
    if (m_cleaningBusy)
    {
        setError(QStringLiteral("A cleaning task is currently running."));
        return false;
    }

    if (m_dataset2MissingTasks.isEmpty())
        return true;

    m_dataset2MissingTasks.clear();
    bool ok = rebuildDataset2();
    if (ok)
    {
        recordActivity(tr("Dataset 2 Reset Missing"), tr("Missing value cleaning reverted"), tr("Cleaning"));
    }
    return ok;
}

bool AppController::resetDataset1Outliers()
{
    if (m_cleaningBusy)
    {
        setError(QStringLiteral("A cleaning task is currently running."));
        return false;
    }

    if (m_dataset1OutlierTasks.isEmpty())
        return true;

    m_dataset1OutlierTasks.clear();
    clearDataset1OutlierCleaning();
    bool ok = rebuildDataset1();
    if (ok)
    {
        recordActivity(tr("Dataset 1 Reset Outliers"), tr("Outlier cleaning reverted"), tr("Cleaning"));
    }
    return ok;
}

bool AppController::resetDataset2Outliers()
{
    if (m_cleaningBusy)
    {
        setError(QStringLiteral("A cleaning task is currently running."));
        return false;
    }

    if (m_dataset2OutlierTasks.isEmpty())
        return true;

    m_dataset2OutlierTasks.clear();
    clearDataset2OutlierCleaning();
    bool ok = rebuildDataset2();
    if (ok)
    {
        recordActivity(tr("Dataset 2 Reset Outliers"), tr("Outlier cleaning reverted"), tr("Cleaning"));
    }
    return ok;
}

bool AppController::resetDatasetMissing(int datasetIndex)
{
    return datasetIndex == 1 ? resetDataset1Missing() : resetDataset2Missing();
}

bool AppController::resetDatasetOutliers(int datasetIndex)
{
    return datasetIndex == 1 ? resetDataset1Outliers() : resetDataset2Outliers();
}

// =========================================================
// CLEANING
// =========================================================

bool AppController::removeDataset1Duplicates()
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveDuplicates;
    task.datasetIndex = 1;
    return startCleaningTask(task);
}

bool AppController::removeDataset2Duplicates()
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveDuplicates;
    task.datasetIndex = 2;
    return startCleaningTask(task);
}

bool AppController::removeDataset1MissingRows()
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveMissingRows;
    task.datasetIndex = 1;
    return startCleaningTask(task);
}

bool AppController::removeDataset2MissingRows()
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveMissingRows;
    task.datasetIndex = 2;
    return startCleaningTask(task);
}

bool AppController::fillDataset1MissingWithMean(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMean;
    task.datasetIndex = 1;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::fillDataset2MissingWithMean(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMean;
    task.datasetIndex = 2;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::fillDataset1MissingWithMedian(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMedian;
    task.datasetIndex = 1;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::fillDataset2MissingWithMedian(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMedian;
    task.datasetIndex = 2;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::fillDataset1MissingWithMode(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMode;
    task.datasetIndex = 1;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::fillDataset2MissingWithMode(
    const QString &columnName
    )
{
    CleaningTask task;
    task.operation = CleaningTask::FillMissingMode;
    task.datasetIndex = 2;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::removeDataset1Outliers(
    const QString &columnName,
    double multiplier
    )
{
    return applyDataset1OutlierAction(
        columnName,
        QStringLiteral("IQR"),
        QStringLiteral("Remove"),
        multiplier
        );
}

bool AppController::removeDataset2Outliers(
    const QString &columnName,
    double multiplier
    )
{
    return applyDataset2OutlierAction(
        columnName,
        QStringLiteral("IQR"),
        QStringLiteral("Remove"),
        multiplier
        );
}

bool AppController::applyDataset1OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    CleaningTask task;
    task.operation = CleaningTask::ApplyOutlierAction;
    task.datasetIndex = 1;
    task.columnName = columnName;
    task.method = method;
    task.action = action;
    task.parameter = parameter;
    return startCleaningTask(task);
}

bool AppController::applyDataset2OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    CleaningTask task;
    task.operation = CleaningTask::ApplyOutlierAction;
    task.datasetIndex = 2;
    task.columnName = columnName;
    task.method = method;
    task.action = action;
    task.parameter = parameter;
    return startCleaningTask(task);
}

void AppController::clearDataset1OutlierCleaning()
{
    if (m_dataset1OutlierCleaningResult.isEmpty())
        return;

    m_dataset1OutlierCleaningResult.clear();

    emit dataset1OutlierCleaningChanged();
}

void AppController::clearDataset2OutlierCleaning()
{
    if (m_dataset2OutlierCleaningResult.isEmpty())
        return;

    m_dataset2OutlierCleaningResult.clear();

    emit dataset2OutlierCleaningChanged();
}

// =========================================================
// MAPPING
// =========================================================

void AppController::generateMappings()
{
    if (m_dataset1.isEmpty() || m_dataset2.isEmpty())
    {
        m_mappingModel.clear();
        clearAnalysis();
        emit mappingsChanged();
        return;
    }

    const QVector<ColumnMapping> mappings =
        m_comparisonEngine.suggestMappings(
            m_dataset1,
            m_dataset2
            );

    m_mappingModel.setMappings(mappings);

    clearAnalysis();
    emit mappingsChanged();
}

void AppController::clearMappings()
{
    m_mappingModel.clear();
    clearAnalysis();
    emit mappingsChanged();
}

QVariantList AppController::getSuggestedMappings() const
{
    QVariantList list;
    for (int i = 0; i < m_mappingModel.count(); ++i)
    {
        list.append(m_mappingModel.get(i));
    }
    return list;
}

// =========================================================
// COMPARISON
// =========================================================

bool AppController::analyzeColumns(
    const QString &sourceColumn,
    const QString &targetColumn
    )
{
    clearError();
    clearAnalysis();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const ColumnComparisonResult result =
        m_analysisEngine.compareColumns(
            m_dataset1,
            sourceColumn,
            m_dataset2,
            targetColumn
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    QVariantMap resultMap;

    resultMap.insert(QStringLiteral("sourceColumn"), result.sourceColumnName);
    resultMap.insert(QStringLiteral("targetColumn"), result.targetColumnName);

    resultMap.insert(
        QStringLiteral("sourceStatistics"),
        statisticsToVariantMap(result.sourceStatistics)
        );

    resultMap.insert(
        QStringLiteral("targetStatistics"),
        statisticsToVariantMap(result.targetStatistics)
        );

    resultMap.insert(QStringLiteral("meanDifference"), result.meanDifference);
    resultMap.insert(QStringLiteral("medianDifference"), result.medianDifference);
    resultMap.insert(QStringLiteral("minimumDifference"), result.minimumDifference);
    resultMap.insert(QStringLiteral("maximumDifference"), result.maximumDifference);
    resultMap.insert(QStringLiteral("rangeDifference"), result.rangeDifference);
    resultMap.insert(QStringLiteral("varianceDifference"), result.varianceDifference);

    resultMap.insert(
        QStringLiteral("standardDeviationDifference"),
        result.standardDeviationDifference
        );

    resultMap.insert(QStringLiteral("q1Difference"), result.q1Difference);
    resultMap.insert(QStringLiteral("q3Difference"), result.q3Difference);
    resultMap.insert(QStringLiteral("iqrDifference"), result.iqrDifference);

    m_analysisResult = resultMap;
    m_analysisAvailable = true;

    emit analysisResultChanged();

    return true;
}

void AppController::clearAnalysis()
{
    const bool hadAnalysis =
        m_analysisAvailable ||
        !m_analysisResult.isEmpty();

    m_analysisResult.clear();
    m_analysisAvailable = false;

    clearDatasetComparison();

    if (hadAnalysis)
        emit analysisResultChanged();
}

void AppController::clearDatasetComparison()
{
    const bool hadComparison =
        m_datasetComparisonAvailable ||
        !m_datasetComparisonResult.isEmpty();

    m_datasetComparisonResult.clear();
    m_datasetComparisonAvailable = false;

    if (hadComparison)
        emit datasetComparisonChanged();
}

bool AppController::compareDatasets(const QVariantList &mappings)
{
    clearError();
    clearDatasetComparison();

    if (m_dataset1.isEmpty())
    {
        setError(tr("Dataset 1 is not loaded."));
        return false;
    }

    if (m_dataset2.isEmpty())
    {
        setError(tr("Dataset 2 is not loaded."));
        return false;
    }

    if (mappings.isEmpty())
    {
        setError(tr("At least one valid column mapping must be selected."));
        return false;
    }

    QVariantList resultsList;
    int totalComparedRecords = 0;
    int totalDifferentRecords = 0;
    int matchedColumnCount = 0;

    for (const QVariant &mappingVar : mappings)
    {
        const QVariantMap map = mappingVar.toMap();
        const QString sourceCol = map.value(QStringLiteral("sourceColumn")).toString().trimmed();
        const QString targetCol = map.value(QStringLiteral("targetColumn")).toString().trimmed();

        if (sourceCol.isEmpty() || targetCol.isEmpty())
            continue;

        const ColumnInfo *col1 = nullptr;
        for (const ColumnInfo &c : m_dataset1.columns())
        {
            if (c.name().compare(sourceCol, Qt::CaseInsensitive) == 0)
            {
                col1 = &c;
                break;
            }
        }

        const ColumnInfo *col2 = nullptr;
        for (const ColumnInfo &c : m_dataset2.columns())
        {
            if (c.name().compare(targetCol, Qt::CaseInsensitive) == 0)
            {
                col2 = &c;
                break;
            }
        }

        if (!col1 || !col2)
            continue;

        matchedColumnCount++;
        const QVector<QVariant> &vals1 = col1->values();
        const QVector<QVariant> &vals2 = col2->values();
        const int commonCount = std::min(vals1.size(), vals2.size());
        int pairCompared = 0;
        int pairDiff = 0;

        for (int r = 0; r < commonCount; ++r)
        {
            const QVariant &v1 = vals1.at(r);
            const QVariant &v2 = vals2.at(r);

            if (v1.isNull() && v2.isNull())
                continue;

            pairCompared++;

            if (v1 != v2)
            {
                bool ok1 = false, ok2 = false;
                const double d1 = v1.toDouble(&ok1);
                const double d2 = v2.toDouble(&ok2);

                if (ok1 && ok2)
                {
                    if (std::fabs(d1 - d2) > 1e-6)
                        pairDiff++;
                }
                else
                {
                    pairDiff++;
                }
            }
        }

        totalComparedRecords += pairCompared;
        totalDifferentRecords += pairDiff;

        QVariantMap pairResult;
        pairResult.insert(QStringLiteral("sourceColumn"), sourceCol);
        pairResult.insert(QStringLiteral("targetColumn"), targetCol);
        pairResult.insert(QStringLiteral("comparedRecords"), pairCompared);
        pairResult.insert(QStringLiteral("differentRecords"), pairDiff);

        const double diffPct =
            pairCompared > 0
                ? (static_cast<double>(pairDiff) / static_cast<double>(pairCompared) * 100.0)
                : 0.0;
        pairResult.insert(QStringLiteral("differencePercentage"), diffPct);

        if (col1->isNumeric() && col2->isNumeric())
        {
            const ColumnComparisonResult comp =
                m_analysisEngine.compareColumns(m_dataset1, sourceCol, m_dataset2, targetCol);

            if (comp.success)
            {
                pairResult.insert(QStringLiteral("meanDifference"), comp.meanDifference);
                pairResult.insert(QStringLiteral("medianDifference"), comp.medianDifference);
                pairResult.insert(QStringLiteral("iqrDifference"), comp.iqrDifference);
                pairResult.insert(
                    QStringLiteral("standardDeviationDifference"),
                    comp.standardDeviationDifference
                    );
            }
        }

        resultsList.append(pairResult);
    }

    if (matchedColumnCount == 0)
    {
        setError(tr("No valid column mapping found."));
        return false;
    }

    QVariantMap summaryMap;
    summaryMap.insert(QStringLiteral("matchedColumnCount"), matchedColumnCount);
    summaryMap.insert(QStringLiteral("comparedRecordCount"), totalComparedRecords);
    summaryMap.insert(QStringLiteral("differentRecordCount"), totalDifferentRecords);

    const double overallDiffPct =
        totalComparedRecords > 0
            ? (static_cast<double>(totalDifferentRecords) / static_cast<double>(totalComparedRecords) * 100.0)
            : 0.0;

    summaryMap.insert(QStringLiteral("differencePercentage"), overallDiffPct);
    summaryMap.insert(QStringLiteral("results"), resultsList);

    m_datasetComparisonResult = summaryMap;
    m_datasetComparisonAvailable = true;

    recordActivity(tr("Dataset Comparison"),
                   tr("%1 mapped column(s), %2 rows compared").arg(matchedColumnCount).arg(totalComparedRecords),
                   tr("Comparison"));

    emit datasetComparisonChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();
    return true;
}

// =========================================================
// EDA SUMMARY
// =========================================================

bool AppController::analyzeDataset1Eda(
    const QString &columnName
    )
{
    clearError();
    clearDataset1Eda();

    const EdaOperationResult result =
        m_edaEngine.analyzeSummary(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage.trimmed().isEmpty()
                ? tr("This column is not numeric. Select a numeric column for statistical analysis.")
                : result.errorMessage
            );
        return false;
    }

    m_dataset1EdaResult = result.data;
    m_dataset1EdaAvailable = true;

    emit dataset1EdaChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

bool AppController::analyzeDataset2Eda(
    const QString &columnName
    )
{
    clearError();
    clearDataset2Eda();

    const EdaOperationResult result =
        m_edaEngine.analyzeSummary(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage.trimmed().isEmpty()
                ? tr("This column is not numeric. Select a numeric column for statistical analysis.")
                : result.errorMessage
            );
        return false;
    }

    m_dataset2EdaResult = result.data;
    m_dataset2EdaAvailable = true;

    emit dataset2EdaChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

void AppController::clearDataset1Eda()
{
    const bool hadResult =
        m_dataset1EdaAvailable ||
        !m_dataset1EdaResult.isEmpty();

    m_dataset1EdaResult.clear();
    m_dataset1EdaAvailable = false;

    if (hadResult)
        emit dataset1EdaChanged();
}

void AppController::clearDataset2Eda()
{
    const bool hadResult =
        m_dataset2EdaAvailable ||
        !m_dataset2EdaResult.isEmpty();

    m_dataset2EdaResult.clear();
    m_dataset2EdaAvailable = false;

    if (hadResult)
        emit dataset2EdaChanged();
}

// =========================================================
// CORRELATION ANALYSIS
// =========================================================

bool AppController::analyzeDataset1Correlation(
    const QString &firstColumnName,
    const QString &secondColumnName
    )
{
    clearError();
    clearDataset1Correlation();

    const EdaOperationResult result =
        m_edaEngine.analyzeCorrelation(
            m_dataset1,
            firstColumnName,
            secondColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1CorrelationResult = result.data;
    m_dataset1CorrelationAvailable = true;

    emit dataset1CorrelationChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

bool AppController::analyzeDataset2Correlation(
    const QString &firstColumnName,
    const QString &secondColumnName
    )
{
    clearError();
    clearDataset2Correlation();

    const EdaOperationResult result =
        m_edaEngine.analyzeCorrelation(
            m_dataset2,
            firstColumnName,
            secondColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2CorrelationResult = result.data;
    m_dataset2CorrelationAvailable = true;

    emit dataset2CorrelationChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

void AppController::clearDataset1Correlation()
{
    const bool hadResult =
        m_dataset1CorrelationAvailable ||
        !m_dataset1CorrelationResult.isEmpty();

    m_dataset1CorrelationResult.clear();
    m_dataset1CorrelationAvailable = false;

    if (hadResult)
        emit dataset1CorrelationChanged();
}

void AppController::clearDataset2Correlation()
{
    const bool hadResult =
        m_dataset2CorrelationAvailable ||
        !m_dataset2CorrelationResult.isEmpty();

    m_dataset2CorrelationResult.clear();
    m_dataset2CorrelationAvailable = false;

    if (hadResult)
        emit dataset2CorrelationChanged();
}

// =========================================================
// VISUALIZATION
// =========================================================

QVariantMap AppController::createDataset1Histogram(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const HistogramResult result =
        m_visualizationEngine.createHistogram(
            m_dataset1,
            columnName,
            binCount
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return histogramToVariantMap(result);
}

QVariantMap AppController::createDataset2Histogram(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const HistogramResult result =
        m_visualizationEngine.createHistogram(
            m_dataset2,
            columnName,
            binCount
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return histogramToVariantMap(result);
}

QVariantMap AppController::createDataset1BoxPlot(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    const BoxPlotResult result =
        m_visualizationEngine.createBoxPlot(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return boxPlotToVariantMap(result);
}

QVariantMap AppController::createDataset2BoxPlot(
    const QString &columnName,
    double multiplier
    )
{
    clearError();

    const BoxPlotResult result =
        m_visualizationEngine.createBoxPlot(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return boxPlotToVariantMap(result);
}

QVariantMap AppController::createDataset1TimeSeries(
    const QString &xColumnName,
    const QString &yColumnName
    )
{
    clearError();

    const TimeSeriesResult result =
        m_visualizationEngine.createTimeSeries(
            m_dataset1,
            xColumnName,
            yColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return timeSeriesToVariantMap(result);
}

QVariantMap AppController::createDataset2TimeSeries(
    const QString &xColumnName,
    const QString &yColumnName
    )
{
    clearError();

    const TimeSeriesResult result =
        m_visualizationEngine.createTimeSeries(
            m_dataset2,
            xColumnName,
            yColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return timeSeriesToVariantMap(result);
}

QVariantMap AppController::createDataset1Distribution(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const DistributionResult result =
        m_visualizationEngine.createDistribution(
            m_dataset1,
            columnName,
            binCount
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return distributionToVariantMap(result);
}

QVariantMap AppController::createDataset2Distribution(
    const QString &columnName,
    int binCount
    )
{
    clearError();

    const DistributionResult result =
        m_visualizationEngine.createDistribution(
            m_dataset2,
            columnName,
            binCount
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return distributionToVariantMap(result);
}

QVariantMap AppController::createDataset1CorrelationMatrix()
{
    clearError();

    const CorrelationMatrixResult result =
        m_visualizationEngine.createCorrelationMatrix(
            m_dataset1
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return correlationMatrixToVariantMap(result);
}

QVariantMap AppController::createDataset2CorrelationMatrix()
{
    clearError();

    const CorrelationMatrixResult result =
        m_visualizationEngine.createCorrelationMatrix(
            m_dataset2
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return correlationMatrixToVariantMap(result);
}

QVariantMap AppController::createDatasetComparisonChart(
    const QString &sourceColumnName,
    const QString &targetColumnName
    )
{
    clearError();

    const ComparisonChartResult result =
        m_visualizationEngine.createComparisonChart(
            m_dataset1,
            sourceColumnName,
            m_dataset2,
            targetColumnName
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        m_datasetComparisonAvailable = true;
        emit visualizationChanged();
        emit datasetComparisonChanged();
    }

    return comparisonChartToVariantMap(result);
}

QVariantMap AppController::createDatasetComparisonDistributionChart(
    const QString &sourceColumnName,
    const QString &targetColumnName,
    int binCount
    )
{
    clearError();

    const ComparisonDistributionResult result =
        m_visualizationEngine.createComparisonDistribution(
            m_dataset1,
            sourceColumnName,
            m_dataset2,
            targetColumnName,
            binCount
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        m_datasetComparisonAvailable = true;
        emit visualizationChanged();
        emit datasetComparisonChanged();
    }

    return comparisonDistributionToVariantMap(result);
}

QVariantMap AppController::createDataset1BarChart(
    const QString &categoryColumnName,
    const QString &valueColumnName,
    const QString &aggregation
    )
{
    clearError();

    const BarChartResult result =
        m_visualizationEngine.createBarChart(
            m_dataset1,
            categoryColumnName,
            valueColumnName,
            aggregation
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return barChartToVariantMap(result);
}

QVariantMap AppController::createDataset2BarChart(
    const QString &categoryColumnName,
    const QString &valueColumnName,
    const QString &aggregation
    )
{
    clearError();

    const BarChartResult result =
        m_visualizationEngine.createBarChart(
            m_dataset2,
            categoryColumnName,
            valueColumnName,
            aggregation
            );

    if (!result.success)
    {
        setError(result.errorMessage);
    }
    else
    {
        m_visualizationAvailable = true;
        emit visualizationChanged();
    }

    return barChartToVariantMap(result);
}

// =========================================================
// EXPORT
// =========================================================

bool AppController::exportDataset1ToCsv(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToCsv(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 1 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset2ToCsv(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToCsv(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 2 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset1ToJson(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToJson(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 1 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset2ToJson(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToJson(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 2 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset1ToXlsx(const QString &filePath)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToXlsx(
            m_dataset1,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 1 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset2ToXlsx(const QString &filePath)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    const QString normalizedPath = normalizeFilePath(filePath);
    if (normalizedPath.isEmpty())
    {
        setError(QStringLiteral("Invalid file path."));
        return false;
    }

    const ExportResult result =
        m_exportEngine.exportDataSetToXlsx(
            m_dataset2,
            normalizedPath
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    recordActivity(tr("Dataset 2 Exported"), normalizedPath, tr("Export"));
    return true;
}

bool AppController::exportDataset(int datasetIndex, const QString &filePath, const QString &format)
{
    clearError();
    const QString ext = format.toLower().trimmed();
    if (ext == QStringLiteral("xlsx"))
    {
        return (datasetIndex == 1) ? exportDataset1ToXlsx(filePath) : exportDataset2ToXlsx(filePath);
    }
    else if (ext == QStringLiteral("csv"))
    {
        return (datasetIndex == 1) ? exportDataset1ToCsv(filePath) : exportDataset2ToCsv(filePath);
    }
    else if (ext == QStringLiteral("json"))
    {
        return (datasetIndex == 1) ? exportDataset1ToJson(filePath) : exportDataset2ToJson(filePath);
    }

    setError(tr("Unsupported export format: %1").arg(format));
    return false;
}

QString AppController::suggestedExportFileName(int datasetIndex, const QString &format) const
{
    const DataSet &ds = (datasetIndex == 1) ? m_dataset1 : m_dataset2;
    QString safeName = ds.name().isEmpty() ? QStringLiteral("dataset") : ds.name();
    safeName.replace(QLatin1Char('/'), QLatin1Char('_')).replace(QLatin1Char('\\'), QLatin1Char('_'));
    const QString cleanName = safeName.split(QLatin1Char('.')).first();
    const QString timeStr = QDateTime::currentDateTime().toString(QStringLiteral("MMdd_HHmm"));
    const QString ext = format.toLower().trimmed();
    return QStringLiteral("%1_Export_%2.%3").arg(cleanName, timeStr, ext);
}

bool AppController::removeDataset1Column(const QString &columnName)
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveColumn;
    task.datasetIndex = 1;
    task.columnName = columnName;
    return startCleaningTask(task);
}

bool AppController::removeDataset2Column(const QString &columnName)
{
    CleaningTask task;
    task.operation = CleaningTask::RemoveColumn;
    task.datasetIndex = 2;
    task.columnName = columnName;
    return startCleaningTask(task);
}

QString AppController::defaultExportDirectory() const
{
    const QString docPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    const QString exportPath = QDir(docPath).filePath(QStringLiteral("GenericDataAnalyzer/Exports"));
    QDir exportDir(exportPath);
    if (!exportDir.exists())
    {
        exportDir.mkpath(QStringLiteral("."));
    }
    return exportPath;
}

QString AppController::appDataDirectory() const
{
    const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir appDataDir(appData);
    if (!appDataDir.exists())
    {
        appDataDir.mkpath(QStringLiteral("."));
    }
    return appData;
}

QString AppController::saveChartImage(const QString &base64Data, const QString &chartTypePrefix)
{
    clearError();

    if (base64Data.isEmpty())
    {
        setError(tr("Image data is empty."));
        return QString();
    }

    const QString outputDirPath = QDir(defaultExportDirectory()).filePath(QStringLiteral("Charts"));
    QDir outputDir(outputDirPath);
    if (!outputDir.exists())
    {
        outputDir.mkpath(QStringLiteral("."));
    }

    QString raw = base64Data;
    int commaIndex = raw.indexOf(QLatin1Char(','));
    if (commaIndex != -1)
    {
        raw = raw.mid(commaIndex + 1);
    }

    QByteArray bytes = QByteArray::fromBase64(raw.toUtf8());
    QImage image;
    if (!image.loadFromData(bytes, "PNG"))
    {
        setError(tr("Failed to decode chart image."));
        return QString();
    }

    const QString safePrefix = chartTypePrefix.isEmpty() ? QStringLiteral("Chart") : chartTypePrefix;
    const QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss"));
    const QString fileName = QStringLiteral("%1_%2.png").arg(safePrefix, timestamp);
    const QString fullPath = outputDir.filePath(fileName);

    if (!image.save(fullPath, "PNG"))
    {
        setError(tr("Failed to save chart file: %1").arg(fullPath));
        return QString();
    }

    m_visualizationAvailable = true;
    emit visualizationChanged();
    if (chartTypePrefix.contains(QStringLiteral("Karsilastirma"), Qt::CaseInsensitive))
    {
        m_datasetComparisonAvailable = true;
        emit datasetComparisonChanged();
    }

    recordActivity(tr("Chart Exported"), fullPath, tr("Export"));
    return fullPath;
}

QString AppController::autoExportDataset(int datasetIndex, const QString &format)
{
    clearError();
    const DataSet &ds = (datasetIndex == 1) ? m_dataset1 : m_dataset2;
    if (ds.isEmpty())
    {
        setError(tr("Dataset not found or is empty."));
        return QString();
    }

    const QString outputDirPath = defaultExportDirectory();
    QDir outputDir(outputDirPath);

    const QString timeStr = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss"));
    QString safeName = ds.name().isEmpty() ? QStringLiteral("dataset") : ds.name();
    safeName.replace(QLatin1Char('/'), QLatin1Char('_')).replace(QLatin1Char('\\'), QLatin1Char('_'));
    const QString cleanName = safeName.split(QLatin1Char('.')).first();
    const QString ext = format.toLower().trimmed();
    const QString filename = QStringLiteral("%1_Export_%2.%3").arg(cleanName, timeStr, ext);
    const QString fullPath = outputDir.filePath(filename);

    bool ok = false;
    if (ext == QStringLiteral("xlsx"))
    {
        ok = (datasetIndex == 1) ? exportDataset1ToXlsx(fullPath) : exportDataset2ToXlsx(fullPath);
    }
    else if (ext == QStringLiteral("csv"))
    {
        ok = (datasetIndex == 1) ? exportDataset1ToCsv(fullPath) : exportDataset2ToCsv(fullPath);
    }
    else if (ext == QStringLiteral("json"))
    {
        ok = (datasetIndex == 1) ? exportDataset1ToJson(fullPath) : exportDataset2ToJson(fullPath);
    }

    if (ok)
    {
        recordActivity(tr("Dataset %1 Exported").arg(datasetIndex), fullPath, tr("Export"));
        return fullPath;
    }
    return QString();
}

// =========================================================
// QUALITY
// =========================================================

bool AppController::analyzeDataset1Quality()
{
    QElapsedTimer qualityTotalTimer;
    qualityTotalTimer.start();

    clearError();
    clearDataset1Quality();

    QElapsedTimer edaQualityTimer;
    edaQualityTimer.start();
    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset1
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }
    qInfo() << "[STARTUP][Dataset1][Quality] EdaEngine analyzeQuality:" << edaQualityTimer.elapsed() << "ms";

    m_dataset1QualityResult = result.data;
    m_dataset1QualityAvailable = true;

    QElapsedTimer outlierScanTimer;
    outlierScanTimer.start();
    analyzeDataset1OutliersAllColumns(QStringLiteral("IQR"), 1.5);
    qInfo() << "[STARTUP][Dataset1][Quality] Outlier scan (IQR 1.5 all columns):" << outlierScanTimer.elapsed() << "ms";

    const int outlierCount = m_dataset1OutlierResult.value(QStringLiteral("outlierCount")).toInt();
    const int affectedCols = m_dataset1OutlierResult.value(QStringLiteral("affectedColumnCount")).toInt();
    m_dataset1QualityResult.insert(QStringLiteral("outlierCount"), outlierCount);
    m_dataset1QualityResult.insert(QStringLiteral("hasOutliers"), outlierCount > 0);
    m_dataset1QualityResult.insert(QStringLiteral("outlierColumnCount"), affectedCols);

    emit dataset1QualityChanged();
    qInfo() << "[STARTUP][Dataset1][Quality] analyzeDataset1Quality total:" << qualityTotalTimer.elapsed() << "ms";

    return true;
}

bool AppController::analyzeDataset2Quality()
{
    QElapsedTimer qualityTotalTimer;
    qualityTotalTimer.start();

    clearError();
    clearDataset2Quality();

    QElapsedTimer edaQualityTimer;
    edaQualityTimer.start();
    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset2
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }
    qInfo() << "[STARTUP][Dataset2][Quality] EdaEngine analyzeQuality:" << edaQualityTimer.elapsed() << "ms";

    m_dataset2QualityResult = result.data;
    m_dataset2QualityAvailable = true;

    QElapsedTimer outlierScanTimer;
    outlierScanTimer.start();
    analyzeDataset2OutliersAllColumns(QStringLiteral("IQR"), 1.5);
    qInfo() << "[STARTUP][Dataset2][Quality] Outlier scan (IQR 1.5 all columns):" << outlierScanTimer.elapsed() << "ms";

    const int outlierCount = m_dataset2OutlierResult.value(QStringLiteral("outlierCount")).toInt();
    const int affectedCols = m_dataset2OutlierResult.value(QStringLiteral("affectedColumnCount")).toInt();
    m_dataset2QualityResult.insert(QStringLiteral("outlierCount"), outlierCount);
    m_dataset2QualityResult.insert(QStringLiteral("hasOutliers"), outlierCount > 0);
    m_dataset2QualityResult.insert(QStringLiteral("outlierColumnCount"), affectedCols);

    emit dataset2QualityChanged();
    qInfo() << "[STARTUP][Dataset2][Quality] analyzeDataset2Quality total:" << qualityTotalTimer.elapsed() << "ms";

    return true;
}

void AppController::clearDataset1Quality()
{
    const bool hadResult =
        m_dataset1QualityAvailable ||
        !m_dataset1QualityResult.isEmpty();

    m_dataset1QualityResult.clear();
    m_dataset1QualityAvailable = false;

    if (hadResult)
        emit dataset1QualityChanged();
}

void AppController::clearDataset2Quality()
{
    const bool hadResult =
        m_dataset2QualityAvailable ||
        !m_dataset2QualityResult.isEmpty();

    m_dataset2QualityResult.clear();
    m_dataset2QualityAvailable = false;

    if (hadResult)
        emit dataset2QualityChanged();
}


// =========================================================
// DATASET LEVEL OUTLIER ANALYSIS — ALL NUMERIC COLUMNS
// =========================================================

bool AppController::analyzeDataset1OutliersAllColumns(
    const QString &method,
    double parameter
    )
{
    clearError();
    clearDataset1Outliers();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is empty."));
        return false;
    }

    const QString normalizedMethod = method.trimmed();

    if (normalizedMethod.compare(
            QStringLiteral("IQR"),
            Qt::CaseInsensitive) != 0 &&
        normalizedMethod.compare(
            QStringLiteral("Z-Score"),
            Qt::CaseInsensitive) != 0)
    {
        setError(QStringLiteral(
            "Outlier method must be IQR or Z-Score."
            ));
        return false;
    }

    if (!std::isfinite(parameter) || parameter <= 0.0)
    {
        setError(QStringLiteral(
            "Outlier parameter must be a finite positive value."
            ));
        return false;
    }

    const bool useIqr =
        normalizedMethod.compare(
            QStringLiteral("IQR"),
            Qt::CaseInsensitive
            ) == 0;

    QVariantList columnResults;

    int numericColumnCount = 0;
    int successfulColumnCount = 0;
    int affectedColumnCount = 0;
    int totalValidValues = 0;
    int totalOutlierCount = 0;

    const QVector<ColumnInfo> columns = m_dataset1.columns();

    for (const ColumnInfo &column : columns)
    {
        if (!column.isNumeric())
            continue;

        ++numericColumnCount;

        QVariantMap columnResult;
        columnResult.insert(QStringLiteral("columnName"), column.name());

        if (useIqr)
        {
            const ColumnOutlierAnalysisResult result =
                m_analysisEngine.analyzeColumnOutliers(
                    m_dataset1,
                    column.name(),
                    parameter
                    );

            if (!result.success)
            {
                columnResult.insert(QStringLiteral("success"), false);
                columnResult.insert(QStringLiteral("error"), result.errorMessage);
                columnResult.insert(QStringLiteral("outlierCount"), 0);
                columnResult.insert(QStringLiteral("outlierPercentage"), 0.0);
                columnResults.append(columnResult);
                continue;
            }

            ++successfulColumnCount;

            const IqrOutlierResult &out = result.outlierResult;

            totalValidValues += out.validValueCount;
            totalOutlierCount += out.outlierCount;

            if (out.outlierCount > 0)
                ++affectedColumnCount;

            columnResult.insert(QStringLiteral("success"), true);
            columnResult.insert(QStringLiteral("method"), QStringLiteral("IQR"));
            columnResult.insert(QStringLiteral("parameter"), parameter);
            columnResult.insert(QStringLiteral("validValueCount"), out.validValueCount);
            columnResult.insert(QStringLiteral("q1"), out.q1);
            columnResult.insert(QStringLiteral("q3"), out.q3);
            columnResult.insert(QStringLiteral("iqr"), out.iqr);
            columnResult.insert(QStringLiteral("lowerBound"), out.lowerBound);
            columnResult.insert(QStringLiteral("upperBound"), out.upperBound);
            columnResult.insert(QStringLiteral("outlierCount"), out.outlierCount);
            columnResult.insert(QStringLiteral("outlierPercentage"), out.outlierPercentage);
        }
        else
        {
            const ZScoreOutlierResult result =
                m_analysisEngine.analyzeColumnZScoreOutliers(
                    m_dataset1,
                    column.name(),
                    parameter
                    );

            if (!result.success)
            {
                columnResult.insert(QStringLiteral("success"), false);
                columnResult.insert(QStringLiteral("error"), result.errorMessage);
                columnResult.insert(QStringLiteral("outlierCount"), 0);
                columnResult.insert(QStringLiteral("outlierPercentage"), 0.0);
                columnResults.append(columnResult);
                continue;
            }

            ++successfulColumnCount;

            totalValidValues += result.validValueCount;
            totalOutlierCount += result.outlierCount;

            if (result.outlierCount > 0)
                ++affectedColumnCount;

            columnResult.insert(QStringLiteral("success"), true);
            columnResult.insert(QStringLiteral("method"), QStringLiteral("Z-Score"));
            columnResult.insert(QStringLiteral("parameter"), parameter);
            columnResult.insert(QStringLiteral("validValueCount"), result.validValueCount);
            columnResult.insert(QStringLiteral("mean"), result.mean);
            columnResult.insert(QStringLiteral("standardDeviation"), result.standardDeviation);
            columnResult.insert(QStringLiteral("threshold"), result.threshold);
            columnResult.insert(QStringLiteral("outlierCount"), result.outlierCount);
            columnResult.insert(QStringLiteral("outlierPercentage"), result.outlierPercentage);
        }

        columnResults.append(columnResult);
    }

    QVariantMap resultMap;
    resultMap.insert(
        QStringLiteral("method"),
        useIqr ? QStringLiteral("IQR") : QStringLiteral("Z-Score")
        );
    resultMap.insert(QStringLiteral("parameter"), parameter);
    resultMap.insert(QStringLiteral("numericColumnCount"), numericColumnCount);
    resultMap.insert(QStringLiteral("successfulColumnCount"), successfulColumnCount);
    resultMap.insert(QStringLiteral("affectedColumnCount"), affectedColumnCount);
    resultMap.insert(QStringLiteral("validValueCount"), totalValidValues);
    resultMap.insert(QStringLiteral("outlierCount"), totalOutlierCount);
    resultMap.insert(
        QStringLiteral("outlierPercentage"),
        totalValidValues > 0
            ? static_cast<double>(totalOutlierCount)
                  / static_cast<double>(totalValidValues) * 100.0
            : 0.0
        );
    resultMap.insert(QStringLiteral("columns"), columnResults);

    m_dataset1OutlierResult = resultMap;
    m_dataset1OutlierAvailable = true;

    if (m_dataset1QualityAvailable)
    {
        m_dataset1QualityResult.insert(QStringLiteral("outlierCount"), totalOutlierCount);
        m_dataset1QualityResult.insert(QStringLiteral("hasOutliers"), totalOutlierCount > 0);
        m_dataset1QualityResult.insert(QStringLiteral("outlierColumnCount"), affectedColumnCount);
        emit dataset1QualityChanged();
    }

    emit dataset1OutlierChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

bool AppController::analyzeDataset2OutliersAllColumns(
    const QString &method,
    double parameter
    )
{
    clearError();
    clearDataset2Outliers();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is empty."));
        return false;
    }

    const QString normalizedMethod = method.trimmed();

    if (normalizedMethod.compare(
            QStringLiteral("IQR"),
            Qt::CaseInsensitive) != 0 &&
        normalizedMethod.compare(
            QStringLiteral("Z-Score"),
            Qt::CaseInsensitive) != 0)
    {
        setError(QStringLiteral(
            "Outlier method must be IQR or Z-Score."
            ));
        return false;
    }

    if (!std::isfinite(parameter) || parameter <= 0.0)
    {
        setError(QStringLiteral(
            "Outlier parameter must be a finite positive value."
            ));
        return false;
    }

    const bool useIqr =
        normalizedMethod.compare(
            QStringLiteral("IQR"),
            Qt::CaseInsensitive
            ) == 0;

    QVariantList columnResults;

    int numericColumnCount = 0;
    int successfulColumnCount = 0;
    int affectedColumnCount = 0;
    int totalValidValues = 0;
    int totalOutlierCount = 0;

    const QVector<ColumnInfo> columns = m_dataset2.columns();

    for (const ColumnInfo &column : columns)
    {
        if (!column.isNumeric())
            continue;

        ++numericColumnCount;

        QVariantMap columnResult;
        columnResult.insert(QStringLiteral("columnName"), column.name());

        if (useIqr)
        {
            const ColumnOutlierAnalysisResult result =
                m_analysisEngine.analyzeColumnOutliers(
                    m_dataset2,
                    column.name(),
                    parameter
                    );

            if (!result.success)
            {
                columnResult.insert(QStringLiteral("success"), false);
                columnResult.insert(QStringLiteral("error"), result.errorMessage);
                columnResult.insert(QStringLiteral("outlierCount"), 0);
                columnResult.insert(QStringLiteral("outlierPercentage"), 0.0);
                columnResults.append(columnResult);
                continue;
            }

            ++successfulColumnCount;

            const IqrOutlierResult &out = result.outlierResult;

            totalValidValues += out.validValueCount;
            totalOutlierCount += out.outlierCount;

            if (out.outlierCount > 0)
                ++affectedColumnCount;

            columnResult.insert(QStringLiteral("success"), true);
            columnResult.insert(QStringLiteral("method"), QStringLiteral("IQR"));
            columnResult.insert(QStringLiteral("parameter"), parameter);
            columnResult.insert(QStringLiteral("validValueCount"), out.validValueCount);
            columnResult.insert(QStringLiteral("q1"), out.q1);
            columnResult.insert(QStringLiteral("q3"), out.q3);
            columnResult.insert(QStringLiteral("iqr"), out.iqr);
            columnResult.insert(QStringLiteral("lowerBound"), out.lowerBound);
            columnResult.insert(QStringLiteral("upperBound"), out.upperBound);
            columnResult.insert(QStringLiteral("outlierCount"), out.outlierCount);
            columnResult.insert(QStringLiteral("outlierPercentage"), out.outlierPercentage);
        }
        else
        {
            const ZScoreOutlierResult result =
                m_analysisEngine.analyzeColumnZScoreOutliers(
                    m_dataset2,
                    column.name(),
                    parameter
                    );

            if (!result.success)
            {
                columnResult.insert(QStringLiteral("success"), false);
                columnResult.insert(QStringLiteral("error"), result.errorMessage);
                columnResult.insert(QStringLiteral("outlierCount"), 0);
                columnResult.insert(QStringLiteral("outlierPercentage"), 0.0);
                columnResults.append(columnResult);
                continue;
            }

            ++successfulColumnCount;

            totalValidValues += result.validValueCount;
            totalOutlierCount += result.outlierCount;

            if (result.outlierCount > 0)
                ++affectedColumnCount;

            columnResult.insert(QStringLiteral("success"), true);
            columnResult.insert(QStringLiteral("method"), QStringLiteral("Z-Score"));
            columnResult.insert(QStringLiteral("parameter"), parameter);
            columnResult.insert(QStringLiteral("validValueCount"), result.validValueCount);
            columnResult.insert(QStringLiteral("mean"), result.mean);
            columnResult.insert(QStringLiteral("standardDeviation"), result.standardDeviation);
            columnResult.insert(QStringLiteral("threshold"), result.threshold);
            columnResult.insert(QStringLiteral("outlierCount"), result.outlierCount);
            columnResult.insert(QStringLiteral("outlierPercentage"), result.outlierPercentage);
        }

        columnResults.append(columnResult);
    }

    QVariantMap resultMap;
    resultMap.insert(
        QStringLiteral("method"),
        useIqr ? QStringLiteral("IQR") : QStringLiteral("Z-Score")
        );
    resultMap.insert(QStringLiteral("parameter"), parameter);
    resultMap.insert(QStringLiteral("numericColumnCount"), numericColumnCount);
    resultMap.insert(QStringLiteral("successfulColumnCount"), successfulColumnCount);
    resultMap.insert(QStringLiteral("affectedColumnCount"), affectedColumnCount);
    resultMap.insert(QStringLiteral("validValueCount"), totalValidValues);
    resultMap.insert(QStringLiteral("outlierCount"), totalOutlierCount);
    resultMap.insert(
        QStringLiteral("outlierPercentage"),
        totalValidValues > 0
            ? static_cast<double>(totalOutlierCount)
                  / static_cast<double>(totalValidValues) * 100.0
            : 0.0
        );
    resultMap.insert(QStringLiteral("columns"), columnResults);

    m_dataset2OutlierResult = resultMap;
    m_dataset2OutlierAvailable = true;

    if (m_dataset2QualityAvailable)
    {
        m_dataset2QualityResult.insert(QStringLiteral("outlierCount"), totalOutlierCount);
        m_dataset2QualityResult.insert(QStringLiteral("hasOutliers"), totalOutlierCount > 0);
        m_dataset2QualityResult.insert(QStringLiteral("outlierColumnCount"), affectedColumnCount);
        emit dataset2QualityChanged();
    }

    emit dataset2OutlierChanged();
    saveCurrentAnalysisSession();
    emit sessionAvailabilityChanged();

    return true;
}

// =========================================================
// IQR OUTLIER ANALYSIS
// =========================================================

bool AppController::analyzeDataset1Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();
    clearDataset1Outliers();

    const EdaOperationResult result =
        m_edaEngine.analyzeOutliers(
            m_dataset1,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(
            result.errorMessage.trimmed().isEmpty()
                ? tr("The selected column is not numeric. Statistical analysis can only be performed on numeric columns.")
                : result.errorMessage
            );
        return false;
    }

    m_dataset1OutlierResult = result.data;
    m_dataset1OutlierAvailable = true;

    emit dataset1OutlierChanged();

    return true;
}

bool AppController::analyzeDataset2Outliers(
    const QString &columnName,
    double multiplier
    )
{
    clearError();
    clearDataset2Outliers();

    const EdaOperationResult result =
        m_edaEngine.analyzeOutliers(
            m_dataset2,
            columnName,
            multiplier
            );

    if (!result.success)
    {
        setError(
            result.errorMessage.trimmed().isEmpty()
                ? tr("The selected column is not numeric. Statistical analysis can only be performed on numeric columns.")
                : result.errorMessage
            );
        return false;
    }

    m_dataset2OutlierResult = result.data;
    m_dataset2OutlierAvailable = true;

    emit dataset2OutlierChanged();

    return true;
}

void AppController::clearDataset1Outliers()
{
    const bool hadResult =
        m_dataset1OutlierAvailable ||
        !m_dataset1OutlierResult.isEmpty();

    m_dataset1OutlierResult.clear();
    m_dataset1OutlierAvailable = false;

    if (hadResult)
        emit dataset1OutlierChanged();
}

void AppController::clearDataset2Outliers()
{
    const bool hadResult =
        m_dataset2OutlierAvailable ||
        !m_dataset2OutlierResult.isEmpty();

    m_dataset2OutlierResult.clear();
    m_dataset2OutlierAvailable = false;

    if (hadResult)
        emit dataset2OutlierChanged();
}

// =========================================================
// RAW DATA
// =========================================================

bool AppController::loadRawMetadata(const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawParameterDefinitions.clear();
        m_rawMetadataLoaded = false;
        m_rawMetadataFilePath.clear();
        m_rawWarnings.clear();

        clearRawParse();

        setError(QStringLiteral("Raw metadata file path is empty."));
        emit rawMetadataChanged();

        return false;
    }

    QStringList errors;
    QStringList warnings;

    const QList<ParameterDefinition> definitions =
        m_rawMetadataParser.loadParameterDefinitions(
            normalizedPath,
            &errors,
            &warnings
            );

    if (!errors.isEmpty() || definitions.isEmpty())
    {
        m_rawParameterDefinitions.clear();
        m_rawMetadataLoaded = false;
        m_rawMetadataFilePath.clear();
        m_rawWarnings = warnings;

        clearRawParse();

        if (!errors.isEmpty())
            setError(errors.join(QStringLiteral("\n")));
        else
            setError(QStringLiteral("No valid raw parameter definitions were found."));

        emit rawMetadataChanged();
        return false;
    }

    m_rawParameterDefinitions = definitions;
    m_rawWarnings = warnings;
    m_rawMetadataFilePath = normalizedPath;
    m_rawMetadataLoaded = true;

    m_lastRawMetadataPath = normalizedPath;
    addRecentFile(normalizedPath, tr("Raw Metadata (Excel)"));
    recordActivity(tr("Raw Metadata Loaded"),
                   tr("%1 (%2 parameters)").arg(QFileInfo(normalizedPath).fileName()).arg(definitions.size()),
                   tr("Raw Data"));
    emit lastSessionChanged();
    saveSettings();

    clearRawParse();
    emit rawMetadataChanged();

    return true;
}

bool AppController::loadRawDataFile(const QString &filePath)
{
    clearError();

    const QString normalizedPath =
        normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_rawData.clear();
        m_rawDataLoaded = false;
        m_rawDataFilePath.clear();

        clearRawParse();

        setError(QStringLiteral("Raw data file path is empty."));
        emit rawDataChanged();

        return false;
    }

    FileRawDataSource source(normalizedPath);

    const RawDataSourceResult result =
        source.read();

    if (!result.success)
    {
        m_rawData.clear();
        m_rawDataLoaded = false;
        m_rawDataFilePath.clear();

        clearRawParse();

        setError(result.errorMessage);
        emit rawDataChanged();

        return false;
    }

    m_rawData = result.data;
    m_rawDataFilePath = normalizedPath;
    m_rawDataLoaded = true;

    m_lastRawDataPath = normalizedPath;
    addRecentFile(normalizedPath, tr("Raw Data File (.bin)"));
    recordActivity(tr("Raw Data File Loaded"),
                   tr("%1 (%2 KB)").arg(QFileInfo(normalizedPath).fileName()).arg(m_rawData.size() / 1024),
                   tr("Raw Data"));
    emit lastSessionChanged();
    saveSettings();

    clearRawParse();
    emit rawDataChanged();

    return true;
}

bool AppController::parseRawData()
{
    if (m_rawParsing)
    {
        setError(QStringLiteral("Raw data parsing is already in progress."));
        return false;
    }

    clearError();
    clearRawParse();

    if (!m_rawMetadataLoaded ||
        m_rawParameterDefinitions.isEmpty())
    {
        setError(QStringLiteral("Raw metadata is not loaded."));
        return false;
    }

    if (!m_rawDataLoaded ||
        m_rawData.isEmpty())
    {
        setError(QStringLiteral("Raw data is not loaded."));
        return false;
    }

    const int packetSize =
        m_rawDataParser.calculateRequiredPacketSize(
            m_rawParameterDefinitions
            );

    if (packetSize <= 0)
    {
        setError(
            QStringLiteral(
                "Packet size could not be calculated from raw metadata."
                )
            );
        return false;
    }

    if (m_rawData.size() < packetSize)
    {
        setError(
            QStringLiteral(
                "Raw data is smaller than the required packet size."
                )
            );
        return false;
    }

    m_rawParsing = true;
    m_rawParseProgress = 0;
    emit rawParsingChanged();
    emit rawParseProgressChanged();

    m_rawParserThread = new QThread();
    m_rawParserWorker = new RawParserWorker(m_rawData, m_rawParameterDefinitions);
    m_rawParserWorker->moveToThread(m_rawParserThread.data());

    connect(m_rawParserWorker.data(), &RawParserWorker::progressChanged, this, &AppController::onRawParseProgress);
    connect(m_rawParserWorker.data(), &RawParserWorker::finished, this, &AppController::onRawParseFinished);
    connect(m_rawParserWorker.data(), &RawParserWorker::failed, this, &AppController::onRawParseFailed);
    connect(m_rawParserWorker.data(), &RawParserWorker::cancelled, this, &AppController::onRawParseCancelled);

    connect(m_rawParserThread.data(), &QThread::started, m_rawParserWorker.data(), &RawParserWorker::startParsing);

    connect(m_rawParserWorker.data(), &RawParserWorker::finished, m_rawParserThread.data(), &QThread::quit);
    connect(m_rawParserWorker.data(), &RawParserWorker::failed, m_rawParserThread.data(), &QThread::quit);
    connect(m_rawParserWorker.data(), &RawParserWorker::cancelled, m_rawParserThread.data(), &QThread::quit);

    connect(m_rawParserThread.data(), &QThread::finished, m_rawParserWorker.data(), &QObject::deleteLater);
    connect(m_rawParserThread.data(), &QThread::finished, m_rawParserThread.data(), &QObject::deleteLater);

    m_rawParserThread->start();
    return true;
}

void AppController::cancelRawParsing()
{
    if (m_rawParserWorker && m_rawParsing)
    {
        m_rawParserWorker->cancel();
    }
}

void AppController::onRawParseProgress(int percent)
{
    m_rawParseProgress = percent;
    emit rawParseProgressChanged();
}

void AppController::onRawParseFinished(
    const QList<QList<ParsedParameter>> &parsedPackets,
    int ignoredByteCount,
    bool hasErrorParameter,
    bool hasSuccessfulParameter
    )
{
    m_rawParsing = false;
    m_rawParseProgress = 100;

    m_cachedParsedRawPackets = parsedPackets;

    // Build preview for ParameterModel
    QList<ParsedParameter> previewParams;
    const int previewLimit = 200;
    int count = 0;
    for (const QList<ParsedParameter> &packet : parsedPackets)
    {
        for (const ParsedParameter &param : packet)
        {
            previewParams.append(param);
            if (++count >= previewLimit)
                break;
        }
        if (count >= previewLimit)
            break;
    }

    if (!hasSuccessfulParameter)
    {
        m_parameterModel.clear();
        m_rawParseAvailable = false;

        setError(
            QStringLiteral(
                "None of the raw parameters could be parsed successfully."
                )
            );

        emit rawParseChanged();
        emit rawParsingChanged();
        emit rawParseProgressChanged();
        emit rawParseCompleted(false, lastError());
        return;
    }

    m_parameterModel.setParameters(previewParams);

    m_rawParseAvailable = true;
    recordActivity(tr("Raw Data Parsed"),
                   tr("%1 packet(s) successfully processed").arg(parsedPackets.size()),
                   tr("Raw Data"));

    emit rawParseChanged();
    emit rawParsingChanged();
    emit rawParseProgressChanged();

    if (hasErrorParameter && ignoredByteCount > 0)
    {
        setError(
            QStringLiteral(
                "Raw data was parsed into %1 packets, but one or more "
                "parameters contain errors and %2 trailing byte(s) were ignored."
                )
                .arg(parsedPackets.size())
                .arg(ignoredByteCount)
            );
    }
    else if (hasErrorParameter)
    {
        setError(
            QStringLiteral(
                "Raw data was parsed into %1 packets, but one or more "
                "parameters contain errors."
                )
                .arg(parsedPackets.size())
            );
    }
    else if (ignoredByteCount > 0)
    {
        setError(
            QStringLiteral(
                "Raw data was parsed into %1 packets. "
                "%2 trailing byte(s) were ignored because they do not "
                "form a complete packet."
                )
                .arg(parsedPackets.size())
                .arg(ignoredByteCount)
            );
    }

    emit rawParseCompleted(true, tr("%1 packet(s) parsed successfully.").arg(parsedPackets.size()));
}

void AppController::onRawParseFailed(const QString &errorMessage)
{
    m_rawParsing = false;
    m_rawParseProgress = 0;
    m_rawParseAvailable = false;
    m_parameterModel.clear();
    setError(errorMessage);

    emit rawParsingChanged();
    emit rawParseProgressChanged();
    emit rawParseChanged();
    emit rawParseCompleted(false, errorMessage);
}

void AppController::onRawParseCancelled()
{
    m_rawParsing = false;
    m_rawParseProgress = 0;
    m_rawParseAvailable = false;
    setError(QStringLiteral("Raw data parsing was cancelled."));

    emit rawParsingChanged();
    emit rawParseProgressChanged();
    emit rawParseChanged();
    emit rawParseCompleted(false, QStringLiteral("Parsing cancelled."));
}

bool AppController::importParsedRawDataAsDataset(
    int datasetIndex,
    const QString &customName
    )
{
    clearError();

    if (!m_rawParseAvailable || m_cachedParsedRawPackets.isEmpty())
    {
        setError(
            QStringLiteral(
                "Ayrıştırılmış ham veri bulunmuyor. "
                "Önce 'Parse Raw Data' çalıştırın."
                )
            );
        return false;
    }

    if (!m_rawMetadataLoaded ||
        m_rawParameterDefinitions.isEmpty())
    {
        setError(QStringLiteral("Raw metadata is not loaded."));
        return false;
    }

    if (!m_rawDataLoaded ||
        m_rawData.isEmpty())
    {
        setError(QStringLiteral("Raw data is not loaded."));
        return false;
    }

    if (datasetIndex != 1 &&
        datasetIndex != 2)
    {
        setError(QStringLiteral("Dataset index must be 1 or 2."));
        return false;
    }

    const QList<QList<ParsedParameter>> &parsedPackets = m_cachedParsedRawPackets;

    const QList<ParsedParameter> &firstPacket =
        parsedPackets.first();

    DataSet importedDataset;

    const QString defaultName =
        customName.trimmed().isEmpty()
            ? (datasetIndex == 1
                   ? QStringLiteral("Parsed_Raw_Packet_1")
                   : QStringLiteral("Parsed_Raw_Packet_2"))
            : customName.trimmed();

    importedDataset.setName(defaultName);
    importedDataset.setFilePath(m_rawDataFilePath);
    importedDataset.setSheetName(QStringLiteral("RawPackets"));

    QVector<ColumnInfo> columns;
    columns.reserve(firstPacket.size());

    for (int paramIndex = 0;
         paramIndex < firstPacket.size();
         ++paramIndex)
    {
        const ParsedParameter &firstParam =
            firstPacket.at(paramIndex);

        ColumnInfo column(firstParam.dataName);
        column.setOriginalName(firstParam.dataName);

        ColumnInfo::DataType colType = ColumnInfo::DataType::Double;
        if (firstParam.dataType.contains(QLatin1String("Int"), Qt::CaseInsensitive))
        {
            colType = ColumnInfo::DataType::Integer;
        }
        else if (firstParam.dataType.contains(QLatin1String("Bool"), Qt::CaseInsensitive))
        {
            colType = ColumnInfo::DataType::Boolean;
        }
        column.setDataType(colType);

        QVector<QVariant> values;
        values.reserve(parsedPackets.size());

        for (const QList<ParsedParameter> &packet : parsedPackets)
        {
            if (paramIndex < packet.size())
            {
                const ParsedParameter &param = packet.at(paramIndex);
                values.append(param.value);
            }
            else
            {
                values.append(QVariant());
            }
        }

        column.setValues(values);
        columns.append(column);
    }

    importedDataset.setColumns(columns);

    if (datasetIndex == 1)
    {
        m_dataset1 = importedDataset;
        m_originalDataset1 = importedDataset;
        m_dataset1Modified = false;

        m_dataset1ColumnModel.setColumns(
            m_dataset1.columns()
            );

        clearDataset1OutlierCleaning();
        clearDataset1Eda();
        clearDataset1Correlation();
        clearAnalysis();

        analyzeDataset1Quality();

        emit dataset1Changed();
    }
    else
    {
        m_dataset2 = importedDataset;
        m_originalDataset2 = importedDataset;
        m_dataset2Modified = false;

        m_dataset2ColumnModel.setColumns(
            m_dataset2.columns()
            );

        clearDataset2OutlierCleaning();
        clearDataset2Eda();
        clearDataset2Correlation();
        clearAnalysis();

        analyzeDataset2Quality();

        emit dataset2Changed();
    }

    tryGenerateMappings();

    recordActivity(tr("Raw Data Imported"),
                   tr("Dataset %1: %2 rows, %3 columns").arg(datasetIndex).arg(importedDataset.rowCount()).arg(importedDataset.columnCount()),
                   tr("Raw Data"));

    return true;
}

bool AppController::applyBulkMissingCleaning(
    int datasetIndex,
    const QString &action,
    const QStringList &columns,
    const QVariantList &numericFlags
    )
{
    CleaningTask task;
    task.operation = CleaningTask::BulkMissing;
    task.datasetIndex = datasetIndex;
    task.bulkAction = action;
    task.targetColumns = columns;
    for (const QVariant &flag : numericFlags)
    {
        task.numericFlags.append(flag.toBool());
    }
    return startCleaningTask(task);
}

bool AppController::applyBulkOutlierCleaning(
    int datasetIndex,
    const QString &method,
    const QString &action,
    double parameter,
    const QStringList &columns
    )
{
    CleaningTask task;
    task.operation = CleaningTask::BulkOutliers;
    task.datasetIndex = datasetIndex;
    task.method = method;
    task.action = action;
    task.parameter = parameter;
    task.targetColumns = columns;
    return startCleaningTask(task);
}

bool AppController::startCleaningTask(const CleaningTask &task)
{
    if (m_cleaningBusy)
    {
        setError(QStringLiteral("Another cleaning task is currently running."));
        return false;
    }

    const DataSet &sourceDataSet = (task.datasetIndex == 1 ? m_dataset1 : m_dataset2);
    if (sourceDataSet.isEmpty())
    {
        setError(QStringLiteral("Dataset is empty."));
        return false;
    }

    clearError();
    m_currentCleaningTask = task;
    m_cleaningBusy = true;
    m_cleaningProgress = 0;
    m_cleaningStatusText = QStringLiteral("Cleaning in progress...");
    emit cleaningBusyChanged();
    emit cleaningProgressChanged();
    emit cleaningStatusTextChanged();

    m_cleaningThread = new QThread();
    m_cleaningWorker = new CleaningWorker(sourceDataSet, task);
    m_cleaningWorker->moveToThread(m_cleaningThread.data());

    connect(m_cleaningWorker.data(), &CleaningWorker::progressChanged, this, &AppController::onCleaningProgress);
    connect(m_cleaningWorker.data(), &CleaningWorker::finished, this, &AppController::onCleaningFinished);
    connect(m_cleaningWorker.data(), &CleaningWorker::failed, this, &AppController::onCleaningFailed);
    connect(m_cleaningWorker.data(), &CleaningWorker::cancelled, this, &AppController::onCleaningCancelled);

    connect(m_cleaningThread.data(), &QThread::started, m_cleaningWorker.data(), &CleaningWorker::startCleaning);

    connect(m_cleaningWorker.data(), &CleaningWorker::finished, m_cleaningThread.data(), &QThread::quit);
    connect(m_cleaningWorker.data(), &CleaningWorker::failed, m_cleaningThread.data(), &QThread::quit);
    connect(m_cleaningWorker.data(), &CleaningWorker::cancelled, m_cleaningThread.data(), &QThread::quit);

    connect(m_cleaningThread.data(), &QThread::finished, m_cleaningWorker.data(), &QObject::deleteLater);
    connect(m_cleaningThread.data(), &QThread::finished, m_cleaningThread.data(), &QObject::deleteLater);

    m_cleaningThread->start();
    return true;
}

void AppController::cancelCleaning()
{
    if (m_cleaningWorker && m_cleaningBusy)
    {
        m_cleaningWorker->cancel();
    }
}

void AppController::onCleaningProgress(int current, int total)
{
    if (total > 0)
    {
        m_cleaningProgress = (current * 100) / total;
        emit cleaningProgressChanged();
    }
}

void AppController::onCleaningFinished(
    const DataSet &cleanedDataSet,
    const CleaningResult &result,
    int datasetIndex,
    const QString &actionDescription
    )
{
    m_cleaningBusy = false;
    m_cleaningProgress = 100;
    m_cleaningStatusText = actionDescription;

    if (datasetIndex == 1)
    {
        switch (m_currentCleaningTask.operation)
        {
        case CleaningTask::RemoveMissingRows:
        case CleaningTask::FillMissingMean:
        case CleaningTask::FillMissingMedian:
        case CleaningTask::FillMissingMode:
            for (int i = m_dataset1MissingTasks.size() - 1; i >= 0; --i)
            {
                if (m_dataset1MissingTasks[i].columnName == m_currentCleaningTask.columnName &&
                    !m_currentCleaningTask.columnName.isEmpty())
                {
                    m_dataset1MissingTasks.removeAt(i);
                }
            }
            m_dataset1MissingTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::BulkMissing:
            m_dataset1MissingTasks.clear();
            m_dataset1MissingTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::ApplyOutlierAction:
            for (int i = m_dataset1OutlierTasks.size() - 1; i >= 0; --i)
            {
                if (m_dataset1OutlierTasks[i].columnName == m_currentCleaningTask.columnName &&
                    !m_currentCleaningTask.columnName.isEmpty())
                {
                    m_dataset1OutlierTasks.removeAt(i);
                }
            }
            m_dataset1OutlierTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::BulkOutliers:
            m_dataset1OutlierTasks.clear();
            m_dataset1OutlierTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::RemoveDuplicates:
        case CleaningTask::RemoveColumn:
            m_dataset1OtherTasks.append(m_currentCleaningTask);
            break;
        }

        m_dataset1 = cleanedDataSet;
        m_dataset1Modified = true;
        m_dataset1ColumnModel.setColumns(m_dataset1.columns());
        if (m_currentCleaningTask.operation == CleaningTask::ApplyOutlierAction ||
            m_currentCleaningTask.operation == CleaningTask::BulkOutliers)
        {
            m_dataset1OutlierCleaningResult = result.details;
        }

        clearDataset1Eda();
        clearDataset1Correlation();
        clearAnalysis();

        analyzeDataset1Quality();

        emit dataset1Changed();
        emit dataset1OutlierCleaningChanged();
        emit dataset1CleaningStateChanged();
    }
    else
    {
        switch (m_currentCleaningTask.operation)
        {
        case CleaningTask::RemoveMissingRows:
        case CleaningTask::FillMissingMean:
        case CleaningTask::FillMissingMedian:
        case CleaningTask::FillMissingMode:
            for (int i = m_dataset2MissingTasks.size() - 1; i >= 0; --i)
            {
                if (m_dataset2MissingTasks[i].columnName == m_currentCleaningTask.columnName &&
                    !m_currentCleaningTask.columnName.isEmpty())
                {
                    m_dataset2MissingTasks.removeAt(i);
                }
            }
            m_dataset2MissingTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::BulkMissing:
            m_dataset2MissingTasks.clear();
            m_dataset2MissingTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::ApplyOutlierAction:
            for (int i = m_dataset2OutlierTasks.size() - 1; i >= 0; --i)
            {
                if (m_dataset2OutlierTasks[i].columnName == m_currentCleaningTask.columnName &&
                    !m_currentCleaningTask.columnName.isEmpty())
                {
                    m_dataset2OutlierTasks.removeAt(i);
                }
            }
            m_dataset2OutlierTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::BulkOutliers:
            m_dataset2OutlierTasks.clear();
            m_dataset2OutlierTasks.append(m_currentCleaningTask);
            break;

        case CleaningTask::RemoveDuplicates:
        case CleaningTask::RemoveColumn:
            m_dataset2OtherTasks.append(m_currentCleaningTask);
            break;
        }

        m_dataset2 = cleanedDataSet;
        m_dataset2Modified = true;
        m_dataset2ColumnModel.setColumns(m_dataset2.columns());
        if (m_currentCleaningTask.operation == CleaningTask::ApplyOutlierAction ||
            m_currentCleaningTask.operation == CleaningTask::BulkOutliers)
        {
            m_dataset2OutlierCleaningResult = result.details;
        }

        clearDataset2Eda();
        clearDataset2Correlation();
        clearAnalysis();

        analyzeDataset2Quality();

        emit dataset2Changed();
        emit dataset2OutlierCleaningChanged();
        emit dataset2CleaningStateChanged();
    }

    tryGenerateMappings();
    recordActivity(
        tr("Dataset %1 Cleaned").arg(datasetIndex),
        actionDescription,
        tr("Cleaning")
    );

    saveCurrentCleaningSession();
    emit sessionAvailabilityChanged();

    emit cleaningBusyChanged();
    emit cleaningProgressChanged();
    emit cleaningStatusTextChanged();
    emit cleaningCompletedSignal(true, actionDescription);
}

void AppController::onCleaningFailed(const QString &errorMessage, int datasetIndex)
{
    Q_UNUSED(datasetIndex);
    m_cleaningBusy = false;
    m_cleaningProgress = 0;
    m_cleaningStatusText = QStringLiteral("Cleaning failed.");

    setError(errorMessage);

    emit cleaningBusyChanged();
    emit cleaningProgressChanged();
    emit cleaningStatusTextChanged();
    emit cleaningCompletedSignal(false, errorMessage);
}

void AppController::onCleaningCancelled(int datasetIndex)
{
    Q_UNUSED(datasetIndex);
    m_cleaningBusy = false;
    m_cleaningProgress = 0;
    m_cleaningStatusText = QStringLiteral("Cleaning cancelled.");

    setError(QStringLiteral("Cleaning operation was cancelled."));

    emit cleaningBusyChanged();
    emit cleaningProgressChanged();
    emit cleaningStatusTextChanged();
    emit cleaningCompletedSignal(false, QStringLiteral("Cleaning cancelled."));
}

void AppController::clearRawMetadata()
{
    const bool hadData =
        m_rawMetadataLoaded ||
        !m_rawParameterDefinitions.isEmpty() ||
        !m_rawMetadataFilePath.isEmpty() ||
        !m_rawWarnings.isEmpty();

    m_rawParameterDefinitions.clear();
    m_rawMetadataFilePath.clear();
    m_rawWarnings.clear();
    m_rawMetadataLoaded = false;

    clearRawParse();

    if (hadData)
        emit rawMetadataChanged();
}

void AppController::clearRawData()
{
    const bool hadData =
        m_rawDataLoaded ||
        !m_rawData.isEmpty() ||
        !m_rawDataFilePath.isEmpty();

    m_rawData.clear();
    m_rawDataFilePath.clear();
    m_rawDataLoaded = false;

    clearRawParse();

    if (hadData)
        emit rawDataChanged();
}

void AppController::clearRawParse()
{
    m_cachedParsedRawPackets.clear();
    m_rawParseProgress = 0;
    const bool hadResults =
        m_rawParseAvailable ||
        !m_parameterModel.isEmpty();

    m_parameterModel.clear();
    m_rawParseAvailable = false;

    if (hadResults)
        emit rawParseChanged();
}

// =========================================================
// HELPERS
// =========================================================

QVariantMap AppController::histogramToVariantMap(
    const HistogramResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("binCount"), result.binCount);
    map.insert(QStringLiteral("minimum"), result.minimum);
    map.insert(QStringLiteral("maximum"), result.maximum);
    map.insert(QStringLiteral("binWidth"), result.binWidth);

    QVariantList lowerBounds;
    QVariantList upperBounds;
    QVariantList frequencies;

    for (double value : result.binLowerBounds)
        lowerBounds.append(value);

    for (double value : result.binUpperBounds)
        upperBounds.append(value);

    for (int value : result.frequencies)
        frequencies.append(value);

    map.insert(QStringLiteral("binLowerBounds"), lowerBounds);
    map.insert(QStringLiteral("binUpperBounds"), upperBounds);
    map.insert(QStringLiteral("frequencies"), frequencies);

    return map;
}

QVariantMap AppController::boxPlotToVariantMap(
    const BoxPlotResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("minimum"), result.minimum);
    map.insert(QStringLiteral("q1"), result.q1);
    map.insert(QStringLiteral("median"), result.median);
    map.insert(QStringLiteral("q3"), result.q3);
    map.insert(QStringLiteral("maximum"), result.maximum);
    map.insert(QStringLiteral("iqr"), result.iqr);
    map.insert(QStringLiteral("lowerBound"), result.lowerBound);
    map.insert(QStringLiteral("upperBound"), result.upperBound);
    map.insert(QStringLiteral("lowerWhisker"), result.lowerWhisker);
    map.insert(QStringLiteral("upperWhisker"), result.upperWhisker);
    map.insert(QStringLiteral("outlierCount"), result.outlierCount);

    QVariantList outliers;

    for (double value : result.outlierValues)
        outliers.append(value);

    map.insert(QStringLiteral("outlierValues"), outliers);

    return map;
}

QVariantMap AppController::timeSeriesToVariantMap(
    const TimeSeriesResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("xColumnName"), result.xColumnName);
    map.insert(QStringLiteral("yColumnName"), result.yColumnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("pointCount"), result.pointCount);

    QVariantList xValues;
    QVariantList yValues;

    for (double value : result.xValues)
        xValues.append(value);

    for (double value : result.yValues)
        yValues.append(value);

    map.insert(QStringLiteral("xValues"), xValues);
    map.insert(QStringLiteral("yValues"), yValues);

    return map;
}

QVariantMap AppController::distributionToVariantMap(
    const DistributionResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("columnName"), result.columnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("validValueCount"), result.validValueCount);
    map.insert(QStringLiteral("binCount"), result.binCount);

    QVariantList centers;
    QVariantList relativeFrequencies;

    for (double value : result.centers)
        centers.append(value);

    for (double value : result.relativeFrequencies)
        relativeFrequencies.append(value);

    map.insert(QStringLiteral("centers"), centers);
    map.insert(QStringLiteral("relativeFrequencies"), relativeFrequencies);

    return map;
}

QVariantMap AppController::correlationMatrixToVariantMap(
    const CorrelationMatrixResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("columnCount"), result.columnCount);
    map.insert(QStringLiteral("columnNames"), result.columnNames);

    QVariantList values;

    for (double value : result.values)
        values.append(value);

    map.insert(QStringLiteral("values"), values);

    return map;
}

QVariantMap AppController::comparisonChartToVariantMap(
    const ComparisonChartResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("sourceColumnName"), result.sourceColumnName);
    map.insert(QStringLiteral("targetColumnName"), result.targetColumnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("pointCount"), result.pointCount);

    QVariantList indexes;
    QVariantList sourceValues;
    QVariantList targetValues;

    for (double value : result.indexes)
        indexes.append(value);

    for (double value : result.sourceValues)
        sourceValues.append(value);

    for (double value : result.targetValues)
        targetValues.append(value);

    map.insert(QStringLiteral("indexes"), indexes);
    map.insert(QStringLiteral("sourceValues"), sourceValues);
    map.insert(QStringLiteral("targetValues"), targetValues);

    return map;
}

QVariantMap AppController::comparisonDistributionToVariantMap(
    const ComparisonDistributionResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("sourceColumnName"), result.sourceColumnName);
    map.insert(QStringLiteral("targetColumnName"), result.targetColumnName);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);
    map.insert(QStringLiteral("sourceValidCount"), result.sourceValidCount);
    map.insert(QStringLiteral("targetValidCount"), result.targetValidCount);
    map.insert(QStringLiteral("binCount"), result.binCount);
    map.insert(QStringLiteral("minimum"), result.minimum);
    map.insert(QStringLiteral("maximum"), result.maximum);
    map.insert(QStringLiteral("binWidth"), result.binWidth);

    QVariantList centers;
    QVariantList sourceDensities;
    QVariantList targetDensities;
    QVariantList sourceFrequencies;
    QVariantList targetFrequencies;

    for (double v : result.centers) centers.append(v);
    for (double v : result.sourceDensities) sourceDensities.append(v);
    for (double v : result.targetDensities) targetDensities.append(v);
    for (double v : result.sourceFrequencies) sourceFrequencies.append(v);
    for (double v : result.targetFrequencies) targetFrequencies.append(v);

    map.insert(QStringLiteral("centers"), centers);
    map.insert(QStringLiteral("sourceDensities"), sourceDensities);
    map.insert(QStringLiteral("targetDensities"), targetDensities);
    map.insert(QStringLiteral("sourceFrequencies"), sourceFrequencies);
    map.insert(QStringLiteral("targetFrequencies"), targetFrequencies);

    return map;
}

QVariantMap AppController::barChartToVariantMap(
    const BarChartResult &result
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("success"), result.success);
    map.insert(QStringLiteral("categoryColumnName"), result.categoryColumnName);
    map.insert(QStringLiteral("valueColumnName"), result.valueColumnName);
    map.insert(QStringLiteral("aggregation"), result.aggregation);
    map.insert(QStringLiteral("categoryCount"), result.categoryCount);
    map.insert(QStringLiteral("labels"), result.labels);
    map.insert(QStringLiteral("errorMessage"), result.errorMessage);

    QVariantList valuesList;
    for (double val : result.values)
    {
        valuesList.append(val);
    }
    map.insert(QStringLiteral("values"), valuesList);

    return map;
}

QString AppController::normalizeFilePath(
    const QString &filePath
    ) const
{
    if (filePath.trimmed().isEmpty())
        return QString();

    const QUrl url(filePath);

    if (url.isLocalFile())
        return url.toLocalFile();

    return filePath;
}

void AppController::tryGenerateMappings()
{
    if (m_dataset1.isEmpty() ||
        m_dataset2.isEmpty())
    {
        m_mappingModel.clear();
        emit mappingsChanged();
        return;
    }

    generateMappings();
}

void AppController::setError(
    const QString &message
    )
{
    if (m_lastError == message)
        return;

    m_lastError = message;
    emit errorChanged();
}

void AppController::clearError()
{
    if (m_lastError.isEmpty())
        return;

    m_lastError.clear();
    emit errorChanged();
}

QVariantMap AppController::statisticsToVariantMap(
    const StatisticsResult &statistics
    ) const
{
    QVariantMap map;

    map.insert(QStringLiteral("count"), statistics.count);
    map.insert(QStringLiteral("mean"), statistics.mean);
    map.insert(QStringLiteral("median"), statistics.median);
    map.insert(QStringLiteral("minimum"), statistics.minimum);
    map.insert(QStringLiteral("maximum"), statistics.maximum);
    map.insert(QStringLiteral("range"), statistics.range);
    map.insert(QStringLiteral("variance"), statistics.variance);

    map.insert(
        QStringLiteral("standardDeviation"),
        statistics.standardDeviation
        );

    map.insert(QStringLiteral("q1"), statistics.q1);
    map.insert(QStringLiteral("q3"), statistics.q3);
    map.insert(QStringLiteral("iqr"), statistics.iqr);

    return map;
}