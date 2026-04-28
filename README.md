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
  islamic_utility: ^1.1.0
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

## Runnable Examples

- `dart run example/islamic_utility_example.dart`
- `dart run example/method_comparison_example.dart`
- `dart run example/custom_adjustment_example.dart`
- `dart run example/hijri_methods_example.dart`
- `dart run example/hijri_official_mock_example.dart`
- `dart run example/hijri_official_http_example.dart`

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
