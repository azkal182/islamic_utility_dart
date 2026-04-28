# API Reference (Bilingual: Indonesia + English)

ID: Dokumen ini menjelaskan API publik `islamic_utility` untuk implementasi aplikasi.
EN: This document describes the public `islamic_utility` API for app integration.

## Import

```dart
import 'package:islamic_utility/islamic_utility.dart';
```

## Public Types / Tipe Publik

- `Coordinates`
- `CalculationMethod`
- `CalculationParameters`
- `Madhab`
- `HighLatitudeRule`
- `Shafaq`
- `Prayer`
- `PrayerTimes`
- `SunnahTimes`
- `Qibla`

## Coordinates

ID: Menyimpan latitude dan longitude lokasi.
EN: Holds location latitude and longitude.

```dart
const Coordinates(double latitude, double longitude)
```

Parameters:
- `latitude` (`double`): `-90..90`
- `longitude` (`double`): `-180..180`

Output:
- immutable `Coordinates` object.

## CalculationMethod

ID: Preset method perhitungan.
EN: Preset calculation methods.

Enum values:
- `muslimWorldLeague`, `egyptian`, `indonesian`, `karachi`, `ummAlQura`
- `qatar`, `dubai`, `kuwait`, `moonsightingCommittee`, `singapore`
- `turkiye`, `tehran`, `northAmerica`, `morocco`, `other`

Property:

```dart
CalculationParameters get parameters
```

Output:
- default `CalculationParameters` for the selected method.

## CalculationParameters

ID: Konfigurasi detail yang memengaruhi hasil jadwal.
EN: Detailed configuration that affects schedule output.

Constructor:

```dart
CalculationParameters(
  CalculationMethod method,
  double fajrAngle,
  double ishaAngle, {
  int dhuhaOffsetMinutes = 20,
  int? ishaInterval,
  double? maghribAngle,
  Madhab? madhab,
  Shafaq? shafaq,
  HighLatitudeRule? highLatitudeRule,
  Map<Prayer, int>? adjustments,
  Map<Prayer, int>? methodAdjustments,
})
```

Key fields / Parameter penting:
- `method`: calculation preset
- `fajrAngle`: fajr solar angle
- `ishaAngle`: isha solar angle
- `dhuhaOffsetMinutes`: minutes after sunrise for `dhuha` (default `20`)
- `ishaInterval`: if set (`> 0`), isha is interval-based from maghrib
- `maghribAngle`: optional angle-based maghrib
- `madhab`: asr madhab (`shafi` or `hanafi`)
- `shafaq`: moonsighting evening twilight type
- `highLatitudeRule`: high-latitude fallback rule
- `adjustments`: user minute offsets by prayer
- `methodAdjustments`: built-in minute offsets by method

Functions:

```dart
CalculationParameters copyWith({ ... })
Map<Prayer, double> nightPortions()
```

Outputs:
- `copyWith`: new `CalculationParameters`
- `nightPortions`: night fractions used by high-latitude fallback

## Prayer enum

ID: Daftar prayer yang didukung API.
EN: Prayer identifiers supported by the API.

Values:
- `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, `ishaBefore`, `fajrAfter`

Notes:
- `imsak`: default `10 minutes before fajr`
- `dhuha`: default `sunrise + dhuhaOffsetMinutes`
- `ishaBefore`, `fajrAfter`: cross-day boundary values

## PrayerTimes

ID: Class utama untuk menghasilkan jadwal sholat.
EN: Main class for producing prayer schedules.

Constructor:

```dart
PrayerTimes({
  required DateTime date,
  required Coordinates coordinates,
  required CalculationParameters calculationParameters,
  bool precision = false,
})
```

Parameters:
- `date`: target date (UTC recommended)
- `coordinates`: location coordinates
- `calculationParameters`: method/config object
- `precision`: second-level vs rounded-minute output

Outputs (all UTC `DateTime`):
- `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, `ishaBefore`, `fajrAfter`

Functions:

```dart
Prayer currentPrayer({required DateTime date})
Prayer nextPrayer({DateTime? date})
DateTime timeForPrayer(Prayer prayer)
```

Function outputs:
- `currentPrayer`: current prayer at a specific instant
- `nextPrayer`: next prayer after a specific instant
- `timeForPrayer`: schedule time for an enum value

## SunnahTimes

ID: Waktu sunnah turunan dari `PrayerTimes`.
EN: Sunnah times derived from `PrayerTimes`.

Constructor:

```dart
SunnahTimes(PrayerTimes prayerTimes, {bool precision = true})
```

Outputs:
- `middleOfTheNight`
- `lastThirdOfTheNight`

## Qibla

ID: Menghitung arah kiblat dari lokasi.
EN: Computes qibla direction from coordinates.

```dart
static double qibla(Coordinates coordinates)
```

Output:
- `double` degrees from north (`0..360`).

## Supporting Enums / Enum Pendukung

- `Madhab`: `shafi`, `hanafi`
- `HighLatitudeRule`: `middleOfTheNight`, `seventhOfTheNight`, `twilightAngle`
- `Shafaq`: `general`, `ahmer`, `abyad`

## Integration Contract / Kontrak Integrasi

- ID: Semua output `PrayerTimes` adalah UTC.
- EN: All `PrayerTimes` outputs are UTC.
- ID: Selalu kirim argumen `date` eksplisit pada `currentPrayer`/`nextPrayer`.
- EN: Always pass explicit `date` for `currentPrayer`/`nextPrayer`.
- ID: Konversi timezone dilakukan di layer presentasi.
- EN: Apply timezone conversion in the presentation layer.

## Quick Integration Checklist

1. Choose a `CalculationMethod`.
2. Build `CalculationParameters` (optionally with `copyWith`).
3. Create `PrayerTimes` using date + coordinates.
4. Read prayer fields or call `currentPrayer` / `nextPrayer`.
5. Use `Qibla.qibla` for qibla direction.
