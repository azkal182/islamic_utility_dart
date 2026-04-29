# Public API Specification

Dokumen ini mendefinisikan kontrak API yang harus dipertahankan agar kompatibel dengan `adhan_dart`.

## Exports Publik

- `SunnahTimes`
- `Coordinates`
- `CalculationMethod`
- `CalculationParameters`
- `Madhab`
- `Prayer`
- `PrayerTimes`
- `Qibla`
- `HighLatitudeRule`
- `Shafaq`
- `HijriCalendar`
- `HijriMethod`
- `HijriDate`
- `HijriResultMeta`
- `HijriAdjustmentClient`
- `AdjustmentFetchResult`
- `AnchorFetchResult`
- `AdjustmentRecord`
- `HijriAnchorRecord`
- `HttpHijriAdjustmentClient`
- `RetryPolicy`
- `HijriAdjustmentCache`
- `InMemoryHijriAdjustmentCache`
- `HiveHijriAdjustmentCache`
- `HijriAnchorCache`
- `InMemoryHijriAnchorCache`
- `HiveHijriAnchorCache`
- `JavaneseCalendar`
- `JavaneseDate`
- `Pasaran`

## Tipe Data

## `Coordinates`

- Konstruktor: `Coordinates(double latitude, double longitude)`
- Sifat: immutable.
- Domain umum:
  - latitude `[-90, 90]`
  - longitude `[-180, 180]`

## `Prayer` enum

- Urutan nilai:
  - `imsak`
  - `fajr`
  - `dhuha`
  - `sunrise`
  - `dhuhr`
  - `asr`
  - `maghrib`
  - `isha`
  - `ishaBefore`
- `fajrAfter`

`ishaBefore` dan `fajrAfter` adalah nilai tambahan untuk boundary lintas hari.

## `CalculationParameters`

Bidang utama:

- `method: CalculationMethod`
- `fajrAngle: double`
- `ishaAngle: double`
- `dhuhaOffsetMinutes: int` (default 20)
- `ishaInterval: int?`
- `maghribAngle: double?`
- `madhab: Madhab?`
- `shafaq: Shafaq?`
- `highLatitudeRule: HighLatitudeRule?`
- `adjustments: Map<Prayer, int>`
- `methodAdjustments: Map<Prayer, int>`

Fungsi:

- `copyWith(...)`
- `nightPortions() -> Map<Prayer, double>`

## `PrayerTimes`

Konstruktor:

```dart
PrayerTimes({
  required DateTime date,
  required Coordinates coordinates,
  required CalculationParameters calculationParameters,
  bool precision = false,
})
```

Properti hasil:

- `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`
- `imsak`, `dhuha`
- `ishaBefore`, `fajrAfter`

Fungsi:

- `Prayer currentPrayer({required DateTime date})`
- `Prayer nextPrayer({DateTime? date})`
- `DateTime timeForPrayer(Prayer prayer)`

## `SunnahTimes`

Konstruktor:

```dart
SunnahTimes(PrayerTimes prayerTimes, {bool precision = true})
```

Properti:

- `middleOfTheNight`
- `lastThirdOfTheNight`

## `Qibla`

Fungsi:

```dart
static double qibla(Coordinates coordinates)
```

Output derajat dari utara (0-360).

## Kontrak Behavior

- Semua waktu pada `PrayerTimes` disimpan sebagai `DateTime` UTC.
- `timeForPrayer` harus selalu mengembalikan field yang sesuai enum.
- `currentPrayer` untuk waktu sebelum `fajr` harus mengembalikan `ishaBefore`.
- `nextPrayer` untuk waktu setelah `isha` harus mengembalikan `fajrAfter`.

## Kontrak API Hijri

- `HijriCalendar()` wajib tersedia untuk mode offline (`calculatedLocal`/`ummAlQura`).
- `HijriCalendar.withOfficial(...)` wajib menerima:
  - `adjustmentClient`
  - optional `cache`
  - optional `anchorCache`
  - `authority`, `regionScope`, `cacheTtl`
- `fromGregorianOfficial(DateTime)` wajib tersedia untuk konversi tanggal tunggal official.
- `fromGregorianOfficialRange({from, to})` wajib tersedia untuk konversi rentang tanggal official.
- `fromGregorianOfficialRange` harus mendukung alur prefetch range lalu resolusi harian tanpa loop remote per tanggal (selama cache range valid).

## Kontrak Client & Cache Hijri

- `HijriAdjustmentClient` wajib memiliki:
  - `fetchByDate`, `fetchLatest`, `fetchRange`
  - `fetchAnchorsByDate`, `fetchLatestAnchors`, `fetchAnchorsRange`
- Implementasi default `fetchRange` dan `fetchAnchorsRange` boleh fallback ke versi per-date, tetapi implementasi HTTP production sebaiknya override dengan query range sebenarnya.
- `HijriAdjustmentCache` dan `HijriAnchorCache` wajib mempertahankan kontrak `get(DateTime)` dan `put(DateTime, Entry)`.
- Implementasi in-memory dan persistent (Hive) harus menjaga format data kompatibel terhadap:
  - `etag`
  - `cachedAt`
  - `ttl`
  - daftar record yang dibutuhkan resolver/provider

## Kontrak API Pasaran Jawa

- `JavaneseCalendar` wajib tersedia sebagai API tambahan (additive).
- `fromGregorian(DateTime)` mengembalikan `JavaneseDate` berisi:
  - `pasaran`
  - `weton`
- `fromGregorianRange({from, to})` mengembalikan rentang inklusif.
- Penambahan API Pasaran Jawa tidak boleh mengubah behavior API existing (prayer/hijri).

## Kontrak Backward Compatibility

- Nama class, enum, dan fungsi publik tidak berubah.
- Semantik parameter default tidak berubah.
- Perubahan besar harus melalui API tambahan, bukan mengganti behavior lama secara diam-diam.
