#ifndef BITEXTRACTOR_H
#define BITEXTRACTOR_H

#include <QtGlobal>

#include "BitExtractionResult.h"
#include "RawDataBuffer.h"

class BitExtractor
{
public:
    static BitExtractionResult extract(
        const RawDataBuffer &buffer,
        int byteOffset,
        int byteSize,
        int bitOffset,
        int bitSize,
        Endianness endianness);

    static bool signExtend(
        quint64 rawValue,
        int bitSize,
        qint64 &signedValue,
        QString &errorMessage);

private:
    static bool validateBitRange(
        int byteSize,
        int bitOffset,
        int bitSize,
        QString &errorMessage);

    static quint64 createMask(
        int bitSize);
};

#endif // BITEXTRACTOR_H