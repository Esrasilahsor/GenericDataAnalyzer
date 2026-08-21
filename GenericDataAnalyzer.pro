QT += core gui qml quick charts

CONFIG += c++11

TEMPLATE = app
TARGET = GenericDataAnalyzer


# =========================================================
# SOURCES
# =========================================================

SOURCES += \
    analysis/EdaEngine.cpp \
    cleaning/CleaningEngine.cpp \
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
    visualization/VisualizationEngine.cpp \
    export/ExportEngine.cpp \
    raw/FileRawDataSource.cpp \


# =========================================================
# HEADERS
# =========================================================

HEADERS += \
    analysis/EdaEngine.h \
    backend/AppController.h \
    cleaning/CleaningEngine.h \
    models/ParameterModel.h \
    parser/ColumnInfo.h \
    parser/DataSet.h \
    parser/DataType.h \
    parser/ExcelParser.h \
    parser/ParserTypes.h \
    parser/ValidationResult.h \
    parser/MetadataValidator.h \
    parser/RawDataBuffer.h \
    parser/BitExtractor.h \
    parser/RawDataParser.h \
    models/ColumnModel.h \
    models/MappingModel.h \
    analysis/AnalysisEngine.h \
    analysis/Statistics.h \
    analysis/ComparisonEngine.h \
    visualization/VisualizationEngine.h \
    export/ExportEngine.h \
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