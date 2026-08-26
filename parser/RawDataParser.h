#ifndef RAWDATAPARSER_H
#define RAWDATAPARSER_H

#include <QByteArray>
#include <QList>
#include <QString>

#include "ParserTypes.h"
#include "RawDataBuffer.h"


class RawDataParser
{
public:
    RawDataParser() = default;


    // =====================================================
    // SINGLE PACKET PARSE
    // =====================================================

    QList<ParsedParameter> parse(
        const QByteArray &rawData,
        const QList<ParameterDefinition> &definitions) const;


    // =====================================================
    // MULTIPLE PACKET PARSE
    // =====================================================

    QList<QList<ParsedParameter>> parsePackets(
        const QByteArray &rawData,
        const QList<ParameterDefinition> &definitions,
        int packetSize) const;


    // =====================================================
    // PACKET SIZE
    // =====================================================

    int calculateRequiredPacketSize(
        const QList<ParameterDefinition> &definitions) const;


private:

    // =====================================================
    // SINGLE PARAMETER
    // =====================================================

    ParsedParameter parseParameter(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;


    // =====================================================
    // INTEGER
    // =====================================================

    ParsedParameter parseInteger(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;


    // =====================================================
    // BOOLEAN
    // =====================================================

    ParsedParameter parseBoolean(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;


    // =====================================================
    // FLOAT
    // =====================================================

    ParsedParameter parseFloat32(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    ParsedParameter parseFloat64(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;


    // =====================================================
    // RANGE CHECK
    // =====================================================

    void applyRangeCheck(
        ParsedParameter &parameter,
        const ParameterDefinition &definition,
        double numericValue) const;


    // =====================================================
    // DISPLAY FORMAT
    // =====================================================

    QString formatFloatingPoint(
        double value) const;
};


#endif // RAWDATAPARSER_H