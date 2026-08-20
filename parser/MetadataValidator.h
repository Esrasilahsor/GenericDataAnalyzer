#ifndef METADATAVALIDATOR_H
#define METADATAVALIDATOR_H

#include "ParameterDefinition.h"
#include "ValidationResult.h"

class MetadataValidator
{
public:
    static ValidationResult validate(
        const ParameterDefinition &definition);

private:
    static void validateName(
        const ParameterDefinition &definition,
        ValidationResult &result);

    static void validateDataType(
        const ParameterDefinition &definition,
        ValidationResult &result);

    static void validateByteLayout(
        const ParameterDefinition &definition,
        ValidationResult &result);

    static void validateBitLayout(
        const ParameterDefinition &definition,
        ValidationResult &result);

    static void validateTypeLayoutCompatibility(
        const ParameterDefinition &definition,
        ValidationResult &result);

    static void validateNumericMetadata(
        const ParameterDefinition &definition,
        ValidationResult &result);
};

#endif // METADATAVALIDATOR_H