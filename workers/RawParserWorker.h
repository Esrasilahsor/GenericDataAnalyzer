#ifndef RAWPARSERWORKER_H
#define RAWPARSERWORKER_H

#include <QObject>
#include <QByteArray>
#include <QList>
#include <QVector>
#include <QString>
#include <atomic>

#include "../parser/ParameterDefinition.h"
#include "../parser/ParsedParameter.h"
#include "../parser/RawDataParser.h"

class RawParserWorker : public QObject
{
    Q_OBJECT

public:
    explicit RawParserWorker(
        const QByteArray &rawData,
        const QList<ParameterDefinition> &definitions,
        QObject *parent = nullptr
    );

    ~RawParserWorker() override;

public slots:
    void startParsing();
    void cancel();

signals:
    void progressChanged(int percent);
    void finished(
        const QList<QList<ParsedParameter>> &parsedPackets,
        int ignoredByteCount,
        bool hasErrorParameter,
        bool hasSuccessfulParameter
    );
    void failed(const QString &errorMessage);
    void cancelled();

private:
    QByteArray m_rawData;
    QList<ParameterDefinition> m_definitions;
    RawDataParser m_parser;
    std::atomic<bool> m_cancelRequested;

    static const int CHUNK_PACKET_SIZE = 5000;
};

#endif // RAWPARSERWORKER_H
