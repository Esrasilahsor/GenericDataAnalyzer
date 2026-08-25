#ifndef PARSEDPARAMETER_H
#define PARSEDPARAMETER_H

#include <QString>
#include <QStringList>
#include <QVariant>

#include "ParseStatus.h"
#include "ParameterDefinition.h"

struct ParsedParameter
{
    // -----------------------------------------------------
    // Parameter information
    // -----------------------------------------------------

    QString structName;
    QString packageOrDataName;
    QString dataName;

    QString dataType;
    QString unit;
    QString info;

    // -----------------------------------------------------
    // Parsed values
    // -----------------------------------------------------

    QVariant rawValue;
    QVariant value;

    QString displayValue;

    // -----------------------------------------------------
    // Parse state
    // -----------------------------------------------------

    ParseStatus status = ParseStatus::InternalError;

    QString errorMessage;
    QStringList warnings;

    bool parsedSuccessfully() const
    {
        return ParseStatusUtils::isSuccess(status);
    }

    bool hasError() const
    {
        return ParseStatusUtils::isError(status);
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
            createBase(definition);

        parameter.status = errorStatus;
        parameter.errorMessage = message;
        parameter.displayValue =
            QStringLiteral("ERROR");

        return parameter;
    }
};

#endif // PARSEDPARAMETER_H