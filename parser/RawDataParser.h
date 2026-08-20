#ifndef RAWDATAPARSER_H
#define RAWDATAPARSER_H

#include <QByteArray>
#include <QList>

#include "ParameterDefinition.h"
#include "ParsedParameter.h"
#include "RawDataBuffer.h"

class RawDataParser
{
public:
    RawDataParser() = default;

    QList<ParsedParameter> parse(
        const QByteArray &rawData,
        const QList<ParameterDefinition> &definitions) const;

private:
    ParsedParameter parseParameter(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    ParsedParameter parseInteger(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    ParsedParameter parseBoolean(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    ParsedParameter parseFloat32(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    ParsedParameter parseFloat64(
        const ParameterDefinition &definition,
        const RawDataBuffer &buffer) const;

    void applyRangeCheck(
        ParsedParameter &parameter,
        const ParameterDefinition &definition,
        double numericValue) const;

    QString formatFloatingPoint(
        double value) const;
};

#endif // RAWDATAPARSER_H