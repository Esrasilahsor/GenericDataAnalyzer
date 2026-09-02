#include "RawParserWorker.h"

#include <QThreadPool>
#include <QRunnable>
#include <QThread>
#include <QMutex>
#include <memory>
#include <algorithm>

namespace {

class ChunkParseTask : public QRunnable
{
public:
    ChunkParseTask(
        int chunkIndex,
        int startPacket,
        int endPacket,
        int packetSize,
        const QByteArray &rawData,
        const QList<ParameterDefinition> &definitions,
        QVector<QList<QList<ParsedParameter>>> &results,
        std::atomic<bool> &cancelFlag,
        std::atomic<int> &processedPackets,
        int totalPackets,
        std::shared_ptr<std::atomic<int>> lastEmittedPercent,
        std::function<void(int)> progressNotifier
    )
        : m_chunkIndex(chunkIndex)
        , m_startPacket(startPacket)
        , m_endPacket(endPacket)
        , m_packetSize(packetSize)
        , m_rawData(rawData)
        , m_definitions(definitions)
        , m_results(results)
        , m_cancelFlag(cancelFlag)
        , m_processedPackets(processedPackets)
        , m_totalPackets(totalPackets)
        , m_lastEmittedPercent(lastEmittedPercent)
        , m_progressNotifier(progressNotifier)
    {
        setAutoDelete(true);
    }

    void run() override
    {
        if (m_cancelFlag.load(std::memory_order_relaxed))
        {
            return;
        }

        const int packetOffset = m_startPacket * m_packetSize;
        const int packetCount = m_endPacket - m_startPacket;
        const int byteCount = packetCount * m_packetSize;

        const QByteArray chunkSlice = m_rawData.mid(packetOffset, byteCount);

        RawDataParser parser;
        QList<QList<ParsedParameter>> parsedChunk =
            parser.parsePackets(
                chunkSlice,
                m_definitions,
                m_packetSize,
                [this](int processedInChunk, int totalInChunk) {
                    Q_UNUSED(processedInChunk);
                    Q_UNUSED(totalInChunk);
                    if (m_cancelFlag.load(std::memory_order_relaxed))
                    {
                        return;
                    }

                    const int globalProcessed = ++m_processedPackets;
                    if (m_totalPackets > 0)
                    {
                        const int pct = (globalProcessed * 100) / m_totalPackets;
                        int last = m_lastEmittedPercent->load(std::memory_order_relaxed);
                        if (pct > last && pct <= 100)
                        {
                            if (m_lastEmittedPercent->compare_exchange_strong(last, pct))
                            {
                                if (m_progressNotifier)
                                {
                                    m_progressNotifier(pct);
                                }
                            }
                        }
                    }
                }
            );

        if (m_cancelFlag.load(std::memory_order_relaxed))
        {
            return;
        }

        m_results[m_chunkIndex] = std::move(parsedChunk);
    }

private:
    int m_chunkIndex;
    int m_startPacket;
    int m_endPacket;
    int m_packetSize;
    QByteArray m_rawData;
    QList<ParameterDefinition> m_definitions;
    QVector<QList<QList<ParsedParameter>>> &m_results;
    std::atomic<bool> &m_cancelFlag;
    std::atomic<int> &m_processedPackets;
    int m_totalPackets;
    std::shared_ptr<std::atomic<int>> m_lastEmittedPercent;
    std::function<void(int)> m_progressNotifier;
};

} // namespace

RawParserWorker::RawParserWorker(
    const QByteArray &rawData,
    const QList<ParameterDefinition> &definitions,
    QObject *parent
)
    : QObject(parent)
    , m_rawData(rawData)
    , m_definitions(definitions)
    , m_cancelRequested(false)
{
}

RawParserWorker::~RawParserWorker()
{
}

void RawParserWorker::cancel()
{
    m_cancelRequested.store(true, std::memory_order_relaxed);
}

void RawParserWorker::startParsing()
{
    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled();
        return;
    }

    if (m_definitions.isEmpty())
    {
        emit failed(QStringLiteral("Raw metadata is not loaded or has no parameter definitions."));
        return;
    }

    if (m_rawData.isEmpty())
    {
        emit failed(QStringLiteral("Raw data is empty."));
        return;
    }

    const int packetSize = m_parser.calculateRequiredPacketSize(m_definitions);
    if (packetSize <= 0)
    {
        emit failed(QStringLiteral("Packet size could not be calculated from raw metadata."));
        return;
    }

    if (m_rawData.size() < packetSize)
    {
        emit failed(QStringLiteral("Raw data is smaller than the required packet size."));
        return;
    }

    const int totalPackets = m_rawData.size() / packetSize;
    if (totalPackets <= 0)
    {
        emit failed(QStringLiteral("No complete packets found in raw data."));
        return;
    }

    const int chunkCount = (totalPackets + CHUNK_PACKET_SIZE - 1) / CHUNK_PACKET_SIZE;
    QVector<QList<QList<ParsedParameter>>> chunkResults(chunkCount);

    std::atomic<int> processedPackets(0);

    QThreadPool pool;
    const int maxThreads = qBound(1, QThread::idealThreadCount() - 1, 8);
    pool.setMaxThreadCount(maxThreads);

    std::shared_ptr<std::atomic<int>> lastEmittedPercent = std::make_shared<std::atomic<int>>(0);
    std::shared_ptr<QMutex> progressMutex = std::make_shared<QMutex>();
    auto progressNotifier = [this, progressMutex](int percent) {
        QMutexLocker locker(progressMutex.get());
        emit progressChanged(percent);
    };

    emit progressChanged(0);

    for (int c = 0; c < chunkCount; ++c)
    {
        if (m_cancelRequested.load(std::memory_order_relaxed))
        {
            break;
        }

        const int startPacket = c * CHUNK_PACKET_SIZE;
        const int endPacket = std::min((c + 1) * CHUNK_PACKET_SIZE, totalPackets);

        ChunkParseTask *task = new ChunkParseTask(
            c,
            startPacket,
            endPacket,
            packetSize,
            m_rawData,
            m_definitions,
            chunkResults,
            m_cancelRequested,
            processedPackets,
            totalPackets,
            lastEmittedPercent,
            progressNotifier
        );

        pool.start(task);
    }

    pool.waitForDone();

    if (m_cancelRequested.load(std::memory_order_relaxed))
    {
        emit cancelled();
        return;
    }

    QList<QList<ParsedParameter>> allPackets;
    allPackets.reserve(totalPackets);

    bool hasSuccessfulParameter = false;
    bool hasErrorParameter = false;

    for (int c = 0; c < chunkCount; ++c)
    {
        const QList<QList<ParsedParameter>> &chunk = chunkResults[c];
        for (const QList<ParsedParameter> &packet : chunk)
        {
            allPackets.append(packet);

            for (const ParsedParameter &param : packet)
            {
                if (param.parsedSuccessfully())
                {
                    hasSuccessfulParameter = true;
                }
                if (param.hasError())
                {
                    hasErrorParameter = true;
                }
            }
        }
    }

    if (allPackets.isEmpty())
    {
        emit failed(QStringLiteral("Raw data parser produced no packet results."));
        return;
    }

    const int ignoredByteCount = m_rawData.size() % packetSize;

    emit progressChanged(100);
    emit finished(allPackets, ignoredByteCount, hasErrorParameter, hasSuccessfulParameter);
}
