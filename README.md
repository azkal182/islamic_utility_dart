# islamic_utility

`islamic_utility` is a Dart package for prayer time calculation, sunnah times, and qibla direction.

ID: `islamic_utility` adalah package Dart untuk kalkulasi waktu sholat, sunnah times, dan arah kiblat.

## Features

- Prayer schedule: `imsak`, `fajr`, `dhuha`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`
- Cross-day boundaries: `ishaBefore`, `fajrAfter`
- Utilities: `currentPrayer`, `nextPrayer`, `timeForPrayer`
- `SunnahTimes`: `middleOfTheNight`, `lastThirdOfTheNight`
- `Qibla`: direction in degrees `0..360`

ID: Semua output `PrayerTimes` disimpan dalam UTC `DateTime`.

## Installation

```yaml
dependencies:
  islamic_utility: ^1.3.0
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

final now = DateTime.now().toUtc();
final current = prayerTimes.currentPrayer(date: now);
final next = prayerTimes.nextPrayer(date: now);

print('Current: $current');
print('Next: $next at ${prayerTimes.timeForPrayer(next)}');
print('Qibla: ${Qibla.qibla(const Coordinates(-6.2, 106.8))}');
```

## Main API

- `Coordinates(latitude, longitude)`
- `CalculationMethod` + `CalculationMethod.xxx.parameters`
- `CalculationParameters.copyWith(...)`
- `PrayerTimes(...)`
- `SunnahTimes(prayerTimes)`
- `Qibla.qibla(coordinates)`
- `HijriCalendar()`
- `HijriCalendar.withOfficial(...)`
- `fromGregorianOfficial(...)`
- `fromGregorianOfficialRange(from: ..., to: ...)`

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

final hijri = await calendar.fromGregorianOfficial(DateTime.utc(2026, 3, 21));
print('${hijri.year}-${hijri.month}-${hijri.day} (${hijri.meta.source})');
```

### Official (Range, Optimized Fetch)

```dart
final results = await calendar.fromGregorianOfficialRange(
  from: DateTime.utc(2026, 3, 15),
  to: DateTime.utc(2026, 3, 30),
);
```

Range behavior:
- Prefetch `anchors` and `adjustments` by range.
- Resolve per-day values from cache/local flow.
- Avoid per-day remote loop in range mode.

## Runnable Examples

- `dart run example/islamic_utility_example.dart`
- `dart run example/method_comparison_example.dart`
- `dart run example/custom_adjustment_example.dart`
- `dart run example/hijri_methods_example.dart`
- `dart run example/hijri_official_mock_example.dart`
- `dart run example/hijri_official_http_example.dart`
- `dart run example/hijri_official_range_hive_example.dart`
- `dart run example/hijri_syawal_boundary_anchor_example.dart`

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
  final adjustmentBox = await Hive.openBox<dynamic>(
    'islamic_utility_adjustment_cache',
  );
  final anchorBox = await Hive.openBox<dynamic>(
    'islamic_utility_anchor_cache',
  );

  final results = await convertRangeWithFlutterHive(
    adjustmentBox: adjustmentBox,
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
- Backend API Spec (Hijri Adjustment): `doc/backend/README.md`
- Public API Spec: `doc/01-public-api-spec.md`
- Core Calculation: `doc/02-calculation-core-spec.md`
- Astronomical Engine: `doc/03-astronomical-formulas.md`
