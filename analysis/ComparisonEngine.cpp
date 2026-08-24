#include "ComparisonEngine.h"

#include <algorithm>
#include <QSet>
#include <QStringList>

ComparisonEngine::ComparisonEngine()
{
}

QVector<ColumnMapping> ComparisonEngine::suggestMappings(
    const DataSet &sourceDataSet,
    const DataSet &targetDataSet
    ) const
{
    QVector<ColumnMapping> mappings;

    const QVector<ColumnInfo> sourceColumns =
        sourceDataSet.columns();

    const QVector<ColumnInfo> targetColumns =
        targetDataSet.columns();

    /*
     * Daha önce eşleşmiş target sütunları burada tutuyoruz.
     *
     * Böylece aynı Dataset 2 sütunu birden fazla kez
     * otomatik önerilmeyecek.
     */
    QSet<int> usedTargetIndexes;

    /*
     * Bunun altındaki skorları gerçek bir eşleşme
     * olarak kabul etmiyoruz.
     */
    const double minimumSimilarityThreshold = 35.0;

    for (const ColumnInfo &sourceColumn : sourceColumns)
    {
        int bestTargetIndex = -1;
        double bestScore = 0.0;

        for (int targetIndex = 0;
             targetIndex < targetColumns.size();
             ++targetIndex)
        {
            /*
             * Bu target sütun daha önce kullanıldıysa
             * tekrar kullanmıyoruz.
             */
            if (usedTargetIndexes.contains(targetIndex))
            {
                continue;
            }

            const ColumnInfo &targetColumn =
                targetColumns.at(targetIndex);

            double score = calculateSimilarity(
                sourceColumn.name(),
                targetColumn.name()
                );

            /*
             * Veri tipi uyumluluğunu skora dahil ediyoruz.
             */
            score = applyTypeCompatibilityBonus(
                score,
                sourceColumn.dataType(),
                targetColumn.dataType()
                );

            if (score > bestScore)
            {
                bestScore = score;
                bestTargetIndex = targetIndex;
            }
        }

        ColumnMapping mapping;

        mapping.sourceColumn =
            sourceColumn.name();

        mapping.accepted = false;

        /*
         * Skor eşik değerin altındaysa eşleşme önermiyoruz.
         */
        if (bestTargetIndex >= 0
            && bestScore >= minimumSimilarityThreshold)
        {
            mapping.targetColumn =
                targetColumns
                    .at(bestTargetIndex)
                    .name();

            mapping.similarityScore =
                bestScore;

            usedTargetIndexes.insert(
                bestTargetIndex
                );
        }
        else
        {
            mapping.targetColumn =
                QString();

            mapping.similarityScore =
                bestScore;
        }

        mappings.append(mapping);
    }

    return mappings;
}

double ComparisonEngine::calculateSimilarity(
    const QString &source,
    const QString &target
    ) const
{
    QString normalizedSource =
        normalizeColumnName(source);

    QString normalizedTarget =
        normalizeColumnName(target);

    if (normalizedSource.isEmpty()
        || normalizedTarget.isEmpty())
    {
        return 0.0;
    }

    /*
     * Normalize edildikten sonra aynı isimler.
     *
     * Engine_Temp
     * Engine Temp
     *
     * gibi.
     */
    if (normalizedSource == normalizedTarget)
    {
        return 100.0;
    }

    double levenshteinScore =
        calculateLevenshteinSimilarity(
            normalizedSource,
            normalizedTarget
            );

    double tokenScore =
        calculateTokenSimilarity(
            source,
            target
            );

    /*
     * Karakter benzerliğini daha yüksek ağırlıkta
     * değerlendiriyoruz.
     */
    double finalScore =
        (levenshteinScore * 0.70)
        +
        (tokenScore * 0.30);

    /*
     * Bir isim diğerini içeriyorsa küçük bir bonus.
     *
     * Pressure
     * OilPressure
     */
    if (normalizedSource.contains(normalizedTarget)
        || normalizedTarget.contains(normalizedSource))
    {
        finalScore += 10.0;
    }

    if (finalScore > 100.0)
    {
        finalScore = 100.0;
    }

    if (finalScore < 0.0)
    {
        finalScore = 0.0;
    }

    return finalScore;
}

QString ComparisonEngine::normalizeColumnName(
    const QString &columnName
    ) const
{
    QString normalized =
        columnName.toLower().trimmed();

    /*
     * Türkçe karakter normalizasyonu.
     */
    normalized.replace("ç", "c");
    normalized.replace("ğ", "g");
    normalized.replace("ı", "i");
    normalized.replace("ö", "o");
    normalized.replace("ş", "s");
    normalized.replace("ü", "u");

    /*
     * Ayırıcıları kaldırıyoruz.
     */
    normalized.replace("_", "");
    normalized.replace("-", "");
    normalized.replace(".", "");
    normalized.replace("/", "");
    normalized.replace("\\", "");
    normalized.replace(" ", "");

    /*
     * Harf ve rakam dışındaki karakterleri temizle.
     */
    QString cleaned;

    for (const QChar &character : normalized)
    {
        if (character.isLetterOrNumber())
        {
            cleaned.append(character);
        }
    }

    return cleaned;
}

int ComparisonEngine::levenshteinDistance(
    const QString &first,
    const QString &second
    ) const
{
    const int firstLength =
        first.length();

    const int secondLength =
        second.length();

    QVector<int> previousRow(
        secondLength + 1
        );

    QVector<int> currentRow(
        secondLength + 1
        );

    for (int j = 0;
         j <= secondLength;
         ++j)
    {
        previousRow[j] = j;
    }

    for (int i = 1;
         i <= firstLength;
         ++i)
    {
        currentRow[0] = i;

        for (int j = 1;
             j <= secondLength;
             ++j)
        {
            const int insertionCost =
                currentRow[j - 1] + 1;

            const int deletionCost =
                previousRow[j] + 1;

            const int substitutionCost =
                previousRow[j - 1]
                +
                (
                    first[i - 1]
                            ==
                            second[j - 1]
                        ? 0
                        : 1
                    );

            currentRow[j] =
                std::min(
                    insertionCost,
                    std::min(
                        deletionCost,
                        substitutionCost
                        )
                    );
        }

        previousRow =
            currentRow;
    }

    return previousRow[secondLength];
}

double ComparisonEngine::calculateLevenshteinSimilarity(
    const QString &first,
    const QString &second
    ) const
{
    if (first.isEmpty()
        && second.isEmpty())
    {
        return 100.0;
    }

    if (first.isEmpty()
        || second.isEmpty())
    {
        return 0.0;
    }

    const int distance =
        levenshteinDistance(
            first,
            second
            );

    const int maxLength =
        std::max(
            first.length(),
            second.length()
            );

    if (maxLength == 0)
    {
        return 100.0;
    }

    double similarity =
        (
            1.0
            -
            static_cast<double>(distance)
                /
                static_cast<double>(maxLength)
            )
        * 100.0;

    if (similarity < 0.0)
    {
        similarity = 0.0;
    }

    return similarity;
}

double ComparisonEngine::calculateTokenSimilarity(
    const QString &first,
    const QString &second
    ) const
{
    QString firstText =
        first.toLower();

    QString secondText =
        second.toLower();

    firstText.replace("_", " ");
    firstText.replace("-", " ");
    firstText.replace(".", " ");

    secondText.replace("_", " ");
    secondText.replace("-", " ");
    secondText.replace(".", " ");

    const QStringList firstTokens =
        firstText.split(
            ' ',
            Qt::SkipEmptyParts
            );

    const QStringList secondTokens =
        secondText.split(
            ' ',
            Qt::SkipEmptyParts
            );

    if (firstTokens.isEmpty()
        || secondTokens.isEmpty())
    {
        return 0.0;
    }

    QSet<QString> firstSet;
    QSet<QString> secondSet;

    for (const QString &token : firstTokens)
    {
        firstSet.insert(
            normalizeColumnName(token)
            );
    }

    for (const QString &token : secondTokens)
    {
        secondSet.insert(
            normalizeColumnName(token)
            );
    }

    QSet<QString> intersection =
        firstSet;

    intersection.intersect(
        secondSet
        );

    QSet<QString> unionSet =
        firstSet;

    unionSet.unite(
        secondSet
        );

    if (unionSet.isEmpty())
    {
        return 0.0;
    }

    return (
               static_cast<double>(
                   intersection.size()
                   )
               /
               static_cast<double>(
                   unionSet.size()
                   )
               ) * 100.0;
}

bool ComparisonEngine::areTypesCompatible(
    ColumnInfo::DataType sourceType,
    ColumnInfo::DataType targetType
    ) const
{
    /*
     * Tam olarak aynı tip.
     */
    if (sourceType == targetType)
    {
        return true;
    }

    /*
     * Integer ve Double ikisi de numeric kabul edilir.
     */
    const bool sourceNumeric =
        sourceType == ColumnInfo::DataType::Integer
        ||
        sourceType == ColumnInfo::DataType::Double;

    const bool targetNumeric =
        targetType == ColumnInfo::DataType::Integer
        ||
        targetType == ColumnInfo::DataType::Double;

    if (sourceNumeric && targetNumeric)
    {
        return true;
    }

    return false;
}

double ComparisonEngine::applyTypeCompatibilityBonus(
    double similarityScore,
    ColumnInfo::DataType sourceType,
    ColumnInfo::DataType targetType
    ) const
{
    if (areTypesCompatible(
            sourceType,
            targetType))
    {
        /*
         * Uyumlu veri tipine küçük bonus.
         */
        similarityScore += 10.0;
    }
    else
    {
        /*
         * Numeric ↔ String gibi eşleşmeleri
         * cezalandırıyoruz.
         */
        similarityScore -= 20.0;
    }

    if (similarityScore > 100.0)
    {
        similarityScore = 100.0;
    }

    if (similarityScore < 0.0)
    {
        similarityScore = 0.0;
    }

    return similarityScore;
}