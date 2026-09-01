#ifndef CLEANINGWORKER_H
#define CLEANINGWORKER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <atomic>

#include "../parser/DataSet.h"
#include "../cleaning/CleaningEngine.h"

struct CleaningTask
{
    enum OperationType
    {
        RemoveDuplicates,
        RemoveMissingRows,
        FillMissingMean,
        FillMissingMedian,
        FillMissingMode,
        ApplyOutlierAction,
        RemoveColumn,
        BulkMissing,
        BulkOutliers
    };

    OperationType operation = RemoveDuplicates;
    int datasetIndex = 1;
    QString columnName;
    QString method;
    QString action;
    double parameter = 1.5;

    // For Bulk operations
    QStringList targetColumns;
    QList<bool> numericFlags;
    QString bulkAction;
};

class CleaningWorker : public QObject
{
    Q_OBJECT

public:
    explicit CleaningWorker(
        const DataSet &dataSet,
        const CleaningTask &task,
        QObject *parent = nullptr
    );

    ~CleaningWorker() override;

public slots:
    void startCleaning();
    void cancel();

signals:
    void progressChanged(int current, int total);
    void finished(
        const DataSet &cleanedDataSet,
        const CleaningResult &result,
        int datasetIndex,
        const QString &actionDescription
    );
    void failed(const QString &errorMessage, int datasetIndex);
    void cancelled(int datasetIndex);

private:
    DataSet m_dataSet;
    CleaningTask m_task;
    CleaningEngine m_engine;
    std::atomic<bool> m_cancelRequested;

    void executeSingleOperation();
    void executeBulkMissing();
    void executeBulkOutliers();
};

#endif // CLEANINGWORKER_H
