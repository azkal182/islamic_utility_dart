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
Prayer nextPrayer({DateTime? date, NextPrayerOptions options})
NextPrayerDetails nextPrayerDetails({
  required DateTime at,
  required DateTime locationDate,
  NextPrayerOptions options,
})
DateTime timeForPrayer(Prayer prayer)
```

By default, next-event candidates are Imsak, Fajr, sunrise, Dhuha, Dhuhr, Asr,
Maghrib, and Isha. Use `NextPrayerOptions.skip` to omit one or more candidates.
Imsak is included on every date by default; `ImsakPolicy.ramadanOnly` includes
it only when `isRamadanOn(localDate)` returns true, and `ImsakPolicy.never`
omits it.

The `isRamadanOn` callback is required for `ramadanOnly`. It receives the
target location's calendar date at UTC midnight. It is called for today and
tomorrow, since the next event may cross midnight. The application should
resolve Ramadan using its selected Hijri method.

`nextPrayerDetails` returns the next event's `prayer`, UTC `time`, and
`isNextDay`. Pass `locationDate` with the target location's calendar date for
the instant in `at` (for example, a date from the app's timezone package). Use
this API when the actual next occurrence time matters; `nextPrayer` returns
only the prayer enum. Pairing that enum with `timeForPrayer` cannot distinguish
a next-day occurrence from the same event on the schedule object's date (for
example, tomorrow's Imsak); use `nextPrayerDetails` to display its actual time.

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
- `JavaneseCalendar`
- `JavaneseDate`
- `Pasaran`
- `UnifiedCalendar`
- `UnifiedCalendarDate`
- `CalendarResolveOptions`

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
  final bool isProvisional;
  final DateTime? anchorDate;
  final DateTime? nextAnchorDate;
  final String? authority;
  final int? revision;
  final String validationStatus;
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
  bool allowLegacyAdjustments = false,
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

```dart
Future<HijriDate> refreshGregorianOfficial(DateTime date)
Future<List<HijriDate>> refreshGregorianOfficialRange({
  required DateTime from,
  required DateTime to,
})
```

Notes:
- `fromGregorianOfficial` is cache-first and returns a stored anchor even after
  its refresh TTL expires. It refreshes stale or missing data in the background.
- If no usable anchor exists, `fromGregorianOfficial` immediately returns
  `local_fallback` with `meta.isProvisional == true` and starts a background fetch.
- `refreshGregorianOfficial` and `refreshGregorianOfficialRange` let callers
  await the refresh and replace the currently displayed value.
- `fromGregorianOfficialRange` returns a complete continuous cached range
  immediately. If cache coverage is incomplete or inconsistent, it returns
  one whole-range local provisional result rather than mixing sources.
- Range refresh uses a batch anchor request; per-day remote loops are avoided.
- Anchor masa depan tidak pernah digunakan untuk tanggal target.
- Jika anchor berikutnya belum tersedia, sistem tetap menghitung beberapa bulan
  ke depan dari anchor terakhir menggunakan fallback lokal yang di-anchor dan
  memberi `meta.isProvisional == true`.
- Jika hasil fallback di antara dua anchor cocok dengan anchor berikutnya,
  `meta.validationStatus` bernilai `inferred_validated`. Ini tervalidasi secara
  kontinuitas, tetapi bukan pengganti anchor resmi langsung.
- Refresh range mencari anchor pendahulu hingga 35 hari sebelum tanggal `from`.
- Refresh eksplisit melempar `StateError` bila respons official tidak mencakup
  seluruh rentang atau memiliki kontinuitas tanggal yang invalid.
- Ketiadaan anchor masa depan saja bukan `StateError`; client harus memeriksa
  `meta.isProvisional` dan `meta.validationStatus`.
- Mode adjustment lama hanya aktif jika `allowLegacyAdjustments: true`.

The anchor HTTP response may include a `predecessor` record outside the
requested `from`/`to` dates. The Dart HTTP client merges this record into the
anchor dataset used by the resolver, while older responses containing only
`records` remain supported:

```json
{
  "schema_version": "1.1.0",
  "generated_at": "2026-09-06T19:33:33.029Z",
  "predecessor": {
    "official_gregorian_date": "2026-01-20",
    "hijri_year": 1447,
    "hijri_month": 8,
    "hijri_day": 1,
    "revision": 1,
    "published_at": "2026-01-19T00:00:00Z",
    "status": "final"
  },
  "records": []
}
```

`published_at` describes the official publication/correction time and is not
used as the Gregorian-to-Hijri calculation anchor. `generated_at` describes
when the response dataset was generated. Timestamps must be timezone-aware;
the production contract uses UTC RFC3339 (`Z`).

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

Anchor cache keys are based on the supplied Gregorian calendar date, not on
`DateTime.toUtc()`. This avoids shifting a local midnight into the previous
calendar date. The cache stores the anchor dataset associated with each queried
date; the resolver still filters out future anchors.

Official anchor contract:

1. `official_gregorian_date` is the first day of the Hijri month.
2. For one authority and region, only one active/final anchor may exist for a
   given Hijri year and month.
3. A revision replaces the previous record; the old record is retained only
   as audit history.
4. The distance between consecutive anchors must be 29 or 30 days.
5. The API does not need a new endpoint, but a range must include the nearest
   preceding anchor when the requested range starts after a month boundary.

## 3) Integration Contract

- Prayer outputs (`PrayerTimes`) are UTC.
- Gunakan `date` eksplisit pada `currentPrayer` / `nextPrayer`.
- Timezone conversion dilakukan di presentation/UI layer.
- Untuk Hijri official production:
  1. gunakan `withOfficial(...)`
  2. gunakan persistent cache
  3. log `meta.source`, `meta.revision`, dan `meta.isProvisional`

## 4) Javanese Calendar API

### Pasaran

Enum:
- `legi`
- `pahing`
- `pon`
- `wage`
- `kliwon`

Property:
- `label` (`String`): `Legi`, `Pahing`, `Pon`, `Wage`, `Kliwon`

### JavaneseDate

```dart
class JavaneseDate {
  final Pasaran pasaran;
  final String weton;
}
```

### JavaneseCalendar

```dart
const JavaneseCalendar()
```

Functions:

```dart
JavaneseDate fromGregorian(DateTime date)
```

```dart
List<JavaneseDate> fromGregorianRange({
  required DateTime from,
  required DateTime to,
})
```

Notes:
- `fromGregorianRange` returns inclusive range.
- Existing APIs remain unchanged; Javanese calendar is additive.

## 5) Quick Checklist

1. Pilih `CalculationMethod` dan buat `PrayerTimes`.
2. Jika butuh Hijri offline, gunakan `HijriCalendar()` + `HijriMethod.calculatedLocal` / `ummAlQura`.
3. Jika butuh Hijri official, gunakan `HijriCalendar.withOfficial(...)`.
4. Untuk range conversion gunakan `fromGregorianOfficialRange(...)`.
5. Untuk Flutter production, pakai cache persistent (Hive) di app layer.

## 6) Unified Calendar API (Transition Mode)

### CalendarResolveOptions

```dart
const CalendarResolveOptions({
  bool includeHijri = false,
  bool includeJavanese = false,
  HijriMethod hijriMethod = HijriMethod.calculatedLocal,
})
```

### UnifiedCalendarDate

```dart
class UnifiedCalendarDate {
  final DateTime gregorian;
  final HijriDate? hijri;
  final JavaneseDate? javanese;
}
```

### UnifiedCalendar

Constructors:

```dart
UnifiedCalendar()
```

```dart
UnifiedCalendar.withOfficialHijri({
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
Future<UnifiedCalendarDate> resolve(
  DateTime date, {
  CalendarResolveOptions options = const CalendarResolveOptions(),
})
```

```dart
Future<List<UnifiedCalendarDate>> resolveRange({
  required DateTime from,
  required DateTime to,
  CalendarResolveOptions options = const CalendarResolveOptions(),
})
```

```dart
Future<UnifiedCalendarDate> refreshOfficial(
  DateTime date, {
  bool includeJavanese = false,
})

Future<List<UnifiedCalendarDate>> refreshOfficialRange({
  required DateTime from,
  required DateTime to,
  bool includeJavanese = false,
})
```

Notes:
- Existing method signatures remain valid; official lookup is now cache-first.
- Use `refreshOfficial` / `refreshOfficialRange` when the caller must await a
  network refresh and repaint the current view with the updated values.
- Unified facade is additive for transition.
- Range + official Hijri uses a coherent cache/local result and batched
  background refresh flow.
