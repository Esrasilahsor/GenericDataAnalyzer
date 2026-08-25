#ifndef DATATYPE_H
#define DATATYPE_H

#include <QString>

enum class DataType
{
    Boolean,

    Int8,
    Int16,
    Int32,

    UInt8,
    UInt16,
    UInt32,

    Float32,
    Float64,

    Unknown
};

enum class Endianness
{
    LittleEndian,
    BigEndian
};

namespace DataTypeUtils
{
DataType fromString(const QString &text);

QString toString(DataType type);

bool isSignedInteger(DataType type);
bool isUnsignedInteger(DataType type);
bool isInteger(DataType type);
bool isFloatingPoint(DataType type);
bool isBoolean(DataType type);

int nativeBitSize(DataType type);

bool isSupported(DataType type);
}

#endif // DATATYPE_H