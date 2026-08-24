#include "MetadataValidator.h"

#include <QtGlobal>

#include <cmath>
#include <limits>

ValidationResult MetadataValidator::validate(
    const ParameterDefinition &definition)
{
    ValidationResult result;

    validateName(definition, result);
    validateDataType(definition, result);
    validateByteLayout(definition, result);
    validateBitLayout(definition, result);

    // Data type bilinmiyorsa tip ile bit alanı karşılaştırması
    // anlamlı olmayacağı için ayrıca kontrol ediyoruz.
    if (DataTypeUtils::isSupported(definition.dataType)) {
        validateTypeLayoutCompatibility(definition, result);
    }

    validateNumericMetadata(definition, result);

    return result;
}

void MetadataValidator::validateName(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (definition.dataName.trimmed().isEmpty()) {
        result.addError(
            QStringLiteral("DATA_NAME cannot be empty."));
    }
}

void MetadataValidator::validateDataType(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (definition.dataType == DataType::Unknown) {

        QString typeText = definition.dataTypeString.trimmed();

        if (typeText.isEmpty())
            typeText = QStringLiteral("<empty>");

        result.addError(
            QStringLiteral("Unsupported DATA_TYPE: %1")
                .arg(typeText));
    }
}

void MetadataValidator::validateByteLayout(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (definition.byteOffset < 0) {
        result.addError(
            QStringLiteral(
                "BYTE_OFFSET cannot be negative."));
    }

    if (definition.byteSize <= 0) {
        result.addError(
            QStringLiteral(
                "BYTE_SIZE must be greater than zero."));
    }

    /*
     * Parser çekirdeğimiz quint64 kullanacak.
     * Bu nedenle tek extraction penceresinde maksimum
     * 8 byte destekleyeceğiz.
     *
     * Daha büyük paketlerin kendisi desteklenebilir.
     * Buradaki sınır yalnızca tek parametrenin extraction
     * window boyutudur.
     */
    if (definition.byteSize > 8) {
        result.addError(
            QStringLiteral(
                "BYTE_SIZE cannot be greater than 8 bytes."));
    }
}

void MetadataValidator::validateBitLayout(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (definition.bitOffset < 0) {
        result.addError(
            QStringLiteral(
                "BIT_OFFSET cannot be negative."));
    }

    if (definition.bitSize <= 0) {
        result.addError(
            QStringLiteral(
                "BIT_SIZE must be greater than zero."));
    }

    if (definition.bitSize > 64) {
        result.addError(
            QStringLiteral(
                "BIT_SIZE cannot be greater than 64."));
    }

    /*
     * Bundan sonraki hesapları ancak temel değerler
     * mantıklıysa yapıyoruz.
     */
    if (definition.byteSize <= 0 ||
        definition.byteSize > 8 ||
        definition.bitOffset < 0 ||
        definition.bitSize <= 0 ||
        definition.bitSize > 64) {
        return;
    }

    const int availableBits =
        definition.byteSize * 8;

    if (definition.bitOffset >= availableBits) {
        result.addError(
            QStringLiteral(
                "BIT_OFFSET (%1) is outside the %2-bit byte window.")
                .arg(definition.bitOffset)
                .arg(availableBits));

        return;
    }

    /*
     * Bilerek:
     *
     * bitOffset + bitSize > availableBits
     *
     * yazmıyoruz.
     *
     * Bunun yerine çıkartma kullanıyoruz. Böylece ileride
     * integer overflow ihtimalini de azaltmış oluyoruz.
     */
    const int remainingBits =
        availableBits - definition.bitOffset;

    if (definition.bitSize > remainingBits) {
        result.addError(
            QStringLiteral(
                "BIT_SIZE (%1) does not fit after BIT_OFFSET (%2). "
                "Only %3 bits are available.")
                .arg(definition.bitSize)
                .arg(definition.bitOffset)
                .arg(remainingBits));
    }
}

void MetadataValidator::validateTypeLayoutCompatibility(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (definition.bitSize <= 0 ||
        definition.byteSize <= 0) {
        return;
    }

    const int nativeBits =
        DataTypeUtils::nativeBitSize(definition.dataType);

    if (nativeBits <= 0)
        return;

    /*
     * Integer tiplerde bit-field kullanımına izin veriyoruz.
     *
     * Örneğin:
     *
     * uint16
     * BIT_OFFSET = 4
     * BIT_SIZE   = 12
     *
     * geçerli olabilir.
     */
    if (DataTypeUtils::isInteger(definition.dataType)) {

        if (definition.bitSize > nativeBits) {
            result.addError(
                QStringLiteral(
                    "BIT_SIZE (%1) exceeds the native size "
                    "of DATA_TYPE %2 (%3 bits).")
                    .arg(definition.bitSize)
                    .arg(DataTypeUtils::toString(definition.dataType))
                    .arg(nativeBits));
        }

        return;
    }

    if (DataTypeUtils::isBoolean(definition.dataType)) {

        if (definition.bitSize != 1) {
            result.addError(
                QStringLiteral(
                    "Boolean parameters must use BIT_SIZE = 1."));
        }

        return;
    }

    /*
     * Float/double alanlarını şimdilik yalnızca
     * byte-aligned standalone değerler olarak kabul ediyoruz.
     *
     * Bit-field float yorumlamak istemiyoruz.
     */
    if (DataTypeUtils::isFloatingPoint(definition.dataType)) {

        const int requiredBytes =
            nativeBits / 8;

        if (definition.bitOffset != 0) {
            result.addError(
                QStringLiteral(
                    "Floating-point parameters must have BIT_OFFSET = 0."));
        }

        if (definition.bitSize != nativeBits) {
            result.addError(
                QStringLiteral(
                    "%1 requires BIT_SIZE = %2.")
                    .arg(DataTypeUtils::toString(definition.dataType))
                    .arg(nativeBits));
        }

        if (definition.byteSize != requiredBytes) {
            result.addError(
                QStringLiteral(
                    "%1 requires BYTE_SIZE = %2.")
                    .arg(DataTypeUtils::toString(definition.dataType))
                    .arg(requiredBytes));
        }
    }
}

void MetadataValidator::validateNumericMetadata(
    const ParameterDefinition &definition,
    ValidationResult &result)
{
    if (!std::isfinite(definition.resolution)) {
        result.addError(
            QStringLiteral(
                "RESOLUTION must be a finite number."));
    }
    else if (qFuzzyIsNull(definition.resolution)) {
        result.addWarning(
            QStringLiteral(
                "RESOLUTION is zero. All scaled values will become zero."));
    }

    if (!std::isfinite(definition.initialValue)) {
        result.addError(
            QStringLiteral(
                "INITIAL must be a finite number."));
    }

    if (!definition.hasMinMax)
        return;

    if (!std::isfinite(definition.minValue)) {
        result.addError(
            QStringLiteral(
                "MIN_VALUE must be a finite number."));
    }

    if (!std::isfinite(definition.maxValue)) {
        result.addError(
            QStringLiteral(
                "MAX_VALUE must be a finite number."));
    }

    if (!std::isfinite(definition.minValue) ||
        !std::isfinite(definition.maxValue)) {
        return;
    }

    if (definition.minValue > definition.maxValue) {
        result.addError(
            QStringLiteral(
                "MIN_VALUE cannot be greater than MAX_VALUE."));
        return;
    }

    if (std::isfinite(definition.initialValue)) {

        if (definition.initialValue < definition.minValue ||
            definition.initialValue > definition.maxValue) {

            result.addWarning(
                QStringLiteral(
                    "INITIAL value is outside the configured "
                    "MIN_VALUE / MAX_VALUE range."));
        }
    }
}