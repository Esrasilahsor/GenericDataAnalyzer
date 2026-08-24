#ifndef PARSESTATUS_H
#define PARSESTATUS_H

#include <QString>

enum class ParseStatus
{
    Ok,
    Warning,

    InvalidMetadata,
    InsufficientData,
    InvalidBitRange,
    UnsupportedType,
    InvalidNumericValue,
    InternalError
};

namespace ParseStatusUtils
{

inline bool isSuccess(ParseStatus status)
{
    return status == ParseStatus::Ok ||
           status == ParseStatus::Warning;
}

inline bool isError(ParseStatus status)
{
    return !isSuccess(status);
}

inline QString toString(ParseStatus status)
{
    switch (status) {

    case ParseStatus::Ok:
        return QStringLiteral("OK");

    case ParseStatus::Warning:
        return QStringLiteral("WARNING");

    case ParseStatus::InvalidMetadata:
        return QStringLiteral("INVALID_METADATA");

    case ParseStatus::InsufficientData:
        return QStringLiteral("INSUFFICIENT_DATA");

    case ParseStatus::InvalidBitRange:
        return QStringLiteral("INVALID_BIT_RANGE");

    case ParseStatus::UnsupportedType:
        return QStringLiteral("UNSUPPORTED_TYPE");

    case ParseStatus::InvalidNumericValue:
        return QStringLiteral("INVALID_NUMERIC_VALUE");

    case ParseStatus::InternalError:
    default:
        return QStringLiteral("INTERNAL_ERROR");
    }
}

}

#endif // PARSESTATUS_H