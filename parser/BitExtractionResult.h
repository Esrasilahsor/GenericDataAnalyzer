#ifndef BITEXTRACTIONRESULT_H
#define BITEXTRACTIONRESULT_H

#include <QString>
#include <QtGlobal>

struct BitExtractionResult
{
    bool success = false;

    quint64 value = 0;

    QString errorMessage;

    static BitExtractionResult ok(quint64 extractedValue)
    {
        BitExtractionResult result;
        result.success = true;
        result.value = extractedValue;
        return result;
    }

    static BitExtractionResult error(const QString &message)
    {
        BitExtractionResult result;
        result.success = false;
        result.value = 0;
        result.errorMessage = message;
        return result;
    }
};

#endif // BITEXTRACTIONRESULT_H