QT += core gui qml quick

CONFIG += c++11

TEMPLATE = app
TARGET = GenericDataAnalyzer


# =========================================================
# SOURCES
# =========================================================

SOURCES += \
    main.cpp \
    backend/AppController.cpp \
    models/ParameterModel.cpp \
    parser/ColumnInfo.cpp \
    parser/DataSet.cpp \
    parser/DataType.cpp \
    parser/ExcelParser.cpp \
    parser/MetadataValidator.cpp \
    parser/RawDataBuffer.cpp \
    parser/BitExtractor.cpp \
    parser/RawDataParser.cpp \
    models/ColumnModel.cpp \
    models/MappingModel.cpp \
    analysis/AnalysisEngine.cpp \
    analysis/Statistics.cpp \
    analysis/ComparisonEngine.cpp \
    raw/FileRawDataSource.cpp \

# =========================================================
# HEADERS
# =========================================================

HEADERS += \
    backend/AppController.h \
    models/ParameterModel.h \
    parser/ColumnInfo.h \
    parser/DataSet.h \
    parser/DataType.h \
    parser/ExcelParser.h \
    parser/ParameterDefinition.h \
    parser/ParseStatus.h \
    parser/ValidationResult.h \
    parser/MetadataValidator.h \
    parser/BitExtractionResult.h \
    parser/RawDataBuffer.h \
    parser/BitExtractor.h \
    parser/ParseStatus.h \
    parser/ParsedParameter.h \
    parser/RawDataParser.h \
    models/ColumnModel.h \
    models/MappingModel.h \
    analysis/AnalysisEngine.h \
    analysis/Statistics.h \
    analysis/ComparisonEngine.h \
    raw/FileRawDataSource.h \
    raw/IRawDataSource.h \
    raw/RawDataSourceResult.h \


# =========================================================
# QML RESOURCES
# =========================================================

RESOURCES += \
    qml.qrc


# =========================================================
# QXlsx
# =========================================================

include($$PWD/QXlsx/QXlsx.pri)