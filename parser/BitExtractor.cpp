#include "BitExtractor.h"

#include <cstring>
#include <limits>

bool BitExtractor::validateBitRange(
    int byteSize,
    int bitOffset,
    int bitSize,
    QString &errorMessage)
{
    if (byteSize <= 0) {
        errorMessage =
            QStringLiteral(
                "BYTE_SIZE must be greater than zero.");

        return false;
    }

    if (byteSize > 8) {
        errorMessage =
            QStringLiteral(
                "BYTE_SIZE cannot exceed 8 bytes.");

        return false;
    }

    if (bitOffset < 0) {
        errorMessage =
            QStringLiteral(
                "BIT_OFFSET cannot be negative.");

        return false;
    }

    if (bitSize <= 0) {
        errorMessage =
            QStringLiteral(
                "BIT_SIZE must be greater than zero.");

        return false;
    }

    if (bitSize > 64) {
        errorMessage =
            QStringLiteral(
                "BIT_SIZE cannot exceed 64 bits.");

        return false;
    }

    const int availableBits =
        byteSize * 8;

    if (bitOffset >= availableBits) {
        errorMessage =
            QStringLiteral(
                "BIT_OFFSET %1 is outside the %2-bit byte window.")
                .arg(bitOffset)
                .arg(availableBits);

        return false;
    }

    const int remainingBits =
        availableBits - bitOffset;

    if (bitSize > remainingBits) {
        errorMessage =
            QStringLiteral(
                "Requested bit field does not fit in the byte window. "
                "BIT_OFFSET=%1, BIT_SIZE=%2, available bits after offset=%3.")
                .arg(bitOffset)
                .arg(bitSize)
                .arg(remainingBits);

        return false;
    }

    return true;
}

quint64 BitExtractor::createMask(int bitSize)
{
    /*
     * Şunu ASLA yapmıyoruz:
     *
     * (1ULL << 64) - 1
     *
     * 64 bit shift C++ tarafında güvenli değildir.
     */
    if (bitSize == 64) {
        return std::numeric_limits<quint64>::max();
    }

    return
        (quint64(1) << bitSize) - quint64(1);
}

BitExtractionResult BitExtractor::extract(
    const RawDataBuffer &buffer,
    int byteOffset,
    int byteSize,
    int bitOffset,
    int bitSize,
    Endianness endianness)
{
    QString errorMessage;

    if (!validateBitRange(
            byteSize,
            bitOffset,
            bitSize,
            errorMessage)) {

        return BitExtractionResult::error(
            errorMessage);
    }

    quint64 rawWindow = 0;

    if (!buffer.readUnsigned(
            byteOffset,
            byteSize,
            endianness,
            rawWindow,
            errorMessage)) {

        return BitExtractionResult::error(
            errorMessage);
    }

    /*
     * BIT_OFFSET her zaman oluşturulan integer window'un
     * least significant bit'i üzerinden uygulanıyor.
     */
    const quint64 shifted =
        rawWindow >> bitOffset;

    const quint64 mask =
        createMask(bitSize);

    const quint64 extracted =
        shifted & mask;

    return BitExtractionResult::ok(
        extracted);
}

bool BitExtractor::signExtend(
    quint64 rawValue,
    int bitSize,
    qint64 &signedValue,
    QString &errorMessage)
{
    signedValue = 0;

    if (bitSize <= 0 ||
        bitSize > 64) {

        errorMessage =
            QStringLiteral(
                "Cannot sign-extend a value with BIT_SIZE %1.")
                .arg(bitSize);

        return false;
    }

    /*
     * 64 bit signed değer zaten bütün qint64 alanını
     * kullanıyor.
     *
     * Burada 1ULL << 64 yapmıyoruz.
     */
    if (bitSize == 64) {

        /*
         * Bit desenini signed alana kopyalamak için memcpy
         * kullanmak dönüşüm davranışını daha açık hale getirir.
         */
        static_assert(
            sizeof(quint64) == sizeof(qint64),
            "quint64 and qint64 sizes must match.");

        std::memcpy(
            &signedValue,
            &rawValue,
            sizeof(signedValue));

        return true;
    }

    const quint64 mask =
        createMask(bitSize);

    rawValue &= mask;

    const quint64 signBit =
        quint64(1) << (bitSize - 1);

    if ((rawValue & signBit) == 0) {

        signedValue =
            static_cast<qint64>(rawValue);

        return true;
    }

    /*
     * Örneğin 8 bit:
     *
     * raw = 11111111
     *
     * sign extension sonrası:
     *
     * 11111111 11111111 ... 11111111
     *
     * yani -1
     */
    const quint64 extended =
        rawValue | (~mask);

    std::memcpy(
        &signedValue,
        &extended,
        sizeof(signedValue));

    return true;
}