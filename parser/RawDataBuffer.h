#ifndef RAWDATABUFFER_H
#define RAWDATABUFFER_H

#include <QByteArray>
#include <QString>
#include <QtGlobal>

#include "DataType.h"

class RawDataBuffer
{
public:
    explicit RawDataBuffer(const QByteArray &data);

    int size() const;
    bool isEmpty() const;

    bool canRead(int byteOffset, int byteSize) const;

    bool readUnsigned(
        int byteOffset,
        int byteSize,
        Endianness endianness,
        quint64 &value,
        QString &errorMessage) const;

    bool readFloat32(
        int byteOffset,
        Endianness endianness,
        float &value,
        QString &errorMessage) const;

    bool readFloat64(
        int byteOffset,
        Endianness endianness,
        double &value,
        QString &errorMessage) const;

private:
    QByteArray m_data;

    bool validateReadRange(
        int byteOffset,
        int byteSize,
        QString &errorMessage) const;
};

#endif // RAWDATABUFFER_H