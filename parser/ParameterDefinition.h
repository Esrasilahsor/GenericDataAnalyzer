#ifndef PARAMETERDEFINITION_H
#define PARAMETERDEFINITION_H

#include <QString>

#include "DataType.h"

struct ParameterDefinition
{
    QString structName;
    QString packageOrDataName;
    QString dataName;

    int byteOffset = 0;
    int byteSize = 0;

    int bitOffset = 0;
    int bitSize = 0;

    QString dataTypeString;
    DataType dataType = DataType::Unknown;

    double minValue = 0.0;
    double maxValue = 0.0;
    double initialValue = 0.0;

    double resolution = 1.0;

    QString unit;
    QString info;

    Endianness endianness = Endianness::LittleEndian;

    bool hasMinMax = false;
};

#endif // PARAMETERDEFINITION_H