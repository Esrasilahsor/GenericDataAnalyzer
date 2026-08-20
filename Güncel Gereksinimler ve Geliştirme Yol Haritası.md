# GenericDataAnalyzer — Güncel Gereksinimler ve Geliştirme Yol Haritası

## 1. Projenin Amacı

GenericDataAnalyzer, farklı veri kaynaklarından gelen verilerin okunması, doğrulanması, karşılaştırılması ve analiz edilmesi amacıyla geliştirilen Qt/C++ tabanlı masaüstü uygulamasıdır.

Uygulama iki temel veri akışını desteklemektedir:

**Tablosal veri akışı**

```text
Excel
  ↓
ExcelParser
  ↓
DataSet
  ↓
ColumnInfo
  ↓
ColumnModel
  ↓
Comparison / Analysis
  ↓
QML
```

**Raw veri akışı**

```text
Metadata Excel
      ↓
ExcelParser
      ↓
ParameterDefinition
      ↓

Raw Data Source
      ↓
FileRawDataSource
      ↓
QByteArray
      ↓
RawDataParser
      ↓
ParsedParameter
      ↓
ParameterModel
      ↓
QML
```

Temel mimari prensip, parser ve analiz katmanlarının verinin kaynağına mümkün olduğunca bağımlı olmamasıdır.

---

# 2. Güncel Proje Klasör Yapısı

```text
GenericDataAnalyzer/
│
├── GenericDataAnalyzer.pro
├── main.cpp
│
├── QXlsx/
│
├── analysis/
│   ├── AnalysisEngine.h
│   ├── AnalysisEngine.cpp
│   ├── ComparisonEngine.h
│   ├── ComparisonEngine.cpp
│   ├── Statistics.h
│   └── Statistics.cpp
│
├── backend/
│   ├── AppController.h
│   └── AppController.cpp
│
├── models/
│   ├── ColumnModel.h
│   ├── ColumnModel.cpp
│   ├── MappingModel.h
│   ├── MappingModel.cpp
│   ├── ParameterModel.h
│   └── ParameterModel.cpp
│
├── parser/
│   ├── BitExtractionResult.h
│   ├── BitExtractor.h
│   ├── BitExtractor.cpp
│   ├── ColumnInfo.h
│   ├── ColumnInfo.cpp
│   ├── DataSet.h
│   ├── DataSet.cpp
│   ├── DataType.h
│   ├── DataType.cpp
│   ├── ExcelParser.h
│   ├── ExcelParser.cpp
│   ├── MetadataValidator.h
│   ├── MetadataValidator.cpp
│   ├── ParameterDefinition.h
│   ├── ParsedParameter.h
│   ├── ParseStatus.h
│   ├── RawDataBuffer.h
│   ├── RawDataBuffer.cpp
│   ├── RawDataParser.h
│   ├── RawDataParser.cpp
│   └── ValidationResult.h
│
├── raw/
│   ├── IRawDataSource.h
│   ├── FileRawDataSource.h
│   ├── FileRawDataSource.cpp
│   └── RawDataSourceResult.h
│
└── qml/
    └── Main.qml
```

Test amaçlı oluşturulan `tests/` yapısı geliştirme doğrulamaları tamamlandıktan sonra ana uygulamadan kaldırılmıştır.

---

# 3. PARSER MODÜLÜ

## Durum: TAMAMLANDI — V1

Parser katmanına yeni bir gereksinim çıkmadıkça özellik eklenmeyecektir.

## 3.1 ColumnInfo

`ColumnInfo`, normal Excel datasetlerinin her sütununa ait bilgileri tutmalıdır.

Desteklenen bilgiler:

- sütun adı,
- original name,
- veri tipi,
- sütun değerleri,
- missing count,
- missing percentage,
- unique count,
- numeric olup olmadığı.

Desteklenen tablosal veri tipleri:

```text
Unknown
Integer
Double
String
Boolean
DateTime
```

## 3.2 DataSet

`DataSet` bir Excel datasetinin uygulamadaki temsilidir.

En az şu bilgileri tutmalıdır:

```text
name
filePath
sheetName
columns
rowCount
columnCount
```

Sütunlar `ColumnInfo` nesneleri olarak saklanmalıdır.

## 3.3 ExcelParser — Dataset Parsing

ExcelParser:

- `.xlsx` dosyasının varlığını kontrol etmelidir,
- dosyanın açılabilir olduğunu kontrol etmelidir,
- worksheet bulunup bulunmadığını kontrol etmelidir,
- ilk kullanılabilir sheet'i seçmelidir,
- header satırını okumalıdır,
- sütun değerlerini okumalıdır,
- veri tipini belirlemelidir,
- missing ve unique bilgilerini hesaplamalıdır,
- sonucu `DataSet` olarak üretmelidir.

Geçersiz Excel dosyası uygulamanın kapanmasına neden olmamalıdır.

---

# 4. RAW METADATA PARSER

## Durum: TAMAMLANDI — V1

ExcelParser ayrıca raw veri tanımlarını okuyabilmelidir.

Metadata Excel içerisindeki temel alanlar:

```text
STRUCT_NAME
PACKAGE_OR_DATA_NAME
DATA_NAME
BYTE_OFFSET
BYTE_SIZE
BIT_OFFSET
BIT_SIZE
DATA_TYPE
MIN_VALUE
MAX_VALUE
INITIAL
UNIT
INFO
RESOLUTION
```

Bu satırlar:

```text
Excel
 ↓
ParameterDefinition
```

yapısına dönüştürülmelidir.

Header sırası sabit kabul edilmemelidir. Kolonlar isimleri üzerinden bulunmalıdır.

Tamamen boş satırlar göz ardı edilmelidir.

Bir metadata satırı hatalıysa diğer satırların okunması devam etmelidir.

---

# 5. ParameterDefinition

## Durum: TAMAMLANDI

Bir raw parametrenin nasıl okunacağını tanımlar.

Temel bilgiler:

```text
dataName
structName
packageOrDataName

byteOffset
byteSize

bitOffset
bitSize

dataType
resolution

minValue
maxValue
initialValue

unit
info

endianness
```

Raw data içerisinde hangi byte ve bitlerin hangi parametreye ait olduğu bu model üzerinden belirlenmelidir.

---

# 6. MetadataValidator

## Durum: TAMAMLANDI — V1

Dışarıdan gelen metadata güvenilir kabul edilmemelidir.

Kontrol edilmesi gereken durumlar:

```text
BYTE_OFFSET >= 0
BYTE_SIZE > 0

BIT_OFFSET >= 0
BIT_SIZE > 0

BIT_SIZE <= desteklenen maksimum değer

BIT_OFFSET + BIT_SIZE
ilgili byte penceresine sığmalı

DATA_TYPE destekleniyor olmalı

MIN_VALUE <= MAX_VALUE

RESOLUTION finite olmalı

INITIAL finite olmalı
```

Geçersiz metadata raw belleğe erişmeden önce reddedilmelidir.

---

# 7. DataType

## Durum: TAMAMLANDI

Raw parser tarafından desteklenen temel veri tipleri:

```text
Boolean

Int8
Int16
Int32

UInt8
UInt16
UInt32

Float32
Float64

Unknown
```

Bilinmeyen veri tipi otomatik olarak başka bir tipe dönüştürülmemelidir.

Örneğin:

```text
uint128
```

gibi desteklenmeyen değer:

```text
Unknown
```

olarak işaretlenmeli ve kontrollü hata üretmelidir.

---

# 8. RawDataBuffer

## Durum: TAMAMLANDI

`QByteArray` üzerinde güvenli erişim sağlamalıdır.

Raw data doğrudan kontrolsüz şekilde:

```cpp
data.at(offset)
```

ile okunmamalıdır.

Önce:

```text
offset geçerli mi?
size geçerli mi?
yeterli byte var mı?
```

kontrol edilmelidir.

Raw paket beklenenden kısa geldiğinde uygulama çökmemelidir.

---

# 9. BitExtractor

## Durum: TAMAMLANDI — V1

BitExtractor raw byte penceresinden istenilen bit alanını çıkarmalıdır.

Desteklenen temel özellikler:

```text
bit offset
bit size
little endian
big endian altyapısı
signed sign-extension
unsigned values
boolean extraction
1–64 bit güvenli extraction altyapısı
```

Özellikle shift işlemlerinde:

```text
32 bit
64 bit
```

sınırları güvenli şekilde ele alınmalıdır.

`1ULL << 64` gibi tanımsız işlemler yapılmamalıdır.

---

# 10. RawDataParser

## Durum: TAMAMLANDI — V1

RawDataParser girdileri:

```text
QByteArray
+
QList<ParameterDefinition>
```

olmalıdır.

Çıktı:

```text
QList<ParsedParameter>
```

olmalıdır.

Parser sırasıyla:

```text
metadata validation
↓
byte/bit extraction
↓
signed / unsigned conversion
↓
datatype conversion
↓
resolution
↓
numeric validation
↓
min/max kontrolü
↓
ParsedParameter
```

işlemlerini gerçekleştirmelidir.

Bir parametre hatalı olduğunda bütün raw paket parse işlemi durdurulmamalıdır.

Örneğin:

```text
20 parametre

18 OK
2 ERROR
```

durumunda 18 başarılı parametre kullanılabilir kalmalıdır.

---

# 11. ParsedParameter ve ParseStatus

## Durum: TAMAMLANDI

Her parse edilen parametre en az:

```text
dataName
rawValue
value
displayValue
dataType
unit
info
status
errorMessage
warnings
```

bilgilerini taşımalıdır.

Temel durumlar:

```text
OK
WARNING
INVALID_METADATA
INSUFFICIENT_DATA
INVALID_BIT_RANGE
UNSUPPORTED_TYPE
INVALID_NUMERIC_VALUE
INTERNAL_ERROR
```

Warning ve Error birbirinden ayrılmalıdır.

Örneğin:

```text
Parse başarılı ama MAX_VALUE aşılmış
→ WARNING
```

olmalıdır.

---

# 12. RAW DATA SOURCE MODÜLÜ

## Durum: DOSYA KAYNAĞI TAMAMLANDI

Raw data kaynağı parserdan ayrılmıştır.

Ortak interface:

```text
IRawDataSource
```

kullanılmaktadır.

Şu anda implement edilen kaynak:

```text
FileRawDataSource
```

Akış:

```text
.bin / .raw / .dat
       ↓
FileRawDataSource
       ↓
QByteArray
```

Dosya kaynağı:

```text
path boş mu?
dosya var mı?
gerçekten file mı?
dosya boş mu?
dosya çok büyük mü?
dosya açılabiliyor mu?
tamamen okunabildi mi?
```

kontrollerini yapmalıdır.

Eski `RawDataLoader` kaldırılmıştır.

## Gelecekte

Aynı interface ileride gerekirse:

```text
CanRawDataSource
TcpRawDataSource
SerialRawDataSource
```

tarafından uygulanabilir.

**Ancak bunlar V1 kapsamında şu anda yapılmayacaktır.**

---

# 13. MODELS MODÜLÜ

## 13.1 ColumnModel

**Durum: TAMAMLANDI**

`DataSet` içerisindeki `ColumnInfo` bilgilerini QML'e taşımalıdır.

QML'de:

```text
name
dataType
missingCount
uniqueCount
isNumeric
```

gibi bilgiler kullanılabilmelidir.

---

## 13.2 MappingModel

**Durum: TEMEL SÜRÜM TAMAMLANDI**

Dataset 1 ve Dataset 2 sütunları arasındaki eşleştirme önerilerini QML'e taşımalıdır.

Temel bilgiler:

```text
sourceColumn
targetColumn
similarityScore
accepted
```

Kullanıcı öneriyi kabul edebilmelidir.

---

## 13.3 ParameterModel

**Durum: TAMAMLANDI**

`ParsedParameter` listesini QML'e aktarmalıdır.

QML'in erişebildiği bilgiler:

```text
dataName
value
rawValue
displayValue
dataType
unit
info
status
errorMessage
warnings
valid
```

---

# 14. ANALYSIS MODÜLÜ

## 14.1 Statistics

**Durum: TEMEL SÜRÜM TAMAMLANDI**

Numeric sütunlar için:

```text
Count
Mean
Median
Minimum
Maximum
Range
Variance
Standard Deviation
Q1
Q3
IQR
```

hesaplanabilmelidir.

---

## 14.2 AnalysisEngine

**Durum: TEMEL SÜRÜM TAMAMLANDI**

İki numeric sütun karşılaştırılabilmelidir.

Sonuçlarda en az:

```text
sourceStatistics
targetStatistics

meanDifference
medianDifference
minimumDifference
maximumDifference
rangeDifference
varianceDifference
standardDeviationDifference
q1Difference
q3Difference
iqrDifference
```

bulunmalıdır.

---

## 14.3 ComparisonEngine

**Durum: TEMEL SÜRÜM TAMAMLANDI**

Dataset 1 ve Dataset 2 sütunları arasında mapping önerisi oluşturmalıdır.

Şu anda temel sütun adı benzerliği kullanılmaktadır.

Daha gelişmiş matching ileriki faza bırakılmıştır.

---

# 15. BACKEND — AppController

## Durum: ÇALIŞIYOR

AppController QML ile backend arasındaki merkezi koordinasyon katmanıdır.

Görevleri:

```text
Dataset 1 yükleme
Dataset 2 yükleme

ColumnModel güncelleme

Mapping oluşturma

Analysis çalıştırma

Raw metadata yükleme

Raw data source çalıştırma

QByteArray saklama

RawDataParser çalıştırma

ParameterModel güncelleme

Error state yönetimi
```

AppController mümkün olduğunca gerçek parsing veya istatistik algoritması içermemelidir.

Bu işlemleri ilgili servis/engine/parser sınıflarına devretmelidir.

---

# 16. QML

## Durum: ÇALIŞIYOR

Şu anda `Main.qml` içerisinde aşağıdaki bölümler bulunmaktadır:

```text
Dataset Selection

Column Discovery

Column Matching Suggestions

Comparison Analysis

Raw Data Parsing
```

Raw Data Parsing ekranında kullanıcı:

```text
Metadata Excel seçebilir
Raw binary dosya seçebilir
Parse Raw Data yapabilir
Sonuçları temizleyebilir
```

Parsed Parameters tablosu:

```text
Parameter
Value
Type
Unit
Status
```

alanlarını göstermektedir.

---

# 17. ŞU ANKİ DURUM — CHECKPOINT

## Çalışan ve tamamlanan bölümler

```text
[✓] Qt/QML temel proje
[✓] QXlsx entegrasyonu

[✓] ExcelParser
[✓] DataSet
[✓] ColumnInfo

[✓] ColumnModel

[✓] Dataset 1 yükleme
[✓] Dataset 2 yükleme

[✓] Column Matching
[✓] MappingModel

[✓] Statistics
[✓] AnalysisEngine
[✓] ComparisonEngine

[✓] ParameterDefinition
[✓] MetadataValidator

[✓] DataType

[✓] RawDataBuffer
[✓] BitExtractor
[✓] RawDataParser
[✓] ParsedParameter
[✓] ParseStatus

[✓] ParameterModel

[✓] IRawDataSource
[✓] FileRawDataSource

[✓] Raw metadata Excel yükleme
[✓] Raw binary dosya yükleme
[✓] QByteArray entegrasyonu
[✓] Raw parameter parsing

[✓] Raw Data QML ekranı

[✓] Excel + Raw Data uçtan uca test
```

## Parser durumu

```text
PARSER V1 = TAMAMLANDI
```

Yeni bir zorunlu gereksinim oluşmadığı sürece parser tarafına dönülmeyecektir.

---

# 18. GELECEK GEREKSİNİMLER

Bundan sonraki çalışmalar aşağıdaki sırayla yapılacaktır.

---

## FAZ 1 — Data Quality Modülü

**Durum: YAPILACAK**

Yeni ana çalışma alanı budur.

Dataset üzerinde genel kalite analizi yapılacaktır.

En az:

```text
Missing value kontrolü
Missing percentage
Duplicate row kontrolü
Constant column kontrolü
Unique value analizi
Numeric / categorical özet
```

sağlanmalıdır.

Önerilen yeni dosyalar:

```text
analysis/
    DataQualityEngine.h
    DataQualityEngine.cpp

models/
    QualityModel.h
    QualityModel.cpp
```

Ancak isimler implementasyon aşamasında kesinleştirilecektir.

---

## FAZ 2 — Missing Value Analysis

**Durum: YAPILACAK**

Her sütun için:

```text
missing count
missing percentage
```

analizi genişletilecektir.

Dataset seviyesinde:

```text
toplam missing
missing bulunan sütun sayısı
en problemli sütunlar
```

gibi bilgiler üretilebilmelidir.

---

## FAZ 3 — Duplicate Analysis

**Durum: YAPILACAK**

Dataset içerisinde:

```text
duplicate row count
duplicate percentage
```

hesaplanmalıdır.

Duplicate tespiti sırasında büyük datasetlerde gereksiz bellek kopyalarından kaçınılmalıdır.

---

## FAZ 4 — Constant Column Detection

**Durum: YAPILACAK**

Bir sütunun bütün geçerli değerleri aynıysa:

```text
constant column
```

olarak işaretlenmelidir.

Bu sütunlar analiz açısından düşük bilgi taşıyan sütunlar olarak raporlanmalıdır.

---

## FAZ 5 — Outlier Analysis

**Durum: YAPILACAK**

Numeric sütunlar için ilk etapta:

```text
IQR
Z-Score
```

yöntemleri desteklenmelidir.

IQR sonucu:

```text
Q1
Q3
IQR
Lower Bound
Upper Bound
Outlier Count
Outlier Percentage
```

içermelidir.

Z-Score sonucu:

```text
threshold
outlier count
outlier percentage
```

içermelidir.

---

## FAZ 6 — Data Quality QML

**Durum: YAPILACAK**

Quality sonuçları kullanıcı arayüzüne taşınacaktır.

Örneğin:

```text
Dataset Quality

Rows
Columns
Missing
Duplicates
Constant Columns
Outliers
```

özet ekranı oluşturulacaktır.

Detaylarda sütun bazlı analiz gösterilebilmelidir.

---

## FAZ 7 — Dataset-Level Comparison

**Durum: YAPILACAK**

Mevcut comparison yalnızca seçilen sütunların istatistiksel karşılaştırmasını yapmaktadır.

Dataset seviyesinde:

```text
Row Count Difference

Column Count Difference

Matched Columns

Unmatched Columns

Data Type Mismatches

Missing Value Difference

Statistical Differences
```

raporlanacaktır.

---

## FAZ 8 — Column Matching V2

**Durum: İKİNCİL**

Mevcut matching sistemi korunacaktır.

Daha sonra eşleşme skoru yalnızca isim üzerinden değil:

```text
Column Name
Data Type
Unit
Min/Max
Mean
Standard Deviation
Value Distribution
```

gibi bilgilerle güçlendirilebilir.

Örneğin:

```text
RPM
EngineSpeed
```

isim olarak düşük benzerlik gösterse bile:

```text
numeric
rpm unit
benzer range
```

özellikleri nedeniyle yüksek eşleşme alabilir.

Bu özellik V1 için zorunlu değildir.

---

## FAZ 9 — QML Refactor

**Durum: YAPILACAK**

`Main.qml` büyümeye başlamıştır.

Backend fonksiyonları tamamlandıktan sonra QML bileşenlere ayrılacaktır.

Önerilen yapı:

```text
qml/
├── Main.qml
│
└── components/
    ├── DatasetCard.qml
    ├── ColumnTable.qml
    ├── MappingPanel.qml
    ├── AnalysisPanel.qml
    ├── QualityPanel.qml
    └── RawDataPanel.qml
```

Ama QML parçalama işlemi şu anda öncelik değildir.

---

## FAZ 10 — Error ve Warning Standardizasyonu

**Durum: YAPILACAK**

Proje genelinde ortak bir hata yaklaşımı oluşturulmalıdır.

Durumlar mümkün olduğunca:

```text
Success
Warning
Error
```

olarak sınıflandırılmalıdır.

Örnek:

```text
Dosya açılamıyor
→ ERROR

Unknown datatype
→ ERROR

Raw packet kısa
→ ERROR

Value MAX_VALUE üzerinde
→ WARNING

Missing values var
→ WARNING
```

Tek bir problem bütün uygulamayı gereksiz yere kullanılamaz hale getirmemelidir.

---

## FAZ 11 — Kod Temizliği

**Durum: YAPILACAK**

V1 tamamlanmadan önce:

```text
unused include
unused class
duplicate source
duplicate header
eski test kodları
dead code
gereksiz helper
gereksiz copy
```

kontrol edilmelidir.

`.pro` dosyasında her `.cpp` ve `.h` yalnızca bir kez bulunmalıdır.

---

## FAZ 12 — Final Validation

**Durum: YAPILACAK**

Son aşamada farklı veri senaryolarıyla uygulama tekrar test edilecektir.

Örnekler:

```text
clean_dataset.xlsx
missing_dataset.xlsx
duplicate_dataset.xlsx
constant_columns.xlsx
different_column_names.xlsx
outlier_dataset.xlsx

valid_metadata.xlsx
invalid_metadata.xlsx

valid_raw.bin
short_raw.bin
```

Final kontrol:

```text
uygulama açılıyor mu?
dosya hatalarında çöküyor mu?
dataset yükleniyor mu?
matching çalışıyor mu?
analysis çalışıyor mu?
quality analysis çalışıyor mu?
raw parsing çalışıyor mu?
QML hatasız mı?
```

kontrol edilmelidir.

---

# 19. ŞİMDİLİK KAPSAM DIŞI

Aşağıdaki özellikler mimaride ileride desteklenebilir fakat şu an geliştirilmemelidir:

```text
CAN

TCP

Serial Port

Real-time streaming

Database

Cloud

Plugin system

Machine Learning

Multithread optimization

Network synchronization
```

Yeni bir gereksinim açıkça ortaya çıkmadıkça bunlara girilmeyecektir.

---

# 20. Güncel Yol Haritası

```text
CURRENT
   │
   ├─ Dataset Parser          ✓
   ├─ Raw Parser              ✓
   ├─ Matching                ✓
   ├─ Basic Analysis          ✓
   └─ QML Integration         ✓
             │
             ▼
      DATA QUALITY
             │
             ▼
      MISSING ANALYSIS
             │
             ▼
      DUPLICATE ANALYSIS
             │
             ▼
     CONSTANT COLUMNS
             │
             ▼
      OUTLIER ANALYSIS
             │
             ▼
     DATASET COMPARISON
             │
             ▼
     MATCHING V2
      (gerekirse)
             │
             ▼
        QML REFACTOR
             │
             ▼
       ERROR CLEANUP
             │
             ▼
        CODE CLEANUP
             │
             ▼
       FINAL VALIDATION
             │
             ▼
        VERSION 1 DONE
```

# 21. Proje Takip Kuralı

Bundan sonra her yeni geliştirmede şu sıra izlenecektir:

```text
1. Gereksinim gerçekten V1 için gerekli mi?

2. Hangi mevcut modülün sorumluluğunda?

3. Yeni sınıf gerçekten gerekiyor mu?

4. Mevcut sınıf genişletilebilir mi?

5. Aynı işi yapan başka kod