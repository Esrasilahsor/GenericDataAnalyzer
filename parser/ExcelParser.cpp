#include "ExcelParser.h"

#include <QFileInfo>
#include <QSet>
#include <QDate>
#include <QDateTime>

#include "xlsxdocument.h"
#include "xlsxworksheet.h"
#include "xlsxcellrange.h"

using namespace QXlsx;

ExcelParser::ExcelParser()
{
}

bool ExcelParser::loadFile(const QString &filePath)
{
    m_lastError.clear();
    m_dataSet.clear();

    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists())
    {
        m_lastError = "Dosya bulunamadı.";
        return false;
    }

    if (fileInfo.suffix().toLower() != "xlsx")
    {
        m_lastError = "Desteklenmeyen dosya formatı. Şimdilik sadece .xlsx destekleniyor.";
        return false;
    }

    Document document(filePath);

    if (!document.load())
    {
        m_lastError = "Excel dosyası açılamadı.";
        return false;
    }

    QStringList sheetNames = document.sheetNames();

    if (sheetNames.isEmpty())
    {
        m_lastError = "Excel dosyasında sheet bulunamadı.";
        return false;
    }

    QString firstSheet = sheetNames.first();

    if (!document.selectSheet(firstSheet))
    {
        m_lastError = "Excel sheet seçilemedi.";
        return false;
    }

    Worksheet *worksheet =
        dynamic_cast<Worksheet *>(document.currentWorksheet());

    if (!worksheet)
    {
        m_lastError = "Worksheet okunamadı.";
        return false;
    }

    CellRange range = worksheet->dimension();

    int firstRow = range.firstRow();
    int lastRow = range.lastRow();

    int firstColumn = range.firstColumn();
    int lastColumn = range.lastColumn();

    if (lastRow < firstRow || lastColumn < firstColumn)
    {
        m_lastError = "Excel dosyası boş.";
        return false;
    }

    /*
     * İlk satırı header olarak kabul ediyoruz.
     *
     * Örneğin:
     *
     * Temperature | RPM | Status
     * 80.5        | 2400| ON
     * 82.0        | 2450| OFF
     */

    QVector<ColumnInfo> columns;

    for (int columnIndex = firstColumn;
         columnIndex <= lastColumn;
         ++columnIndex)
    {
        QVariant headerValue =
            worksheet->read(firstRow, columnIndex);

        QString columnName =
            headerValue.toString().trimmed();

        if (columnName.isEmpty())
        {
            columnName =
                QString("Column_%1").arg(columnIndex);
        }

        ColumnInfo column(columnName);

        column.setOriginalName(columnName);

        QVector<QVariant> values;

        for (int rowIndex = firstRow + 1;
             rowIndex <= lastRow;
             ++rowIndex)
        {
            QVariant value =
                worksheet->read(rowIndex, columnIndex);

            values.append(value);
        }

        column.setValues(values);

        ColumnInfo::DataType detectedType =
            detectColumnType(values);

        column.setDataType(detectedType);

        int missingCount =
            calculateMissingCount(values);

        column.setMissingCount(missingCount);

        double missingPercentage = 0.0;

        if (!values.isEmpty())
        {
            missingPercentage =
                (static_cast<double>(missingCount)
                 / values.size())
                * 100.0;
        }

        column.setMissingPercentage(
            missingPercentage);

        column.setUniqueCount(
            calculateUniqueCount(values));

        columns.append(column);
    }

    m_dataSet.setName(fileInfo.fileName());

    m_dataSet.setFilePath(
        fileInfo.absoluteFilePath());

    m_dataSet.setSheetName(firstSheet);

    m_dataSet.setColumns(columns);

    return true;
}

DataSet ExcelParser::dataSet() const
{
    return m_dataSet;
}

QString ExcelParser::lastError() const
{
    return m_lastError;
}

ColumnInfo::DataType ExcelParser::detectColumnType(
    const QVector<QVariant> &values) const
{
    bool hasInteger = false;
    bool hasDouble = false;
    bool hasString = false;
    bool hasBoolean = false;
    bool hasDateTime = false;

    for (const QVariant &value : values)
    {
        if (isMissingValue(value))
        {
            continue;
        }

        switch (value.type())
        {

        case QVariant::Int:
        case QVariant::LongLong:
        case QVariant::UInt:
        case QVariant::ULongLong:

            hasInteger = true;
            break;


        case QVariant::Double:

            hasDouble = true;
            break;


        case QVariant::Bool:

            hasBoolean = true;
            break;


        case QVariant::Date:
        case QVariant::DateTime:
        case QVariant::Time:

            hasDateTime = true;
            break;


        default:

            hasString = true;
            break;
        }
    }

    /*
     * String varsa sütunu String kabul ediyoruz.
     *
     * Örnek:
     *
     * 80
     * 82
     * ERROR
     *
     * Bu sütun artık saf numeric değildir.
     */

    if (hasString)
    {
        return ColumnInfo::DataType::String;
    }

    /*
     * Integer ve Double birlikte varsa
     * Double kabul ediyoruz.
     *
     * Örnek:
     *
     * 80
     * 81.5
     * 82
     */

    if (hasDouble)
    {
        return ColumnInfo::DataType::Double;
    }

    if (hasInteger)
    {
        return ColumnInfo::DataType::Integer;
    }

    if (hasBoolean)
    {
        return ColumnInfo::DataType::Boolean;
    }

    if (hasDateTime)
    {
        return ColumnInfo::DataType::DateTime;
    }

    return ColumnInfo::DataType::Unknown;
}

bool ExcelParser::isMissingValue(
    const QVariant &value) const
{
    if (!value.isValid())
    {
        return true;
    }

    if (value.isNull())
    {
        return true;
    }

    if (value.type() == QVariant::String)
    {
        QString text =
            value.toString().trimmed();

        if (text.isEmpty())
        {
            return true;
        }

        QString lower =
            text.toLower();

        if (lower == "null"
            || lower == "nan"
            || lower == "na"
            || lower == "n/a")
        {
            return true;
        }
    }

    return false;
}

int ExcelParser::calculateMissingCount(
    const QVector<QVariant> &values) const
{
    int count = 0;

    for (const QVariant &value : values)
    {
        if (isMissingValue(value))
        {
            ++count;
        }
    }

    return count;
}

int ExcelParser::calculateUniqueCount(
    const QVector<QVariant> &values) const
{
    QSet<QString> uniqueValues;

    for (const QVariant &value : values)
    {
        if (isMissingValue(value))
        {
            continue;
        }

        uniqueValues.insert(
            value.toString());
    }

    return uniqueValues.size();
}