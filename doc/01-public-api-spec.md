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

## Kontrak Backward Compatibility

- Nama class, enum, dan fungsi publik tidak berubah.
- Semantik parameter default tidak berubah.
- Perubahan besar harus melalui API tambahan, bukan mengganti behavior lama secara diam-diam.
