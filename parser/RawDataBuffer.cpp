#include "RawDataBuffer.h"

#include <cstring>
#include <limits>

RawDataBuffer::RawDataBuffer(const QByteArray &data)
    : m_data(data)
{
}

int RawDataBuffer::size() const
{
    return m_data.size();
}

bool RawDataBuffer::isEmpty() const
{
    return m_data.isEmpty();
}

bool RawDataBuffer::canRead(
    int byteOffset,
    int byteSize) const
{
    QString error;
    return validateReadRange(
        byteOffset,
        byteSize,
        error);
}

bool RawDataBuffer::validateReadRange(
    int byteOffset,
    int byteSize,
    QString &errorMessage) const
{
    if (byteOffset < 0) {
        errorMessage =
            QStringLiteral(
                "Byte offset cannot be negative.");

        return false;
    }

    if (byteSize <= 0) {
        errorMessage =
            QStringLiteral(
                "Byte size must be greater than zero.");

        return false;
    }

    /*
     * Byte offset QByteArray sınırının dışında mı?
     *
     * QByteArray::size() int döndürdüğü için önce
     * offset'i kontrol ediyoruz.
     */
    if (byteOffset > m_data.size()) {
        errorMessage =
            QStringLiteral(
                "Byte offset %1 exceeds raw data size %2.")
                .arg(byteOffset)
                .arg(m_data.size());

        return false;
    }

    /*
     * Burada özellikle:
     *
     * byteOffset + byteSize > m_data.size()
     *
     * kullanmıyoruz.
     *
     * Teorik integer overflow riskini engellemek için
     * çıkarma üzerinden kontrol ediyoruz.
     */
    const int remainingBytes =
        m_data.size() - byteOffset;

    if (byteSize > remainingBytes) {
        errorMessage =
            QStringLiteral(
                "Cannot read %1 byte(s) from offset %2. "
                "Raw data size is %3 and only %4 byte(s) remain.")
                .arg(byteSize)
                .arg(byteOffset)
                .arg(m_data.size())
                .arg(remainingBytes);

        return false;
    }

    return true;
}

bool RawDataBuffer::readUnsigned(
    int byteOffset,
    int byteSize,
    Endianness endianness,
    quint64 &value,
    QString &errorMessage) const
{
    value = 0;

    if (!validateReadRange(
            byteOffset,
            byteSize,
            errorMessage)) {
        return false;
    }

    /*
     * Extraction altyapımız quint64 olduğu için
     * maksimum 8 byte okuyabiliriz.
     */
    if (byteSize > 8) {
        errorMessage =
            QStringLiteral(
                "Unsigned integer reads cannot exceed 8 bytes.");

        return false;
    }

    if (endianness == Endianness::LittleEndian) {

        /*
         * Örnek:
         *
         * raw:
         * 34 12
         *
         * little endian:
         * 0x1234
         */
        for (int i = byteSize - 1; i >= 0; --i) {

            value <<= 8;

            const quint8 byte =
                static_cast<quint8>(
                    m_data.at(byteOffset + i));

            value |= static_cast<quint64>(byte);
        }
    }
    else {

        /*
         * Örnek:
         *
         * raw:
         * 12 34
         *
         * big endian:
         * 0x1234
         */
        for (int i = 0; i < byteSize; ++i) {

            value <<= 8;

            const quint8 byte =
                static_cast<quint8>(
                    m_data.at(byteOffset + i));

            value |= static_cast<quint64>(byte);
        }
    }

    return true;
}

bool RawDataBuffer::readFloat32(
    int byteOffset,
    Endianness endianness,
    float &value,
    QString &errorMessage) const
{
    value = 0.0f;

    constexpr int floatSize =
        static_cast<int>(sizeof(float));

    /*
     * IEEE float32 varsayımı.
     *
     * Qt desteklediğimiz masaüstü platformlarında bu
     * pratikte 4 byte olacaktır ancak yine de kontrol ediyoruz.
     */
    if (floatSize != 4) {
        errorMessage =
            QStringLiteral(
                "This platform does not use a 4-byte float.");

        return false;
    }

    quint64 raw = 0;

    if (!readUnsigned(
            byteOffset,
            floatSize,
            endianness,
            raw,
            errorMessage)) {
        return false;
    }

    const quint32 raw32 =
        static_cast<quint32>(raw);

    std::memcpy(
        &value,
        &raw32,
        sizeof(value));

    return true;
}

bool RawDataBuffer::readFloat64(
    int byteOffset,
    Endianness endianness,
    double &value,
    QString &errorMessage) const
{
    value = 0.0;

    constexpr int doubleSize =
        static_cast<int>(sizeof(double));

    if (doubleSize != 8) {
        errorMessage =
            QStringLiteral(
                "This platform does not use an 8-byte double.");

        return false;
    }

    quint64 raw = 0;

    if (!readUnsigned(
            byteOffset,
            doubleSize,
            endianness,
            raw,
            errorMessage)) {
        return false;
    }

    std::memcpy(
        &value,
        &raw,
        sizeof(value));

    return true;
}