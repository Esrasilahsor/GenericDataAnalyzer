QT += core gui qml quick charts concurrent

CONFIG += c++11

TEMPLATE = app
TARGET = GenericDataAnalyzer

RC_ICONS = app_icon.ico


# =========================================================
# SOURCES
# =========================================================

SOURCES += \
    main.cpp \
    \
    backend/AppController.cpp \
    \
    session/SessionManager.cpp \
    \
    models/ParameterModel.cpp \
    models/ColumnModel.cpp \
    models/MappingModel.cpp \
    \
    parser/ColumnInfo.cpp \
    parser/DataSet.cpp \
    parser/DataType.cpp \
    parser/ExcelParser.cpp \
    parser/MetadataValidator.cpp \
    parser/RawDataBuffer.cpp \
    parser/BitExtractor.cpp \
    parser/RawDataParser.cpp \
    \
    analysis/EdaEngine.cpp \
    analysis/AnalysisEngine.cpp \
    analysis/Statistics.cpp \
    analysis/ComparisonEngine.cpp \
    \
    cleaning/CleaningEngine.cpp \
    \
    visualization/VisualizationEngine.cpp \
    \
    export/ExportEngine.cpp \
    \
    raw/FileRawDataSource.cpp \
    \
    workers/RawParserWorker.cpp \
    workers/CleaningWorker.cpp


# =========================================================
# HEADERS
# =========================================================

HEADERS += \
    backend/AppController.h \
    \
    session/SessionManager.h \
    \
    models/ParameterModel.h \
    models/ColumnModel.h \
    models/MappingModel.h \
    \
    parser/ColumnInfo.h \
    parser/DataSet.h \
    parser/DataType.h \
    parser/ExcelParser.h \
    parser/MetadataValidator.h \
    parser/ParameterDefinition.h \
    parser/ParseStatus.h \
    parser/ValidationResult.h \
    parser/BitExtractionResult.h \
    parser/RawDataBuffer.h \
    parser/BitExtractor.h \
    parser/ParsedParameter.h \
    parser/RawDataParser.h \
    parser/ParserTypes.h \
    \
    analysis/EdaEngine.h \
    analysis/AnalysisEngine.h \
    analysis/Statistics.h \
    analysis/ComparisonEngine.h \
    \
    cleaning/CleaningEngine.h \
    \
    visualization/VisualizationEngine.h \
    \
    export/ExportEngine.h \
    \
    raw/FileRawDataSource.h \
    raw/IRawDataSource.h \
    raw/RawDataSourceResult.h \
    \
    workers/RawParserWorker.h \
    workers/CleaningWorker.h


# =========================================================
# QML RESOURCES
# =========================================================

RESOURCES += \
    qml.qrc


# =========================================================
# QXlsx
# =========================================================

include($$PWD/QXlsx/QXlsx.pri)
