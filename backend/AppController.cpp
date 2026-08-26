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
#include <cmath>

#include "../raw/FileRawDataSource.h"

AppController::AppController(QObject *parent)
    : QObject(parent),
    m_dataset1ColumnModel(this),
    m_dataset2ColumnModel(this),
    m_mappingModel(this),
    m_parameterModel(this)
{
    loadSettings();

    if (m_autoRestoreEnabled)
    {
        restoreLastSession();
    }
}

// =========================================================
// GETTERS
// =========================================================

QString AppController::dataset1Name() const { return m_dataset1.name(); }
QString AppController::dataset2Name() const { return m_dataset2.name(); }
QString AppController::dataDirectory() const
{
    // 1. Direct project path check
    const QString knownProjectPath = QStringLiteral("C:/Users/aybuk/Desktop/GenericDataAnalyzer/data");
    if (QDir(knownProjectPath).exists())
    {
        return QDir(knownProjectPath).absolutePath();
    }

    // 2. Search relative candidates
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
    return (!m_lastDataset1Path.isEmpty() && QFileInfo::exists(m_lastDataset1Path)) ||
           (!m_lastDataset2Path.isEmpty() && QFileInfo::exists(m_lastDataset2Path));
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
    QSettings settings;

    m_lastDataset1Path = settings.value(QStringLiteral("session/lastDataset1Path")).toString();
    m_lastDataset2Path = settings.value(QStringLiteral("session/lastDataset2Path")).toString();
    m_lastRawMetadataPath = settings.value(QStringLiteral("session/lastRawMetadataPath")).toString();
    m_lastRawDataPath = settings.value(QStringLiteral("session/lastRawDataPath")).toString();
    m_autoRestoreEnabled = settings.value(QStringLiteral("session/autoRestoreEnabled"), true).toBool();

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

bool AppController::restoreLastSession()
{
    bool restoredAny = false;

    if (!m_lastDataset1Path.isEmpty() && QFileInfo::exists(m_lastDataset1Path))
    {
        if (loadDataset1(m_lastDataset1Path))
        {
            restoredAny = true;
        }
    }

    if (!m_lastDataset2Path.isEmpty() && QFileInfo::exists(m_lastDataset2Path))
    {
        if (loadDataset2(m_lastDataset2Path))
        {
            restoredAny = true;
        }
    }

    if (!m_lastRawMetadataPath.isEmpty() && QFileInfo::exists(m_lastRawMetadataPath))
    {
        loadRawMetadata(m_lastRawMetadataPath);
    }

    if (!m_lastRawDataPath.isEmpty() && QFileInfo::exists(m_lastRawDataPath))
    {
        loadRawDataFile(m_lastRawDataPath);
    }

    emit lastSessionChanged();
    return restoredAny;
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
    clearError();

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset1.clear();
        m_originalDataset1.clear();
        m_dataset1Modified = false;
        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(QStringLiteral("Dataset 1 file path is empty."));

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser1.loadFile(normalizedPath))
    {
        m_dataset1.clear();
        m_originalDataset1.clear();
        m_dataset1Modified = false;
        m_dataset1ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(m_parser1.lastError());

        emit dataset1Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset1 = m_parser1.dataSet();
    m_originalDataset1 = m_dataset1;
    m_dataset1Modified = false;

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    analyzeDataset1Quality();

    m_lastDataset1Path = normalizedPath;
    addRecentFile(normalizedPath, QStringLiteral("Dataset 1 (Excel/CSV)"), m_dataset1.rowCount(), m_dataset1.columnCount());
    recordActivity(QStringLiteral("Veri Seti 1 Yüklendi"),
                   QStringLiteral("%1 (%2 satır, %3 sütun)").arg(m_dataset1.name()).arg(m_dataset1.rowCount()).arg(m_dataset1.columnCount()),
                   QStringLiteral("Yükleme"));
    emit lastSessionChanged();
    saveSettings();

    emit dataset1Changed();

    clearAnalysis();
    tryGenerateMappings();

    return true;
}

bool AppController::loadDataset2(const QString &filePath)
{
    clearError();

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();

    const QString normalizedPath = normalizeFilePath(filePath);

    if (normalizedPath.trimmed().isEmpty())
    {
        m_dataset2.clear();
        m_originalDataset2.clear();
        m_dataset2Modified = false;
        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(QStringLiteral("Dataset 2 file path is empty."));

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    if (!m_parser2.loadFile(normalizedPath))
    {
        m_dataset2.clear();
        m_originalDataset2.clear();
        m_dataset2Modified = false;
        m_dataset2ColumnModel.clear();
        m_mappingModel.clear();
        clearAnalysis();

        setError(m_parser2.lastError());

        emit dataset2Changed();
        emit mappingsChanged();

        return false;
    }

    m_dataset2 = m_parser2.dataSet();
    m_originalDataset2 = m_dataset2;
    m_dataset2Modified = false;

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    analyzeDataset2Quality();

    m_lastDataset2Path = normalizedPath;
    addRecentFile(normalizedPath, QStringLiteral("Dataset 2 (Excel/CSV)"), m_dataset2.rowCount(), m_dataset2.columnCount());
    recordActivity(QStringLiteral("Veri Seti 2 Yüklendi"),
                   QStringLiteral("%1 (%2 satır, %3 sütun)").arg(m_dataset2.name()).arg(m_dataset2.rowCount()).arg(m_dataset2.columnCount()),
                   QStringLiteral("Yükleme"));
    emit lastSessionChanged();
    saveSettings();

    emit dataset2Changed();

    clearAnalysis();
    tryGenerateMappings();

    return true;
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

    m_dataset1ColumnModel.setColumns(m_dataset1.columns());

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();
    recordActivity(QStringLiteral("Dataset 1 Sıfırlandı"), QStringLiteral("Orijinal veriye geri dönüldü"), QStringLiteral("Temizleme"));

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

    m_dataset2ColumnModel.setColumns(m_dataset2.columns());

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();
    recordActivity(QStringLiteral("Dataset 2 Sıfırlandı"), QStringLiteral("Orijinal veriye geri dönüldü"), QStringLiteral("Temizleme"));

    return true;
}

// =========================================================
// CLEANING
// =========================================================

bool AppController::removeDataset1Duplicates()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeDuplicateRows(
            m_dataset1
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2Duplicates()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeDuplicateRows(
            m_dataset2
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset1MissingRows()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeRowsWithMissingValues(
            m_dataset1
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::removeDataset2MissingRows()
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.removeRowsWithMissingValues(
            m_dataset2
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMean(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMean(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMean(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMedian(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMedian(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMedian(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset1MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMode(
            m_dataset1,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1Modified = true;

    m_dataset1ColumnModel.setColumns(
        m_dataset1.columns()
        );

    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1OutlierCleaning();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();

    emit dataset1Changed();

    tryGenerateMappings();

    return true;
}

bool AppController::fillDataset2MissingWithMode(
    const QString &columnName
    )
{
    clearError();

    const CleaningResult result =
        m_cleaningEngine.fillMissingWithMode(
            m_dataset2,
            columnName
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2Modified = true;

    m_dataset2ColumnModel.setColumns(
        m_dataset2.columns()
        );

    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2OutlierCleaning();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();

    emit dataset2Changed();

    tryGenerateMappings();

    return true;
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
    clearError();
    clearDataset1OutlierCleaning();

    const CleaningResult result =
        m_cleaningEngine.applyOutlierAction(
            m_dataset1,
            columnName,
            method,
            action,
            parameter
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset1OutlierCleaningResult =
        result.details;

    if (result.modified)
    {
        m_dataset1Modified = true;

        m_dataset1ColumnModel.setColumns(
            m_dataset1.columns()
            );

        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1Eda();
        clearDataset1Correlation();
        clearAnalysis();

        emit dataset1Changed();

        tryGenerateMappings();
    }

    emit dataset1OutlierCleaningChanged();

    return true;
}

bool AppController::applyDataset2OutlierAction(
    const QString &columnName,
    const QString &method,
    const QString &action,
    double parameter
    )
{
    clearError();
    clearDataset2OutlierCleaning();

    const CleaningResult result =
        m_cleaningEngine.applyOutlierAction(
            m_dataset2,
            columnName,
            method,
            action,
            parameter
            );

    if (!result.success)
    {
        setError(
            result.errorMessage
            );

        return false;
    }

    m_dataset2OutlierCleaningResult =
        result.details;

    if (result.modified)
    {
        m_dataset2Modified = true;

        m_dataset2ColumnModel.setColumns(
            m_dataset2.columns()
            );

        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2Eda();
        clearDataset2Correlation();
        clearAnalysis();

        emit dataset2Changed();

        tryGenerateMappings();
    }

    emit dataset2OutlierCleaningChanged();

    return true;
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
        setError(QStringLiteral("Dataset 1 yüklü değil."));
        return false;
    }

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 yüklü değil."));
        return false;
    }

    if (mappings.isEmpty())
    {
        setError(QStringLiteral("En az bir geçerli sütun eşleştirmesi seçilmelidir."));
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
        setError(QStringLiteral("Geçerli sütun eşleştirmesi bulunamadı."));
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

    recordActivity(QStringLiteral("Veri Seti Karşılaştırması"),
                   QStringLiteral("%1 eşleştirilmiş sütun, %2 satır karşılaştırıldı").arg(matchedColumnCount).arg(totalComparedRecords),
                   QStringLiteral("Karşılaştırma"));

    emit datasetComparisonChanged();
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
                ? QStringLiteral(
                      "Bu sütun sayısal değil. "
                      "İstatistiksel analiz için sayısal bir sütun seçin."
                      )
                : result.errorMessage
            );
        return false;
    }

    m_dataset1EdaResult = result.data;
    m_dataset1EdaAvailable = true;

    emit dataset1EdaChanged();

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
                ? QStringLiteral(
                      "Bu sütun sayısal değil. "
                      "İstatistiksel analiz için sayısal bir sütun seçin."
                      )
                : result.errorMessage
            );
        return false;
    }

    m_dataset2EdaResult = result.data;
    m_dataset2EdaAvailable = true;

    emit dataset2EdaChanged();

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

    return true;
}

bool AppController::removeDataset1Column(const QString &columnName)
{
    clearError();

    if (m_dataset1.isEmpty())
    {
        setError(QStringLiteral("Dataset 1 is not loaded."));
        return false;
    }

    if (!m_dataset1.removeColumn(columnName))
    {
        setError(QStringLiteral("Column could not be removed from Dataset 1: ") + columnName);
        return false;
    }

    m_dataset1Modified = true;
    m_dataset1ColumnModel.setColumns(m_dataset1.columns());
    clearDataset1Quality();
    clearDataset1Outliers();
    clearDataset1Eda();
    clearDataset1Correlation();
    clearAnalysis();
    emit dataset1Changed();
    tryGenerateMappings();
    return true;
}

bool AppController::removeDataset2Column(const QString &columnName)
{
    clearError();

    if (m_dataset2.isEmpty())
    {
        setError(QStringLiteral("Dataset 2 is not loaded."));
        return false;
    }

    if (!m_dataset2.removeColumn(columnName))
    {
        setError(QStringLiteral("Column could not be removed from Dataset 2: ") + columnName);
        return false;
    }

    m_dataset2Modified = true;
    m_dataset2ColumnModel.setColumns(m_dataset2.columns());
    clearDataset2Quality();
    clearDataset2Outliers();
    clearDataset2Eda();
    clearDataset2Correlation();
    clearAnalysis();
    emit dataset2Changed();
    tryGenerateMappings();
    return true;
}

QString AppController::saveChartImage(const QString &base64Data, const QString &chartTypePrefix)
{
    clearError();

    if (base64Data.isEmpty())
    {
        setError(QStringLiteral("Görsel verisi boş."));
        return QString();
    }

    QString baseDir = QDir::currentPath();
    const QString knownProjectPath = QStringLiteral("C:/Users/aybuk/Desktop/GenericDataAnalyzer");
    if (QDir(knownProjectPath).exists())
    {
        baseDir = knownProjectPath;
    }

    QDir outputDir(baseDir + QStringLiteral("/output"));
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
        setError(QStringLiteral("Grafik görseli dönüştürülemedi."));
        return QString();
    }

    const QString safePrefix = chartTypePrefix.isEmpty() ? QStringLiteral("Grafik") : chartTypePrefix;
    const QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd_hhmmss"));
    const QString fileName = QStringLiteral("%1_%2.png").arg(safePrefix, timestamp);
    const QString fullPath = outputDir.filePath(fileName);

    if (!image.save(fullPath, "PNG"))
    {
        setError(QStringLiteral("Grafik dosyası kaydedilemedi: ") + fullPath);
        return QString();
    }

    m_visualizationAvailable = true;
    emit visualizationChanged();
    if (chartTypePrefix.contains(QStringLiteral("Karsilastirma"), Qt::CaseInsensitive))
    {
        m_datasetComparisonAvailable = true;
        emit datasetComparisonChanged();
    }

    return fullPath;
}

QString AppController::autoExportDataset(int datasetIndex, const QString &format)
{
    clearError();
    const DataSet &ds = (datasetIndex == 1) ? m_dataset1 : m_dataset2;
    if (ds.isEmpty())
    {
        setError(QStringLiteral("Veri seti bulunamadı veya boş."));
        return QString();
    }

    QString baseDir = QDir::currentPath();
    const QString knownProjectPath = QStringLiteral("C:/Users/aybuk/Desktop/GenericDataAnalyzer");
    if (QDir(knownProjectPath).exists())
    {
        baseDir = knownProjectPath;
    }

    QDir outputDir(baseDir + QStringLiteral("/output"));
    if (!outputDir.exists())
    {
        outputDir.mkpath(QStringLiteral("."));
    }

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
        return fullPath;
    }
    return QString();
}

// =========================================================
// QUALITY
// =========================================================

bool AppController::analyzeDataset1Quality()
{
    clearError();
    clearDataset1Quality();

    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset1
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset1QualityResult = result.data;
    m_dataset1QualityAvailable = true;

    emit dataset1QualityChanged();

    return true;
}

bool AppController::analyzeDataset2Quality()
{
    clearError();
    clearDataset2Quality();

    const EdaOperationResult result =
        m_edaEngine.analyzeQuality(
            m_dataset2
            );

    if (!result.success)
    {
        setError(result.errorMessage);
        return false;
    }

    m_dataset2QualityResult = result.data;
    m_dataset2QualityAvailable = true;

    emit dataset2QualityChanged();

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

    emit dataset1OutlierChanged();

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

    emit dataset2OutlierChanged();

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
                ? QStringLiteral(
                      "Seçilen sütun sayısal değil. "
                      "İstatistiksel analiz yalnızca sayısal sütunlarda yapılabilir."
                      )
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
                ? QStringLiteral(
                      "Seçilen sütun sayısal değil. "
                      "İstatistiksel analiz yalnızca sayısal sütunlarda yapılabilir."
                      )
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
    addRecentFile(normalizedPath, QStringLiteral("Ham Veri Metadata (Excel)"));
    recordActivity(QStringLiteral("Ham Veri Metadata Yüklendi"),
                   QStringLiteral("%1 (%2 parametre)").arg(QFileInfo(normalizedPath).fileName()).arg(definitions.size()),
                   QStringLiteral("Ham Veri"));
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
    addRecentFile(normalizedPath, QStringLiteral("Ham Veri Dosyası (.bin)"));
    recordActivity(QStringLiteral("Ham Veri Dosyası Yüklendi"),
                   QStringLiteral("%1 (%2 KB)").arg(QFileInfo(normalizedPath).fileName()).arg(m_rawData.size() / 1024),
                   QStringLiteral("Ham Veri"));
    emit lastSessionChanged();
    saveSettings();

    clearRawParse();
    emit rawDataChanged();

    return true;
}

bool AppController::parseRawData()
{
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

    const QList<QList<ParsedParameter>> parsedPackets =
        m_rawDataParser.parsePackets(
            m_rawData,
            m_rawParameterDefinitions,
            packetSize
            );

    if (parsedPackets.isEmpty())
    {
        setError(QStringLiteral("Raw data parser produced no packet results."));
        return false;
    }

    /*
     * ParameterModel düz bir liste tuttuğu için bütün
     * packet'ların parametrelerini tek listede topluyoruz.
     *
     * Örnek:
     * 50 packet x 5 parametre = 250 ParsedParameter
     */
    QList<ParsedParameter> allParsedParameters;

    allParsedParameters.reserve(
        parsedPackets.size() *
        m_rawParameterDefinitions.size()
        );

    bool hasSuccessfulParameter = false;
    bool hasErrorParameter = false;

    for (const QList<ParsedParameter> &packet : parsedPackets)
    {
        for (const ParsedParameter &parameter : packet)
        {
            allParsedParameters.append(parameter);

            if (parameter.parsedSuccessfully())
                hasSuccessfulParameter = true;

            if (parameter.hasError())
                hasErrorParameter = true;
        }
    }

    if (allParsedParameters.isEmpty())
    {
        setError(QStringLiteral("Raw data parser produced no parameter results."));
        return false;
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
        return false;
    }

    m_parameterModel.setParameters(allParsedParameters);

    m_rawParseAvailable = true;
    recordActivity(QStringLiteral("Ham Veri Ayrıştırıldı"),
                   QStringLiteral("%1 paket başarıyla işlendi").arg(parsedPackets.size()),
                   QStringLiteral("Ham Veri"));
    emit rawParseChanged();

    const int ignoredByteCount =
        m_rawData.size() % packetSize;

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

    return true;
}

bool AppController::importParsedRawDataAsDataset(
    int datasetIndex,
    const QString &customName
    )
{
    clearError();

    if (!m_rawParseAvailable)
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

    const QList<QList<ParsedParameter>> parsedPackets =
        m_rawDataParser.parsePackets(
            m_rawData,
            m_rawParameterDefinitions,
            packetSize
            );

    if (parsedPackets.isEmpty())
    {
        setError(
            QStringLiteral(
                "Parsed raw packets are not available."
                )
            );
        return false;
    }

    const QList<ParsedParameter> &firstPacket =
        parsedPackets.first();

    if (firstPacket.isEmpty())
    {
        setError(
            QStringLiteral(
                "The first parsed raw packet contains no parameters."
                )
            );
        return false;
    }

    DataSet dataSet;

    const QString name =
        customName.isEmpty()
            ? QStringLiteral("Parsed_Raw_Data")
            : customName;

    dataSet.setName(name);
    dataSet.setFilePath(m_rawDataFilePath);
    dataSet.setSheetName(QStringLiteral("RawPackets"));

    /*
     * Her metadata parametresi bir sütundur.
     * Her packet ise bir satırdır.
     *
     * Örnek:
     *
     * Packet 1 -> satır 1
     * Packet 2 -> satır 2
     * ...
     * Packet 50 -> satır 50
     */
    for (int parameterIndex = 0;
         parameterIndex < firstPacket.size();
         ++parameterIndex)
    {
        const ParsedParameter &schemaParameter =
            firstPacket.at(parameterIndex);

        ColumnInfo col;

        col.setName(schemaParameter.dataName);
        col.setOriginalName(schemaParameter.dataName);

        QVector<QVariant> vals;
        vals.reserve(parsedPackets.size());

        for (const QList<ParsedParameter> &packet : parsedPackets)
        {
            if (parameterIndex >= packet.size())
            {
                vals.append(QVariant());
                continue;
            }

            const ParsedParameter &parameter =
                packet.at(parameterIndex);

            if (parameter.parsedSuccessfully() &&
                parameter.value.isValid() &&
                !parameter.value.isNull())
            {
                vals.append(parameter.value);
            }
            else
            {
                vals.append(QVariant());
            }
        }

        col.setValues(vals);

        // -------------------------------------------------
        // COLUMN DATA TYPE
        // -------------------------------------------------

        const QString typeStr =
            schemaParameter.dataType
                .trimmed()
                .toLower();

        if (typeStr == QStringLiteral("boolean") ||
            typeStr == QStringLiteral("bool"))
        {
            col.setDataType(
                ColumnInfo::DataType::Boolean
                );
        }
        else if (
            typeStr == QStringLiteral("float32") ||
            typeStr == QStringLiteral("float64") ||
            typeStr == QStringLiteral("float") ||
            typeStr == QStringLiteral("double"))
        {
            col.setDataType(
                ColumnInfo::DataType::Double
                );
        }
        else if (
            typeStr.startsWith(QStringLiteral("int")) ||
            typeStr.startsWith(QStringLiteral("uint")))
        {
            bool containsDouble = false;

            for (const QVariant &value : vals)
            {
                if (!value.isValid() ||
                    value.isNull())
                {
                    continue;
                }

                if (value.type() == QVariant::Double)
                {
                    containsDouble = true;
                    break;
                }
            }

            col.setDataType(
                containsDouble
                    ? ColumnInfo::DataType::Double
                    : ColumnInfo::DataType::Integer
                );
        }
        else
        {
            bool hasInt = false;
            bool hasDouble = false;
            bool hasBool = false;

            for (const QVariant &value : vals)
            {
                if (!value.isValid() ||
                    value.isNull())
                {
                    continue;
                }

                if (value.type() == QVariant::Bool)
                {
                    hasBool = true;
                }
                else if (value.type() == QVariant::Double)
                {
                    hasDouble = true;
                }
                else if (value.canConvert<qint64>())
                {
                    hasInt = true;
                }
            }

            if (hasDouble)
            {
                col.setDataType(
                    ColumnInfo::DataType::Double
                    );
            }
            else if (hasInt)
            {
                col.setDataType(
                    ColumnInfo::DataType::Integer
                    );
            }
            else if (hasBool)
            {
                col.setDataType(
                    ColumnInfo::DataType::Boolean
                    );
            }
            else
            {
                col.setDataType(
                    ColumnInfo::DataType::Unknown
                    );
            }
        }

        // -------------------------------------------------
        // MISSING / UNIQUE STATISTICS
        // -------------------------------------------------

        int missingCount = 0;
        QSet<QString> uniqueValues;

        for (const QVariant &value : vals)
        {
            if (!value.isValid() ||
                value.isNull() ||
                (value.type() == QVariant::String &&
                 value.toString().trimmed().isEmpty()))
            {
                ++missingCount;
            }
            else
            {
                uniqueValues.insert(
                    value.toString()
                    );
            }
        }

        col.setMissingCount(
            missingCount
            );

        const double missingPercentage =
            vals.isEmpty()
                ? 0.0
                : static_cast<double>(missingCount)
                      / static_cast<double>(vals.size())
                      * 100.0;

        col.setMissingPercentage(
            missingPercentage
            );

        col.setUniqueCount(
            uniqueValues.size()
            );

        dataSet.addColumn(col);
    }

    if (dataSet.isEmpty())
    {
        setError(
            QStringLiteral(
                "Parsed raw data could not be converted to a dataset."
                )
            );
        return false;
    }

    if (datasetIndex == 1)
    {
        m_originalDataset1 = dataSet;
        m_dataset1 = dataSet;
        m_dataset1Modified = false;

        m_dataset1ColumnModel.setColumns(
            m_dataset1.columns()
            );

        clearDataset1Quality();
        clearDataset1Outliers();
        clearDataset1OutlierCleaning();
        clearDataset1Eda();
        clearDataset1Correlation();
        clearAnalysis();

        emit dataset1Changed();

        tryGenerateMappings();
        analyzeDataset1Quality();
    }
    else
    {
        m_originalDataset2 = dataSet;
        m_dataset2 = dataSet;
        m_dataset2Modified = false;

        m_dataset2ColumnModel.setColumns(
            m_dataset2.columns()
            );

        clearDataset2Quality();
        clearDataset2Outliers();
        clearDataset2OutlierCleaning();
        clearDataset2Eda();
        clearDataset2Correlation();
        clearAnalysis();

        emit dataset2Changed();

        tryGenerateMappings();
        analyzeDataset2Quality();
    }

    recordActivity(QStringLiteral("Ham Veri -> Dataset %1 Aktarıldı").arg(datasetIndex),
                   QStringLiteral("%1 satır, %2 sütun oluşturuldu").arg(dataSet.rowCount()).arg(dataSet.columnCount()),
                   QStringLiteral("Ham Veri"));

    return true;
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