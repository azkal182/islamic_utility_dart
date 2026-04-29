# API Reference (Bilingual: Indonesia + English)

ID: Dokumen ini menjelaskan API publik `islamic_utility` untuk integrasi aplikasi.
EN: This document describes the public `islamic_utility` API for app integration.

## Import

```dart
import 'package:islamic_utility/islamic_utility.dart';
```

## 1) Prayer API

### Public Types

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

### Coordinates

```dart
const Coordinates(double latitude, double longitude)
```

- `latitude`: `-90..90`
- `longitude`: `-180..180`

### CalculationMethod

Enum:
- `muslimWorldLeague`, `egyptian`, `indonesian`, `karachi`, `ummAlQura`
- `qatar`, `dubai`, `kuwait`, `moonsightingCommittee`, `singapore`
- `turkiye`, `tehran`, `northAmerica`, `morocco`, `other`

Property:

```dart
CalculationParameters get parameters
```

### CalculationParameters

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

Functions:

```dart
CalculationParameters copyWith({ ... })
Map<Prayer, double> nightPortions()
```

### Prayer enum

- `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, `ishaBefore`, `fajrAfter`

### PrayerTimes

```dart
PrayerTimes({
  required DateTime date,
  required Coordinates coordinates,
  required CalculationParameters calculationParameters,
  bool precision = false,
})
```

Outputs (UTC):
- `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`, `ishaBefore`, `fajrAfter`

Functions:

```dart
Prayer currentPrayer({required DateTime date})
Prayer nextPrayer({DateTime? date})
DateTime timeForPrayer(Prayer prayer)
```

### SunnahTimes

```dart
SunnahTimes(PrayerTimes prayerTimes, {bool precision = true})
```

Outputs:
- `middleOfTheNight`
- `lastThirdOfTheNight`

### Qibla

```dart
static double qibla(Coordinates coordinates)
```

Output:
- Degree from north (`0..360`).

## 2) Hijri API

### Public Types

- `HijriCalendar`
- `HijriMethod`
- `HijriDate`
- `HijriResultMeta`
- `HijriAdjustmentClient`
- `AdjustmentFetchResult`
- `AnchorFetchResult`
- `AdjustmentRecord`
- `HijriAnchorRecord`
- `HijriAdjustmentCache`, `InMemoryHijriAdjustmentCache`, `HiveHijriAdjustmentCache`
- `HijriAnchorCache`, `InMemoryHijriAnchorCache`, `HiveHijriAnchorCache`
- `HttpHijriAdjustmentClient`
- `RetryPolicy`

### HijriMethod

Enum:
- `calculatedLocal`
- `ummAlQura`
- `kemenagRiOfficial`

### HijriDate and HijriResultMeta

```dart
class HijriDate {
  final int year;
  final int month;
  final int day;
  final HijriResultMeta meta;
}
```

```dart
class HijriResultMeta {
  final String source;
  final bool isAdjusted;
  final int adjustmentDays;
  final String? authority;
  final int? revision;
}
```

### HijriCalendar

Constructors:

```dart
HijriCalendar()
```

```dart
HijriCalendar.withOfficial({
  required HijriAdjustmentClient adjustmentClient,
  HijriAdjustmentCache? cache,
  HijriAnchorCache? anchorCache,
  String authority = 'kemenag_ri',
  String regionScope = 'national',
  Duration cacheTtl = const Duration(hours: 24),
})
```

Functions:

```dart
HijriDate fromGregorian(
  DateTime date, {
  HijriMethod method = HijriMethod.calculatedLocal,
})
```

```dart
Future<HijriDate> fromGregorianOfficial(DateTime date)
```

```dart
Future<List<HijriDate>> fromGregorianOfficialRange({
  required DateTime from,
  required DateTime to,
})
```

Notes:
- `fromGregorianOfficialRange` melakukan prefetch range (`anchors` + `adjustments`) lalu resolve lokal per tanggal.
- Untuk mode range, request harian remote dihindari selama cache range masih berlaku.

### HijriAdjustmentClient

```dart
abstract class HijriAdjustmentClient {
  Future<AdjustmentFetchResult> fetchByDate({required DateTime date, String? etag});
  Future<AdjustmentFetchResult> fetchLatest({String? etag});
  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  });

  Future<AnchorFetchResult> fetchAnchorsByDate({required DateTime date, String? etag});
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag});
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  });
}
```

Default behavior:
- `fetchLatest` default ke `fetchByDate(nowUtc)`.
- `fetchRange` default ke `fetchByDate(from)` (override untuk implementasi range aktual).
- `fetchLatestAnchors` default ke `fetchAnchorsByDate(nowUtc)`.
- `fetchAnchorsRange` default ke `fetchAnchorsByDate(from)` (override untuk implementasi range aktual).

### HttpHijriAdjustmentClient

```dart
HttpHijriAdjustmentClient({
  required String baseUrl,
  required String apiKey,
  String country = 'ID',
  String authority = 'kemenag_ri',
  String regionScope = 'national',
  RetryPolicy retryPolicy = const RetryPolicy(),
  RetryAttemptLogger? onRetryAttempt,
  HttpClient? httpClient,
})
```

Supports:
- `fetchByDate`, `fetchLatest`, `fetchRange`
- `fetchAnchorsByDate`, `fetchLatestAnchors`, `fetchAnchorsRange`
- ETag (`If-None-Match`)
- retry for `429` and `5xx`
- `Retry-After` parsing and clamp

### Cache Interfaces

```dart
abstract class HijriAdjustmentCache {
  AdjustmentCacheEntry? get(DateTime date);
  void put(DateTime date, AdjustmentCacheEntry entry);
}
```

```dart
abstract class HijriAnchorCache {
  AnchorCacheEntry? get(DateTime date);
  void put(DateTime date, AnchorCacheEntry entry);
}
```

Implementations:
- In-memory: `InMemoryHijriAdjustmentCache`, `InMemoryHijriAnchorCache`
- Persistent (Hive): `HiveHijriAdjustmentCache`, `HiveHijriAnchorCache`

## 3) Integration Contract

- Prayer outputs (`PrayerTimes`) are UTC.
- Gunakan `date` eksplisit pada `currentPrayer` / `nextPrayer`.
- Timezone conversion dilakukan di presentation/UI layer.
- Untuk Hijri official production:
  1. gunakan `withOfficial(...)`
  2. gunakan persistent cache
  3. log `meta.source` dan `meta.revision`

## 4) Quick Checklist

1. Pilih `CalculationMethod` dan buat `PrayerTimes`.
2. Jika butuh Hijri offline, gunakan `HijriCalendar()` + `HijriMethod.calculatedLocal` / `ummAlQura`.
3. Jika butuh Hijri official, gunakan `HijriCalendar.withOfficial(...)`.
4. Untuk range conversion gunakan `fromGregorianOfficialRange(...)`.
5. Untuk Flutter production, pakai cache persistent (Hive) di app layer.
