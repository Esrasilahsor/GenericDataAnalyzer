#include "RawDataParser.h"

#include "BitExtractor.h"
#include "MetadataValidator.h"

#include <cmath>
#include <limits>


// =========================================================
// SINGLE PACKET PARSE
// =========================================================

QList<ParsedParameter> RawDataParser::parse(
    const QByteArray &rawData,
    const QList<ParameterDefinition> &definitions) const
{
    QList<ParsedParameter> results;

    results.reserve(definitions.size());

    RawDataBuffer buffer(rawData);

    /*
     * Her metadata tanımı mevcut packet üzerinde
     * bağımsız olarak parse edilir.
     *
     * Bir parametre hata verdiğinde diğer parametrelerin
     * parse işlemi devam eder.
     */
    for (const ParameterDefinition &definition : definitions)
    {
        ParsedParameter parameter =
            parseParameter(
                definition,
                buffer);

        results.append(parameter);
    }

    return results;
}


// =========================================================
// MULTIPLE PACKET PARSE
// =========================================================

QList<QList<ParsedParameter>> RawDataParser::parsePackets(
    const QByteArray &rawData,
    const QList<ParameterDefinition> &definitions,
    int packetSize) const
{
    QList<QList<ParsedParameter>> allPackets;

    // -----------------------------------------------------
    // BASIC VALIDATION
    // -----------------------------------------------------

    if (rawData.isEmpty())
    {
        return allPackets;
    }

    if (definitions.isEmpty())
    {
        return allPackets;
    }

    if (packetSize <= 0)
    {
        return allPackets;
    }


    // -----------------------------------------------------
    // REQUIRED PACKET SIZE
    // -----------------------------------------------------

    const int requiredPacketSize =
        calculateRequiredPacketSize(
            definitions);

    /*
     * Metadata örneğin en az 16 byte gerektiriyorsa
     * packetSize 16'dan küçük olamaz.
     */
    if (requiredPacketSize <= 0 ||
        packetSize < requiredPacketSize)
    {
        return allPackets;
    }


    // -----------------------------------------------------
    // PACKET COUNT
    // -----------------------------------------------------

    /*
     * Örnek:
     *
     * rawData.size() = 800
     * packetSize     = 16
     *
     * 800 / 16 = 50 packet
     */
    const int packetCount =
        rawData.size() / packetSize;

    if (packetCount <= 0)
    {
        return allPackets;
    }

    allPackets.reserve(packetCount);


    // -----------------------------------------------------
    // PACKET LOOP
    // -----------------------------------------------------

    for (int packetIndex = 0;
         packetIndex < packetCount;
         ++packetIndex)
    {
        const int packetOffset =
            packetIndex * packetSize;

        const QByteArray packetData =
            rawData.mid(
                packetOffset,
                packetSize);

        /*
         * Güvenlik kontrolü.
         */
        if (packetData.size() != packetSize)
        {
            break;
        }

        /*
         * Tek packet parser'ı tekrar kullanıyoruz.
         *
         * Böylece integer, boolean, bit extraction,
         * resolution ve range kontrol kodlarını tekrar
         * yazmak zorunda kalmıyoruz.
         */
        const QList<ParsedParameter> parsedPacket =
            parse(
                packetData,
                definitions);

        allPackets.append(
            parsedPacket);
    }

    /*
     * Eğer rawData sonunda packetSize'dan küçük artık
     * byte varsa şu anda parse edilmiyor.
     *
     * Örnek:
     *
     * 805 byte raw
     * 16 byte packet
     *
     * 50 tam packet parse edilir,
     * son 5 byte ignore edilir.
     */

    return allPackets;
}


// =========================================================
// CALCULATE REQUIRED PACKET SIZE
// =========================================================

int RawDataParser::calculateRequiredPacketSize(
    const QList<ParameterDefinition> &definitions) const
{
    int requiredSize = 0;

    for (const ParameterDefinition &definition : definitions)
    {
        /*
         * Geçersiz metadata packet boyutu hesabını
         * bozmamalı.
         *
         * Asıl hata MetadataValidator tarafından
         * daha sonra raporlanır.
         */
        if (definition.byteOffset < 0)
        {
            continue;
        }

        if (definition.byteSize <= 0)
        {
            continue;
        }


        /*
         * Integer overflow koruması.
         */
        if (definition.byteOffset >
            std::numeric_limits<int>::max()
                - definition.byteSize)
        {
            continue;
        }


        const int parameterEnd =
            definition.byteOffset
            +
            definition.byteSize;

        if (parameterEnd > requiredSize)
        {
            requiredSize =
                parameterEnd;
        }
    }

    return requiredSize;
}


// =========================================================
// SINGLE PARAMETER
// =========================================================

ParsedParameter RawDataParser::parseParameter(
    const ParameterDefinition &definition,
    const RawDataBuffer &buffer) const
{
    /*
     * Raw data okunmadan önce metadata doğrulanır.
     */
    const ValidationResult validation =
        MetadataValidator::validate(
            definition);

    if (!validation.valid)
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidMetadata,
            validation.errorText());
    }


    ParsedParameter parameter;


    switch (definition.dataType)
    {
    case DataType::Boolean:

        parameter =
            parseBoolean(
                definition,
                buffer);

        break;


    case DataType::Int8:
    case DataType::Int16:
    case DataType::Int32:
    case DataType::UInt8:
    case DataType::UInt16:
    case DataType::UInt32:

        parameter =
            parseInteger(
                definition,
                buffer);

        break;


    case DataType::Float32:

        parameter =
            parseFloat32(
                definition,
                buffer);

        break;


    case DataType::Float64:

        parameter =
            parseFloat64(
                definition,
                buffer);

        break;


    case DataType::Unknown:
    default:

        return ParsedParameter::createError(
            definition,
            ParseStatus::UnsupportedType,
            QStringLiteral(
                "Unsupported data type."));
    }


    // -----------------------------------------------------
    // METADATA WARNINGS
    // -----------------------------------------------------

    for (const QString &warning : validation.warnings)
    {
        parameter.warnings.append(
            warning);
    }


    if (parameter.parsedSuccessfully() &&
        parameter.hasWarnings())
    {
        parameter.status =
            ParseStatus::Warning;
    }


    return parameter;
}


// =========================================================
// INTEGER
// =========================================================

ParsedParameter RawDataParser::parseInteger(
    const ParameterDefinition &definition,
    const RawDataBuffer &buffer) const
{
    ParsedParameter parameter =
        ParsedParameter::createBase(
            definition);


    const BitExtractionResult extraction =
        BitExtractor::extract(
            buffer,
            definition.byteOffset,
            definition.byteSize,
            definition.bitOffset,
            definition.bitSize,
            definition.endianness);


    if (!extraction.success)
    {
        parameter.status =
            ParseStatus::InsufficientData;

        parameter.errorMessage =
            extraction.errorMessage;

        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }


    const quint64 raw =
        extraction.value;


    // =====================================================
    // SIGNED INTEGER
    // =====================================================

    if (DataTypeUtils::isSignedInteger(
            definition.dataType))
    {
        qint64 signedValue = 0;

        QString errorMessage;


        if (!BitExtractor::signExtend(
                raw,
                definition.bitSize,
                signedValue,
                errorMessage))
        {
            parameter.status =
                ParseStatus::InvalidBitRange;

            parameter.errorMessage =
                errorMessage;

            parameter.displayValue =
                QStringLiteral("ERROR");

            return parameter;
        }


        parameter.rawValue =
            QVariant::fromValue<qint64>(
                signedValue);


        /*
         * Resolution = 1 ise integer tipini koruyoruz.
         */
        if (qFuzzyCompare(
                definition.resolution,
                1.0))
        {
            parameter.value =
                QVariant::fromValue<qint64>(
                    signedValue);

            parameter.displayValue =
                QString::number(
                    signedValue);

            parameter.status =
                ParseStatus::Ok;


            applyRangeCheck(
                parameter,
                definition,
                static_cast<double>(
                    signedValue));


            return parameter;
        }


        const double scaledValue =
            static_cast<double>(
                signedValue)
            *
            definition.resolution;


        if (!std::isfinite(
                scaledValue))
        {
            return ParsedParameter::createError(
                definition,
                ParseStatus::InvalidNumericValue,
                QStringLiteral(
                    "Scaled signed integer value "
                    "is not finite."));
        }


        parameter.value =
            scaledValue;

        parameter.displayValue =
            formatFloatingPoint(
                scaledValue);

        parameter.status =
            ParseStatus::Ok;


        applyRangeCheck(
            parameter,
            definition,
            scaledValue);


        return parameter;
    }


    // =====================================================
    // UNSIGNED INTEGER
    // =====================================================

    parameter.rawValue =
        QVariant::fromValue<qulonglong>(
            raw);


    if (qFuzzyCompare(
            definition.resolution,
            1.0))
    {
        parameter.value =
            QVariant::fromValue<qulonglong>(
                raw);

        parameter.displayValue =
            QString::number(
                raw);

        parameter.status =
            ParseStatus::Ok;


        applyRangeCheck(
            parameter,
            definition,
            static_cast<double>(
                raw));


        return parameter;
    }


    const double scaledValue =
        static_cast<double>(
            raw)
        *
        definition.resolution;


    if (!std::isfinite(
            scaledValue))
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidNumericValue,
            QStringLiteral(
                "Scaled unsigned integer value "
                "is not finite."));
    }


    parameter.value =
        scaledValue;

    parameter.displayValue =
        formatFloatingPoint(
            scaledValue);

    parameter.status =
        ParseStatus::Ok;


    applyRangeCheck(
        parameter,
        definition,
        scaledValue);


    return parameter;
}


// =========================================================
// BOOLEAN
// =========================================================

ParsedParameter RawDataParser::parseBoolean(
    const ParameterDefinition &definition,
    const RawDataBuffer &buffer) const
{
    ParsedParameter parameter =
        ParsedParameter::createBase(
            definition);


    const BitExtractionResult extraction =
        BitExtractor::extract(
            buffer,
            definition.byteOffset,
            definition.byteSize,
            definition.bitOffset,
            definition.bitSize,
            definition.endianness);


    if (!extraction.success)
    {
        parameter.status =
            ParseStatus::InsufficientData;

        parameter.errorMessage =
            extraction.errorMessage;

        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }


    const bool value =
        extraction.value != 0;


    parameter.rawValue =
        value;

    parameter.value =
        value;

    parameter.displayValue =
        value
            ? QStringLiteral("true")
            : QStringLiteral("false");

    parameter.status =
        ParseStatus::Ok;


    return parameter;
}


// =========================================================
// FLOAT 32
// =========================================================

ParsedParameter RawDataParser::parseFloat32(
    const ParameterDefinition &definition,
    const RawDataBuffer &buffer) const
{
    ParsedParameter parameter =
        ParsedParameter::createBase(
            definition);


    float rawValue = 0.0f;

    QString errorMessage;


    if (!buffer.readFloat32(
            definition.byteOffset,
            definition.endianness,
            rawValue,
            errorMessage))
    {
        parameter.status =
            ParseStatus::InsufficientData;

        parameter.errorMessage =
            errorMessage;

        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }


    if (!std::isfinite(
            static_cast<double>(
                rawValue)))
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidNumericValue,
            QStringLiteral(
                "Float32 value is NaN or Infinity."));
    }


    parameter.rawValue =
        rawValue;


    const double scaledValue =
        static_cast<double>(
            rawValue)
        *
        definition.resolution;


    if (!std::isfinite(
            scaledValue))
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidNumericValue,
            QStringLiteral(
                "Scaled Float32 value is "
                "NaN or Infinity."));
    }


    parameter.value =
        scaledValue;

    parameter.displayValue =
        formatFloatingPoint(
            scaledValue);

    parameter.status =
        ParseStatus::Ok;


    applyRangeCheck(
        parameter,
        definition,
        scaledValue);


    return parameter;
}


// =========================================================
// FLOAT 64
// =========================================================

ParsedParameter RawDataParser::parseFloat64(
    const ParameterDefinition &definition,
    const RawDataBuffer &buffer) const
{
    ParsedParameter parameter =
        ParsedParameter::createBase(
            definition);


    double rawValue = 0.0;

    QString errorMessage;


    if (!buffer.readFloat64(
            definition.byteOffset,
            definition.endianness,
            rawValue,
            errorMessage))
    {
        parameter.status =
            ParseStatus::InsufficientData;

        parameter.errorMessage =
            errorMessage;

        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }


    if (!std::isfinite(
            rawValue))
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidNumericValue,
            QStringLiteral(
                "Float64 value is NaN or Infinity."));
    }


    parameter.rawValue =
        rawValue;


    const double scaledValue =
        rawValue
        *
        definition.resolution;


    if (!std::isfinite(
            scaledValue))
    {
        return ParsedParameter::createError(
            definition,
            ParseStatus::InvalidNumericValue,
            QStringLiteral(
                "Scaled Float64 value is "
                "NaN or Infinity."));
    }


    parameter.value =
        scaledValue;

    parameter.displayValue =
        formatFloatingPoint(
            scaledValue);

    parameter.status =
        ParseStatus::Ok;


    applyRangeCheck(
        parameter,
        definition,
        scaledValue);


    return parameter;
}


// =========================================================
// RANGE CHECK
// =========================================================

void RawDataParser::applyRangeCheck(
    ParsedParameter &parameter,
    const ParameterDefinition &definition,
    double numericValue) const
{
    if (!definition.hasMinMax)
    {
        return;
    }


    if (!std::isfinite(
            numericValue))
    {
        parameter.status =
            ParseStatus::InvalidNumericValue;

        parameter.errorMessage =
            QStringLiteral(
                "Numeric value is not finite.");

        parameter.displayValue =
            QStringLiteral("ERROR");

        return;
    }


    if (numericValue <
        definition.minValue)
    {
        parameter.warnings.append(
            QStringLiteral(
                "Value %1 is below MIN_VALUE %2.")
                .arg(numericValue)
                .arg(definition.minValue));

        parameter.status =
            ParseStatus::Warning;

        return;
    }


    if (numericValue >
        definition.maxValue)
    {
        parameter.warnings.append(
            QStringLiteral(
                "Value %1 exceeds MAX_VALUE %2.")
                .arg(numericValue)
                .arg(definition.maxValue));

        parameter.status =
            ParseStatus::Warning;
    }
}


// =========================================================
// DISPLAY FORMAT
// =========================================================

QString RawDataParser::formatFloatingPoint(
    double value) const
{
    if (!std::isfinite(
            value))
    {
        return QStringLiteral(
            "ERROR");
    }


    return QString::number(
        value,
        'f',
        6);
}