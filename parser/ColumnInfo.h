#ifndef COLUMNINFO_H
#define COLUMNINFO_H

#include <QString>
#include <QVariant>
#include <QVector>

class ColumnInfo
{
public:
    enum class DataType
    {
        Unknown,
        Integer,
        Double,
        String,
        Boolean,
        DateTime
    };

    ColumnInfo();
    explicit ColumnInfo(const QString &name);

    QString name() const;
    void setName(const QString &name);

    QString originalName() const;
    void setOriginalName(const QString &originalName);

    DataType dataType() const;
    void setDataType(DataType type);

    QVector<QVariant> values() const;
    void setValues(const QVector<QVariant> &values);

    void addValue(const QVariant &value);

    int valueCount() const;

    int missingCount() const;
    void setMissingCount(int count);

    double missingPercentage() const;
    void setMissingPercentage(double percentage);

    int uniqueCount() const;
    void setUniqueCount(int count);

    bool isNumeric() const;

private:
    QString m_name;
    QString m_originalName;

    DataType m_dataType;

    QVector<QVariant> m_values;

    int m_missingCount;
    double m_missingPercentage;
    int m_uniqueCount;
};

#endif // COLUMNINFO_H