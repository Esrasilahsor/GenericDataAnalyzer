#ifndef IRAWDATASOURCE_H
#define IRAWDATASOURCE_H

#include "RawDataSourceResult.h"

class IRawDataSource
{
public:
    virtual ~IRawDataSource() = default;

    virtual RawDataSourceResult read() = 0;
};

#endif // IRAWDATASOURCE_H