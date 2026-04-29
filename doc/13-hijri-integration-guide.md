# Hijri Integration Guide (Bilingual)

EN: This guide explains practical Hijri integration in `islamic_utility`.
ID: Panduan ini menjelaskan integrasi praktis fitur Hijriyah di `islamic_utility`.

## 1) Choose the Mode / Pilih Mode

- `HijriMethod.calculatedLocal`
  - EN: Fully offline civil/tabular conversion.
  - ID: Konversi lokal offline (civil/tabular).
- `HijriMethod.ummAlQura`
  - EN: Offline conversion based on bundled Umm al-Qura data.
  - ID: Konversi offline berbasis dataset Umm al-Qura.
- `kemenagRiOfficial` via `HijriCalendar.withOfficial(...)`
  - EN: Anchor-first official flow with API + cache + fallback.
  - ID: Alur official anchor-first dengan API + cache + fallback.

## 2) Local Offline Example

```dart
import 'package:islamic_utility/islamic_utility.dart';

final calendar = HijriCalendar();
final result = calendar.fromGregorian(
  DateTime.utc(2024, 3, 11),
  method: HijriMethod.calculatedLocal,
);

print('${result.year}-${result.month}-${result.day}');
print(result.meta.source); // local_calculated_civil
```

## 3) Umm al-Qura Offline Example

```dart
final calendar = HijriCalendar();
final result = calendar.fromGregorian(
  DateTime.utc(2024, 3, 11),
  method: HijriMethod.ummAlQura,
);

print('${result.year}-${result.month}-${result.day}');
print(result.meta.source); // ummalqura_local
```

## 4) Official Single-Date Example

```dart
final client = HttpHijriAdjustmentClient(
  baseUrl: 'https://your-backend.example.com/api',
  apiKey: 'your-api-key',
);

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
);

final result = await calendar.fromGregorianOfficial(DateTime.utc(2026, 3, 21));
print('${result.year}-${result.month}-${result.day}');
print(result.meta.source);
```

## 5) Official Range Example (No Per-Day Remote Loop)

```dart
final results = await calendar.fromGregorianOfficialRange(
  from: DateTime.utc(2026, 3, 15),
  to: DateTime.utc(2026, 3, 30),
);
```

Behavior:
- EN: Range flow performs remote prefetch once per dataset (`anchors` and `adjustments`), then resolves daily values from cache/local computation.
- ID: Alur range melakukan prefetch remote sekali per jenis data (`anchors` dan `adjustments`), lalu resolusi harian dari cache/kalkulasi lokal.

## 6) Persistent Cache (Hive)

### Dart CLI / Server

```dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:islamic_utility/islamic_utility.dart';

final dir = Directory('.hive_cache')..createSync(recursive: true);
Hive.init(dir.path);

final adjustmentBox = await Hive.openBox<dynamic>('islamic_utility_adjustment_cache');
final anchorBox = await Hive.openBox<dynamic>('islamic_utility_anchor_cache');

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
  cache: HiveHijriAdjustmentCache(adjustmentBox),
  anchorCache: HiveHijriAnchorCache(anchorBox),
);
```

### Flutter App

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_utility/islamic_utility.dart';

await Hive.initFlutter();
final adjustmentBox = await Hive.openBox<dynamic>('islamic_utility_adjustment_cache');
final anchorBox = await Hive.openBox<dynamic>('islamic_utility_anchor_cache');

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
  cache: HiveHijriAdjustmentCache(adjustmentBox),
  anchorCache: HiveHijriAnchorCache(anchorBox),
);
```

## 7) Source Metadata and Fallback

Common `meta.source` values:
- `remote_anchor_adjusted`
- `cache_anchor_adjusted`
- `remote_adjusted`
- `cache_adjusted`
- `remote_noop`
- `local`

Meaning:
- EN: `anchor` sources indicate anchor-first resolution path.
- ID: source `anchor` menunjukkan jalur anchor-first yang dipakai.

## 8) Fallback Priority

For official mode:
1. anchor from cache
2. anchor from remote
3. delta adjustment from cache/remote
4. local calculated fallback

For official range mode:
1. prefetch anchors range
2. prefetch adjustments range
3. resolve each day from cache/local without per-day remote loop

## 9) Production Checklist

1. Use `HijriCalendar.withOfficial(...)`.
2. Use persistent cache (`HiveHijriAdjustmentCache` + `HiveHijriAnchorCache`).
3. Prefer `fromGregorianOfficialRange(...)` for calendar pages/list views.
4. Keep `authority`, `regionScope`, and `country` consistent with backend policy.
5. Log `meta.source`, `meta.revision`, and request IDs for observability.
6. Add boundary tests (Ramadan/Syawal/Zulhijjah transitions).

## 10) Runnable Examples

- `example/hijri_official_mock_example.dart`
- `example/hijri_official_http_example.dart`
- `example/hijri_official_range_hive_example.dart`
- `example/hijri_official_range_hive_flutter_example.dart`
- `example/hijri_syawal_boundary_anchor_example.dart`
