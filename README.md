# 📊 Generic Data Analyzer

Modern, yüksek performanslı ve şemadan bağımsız (generic) veri analizi, veri temizleme, iki veri seti karşılaştırma, etkileşimli görselleştirme ve ham telemetri/binary paket ayrıştırma platformu.

![Qt Version](https://img.shields.io/badge/Qt-5.15%2B-green.svg)
![C++ Standard](https://img.shields.io/badge/C%2B%2B-11%2F17-blue.svg)
![UI](https://img.shields.io/badge/UI-Qt%20Quick%20%2F%20QML-orange.svg)

---

## 🌟 Proje Özeti ve "Generic" Mimarisi

**Generic Data Analyzer**, belirli bir tablo şemasına veya sabit veri modellerine bağlı kalmaksızın her türlü tabloyu ve ham ikili (binary) veri akışını dinamik olarak işleyebilen esnek bir mimariye sahiptir.

- **Şemadan Bağımsız Çekirdek:** Sütun sayısı, tipleri (`Integer`, `Double`, `String`, `DateTime`, `Boolean`) çalışma anında otomatik tespit edilir.
- **Protokol Bağımsız Ham Veri Ayrıştırma:** Excel formatındaki parametre meta veri tablosuna bakarak bit/byte düzeyinde her türlü binary (`.bin`, `.dat`, `.txt`) telemetri veya sensör paketini çözer.
- **Akıllı Karşılaştırma:** İki farklı veri setindeki sütunları Levenshtein benzerlik algoritmasıyla eşleştirir ve istatistiksel fark analizi sunar.
- **Kalıcı Durum (State Persistence):** Sayfalar arası geçişlerde yapılan seçimler, çizilen grafikler ve temizleme logları kaybolmaz.

---

## 🚀 Temel Özellikler ve Modüller

### 1. 📂 Çoklu Format Desteği ve Veri Seti Yönetimi

- **Excel (.xlsx), CSV ve JSON** formatlarındaki veri setlerini hızlıca yükleme.
- Aynı anda iki farklı veri setini (Dataset 1 ve Dataset 2) hafızada tutabilme.
- Sütun veri tiplerini, eksik veri oranlarını ve temel tablo özetlerini anında çıkarma.

---

### 2. ⚡ Ham Veri (Raw Data) ve Telemetri Ayrıştırma

- **Parametre Meta Verisi Yükleme:** Excel tablosundan parametre adı, başlangıç biti/baytı, bit uzunluğu, veri tipi (int, uint, float, bool), endianness ve ölçekleme katsayılarını (slope, intercept) okuma.
- **Binary / Metin Paket Çözümleme:** Yüklenen ham veri dosyasını tanımlara göre ayrıştırarak değer, birim ve durum (`OK` / `ERROR`) tablosunda listeleme.
- **Tek Tıkla Veri Setine Aktarma:** Ayrıştırılan telemetri paketini doğrudan **Dataset 1** veya **Dataset 2** olarak analize aktarabilme.

---

### 3. 🧹 Kapsamlı Veri Temizleme Motoru (Data Cleaning Engine)

Modüler ve kategorize edilmiş arayüz ile hem tek tek sütun bazında hem de toplu olarak temizlik:

- **Eksik Değer Doldurma:**
  - `Mean (Ortalama)` ile doldurma
  - `Median (Medyan)` ile doldurma
  - `Mode (Mod)` ile doldurma
  - `Satırları Kaldır (Sil)`
  - `Atla`
- **Aykırı Değer (Outlier) Tespiti ve Yönetimi:**
  - **Yöntemler:** IQR (1.5 Çarpanı), IQR (3.0 Çarpanı), Z-Score (3.0 Eşiği).
  - **Stratejiler:** Aykırıları silme, Mean ile değiştirme, Median ile değiştirme, Mode ile değiştirme ve **Sınırla (Cap / Winsorization)**.
- **Tekrarlanan Kayıtlar & Sabit Sütunlar:** Tekrarlanan satırları ve bilgi taşımayan tek değerli sabit sütunları kaldırma.
- **Canlı Log Konsolu & Geri Alma:** Yapılan tüm işlemleri zaman damgalı canlı günlükte izleme ve dilediğiniz an _"Orijinale Sıfırla"_ butonuyla ilk haline dönebilme.

---

### 4. 🔄 İki Veri Seti Karşılaştırma (Comparison Engine)

- **Otomatik Benzerlik Eşleştirme:** İki veri setindeki sütunları isim ve veri benzerliğine göre karşılaştırarak **% puanına göre büyükten küçüğe** sıralar.
- **Özelleştirilebilir Filtre:** Yalnızca CheckBox ile seçilen sütun çiftlerini veya satır başındaki `▶ Karşılaştır` butonuyla tekil çiftleri analiz etme.
- **Çoklu Grafiksel Karşılaştırma Modları:**
  1. _Sütun İstatistikleri_ (Mean, Median, IQR, Std Sapma delta çubukları)
  2. _Dağılım / Yoğunluk Eğrisi_
  3. _Kutu Grafiği (Box Plot)_: Gerçek istatistiki Whiskers, Min, Q1, Medyan, Q3, Max değerleriyle yan yana çizim.
  4. _Trend / Çizgi Grafiği_

---

### 5. 📈 Görselleştirme ve Otomatik Dışa Aktarma (Export)

- **Grafik Çeşitleri:** Histogram (Frekans), Kutu Grafiği (Box Plot), Çizgi Grafiği (Line / Time-Series), Olasılık Dağılımı (Distribution), Korelasyon Matrisi (Heatmap), İki Veri Seti Karşılaştırma.
- **Tekli & Yan Yana Çift Çizim:** Dataset 1 ve Dataset 2'yi aynı anda yan yana panellerde inceleyebilme.
- **Yüksek Performans (Decimation):** 10.000+ satırlık veriler akıllı alt-örnekleme ile UI donması yaşanmadan 5 ms altında anında çizilir.
- **Otomatik Dışa Aktarma:**
  - Temizlenmiş veriyi **Excel (.xlsx)**, **CSV** veya **JSON** formatında tek tıkla `output/<Ad>_Export_<Tarih>.<uzantı>` olarak kaydetme.
  - Oluşturulan grafikleri **💾 Grafiği Kaydet** butonuyla PNG olarak `output/` klasörüne aktarma.

---

### 6. 🌙 Modern UX & Tema Desteği

- **Açık / Koyu Tema (Light / Dark Mode):** Hem sol menüden hem de sağ üstteki **🌙 / ☀️** ikonundan anında tema değiştirme.
- **Kalıcı Durum (State Persistence):** Sayfalar arasında geçiş yapıldığında grafikler, seçili parametreler ve loglar silinmez.

---

## 🏗️ Proje Dizin Yapısı

```
GenericDataAnalyzer/
├── analysis/               # İstatistik, EDA ve Karşılaştırma motorları
│   ├── AnalysisEngine.h/.cpp
│   └── ComparisonEngine.h/.cpp
├── backend/                # QML - C++ köprüsü (AppController)
│   ├── AppController.h/.cpp
│   └── AppController_p.h
├── cleaning/               # Eksik veri, aykırı değer ve temizleme motoru
│   └── CleaningEngine.h/.cpp
├── models/                 # QML ListModel sınıfları (ColumnModel, MappingModel, ParameterModel)
├── parser/                 # Generic DataSet, CSV/Xlsx/JSON ve RawDataParser motoru
│   ├── DataSet.h/.cpp
│   ├── DataParser.h / CsvParser / ExcelParser / JsonParser
│   └── RawDataParser.h/.cpp
├── visualization/          # Histogram, BoxPlot, TimeSeries ve Korelasyon çizim motoru
│   └── VisualizationEngine.h/.cpp
├── qml/                    # Qt Quick arayüz bileşenleri ve sayfaları
│   ├── Main.qml
│   ├── Theme.qml
│   ├── components/         # Sidebar ve ortak arayüz bileşenleri
│   └── pages/              # Dashboard, Datasets, Analysis, Cleaning, Comparison, Viz, RawData
├── QXlsx/                  # Bağımsız C++ Excel okuma/yazma kütüphanesi
├── data/                   # Örnek test veri setleri (.xlsx, .csv, .bin)
├── output/                 # Otomatik dışa aktarılan rapor ve grafik dizini
└── GenericDataAnalyzer.pro # QMake proje yapılandırma dosyası
```

---

## ⚙️ Kurulum ve Derleme (Build)

### Gereksinimler

- **Qt 5.15.x** (MinGW 64-bit veya MSVC)
- **C++11** veya üzeri destekli derleyici
- **Qt Modülleri:** `QtQuick`, `QtQml`, `QtCharts`, `QtWidgets`, `QtGui`, `QtCore`, `QtNetwork`

### QMake & MinGW ile Derleme

```bash
# 1. Proje dizinine gidin
cd GenericDataAnalyzer

# 2. QMake çalıştırın
qmake GenericDataAnalyzer.pro -spec win32-g++

# 3. Projeyi derleyin
mingw32-make -j4

# 4. Uygulamayı çalıştırın
./release/GenericDataAnalyzer.exe
```

---

## 📖 Kullanım Adımları

1. **Veri Yükleme:** _Veri Setleri_ sekmesine giderek Dataset 1 ve Dataset 2 için `.xlsx` veya `.csv` dosyalarınızı yükleyin.
2. **Ham Veri Ayrıştırma (Opsiyonel):** _Raw Data Ayrıştırma_ sekmesinden parametre meta veri Excel tablosunu ve `.bin` dosyasını seçip _⚡ Parse Raw Data_ butonuna basın; ayrışan değerleri tek tıkla Dataset olarak aktarın.
3. **Veri Temizleme:** _Veri Temizleme_ sekmesinde eksik değerleri (Mean/Median/Mode) doldurun, aykırı değerleri (IQR/Z-Score) sınırlandırın veya silin.
4. **Karşılaştırma:** _Karşılaştırma_ sekmesinde iki veri seti arasındaki benzer sütunları eşleştirin ve istatistiksel / grafiksel farkları inceleyin.
5. **Görselleştirme & Dışa Aktarma:** _Görselleştirme_ sekmesinde dilediğiniz grafik türünü seçip çizin, grafiği PNG olarak kaydedin veya temizlenmiş verinizi Excel/CSV olarak dışa aktarın.

---

## 👥 Geliştiriciler

**Aybüke Turgun & Esra Silahşor**
