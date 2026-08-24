#include "DataType.h"

DataType DataTypeUtils::fromString(const QString &text)
{
    const QString value = text.trimmed().toLower();

    if (value == QStringLiteral("boolean") ||
        value == QStringLiteral("bool"))
        return DataType::Boolean;

    if (value == QStringLiteral("int8"))
        return DataType::Int8;

    if (value == QStringLiteral("int16"))
        return DataType::Int16;

    if (value == QStringLiteral("int32"))
        return DataType::Int32;

    if (value == QStringLiteral("uint8"))
        return DataType::UInt8;

    if (value == QStringLiteral("uint16"))
        return DataType::UInt16;

    if (value == QStringLiteral("uint32"))
        return DataType::UInt32;

    if (value == QStringLiteral("single") ||
        value == QStringLiteral("float") ||
        value == QStringLiteral("float32"))
        return DataType::Float32;

    if (value == QStringLiteral("double") ||
        value == QStringLiteral("float64"))
        return DataType::Float64;

    return DataType::Unknown;
}

QString DataTypeUtils::toString(DataType type)
{
    switch (type) {

    case DataType::Boolean:
        return QStringLiteral("boolean");

    case DataType::Int8:
        return QStringLiteral("int8");

    case DataType::Int16:
        return QStringLiteral("int16");

    case DataType::Int32:
        return QStringLiteral("int32");

    case DataType::UInt8:
        return QStringLiteral("uint8");

    case DataType::UInt16:
        return QStringLiteral("uint16");

    case DataType::UInt32:
        return QStringLiteral("uint32");

    case DataType::Float32:
        return QStringLiteral("float32");

    case DataType::Float64:
        return QStringLiteral("float64");

    case DataType::Unknown:
    default:
        return QStringLiteral("unknown");
    }
}

bool DataTypeUtils::isSignedInteger(DataType type)
{
    return type == DataType::Int8 ||
           type == DataType::Int16 ||
           type == DataType::Int32;
}

bool DataTypeUtils::isUnsignedInteger(DataType type)
{
    return type == DataType::UInt8 ||
           type == DataType::UInt16 ||
           type == DataType::UInt32;
}

bool DataTypeUtils::isInteger(DataType type)
{
    return isSignedInteger(type) ||
           isUnsignedInteger(type);
}

bool DataTypeUtils::isFloatingPoint(DataType type)
{
    return type == DataType::Float32 ||
           type == DataType::Float64;
}

bool DataTypeUtils::isBoolean(DataType type)
{
    return type == DataType::Boolean;
}

int DataTypeUtils::nativeBitSize(DataType type)
{
    switch (type) {

    case DataType::Boolean:
        return 1;

    case DataType::Int8:
    case DataType::UInt8:
        return 8;

    case DataType::Int16:
    case DataType::UInt16:
        return 16;

    case DataType::Int32:
    case DataType::UInt32:
    case DataType::Float32:
        return 32;

    case DataType::Float64:
        return 64;

    case DataType::Unknown:
    default:
        return 0;
    }
}

bool DataTypeUtils::isSupported(DataType type)
{
    return type != DataType::Unknown;
}