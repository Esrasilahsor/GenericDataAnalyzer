#include "CleaningWorker.h"

CleaningWorker::CleaningWorker(
    const DataSet &dataSet,
    const CleaningTask &task,
    QObject *parent
)
    : QObject(parent)
    , m_dataSet(dataSet)
    , m_task(task)
    , m_cancelRequested(false)
{
}

CleaningWorker::~CleaningWorker()
{
}

void CleaningWorker::cancel()
{
    m_cancelRequested.store(true, std::memory_order_relaxed);
}

void CleaningWorker::startCleaning()
{
    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled(m_task.datasetIndex);
        return;
    }

    if (m_dataSet.isEmpty())
    {
        emit failed(QStringLiteral("Dataset is empty."), m_task.datasetIndex);
        return;
    }

    switch (m_task.operation)
    {
    case CleaningTask::BulkMissing:
        executeBulkMissing();
        break;

    case CleaningTask::BulkOutliers:
        executeBulkOutliers();
        break;

    default:
        executeSingleOperation();
        break;
    }
}

void CleaningWorker::executeSingleOperation()
{
    CleaningResult result;
    QString desc;

    switch (m_task.operation)
    {
    case CleaningTask::RemoveDuplicates:
        result = m_engine.removeDuplicateRows(m_dataSet);
        desc = QStringLiteral("Duplicate records removed");
        break;

    case CleaningTask::RemoveMissingRows:
        result = m_engine.removeRowsWithMissingValues(m_dataSet);
        desc = QStringLiteral("Rows with missing values removed");
        break;

    case CleaningTask::FillMissingMean:
        result = m_engine.fillMissingWithMean(m_dataSet, m_task.columnName);
        desc = QStringLiteral("Filled '%1' with Mean").arg(m_task.columnName);
        break;

    case CleaningTask::FillMissingMedian:
        result = m_engine.fillMissingWithMedian(m_dataSet, m_task.columnName);
        desc = QStringLiteral("Filled '%1' with Median").arg(m_task.columnName);
        break;

    case CleaningTask::FillMissingMode:
        result = m_engine.fillMissingWithMode(m_dataSet, m_task.columnName);
        desc = QStringLiteral("Filled '%1' with Mode").arg(m_task.columnName);
        break;

    case CleaningTask::RemoveColumn:
    {
        bool ok = m_dataSet.removeColumn(m_task.columnName);
        result.success = ok;
        result.modified = ok;
        if (!ok)
        {
            result.errorMessage = QStringLiteral("Column '%1' could not be removed.").arg(m_task.columnName);
        }
        desc = QStringLiteral("Column '%1' removed").arg(m_task.columnName);
        break;
    }

    case CleaningTask::ApplyOutlierAction:
        result = m_engine.applyOutlierAction(
            m_dataSet,
            m_task.columnName,
            m_task.method,
            m_task.action,
            m_task.parameter
        );
        desc = QStringLiteral("Outlier action '%1' (%2) applied to '%3'")
            .arg(m_task.action)
            .arg(m_task.method)
            .arg(m_task.columnName);
        break;

    default:
        result.success = false;
        result.errorMessage = QStringLiteral("Unknown cleaning operation.");
        break;
    }

    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled(m_task.datasetIndex);
        return;
    }

    if (!result.success)
    {
        emit failed(result.errorMessage, m_task.datasetIndex);
        return;
    }

    emit finished(m_dataSet, result, m_task.datasetIndex, desc);
}

void CleaningWorker::executeBulkMissing()
{
    const QString act = m_task.bulkAction;
    CleaningResult result;
    result.success = true;
    result.modified = true;

    if (act == QLatin1String("Drop Rows") || act == QString::fromUtf8("Satırları Sil") || act == QLatin1String("Drop Missing Rows"))
    {
        result = m_engine.removeRowsWithMissingValues(m_dataSet);
    }
    else if (act == QLatin1String("Drop Column") || act == QString::fromUtf8("Sütunu Sil") || act == QLatin1String("Remove Column") || act == QLatin1String("Delete Column"))
    {
        const int total = m_task.targetColumns.size();
        for (int i = 0; i < total; ++i)
        {
            if (m_cancelRequested.load(std::memory_order_relaxed))
            {
                emit cancelled(m_task.datasetIndex);
                return;
            }

            m_dataSet.removeColumn(m_task.targetColumns.at(i));
            emit progressChanged(i + 1, total);
        }
    }
    else
    {
        const int total = m_task.targetColumns.size();
        for (int i = 0; i < total; ++i)
        {
            if (m_cancelRequested.load(std::memory_order_relaxed))
            {
                emit cancelled(m_task.datasetIndex);
                return;
            }

            const QString &col = m_task.targetColumns.at(i);
            const bool isNum = (i < m_task.numericFlags.size()) ? m_task.numericFlags.at(i) : false;

            if ((act.contains(QLatin1String("Mean")) || act.contains(QString::fromUtf8("Ortalama"))) && isNum)
            {
                m_engine.fillMissingWithMean(m_dataSet, col);
            }
            else if ((act.contains(QLatin1String("Median")) || act.contains(QString::fromUtf8("Medyan"))) && isNum)
            {
                m_engine.fillMissingWithMedian(m_dataSet, col);
            }
            else if (act.contains(QLatin1String("Mode")) || act.contains(QString::fromUtf8("Mod")))
            {
                m_engine.fillMissingWithMode(m_dataSet, col);
            }

            emit progressChanged(i + 1, total);
        }
    }

    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled(m_task.datasetIndex);
        return;
    }

    emit finished(m_dataSet, result, m_task.datasetIndex, QStringLiteral("Bulk missing value cleaning applied (%1)").arg(act));
}

void CleaningWorker::executeBulkOutliers()
{
    const int total = m_task.targetColumns.size();
    CleaningResult finalResult;
    finalResult.success = true;
    finalResult.modified = true;

    for (int i = 0; i < total; ++i)
    {
        if (m_cancelRequested.load(std::memory_order_relaxed))
        {
            emit cancelled(m_task.datasetIndex);
            return;
        }

        const QString &col = m_task.targetColumns.at(i);
        CleaningResult res = m_engine.applyOutlierAction(
            m_dataSet,
            col,
            m_task.method,
            m_task.action,
            m_task.parameter
        );

        if (res.modified)
        {
            finalResult.modified = true;
        }

        emit progressChanged(i + 1, total);
    }

    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled(m_task.datasetIndex);
        return;
    }

    emit finished(m_dataSet, finalResult, m_task.datasetIndex, QStringLiteral("Bulk outlier cleaning applied (%1)").arg(m_task.action));
}
