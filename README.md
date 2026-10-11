# islamic_utility

`islamic_utility` is a Dart package for prayer time calculation, sunnah times, and qibla direction.

ID: `islamic_utility` adalah package Dart untuk kalkulasi waktu sholat, sunnah times, dan arah kiblat.

## Features

- Prayer schedule: `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`
- Cross-day boundaries: `ishaBefore`, `fajrAfter`
- Utilities: `currentPrayer`, `nextPrayer`, `timeForPrayer`
- `SunnahTimes`: `middleOfTheNight`, `lastThirdOfTheNight`
- `Qibla`: direction in degrees `0..360`
- `JavaneseCalendar`: pasaran Jawa (`Legi`, `Pahing`, `Pon`, `Wage`, `Kliwon`)

ID: Semua output `PrayerTimes` disimpan dalam UTC `DateTime`.

## Installation

```yaml
dependencies:
  islamic_utility: ^1.6.0
```

```bash
dart pub get
```

ID: Jika dipakai lokal dulu, Anda bisa gunakan `path:` dependency.

## Quick Start

```dart
import 'package:islamic_utility/islamic_utility.dart';

final params = CalculationMethod.indonesian.parameters;
final prayerTimes = PrayerTimes(
  date: DateTime.utc(2026, 5, 1),
  coordinates: const Coordinates(-6.2, 106.8),
  calculationParameters: params,
  precision: true,
);

final now = prayerTimes.isha.add(const Duration(minutes: 1));
final current = prayerTimes.currentPrayer(date: now);
final next = prayerTimes.nextPrayerDetails(
  at: now,
  // Use the target location's calendar date for this instant. A live app can
  // get it from its timezone package (for example, as a TZDateTime).
  locationDate: DateTime.utc(2026, 5, 1),
  options: const NextPrayerOptions(
    skip: {Prayer.sunrise, Prayer.dhuha},
  ),
);

print('Current: $current');
print('Next: ${next.prayer} at ${next.time}');
print('Next prayer is on another local day: ${next.isNextDay}');
print('Qibla: ${Qibla.qibla(const Coordinates(-6.2, 106.8))}');
```

## Main API

- `Coordinates(latitude, longitude)`
- `CalculationMethod` + `CalculationMethod.xxx.parameters`
- `CalculationParameters.copyWith(...)`
- `PrayerTimes(...)`
- `NextPrayerOptions` / `ImsakPolicy`
- `SunnahTimes(prayerTimes)`
- `Qibla.qibla(coordinates)`
- `HijriCalendar()`
- `HijriCalendar.withOfficial(...)`
- `fromGregorianOfficial(...)`
- `fromGregorianOfficialRange(from: ..., to: ...)`
- `JavaneseCalendar.fromGregorian(...)`
- `JavaneseCalendar.fromGregorianRange(...)`
- `UnifiedCalendar.resolve(...)`
- `UnifiedCalendar.resolveRange(...)`

ID: Referensi API lengkap ada di `doc/11-api-reference.md`.

## Advanced Configuration

```dart
final params = CalculationMethod.indonesian.parameters.copyWith(
  madhab: Madhab.hanafi,
  highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
  dhuhaOffsetMinutes: 30,
);

params.adjustments[Prayer.fajr] = 2;
params.adjustments[Prayer.isha] = 2;
```

## Timezone Contract

- Use UTC consistently in domain logic.
- Always pass explicit `date` for `currentPrayer` and `nextPrayer`.
- Convert UTC output to local timezone in presentation/UI layer.
- Use `nextPrayerDetails` when displaying the actual next event time or its
  local day. `nextPrayer` returns only an enum, so `timeForPrayer` cannot
  distinguish a future-day occurrence (such as tomorrow's Imsak) from today's
  occurrence.

```dart
final nowUtc = DateTime.now().toUtc();
final next = prayerTimes.nextPrayer(date: nowUtc);
```

## Precision

- `precision: true` -> keeps second-level precision
- `precision: false` -> rounds to nearest minute

## Hijri Quick Start

### Offline (Local / Umm al-Qura)

```dart
final calendar = HijriCalendar();

final local = calendar.fromGregorian(
  DateTime.utc(2026, 3, 21),
  method: HijriMethod.calculatedLocal,
);

final umm = calendar.fromGregorian(
  DateTime.utc(2026, 3, 21),
  method: HijriMethod.ummAlQura,
);
```

### Official (Single Date)

```dart
final client = HttpHijriAdjustmentClient(
  baseUrl: 'https://your-backend.example.com/api',
  apiKey: 'your-api-key',
);

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
);

final hijri = await calendar.refreshGregorianOfficial(DateTime.utc(2026, 3, 21));
print('${hijri.year}-${hijri.month}-${hijri.day} (${hijri.meta.source})');
```

Official mode uses Hijri month-start anchors. An anchor is valid only for its
date and later dates; a future anchor is never used to resolve historical
dates. If the following anchor is missing, the provider continues from the
last anchor using an anchored local fallback. Inspect
`result.meta.isProvisional` before presenting it as official. If a later anchor
confirms the inferred boundaries, `result.meta.validationStatus` is
`inferred_validated`. Normal range lookups return complete cached ranges or a
whole-range local provisional result. Explicit refresh methods report an
inconsistent server anchor sequence with `StateError`.

The old adjustment flow is disabled by default. It can be enabled temporarily
for migration with `allowLegacyAdjustments: true`, but new integrations should
publish and consume anchors instead.

### Official (Range, Optimized Fetch)

```dart
final results = await calendar.refreshGregorianOfficialRange(
  from: DateTime.utc(2026, 3, 15),
  to: DateTime.utc(2026, 3, 30),
);
```

Handle invalid official data explicitly:

```dart
try {
  final results = await calendar.refreshGregorianOfficialRange(from: from, to: to);
} on StateError {
  // The anchor sequence is invalid or contains a duplicate/skip.
  // Do not present a partial result as final official data.
}
```

Range behavior:
- Return a complete, continuous cached range immediately, even after its refresh
  TTL expires; refresh expired data in the background.
- If the cache does not cover the whole range, return one coherent local
  provisional range rather than mixing local and official dates.
- Fetch anchors in one range request (including up to 35 days before the start)
  during background refresh; there is no per-day remote loop.
- Use `refreshGregorianOfficialRange(from: ..., to: ...)` when the caller needs
  to wait for the refresh and update the current view.
- Never use an anchor dated after the requested Gregorian date.
- Continue several future months from the last anchor using an anchored local
  fallback and mark them provisional.
- Reconcile the provisional segment when a later anchor is received; the new
  anchor always wins and affected cache entries must be refreshed.
- Reject only an inconsistent sequence with `StateError`; missing future
  anchors alone are not an error.

## Javanese Pasaran Quick Start

```dart
final java = const JavaneseCalendar();
final item = java.fromGregorian(DateTime.utc(2026, 3, 21));
print(item.pasaran.label); // Legi/Pahing/Pon/Wage/Kliwon
print(item.weton); // e.g. "Sabtu Kliwon"
```

## Unified Calendar Quick Start (Transition-Friendly)

```dart
final unified = UnifiedCalendar();
final result = await unified.resolve(
  DateTime.utc(2026, 3, 21),
  options: const CalendarResolveOptions(
    includeHijri: true,
    includeJavanese: true,
    hijriMethod: HijriMethod.calculatedLocal,
  ),
);

print(result.gregorian); // always available
print(result.hijri); // optional, based on options
print(result.javanese); // optional, based on options
```

## Runnable Examples

- `dart run example/islamic_utility_example.dart`
- `dart run example/method_comparison_example.dart`
- `dart run example/custom_adjustment_example.dart`
- `dart run example/hijri_methods_example.dart`
- `dart run example/hijri_official_mock_example.dart`
- `dart run example/hijri_official_http_example.dart`
- `dart run example/hijri_official_range_hive_example.dart`
- `dart run example/javanese_pasaran_example.dart`
- `dart run example/unified_calendar_example.dart`

## Flutter + Hive (Persistent Range Cache)

`islamic_utility` tetap package Dart murni. Untuk Flutter, lakukan inisialisasi
`Hive.initFlutter()` di layer aplikasi, lalu berikan `Box` ke helper example:
`example/hijri_official_range_hive_flutter_example.dart`.

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_utility/islamic_utility.dart';
import 'package:your_app/hijri_official_range_hive_flutter_example.dart';

Future<void> bootstrapHijri() async {
  await Hive.initFlutter();
final anchorBox = await Hive.openBox<dynamic>(
  'islamic_utility_anchor_cache',
);

  final results = await convertRangeWithFlutterHive(
    anchorBox: anchorBox,
    baseUrl: 'https://your-backend.example.com/api',
    apiKey: 'your-api-key',
    from: DateTime.utc(2026, 3, 15),
    to: DateTime.utc(2026, 3, 30),
  );

  for (final item in results) {
    print('${item.year}-${item.month}-${item.day} (${item.meta.source})');
  }
}
```

## Testing

```bash
dart test
```

## Documentation

- Index: `doc/README.md`
- API Reference (Bilingual): `doc/11-api-reference.md`
- FAQ & Troubleshooting (Bilingual): `doc/12-faq-troubleshooting.md`
- Hijri Integration Guide (Bilingual): `doc/13-hijri-integration-guide.md`
- Backend API Spec (Hijri Anchor-First): `doc/backend/README.md`
- Public API Spec: `doc/01-public-api-spec.md`
- Core Calculation: `doc/02-calculation-core-spec.md`
- Astronomical Engine: `doc/03-astronomical-formulas.md`
