#ifndef VALIDATIONRESULT_H
#define VALIDATIONRESULT_H

#include <QString>
#include <QStringList>

struct ValidationResult
{
    bool valid = true;

    QStringList errors;
    QStringList warnings;

    void addError(const QString &message)
    {
        valid = false;
        errors.append(message);
    }

    void addWarning(const QString &message)
    {
        warnings.append(message);
    }

    bool hasErrors() const
    {
        return !errors.isEmpty();
    }

    bool hasWarnings() const
    {
        return !warnings.isEmpty();
    }

    QString errorText() const
    {
        return errors.join(QStringLiteral("\n"));
    }

    QString warningText() const
    {
        return warnings.join(QStringLiteral("\n"));
    }
};

#endif // VALIDATIONRESULT_H