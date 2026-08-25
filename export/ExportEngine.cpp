#include "ExportEngine.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTextStream>

#include "xlsxdocument.h"

using namespace QXlsx;

ExportEngine::ExportEngine()
{
}

ExportResult ExportEngine::exportDataSetToCsv(
    const DataSet &dataSet,
    const QString &filePath
    ) const
{
    ExportResult result;
    result.filePath = filePath;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (filePath.trimmed().isEmpty())
    {
        result.errorMessage = QStringLiteral("Export file path is empty.");
        return result;
    }

    QFile file(filePath);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        result.errorMessage =
            QStringLiteral("CSV file could not be opened for writing.");
        return result;
    }

    QTextStream stream(&file);
    stream.setCodec("UTF-8");

    const QVector<ColumnInfo> columns = dataSet.columns();

    if (columns.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset contains no columns.");
        file.close();
        return result;
    }

    for (int columnIndex = 0; columnIndex < columns.size(); ++columnIndex)
    {
        if (columnIndex > 0)
            stream << ",";

        stream << normalizeCsvValue(columns.at(columnIndex).name());
    }

    stream << "\n";

    for (int row = 0; row < dataSet.rowCount(); ++row)
    {
        for (int columnIndex = 0; columnIndex < columns.size(); ++columnIndex)
        {
            if (columnIndex > 0)
                stream << ",";

            const QVector<QVariant> values =
                columns.at(columnIndex).values();

            QString value;

            if (row < values.size())
            {
                const QVariant &variant = values.at(row);

                if (variant.isValid() && !variant.isNull())
                    value = variant.toString();
            }

            stream << normalizeCsvValue(value);
        }

        stream << "\n";
    }

    file.close();
    result.success = true;

    return result;
}

ExportResult ExportEngine::exportDataSetToJson(
    const DataSet &dataSet,
    const QString &filePath
    ) const
{
    ExportResult result;
    result.filePath = filePath;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (filePath.trimmed().isEmpty())
    {
        result.errorMessage = QStringLiteral("Export file path is empty.");
        return result;
    }

    const QVector<ColumnInfo> columns = dataSet.columns();

    if (columns.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset contains no columns.");
        return result;
    }

    QJsonArray rowsArray;

    for (int row = 0; row < dataSet.rowCount(); ++row)
    {
        QJsonObject rowObject;

        for (const ColumnInfo &column : columns)
        {
            const QVector<QVariant> values = column.values();

            if (row >= values.size())
            {
                rowObject.insert(column.name(), QJsonValue::Null);
                continue;
            }

            const QVariant &value = values.at(row);

            if (!value.isValid() || value.isNull())
            {
                rowObject.insert(column.name(), QJsonValue::Null);
                continue;
            }

            if (value.type() == QVariant::Bool)
            {
                rowObject.insert(column.name(), value.toBool());
                continue;
            }

            bool numericOk = false;
            const double numericValue = value.toDouble(&numericOk);

            if (numericOk)
            {
                rowObject.insert(column.name(), numericValue);
                continue;
            }

            rowObject.insert(column.name(), value.toString());
        }

        rowsArray.append(rowObject);
    }

    QJsonObject rootObject;

    rootObject.insert(QStringLiteral("datasetName"), dataSet.name());
    rootObject.insert(QStringLiteral("sheetName"), dataSet.sheetName());
    rootObject.insert(QStringLiteral("rowCount"), dataSet.rowCount());
    rootObject.insert(QStringLiteral("columnCount"), dataSet.columnCount());
    rootObject.insert(QStringLiteral("rows"), rowsArray);

    QFile file(filePath);

    if (!file.open(QIODevice::WriteOnly))
    {
        result.errorMessage =
            QStringLiteral("JSON file could not be opened for writing.");
        return result;
    }

    file.write(
        QJsonDocument(rootObject).toJson(
            QJsonDocument::Indented
            )
        );

    file.close();
    result.success = true;

    return result;
}

ExportResult ExportEngine::exportDataSetToXlsx(
    const DataSet &dataSet,
    const QString &filePath
    ) const
{
    ExportResult result;

    if (dataSet.isEmpty())
    {
        result.errorMessage = QStringLiteral("Dataset is empty.");
        return result;
    }

    if (filePath.trimmed().isEmpty())
    {
        result.errorMessage = QStringLiteral("Export file path is empty.");
        return result;
    }

    const QVector<ColumnInfo> columns = dataSet.columns();

    if (columns.isEmpty())
    {
        result.errorMessage =
            QStringLiteral("Dataset contains no columns.");
        return result;
    }

    QString normalizedPath = filePath;

    if (!normalizedPath.endsWith(
            QStringLiteral(".xlsx"),
            Qt::CaseInsensitive))
    {
        normalizedPath += QStringLiteral(".xlsx");
    }

    result.filePath = normalizedPath;

    Document document;

    for (int columnIndex = 0; columnIndex < columns.size(); ++columnIndex)
    {
        document.write(
            1,
            columnIndex + 1,
            columns.at(columnIndex).name()
            );
    }

    for (int row = 0; row < dataSet.rowCount(); ++row)
    {
        for (int columnIndex = 0; columnIndex < columns.size(); ++columnIndex)
        {
            const QVector<QVariant> values =
                columns.at(columnIndex).values();

            QVariant value;

            if (row < values.size())
                value = values.at(row);

            document.write(
                row + 2,
                columnIndex + 1,
                value
                );
        }
    }

    if (!document.saveAs(normalizedPath))
    {
        result.errorMessage =
            QStringLiteral("Excel file could not be written.");
        return result;
    }

    result.success = true;

    return result;
}

QString ExportEngine::normalizeCsvValue(
    const QString &value
    ) const
{
    QString normalized = value;

    const bool needsQuotes =
        normalized.contains(',')
        ||
        normalized.contains('"')
        ||
        normalized.contains('\n')
        ||
        normalized.contains('\r');

    normalized.replace("\"", "\"\"");

    if (needsQuotes)
        normalized = "\"" + normalized + "\"";

    return normalized;
}