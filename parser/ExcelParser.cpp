#include "ExcelParser.h"

#include <QFileInfo>
#include <QSet>
#include <QHash>
#include <QVariant>
#include <QVector>
#include <QDate>
#include <QDateTime>
#include <QFile>
#include <QTextStream>

#include <cmath>

#include "DataType.h"
#include "MetadataValidator.h"

#include "xlsxdocument.h"
#include "xlsxworksheet.h"
#include "xlsxcellrange.h"

using namespace QXlsx;


// =========================================================
// HELPER FUNCTIONS
// =========================================================

namespace
{

ColumnInfo::DataType detectColumnDataType(
    const QVector<QVariant> &values);

QString normalizeHeader(const QString &header)
{
    QString result =
        header.trimmed().toUpper();

    result.replace(' ', '_');
    result.replace('-', '_');

    while (result.contains(QStringLiteral("__"))) {
        result.replace(
            QStringLiteral("__"),
            QStringLiteral("_"));
    }

    return result;
}


int findColumn(
    const QHash<QString, int> &headers,
    const QString &name)
{
    return headers.value(
        normalizeHeader(name),
        -1);
}


QString readOptionalString(
    Document &document,
    int row,
    int column)
{
    if (column <= 0)
        return QString();

    const QVariant value =
        document.read(row, column);

    if (!value.isValid())
        return QString();

    return value.toString().trimmed();
}


bool readRequiredInt(
    Document &document,
    int row,
    int column,
    const QString &fieldName,
    int &result,
    QString &errorMessage)
{
    result = 0;

    if (column <= 0) {
        errorMessage =
            QStringLiteral(
                "Required column '%1' was not found.")
                .arg(fieldName);

        return false;
    }

    const QVariant cellValue =
        document.read(row, column);

    if (!cellValue.isValid() ||
        cellValue.toString().trimmed().isEmpty()) {

        errorMessage =
            QStringLiteral(
                "%1 is empty.")
                .arg(fieldName);

        return false;
    }

    bool ok = false;

    const int parsed =
        cellValue.toString()
            .trimmed()
            .toInt(&ok);

    if (!ok) {
        errorMessage =
            QStringLiteral(
                "%1 must be an integer. Received: '%2'")
                .arg(fieldName)
                .arg(cellValue.toString());

        return false;
    }

    result = parsed;

    return true;
}


bool readOptionalDouble(
    Document &document,
    int row,
    int column,
    const QString &fieldName,
    double defaultValue,
    double &result,
    QString &errorMessage)
{
    result = defaultValue;

    if (column <= 0)
        return true;

    const QVariant cellValue =
        document.read(row, column);

    if (!cellValue.isValid() ||
        cellValue.toString().trimmed().isEmpty()) {

        return true;
    }

    bool ok = false;

    const double parsed =
        cellValue.toString()
            .trimmed()
            .toDouble(&ok);

    if (!ok ||
        !std::isfinite(parsed)) {

        errorMessage =
            QStringLiteral(
                "%1 must be a finite numeric value. Received: '%2'")
                .arg(fieldName)
                .arg(cellValue.toString());

        return false;
    }

    result = parsed;

    return true;
}


bool rowIsCompletelyEmpty(
    Document &document,
    int row,
    int columnCount)
{
    for (int column = 1;
         column <= columnCount;
         ++column) {

        const QVariant value =
            document.read(row, column);

        if (value.isValid() &&
            !value.toString().trimmed().isEmpty()) {

            return false;
        }
    }

    return true;
}



// =========================================================
// DELIMITED FILE HELPERS
// =========================================================

QChar detectDelimiter(
    const QString &line,
    const QString &suffix)
{
    if (suffix.compare(
            QStringLiteral("csv"),
            Qt::CaseInsensitive) == 0) {

        const int commaCount = line.count(',');
        const int semicolonCount = line.count(';');

        return semicolonCount > commaCount ? ';' : ',';
    }

    const QList<QChar> candidates = {
        '\t',
        ',',
        ';',
        '|'
    };

    QChar bestDelimiter = '\t';
    int bestCount = -1;

    for (const QChar delimiter : candidates) {
        const int count = line.count(delimiter);

        if (count > bestCount) {
            bestCount = count;
            bestDelimiter = delimiter;
        }
    }

    return bestDelimiter;
}


QStringList parseDelimitedLine(
    const QString &line,
    QChar delimiter)
{
    QStringList fields;
    QString currentField;

    bool insideQuotes = false;

    for (int i = 0;
         i < line.size();
         ++i) {

        const QChar character =
            line.at(i);

        if (character == '"') {

            if (insideQuotes &&
                i + 1 < line.size() &&
                line.at(i + 1) == '"') {

                currentField.append('"');
                ++i;
                continue;
            }

            insideQuotes = !insideQuotes;
            continue;
        }

        if (character == delimiter &&
            !insideQuotes) {

            fields.append(currentField);
            currentField.clear();
            continue;
        }

        currentField.append(character);
    }

    fields.append(currentField);

    return fields;
}


QVariant textToVariant(
    const QString &text)
{
    const QString trimmed =
        text.trimmed();

    if (trimmed.isEmpty())
        return QVariant();

    const QString lower =
        trimmed.toLower();

    if (lower == QStringLiteral("true"))
        return QVariant(true);

    if (lower == QStringLiteral("false"))
        return QVariant(false);

    bool integerOk = false;

    const qlonglong integerValue =
        trimmed.toLongLong(&integerOk);

    if (integerOk)
        return QVariant::fromValue(integerValue);

    bool doubleOk = false;

    const double doubleValue =
        trimmed.toDouble(&doubleOk);

    if (doubleOk &&
        std::isfinite(doubleValue)) {

        return QVariant(doubleValue);
    }

    const QDateTime dateTime =
        QDateTime::fromString(
            trimmed,
            Qt::ISODate);

    if (dateTime.isValid())
        return QVariant(dateTime);

    const QDate date =
        QDate::fromString(
            trimmed,
            Qt::ISODate);

    if (date.isValid())
        return QVariant(date);

    return QVariant(trimmed);
}


void finalizeColumnInfo(
    ColumnInfo &columnInfo,
    const QVector<QVariant> &values)
{
    int missingCount = 0;
    QSet<QString> uniqueValues;

    for (const QVariant &value : values) {

        const QString text =
            value.toString().trimmed();

        if (!value.isValid() ||
            value.isNull() ||
            text.isEmpty()) {

            ++missingCount;
            continue;
        }

        uniqueValues.insert(text);
    }

    columnInfo.setValues(values);
    columnInfo.setMissingCount(missingCount);
    columnInfo.setUniqueCount(uniqueValues.size());

    const int totalValues =
        values.size();

    const double missingPercentage =
        totalValues > 0
            ? (
                  static_cast<double>(missingCount)
                  /
                  static_cast<double>(totalValues)
                  ) * 100.0
            : 0.0;

    columnInfo.setMissingPercentage(
        missingPercentage);

    columnInfo.setDataType(
        detectColumnDataType(values));
}

// =========================================================
// COLUMN TYPE DETECTION
// =========================================================

ColumnInfo::DataType detectColumnDataType(
    const QVector<QVariant> &values)
{
    bool hasInteger = false;
    bool hasDouble = false;
    bool hasString = false;
    bool hasBoolean = false;
    bool hasDateTime = false;

    for (const QVariant &value : values) {

        if (!value.isValid() ||
            value.isNull()) {
            continue;
        }

        const QString text =
            value.toString().trimmed();

        if (text.isEmpty())
            continue;


        // -------------------------------------------------
        // DATETIME
        // -------------------------------------------------

        if (value.type() == QVariant::DateTime ||
            value.type() == QVariant::Date) {

            hasDateTime = true;
            continue;
        }


        // -------------------------------------------------
        // BOOLEAN
        // -------------------------------------------------

        const QString lower =
            text.toLower();

        if (lower == QStringLiteral("true") ||
            lower == QStringLiteral("false")) {

            hasBoolean = true;
            continue;
        }


        // -------------------------------------------------
        // INTEGER
        // -------------------------------------------------

        bool intOk = false;

        text.toLongLong(&intOk);

        if (intOk) {
            hasInteger = true;
            continue;
        }


        // -------------------------------------------------
        // DOUBLE
        // -------------------------------------------------

        bool doubleOk = false;

        text.toDouble(&doubleOk);

        if (doubleOk) {
            hasDouble = true;
            continue;
        }


        // -------------------------------------------------
        // STRING
        // -------------------------------------------------

        hasString = true;
    }


    /*
     * Mixed data varsa daha güvenli olan tip seçiliyor.
     *
     * String varsa tamamını string kabul ediyoruz.
     */
    if (hasString)
        return ColumnInfo::DataType::String;


    /*
     * Integer + Double varsa Double.
     */
    if (hasDouble)
        return ColumnInfo::DataType::Double;


    if (hasInteger)
        return ColumnInfo::DataType::Integer;


    if (hasBoolean)
        return ColumnInfo::DataType::Boolean;


    if (hasDateTime)
        return ColumnInfo::DataType::DateTime;


    return ColumnInfo::DataType::Unknown;
}

}


// =========================================================
// CONSTRUCTOR
// =========================================================

ExcelParser::ExcelParser()
{
}


// =========================================================
// NORMAL DATASET LOADING
// =========================================================

bool ExcelParser::loadFile(
    const QString &filePath)
{
    m_lastError.clear();
    m_dataSet.clear();

    const QFileInfo fileInfo(filePath);

    if (!fileInfo.exists() ||
        !fileInfo.isFile()) {

        m_lastError =
            QStringLiteral(
                "Dosya bulunamadı.");

        return false;
    }

    const QString suffix =
        fileInfo.suffix().toLower();

    if (suffix == QStringLiteral("xlsx"))
        return loadExcelDataSet(filePath);

    if (suffix == QStringLiteral("csv") ||
        suffix == QStringLiteral("txt"))
        return loadDelimitedDataSet(filePath);

    m_lastError =
        QStringLiteral(
            "Desteklenmeyen dosya formatı. "
            "Desteklenen formatlar: .xlsx, .csv, .txt");

    return false;
}


// =========================================================
// XLSX DATASET LOADING
// =========================================================

bool ExcelParser::loadExcelDataSet(
    const QString &filePath)
{
    const QFileInfo fileInfo(filePath);

    Document document(filePath);

    if (!document.load()) {

        m_lastError =
            QStringLiteral(
                "Excel dosyası açılamadı.");

        return false;
    }

    const QStringList sheets =
        document.sheetNames();

    if (sheets.isEmpty()) {

        m_lastError =
            QStringLiteral(
                "Excel dosyasında sheet bulunamadı.");

        return false;
    }

    const QString selectedSheet =
        sheets.first();

    if (!document.selectSheet(
            selectedSheet)) {

        m_lastError =
            QStringLiteral(
                "Excel sheet seçilemedi.");

        return false;
    }

    Worksheet *worksheet =
        dynamic_cast<Worksheet *>(
            document.currentWorksheet());

    if (!worksheet) {

        m_lastError =
            QStringLiteral(
                "Excel worksheet okunamadı.");

        return false;
    }

    const CellRange range =
        worksheet->dimension();

    const int rowCount =
        range.rowCount();

    const int columnCount =
        range.columnCount();

    if (rowCount <= 0 ||
        columnCount <= 0) {

        m_lastError =
            QStringLiteral(
                "Excel dosyası boş.");

        return false;
    }

    if (rowCount < 2) {

        m_lastError =
            QStringLiteral(
                "Excel dosyasında veri satırı bulunamadı.");

        return false;
    }

    m_dataSet.setName(
        fileInfo.baseName());

    m_dataSet.setFilePath(
        filePath);

    m_dataSet.setSheetName(
        selectedSheet);

    for (int columnIndex = 1;
         columnIndex <= columnCount;
         ++columnIndex) {

        QString columnName =
            document.read(
                        1,
                        columnIndex)
                .toString()
                .trimmed();

        if (columnName.isEmpty()) {
            columnName =
                QStringLiteral("Column_%1")
                    .arg(columnIndex);
        }

        QVector<QVariant> values;

        values.reserve(
            rowCount - 1);

        for (int rowIndex = 2;
             rowIndex <= rowCount;
             ++rowIndex) {

            values.append(
                document.read(
                    rowIndex,
                    columnIndex));
        }

        ColumnInfo columnInfo(
            columnName);

        columnInfo.setOriginalName(
            columnName);

        finalizeColumnInfo(
            columnInfo,
            values);

        m_dataSet.addColumn(
            columnInfo);
    }

    return true;
}


// =========================================================
// CSV / TXT DATASET LOADING
// =========================================================

bool ExcelParser::loadDelimitedDataSet(
    const QString &filePath)
{
    const QFileInfo fileInfo(filePath);

    QFile file(filePath);

    if (!file.open(
            QIODevice::ReadOnly |
            QIODevice::Text)) {

        m_lastError =
            QStringLiteral(
                "CSV/TXT dosyası açılamadı.");

        return false;
    }

    QTextStream stream(&file);

    stream.setCodec("UTF-8");

    QStringList lines;

    while (!stream.atEnd()) {

        QString line =
            stream.readLine();

        if (line.endsWith('\r'))
            line.chop(1);

        if (!line.trimmed().isEmpty())
            lines.append(line);
    }

    file.close();

    if (lines.isEmpty()) {

        m_lastError =
            QStringLiteral(
                "CSV/TXT dosyası boş.");

        return false;
    }

    if (lines.size() < 2) {

        m_lastError =
            QStringLiteral(
                "CSV/TXT dosyasında veri satırı bulunamadı.");

        return false;
    }

    const QChar delimiter =
        detectDelimiter(
            lines.first(),
            fileInfo.suffix());

    const QStringList headerFields =
        parseDelimitedLine(
            lines.first(),
            delimiter);

    if (headerFields.isEmpty()) {

        m_lastError =
            QStringLiteral(
                "CSV/TXT sütun başlıkları okunamadı.");

        return false;
    }

    const int columnCount =
        headerFields.size();

    QVector<QString> columnNames;
    columnNames.reserve(columnCount);

    QSet<QString> usedNames;

    for (int columnIndex = 0;
         columnIndex < columnCount;
         ++columnIndex) {

        QString columnName =
            headerFields.at(
                            columnIndex)
                .trimmed();

        if (columnName.isEmpty()) {
            columnName =
                QStringLiteral("Column_%1")
                    .arg(columnIndex + 1);
        }

        QString uniqueName =
            columnName;

        int duplicateIndex = 2;

        while (usedNames.contains(
            uniqueName)) {

            uniqueName =
                QStringLiteral("%1_%2")
                    .arg(columnName)
                    .arg(duplicateIndex);

            ++duplicateIndex;
        }

        usedNames.insert(uniqueName);
        columnNames.append(uniqueName);
    }

    QVector<QVector<QVariant>> columns;
    columns.resize(columnCount);

    for (int lineIndex = 1;
         lineIndex < lines.size();
         ++lineIndex) {

        const QStringList rowFields =
            parseDelimitedLine(
                lines.at(lineIndex),
                delimiter);

        for (int columnIndex = 0;
             columnIndex < columnCount;
             ++columnIndex) {

            if (columnIndex <
                rowFields.size()) {

                columns[columnIndex].append(
                    textToVariant(
                        rowFields.at(
                            columnIndex)));
            }
            else {
                columns[columnIndex].append(
                    QVariant());
            }
        }
    }

    m_dataSet.setName(
        fileInfo.baseName());

    m_dataSet.setFilePath(
        filePath);

    m_dataSet.setSheetName(
        QStringLiteral("N/A"));

    for (int columnIndex = 0;
         columnIndex < columnCount;
         ++columnIndex) {

        ColumnInfo columnInfo(
            columnNames.at(
                columnIndex));

        columnInfo.setOriginalName(
            headerFields.at(
                            columnIndex)
                .trimmed());

        finalizeColumnInfo(
            columnInfo,
            columns.at(
                columnIndex));

        m_dataSet.addColumn(
            columnInfo);
    }

    return true;
}


// =========================================================
// DATASET GETTER
// =========================================================

const DataSet &ExcelParser::dataSet() const
{
    return m_dataSet;
}


// =========================================================
// LAST ERROR
// =========================================================

QString ExcelParser::lastError() const
{
    return m_lastError;
}


// =========================================================
// PARAMETER METADATA LOADING
// =========================================================

QList<ParameterDefinition>
ExcelParser::loadParameterDefinitions(
    const QString &filePath,
    QStringList *errors,
    QStringList *warnings)
{
    QList<ParameterDefinition> definitions;


    if (errors)
        errors->clear();

    if (warnings)
        warnings->clear();


    // -----------------------------------------------------
    // FILE CHECK
    // -----------------------------------------------------

    const QFileInfo fileInfo(filePath);


    if (!fileInfo.exists() ||
        !fileInfo.isFile()) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "File does not exist: %1")
                    .arg(filePath));
        }

        return definitions;
    }


    if (fileInfo.suffix().compare(
            QStringLiteral("xlsx"),
            Qt::CaseInsensitive) != 0) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Unsupported file format. "
                    "Parameter metadata must be .xlsx."));
        }

        return definitions;
    }


    // -----------------------------------------------------
    // OPEN DOCUMENT
    // -----------------------------------------------------

    Document document(filePath);


    if (!document.load()) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Excel file could not be opened."));
        }

        return definitions;
    }


    const QStringList sheets =
        document.sheetNames();


    if (sheets.isEmpty()) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Excel file contains no worksheets."));
        }

        return definitions;
    }


    if (!document.selectSheet(
            sheets.first())) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Worksheet could not be selected."));
        }

        return definitions;
    }


    Worksheet *worksheet =
        dynamic_cast<Worksheet *>(
            document.currentWorksheet());


    if (!worksheet) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Current worksheet is invalid."));
        }

        return definitions;
    }


    const CellRange range =
        worksheet->dimension();


    const int rowCount =
        range.rowCount();

    const int columnCount =
        range.columnCount();


    if (columnCount <= 0) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Metadata sheet contains no columns."));
        }

        return definitions;
    }


    if (rowCount < 2) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Metadata sheet contains no data rows."));
        }

        return definitions;
    }


    // -----------------------------------------------------
    // HEADER MAP
    // -----------------------------------------------------

    QHash<QString, int> headers;


    for (int column = 1;
         column <= columnCount;
         ++column) {

        const QString originalHeader =
            document.read(
                        1,
                        column)
                .toString()
                .trimmed();


        if (originalHeader.isEmpty())
            continue;


        const QString normalized =
            normalizeHeader(
                originalHeader);


        if (headers.contains(
                normalized)) {

            if (warnings) {
                warnings->append(
                    QStringLiteral(
                        "Duplicate header '%1'. "
                        "First occurrence will be used.")
                        .arg(originalHeader));
            }

            continue;
        }


        headers.insert(
            normalized,
            column);
    }


    // -----------------------------------------------------
    // REQUIRED HEADERS
    // -----------------------------------------------------

    const QStringList requiredHeaders = {

    QStringLiteral("DATA_NAME"),
        QStringLiteral("BYTE_OFFSET"),
        QStringLiteral("BYTE_SIZE"),
        QStringLiteral("BIT_OFFSET"),
        QStringLiteral("BIT_SIZE"),
        QStringLiteral("DATA_TYPE")
};


bool missingRequiredHeader =
    false;


for (const QString &header :
     requiredHeaders) {

    if (!headers.contains(
            normalizeHeader(header))) {

        missingRequiredHeader =
            true;


        if (errors) {
            errors->append(
                QStringLiteral(
                    "Required Excel column '%1' is missing.")
                    .arg(header));
        }
    }
}


if (missingRequiredHeader)
    return definitions;


// -----------------------------------------------------
// COLUMN INDEXES
// -----------------------------------------------------

const int structNameColumn =
    findColumn(
        headers,
        QStringLiteral("STRUCT_NAME"));


const int packageNameColumn =
    findColumn(
        headers,
        QStringLiteral("PACKAGE_OR_DATA_NAME"));


const int dataNameColumn =
    findColumn(
        headers,
        QStringLiteral("DATA_NAME"));


const int byteOffsetColumn =
    findColumn(
        headers,
        QStringLiteral("BYTE_OFFSET"));


const int byteSizeColumn =
    findColumn(
        headers,
        QStringLiteral("BYTE_SIZE"));


const int bitOffsetColumn =
    findColumn(
        headers,
        QStringLiteral("BIT_OFFSET"));


const int bitSizeColumn =
    findColumn(
        headers,
        QStringLiteral("BIT_SIZE"));


const int dataTypeColumn =
    findColumn(
        headers,
        QStringLiteral("DATA_TYPE"));


const int minValueColumn =
    findColumn(
        headers,
        QStringLiteral("MIN_VALUE"));


const int maxValueColumn =
    findColumn(
        headers,
        QStringLiteral("MAX_VALUE"));


const int initialColumn =
    findColumn(
        headers,
        QStringLiteral("INITIAL"));


const int unitColumn =
    findColumn(
        headers,
        QStringLiteral("UNIT"));


const int infoColumn =
    findColumn(
        headers,
        QStringLiteral("INFO"));


const int resolutionColumn =
    findColumn(
        headers,
        QStringLiteral("RESOLUTION"));


// -----------------------------------------------------
// ROW LOOP
// -----------------------------------------------------

for (int row = 2;
     row <= rowCount;
     ++row) {


    if (rowIsCompletelyEmpty(
            document,
            row,
            columnCount)) {

        continue;
    }


    ParameterDefinition definition;


    // -------------------------------------------------
    // STRINGS
    // -------------------------------------------------

    definition.dataName =
        readOptionalString(
            document,
            row,
            dataNameColumn);


    definition.structName =
        readOptionalString(
            document,
            row,
            structNameColumn);


    definition.packageOrDataName =
        readOptionalString(
            document,
            row,
            packageNameColumn);


    definition.unit =
        readOptionalString(
            document,
            row,
            unitColumn);


    definition.info =
        readOptionalString(
            document,
            row,
            infoColumn);


    // -------------------------------------------------
    // DATA TYPE
    // -------------------------------------------------

    definition.dataTypeString =
        readOptionalString(
            document,
            row,
            dataTypeColumn);


    definition.dataType =
        DataTypeUtils::fromString(
            definition.dataTypeString);


    definition.endianness =
        Endianness::LittleEndian;


    QString rowError;


    // -------------------------------------------------
    // BYTE OFFSET
    // -------------------------------------------------

    if (!readRequiredInt(
            document,
            row,
            byteOffsetColumn,
            QStringLiteral("BYTE_OFFSET"),
            definition.byteOffset,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(
                        definition.dataName.isEmpty()
                            ? QStringLiteral("<unnamed>")
                            : definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // BYTE SIZE
    // -------------------------------------------------

    if (!readRequiredInt(
            document,
            row,
            byteSizeColumn,
            QStringLiteral("BYTE_SIZE"),
            definition.byteSize,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // BIT OFFSET
    // -------------------------------------------------

    if (!readRequiredInt(
            document,
            row,
            bitOffsetColumn,
            QStringLiteral("BIT_OFFSET"),
            definition.bitOffset,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // BIT SIZE
    // -------------------------------------------------

    if (!readRequiredInt(
            document,
            row,
            bitSizeColumn,
            QStringLiteral("BIT_SIZE"),
            definition.bitSize,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // RESOLUTION
    // -------------------------------------------------

    if (!readOptionalDouble(
            document,
            row,
            resolutionColumn,
            QStringLiteral("RESOLUTION"),
            1.0,
            definition.resolution,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // INITIAL
    // -------------------------------------------------

    if (!readOptionalDouble(
            document,
            row,
            initialColumn,
            QStringLiteral("INITIAL"),
            0.0,
            definition.initialValue,
            rowError)) {

        if (errors) {
            errors->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(rowError));
        }

        continue;
    }


    // -------------------------------------------------
    // MIN / MAX EXISTENCE
    // -------------------------------------------------

    bool hasMin = false;
    bool hasMax = false;


    if (minValueColumn > 0) {

        hasMin =
            !document.read(
                         row,
                         minValueColumn)
                 .toString()
                 .trimmed()
                 .isEmpty();
    }


    if (maxValueColumn > 0) {

        hasMax =
            !document.read(
                         row,
                         maxValueColumn)
                 .toString()
                 .trimmed()
                 .isEmpty();
    }


    // -------------------------------------------------
    // ONLY ONE PROVIDED
    // -------------------------------------------------

    if (hasMin != hasMax) {

        definition.hasMinMax =
            false;


        if (warnings) {
            warnings->append(
                QStringLiteral(
                    "Row %1 (%2): MIN_VALUE and MAX_VALUE "
                    "must both exist. Range check disabled.")
                    .arg(row)
                    .arg(definition.dataName));
        }
    }


    // -------------------------------------------------
    // BOTH PROVIDED
    // -------------------------------------------------

    else if (hasMin &&
             hasMax) {

        double minValue = 0.0;
        double maxValue = 0.0;

        QString minError;
        QString maxError;


        const bool minOk =
            readOptionalDouble(
                document,
                row,
                minValueColumn,
                QStringLiteral("MIN_VALUE"),
                0.0,
                minValue,
                minError);


        const bool maxOk =
            readOptionalDouble(
                document,
                row,
                maxValueColumn,
                QStringLiteral("MAX_VALUE"),
                0.0,
                maxValue,
                maxError);


        if (!minOk ||
            !maxOk) {

            if (errors) {
                errors->append(
                    QStringLiteral(
                        "Row %1 (%2): %3")
                        .arg(row)
                        .arg(definition.dataName)
                        .arg(
                            !minOk
                                ? minError
                                : maxError));
            }

            continue;
        }


        definition.minValue =
            minValue;

        definition.maxValue =
            maxValue;

        definition.hasMinMax =
            true;
    }


    // -------------------------------------------------
    // FINAL VALIDATION
    // -------------------------------------------------

    const ValidationResult validation =
        MetadataValidator::validate(
            definition);


    if (!validation.valid) {

        if (errors) {

            for (const QString &message :
                 validation.errors) {

                errors->append(
                    QStringLiteral(
                        "Row %1 (%2): %3")
                        .arg(row)
                        .arg(
                            definition.dataName.isEmpty()
                                ? QStringLiteral("<unnamed>")
                                : definition.dataName)
                        .arg(message));
            }
        }

        continue;
    }


    // -------------------------------------------------
    // VALIDATION WARNINGS
    // -------------------------------------------------

    if (warnings) {

        for (const QString &message :
             validation.warnings) {

            warnings->append(
                QStringLiteral(
                    "Row %1 (%2): %3")
                    .arg(row)
                    .arg(definition.dataName)
                    .arg(message));
        }
    }


    // -------------------------------------------------
    // VALID DEFINITION
    // -------------------------------------------------

    definitions.append(
        definition);
}


return definitions;
}