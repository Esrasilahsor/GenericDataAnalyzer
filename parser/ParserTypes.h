#ifndef PARSERTYPES_H
#define PARSERTYPES_H

#include <QString>
#include <QStringList>
#include <QVariant>
#include <QtGlobal>

#include "DataType.h"


// =========================================================
// PARAMETER DEFINITION
// =========================================================

struct ParameterDefinition
{
    QString structName;
    QString packageOrDataName;
    QString dataName;

    int byteOffset = 0;
    int byteSize = 0;

    int bitOffset = 0;
    int bitSize = 0;

    QString dataTypeString;
    DataType dataType = DataType::Unknown;

    double minValue = 0.0;
    double maxValue = 0.0;
    double initialValue = 0.0;

    double resolution = 1.0;

    QString unit;
    QString info;

    Endianness endianness =
        Endianness::LittleEndian;

    bool hasMinMax = false;
};


// =========================================================
// PARSE STATUS
// =========================================================

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


// =========================================================
// PARSE STATUS UTILS
// =========================================================

namespace ParseStatusUtils
{

inline bool isSuccess(
    ParseStatus status)
{
    return status == ParseStatus::Ok ||
           status == ParseStatus::Warning;
}


inline bool isError(
    ParseStatus status)
{
    return !isSuccess(status);
}


inline QString toString(
    ParseStatus status)
{
    switch (status)
    {
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


// =========================================================
// BIT EXTRACTION RESULT
// =========================================================

struct BitExtractionResult
{
    bool success = false;

    quint64 value = 0;

    QString errorMessage;


    static BitExtractionResult ok(
        quint64 extractedValue)
    {
        BitExtractionResult result;

        result.success = true;
        result.value = extractedValue;

        return result;
    }


    static BitExtractionResult error(
        const QString &message)
    {
        BitExtractionResult result;

        result.success = false;
        result.value = 0;
        result.errorMessage = message;

        return result;
    }
};


// =========================================================
// PARSED PARAMETER
// =========================================================

struct ParsedParameter
{
    QString structName;
    QString packageOrDataName;
    QString dataName;

    QString dataType;
    QString unit;
    QString info;

    QVariant rawValue;
    QVariant value;

    QString displayValue;

    ParseStatus status =
        ParseStatus::InternalError;

    QString errorMessage;

    QStringList warnings;


    bool parsedSuccessfully() const
    {
        return ParseStatusUtils::isSuccess(
            status);
    }


    bool hasError() const
    {
        return ParseStatusUtils::isError(
            status);
    }


    bool hasWarnings() const
    {
        return !warnings.isEmpty();
    }


    static ParsedParameter createBase(
        const ParameterDefinition &definition)
    {
        ParsedParameter parameter;

        parameter.structName =
            definition.structName;

        parameter.packageOrDataName =
            definition.packageOrDataName;

        parameter.dataName =
            definition.dataName;

        parameter.dataType =
            DataTypeUtils::toString(
                definition.dataType);

        parameter.unit =
            definition.unit;

        parameter.info =
            definition.info;

        return parameter;
    }


    static ParsedParameter createError(
        const ParameterDefinition &definition,
        ParseStatus errorStatus,
        const QString &message)
    {
        ParsedParameter parameter =
            createBase(
                definition);

        parameter.status =
            errorStatus;

        parameter.errorMessage =
            message;

        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }
};


#endif // PARSERTYPES_H