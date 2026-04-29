# Hijri Integration Guide (Bilingual)

This guide explains how to integrate Hijri features in `islamic_utility`.

Panduan ini menjelaskan cara integrasi fitur Hijriyah di `islamic_utility`.

## 1) Choose Method / Pilih Metode

- `HijriMethod.calculatedLocal`
  - EN: Offline civil/tabular calculation.
  - ID: Perhitungan lokal offline.
- `HijriMethod.ummAlQura`
  - EN: Dataset-based Umm al-Qura conversion.
  - ID: Konversi berbasis dataset Umm al-Qura.
- `kemenagRiOfficial` (via `HijriCalendar.withOfficial`)
  - EN: Local base + optional official adjustment API.
  - ID: Basis lokal + adjustment API official opsional.

## 2) Local Method Example

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

## 3) Umm al-Qura Method Example

```dart
final calendar = HijriCalendar();
final result = calendar.fromGregorian(
  DateTime.utc(2024, 3, 11),
  method: HijriMethod.ummAlQura,
);

print('${result.year}-${result.month}-${result.day}');
print(result.meta.source); // ummalqura_local
```

## 4) Official (Mock/Backend) Example

```dart
class MyAdjustmentClient implements HijriAdjustmentClient {
  @override
  Future<AdjustmentFetchResult> fetchByDate({required DateTime date, String? etag}) async {
    return AdjustmentFetchResult(
      statusCode: 200,
      etag: 'v1',
      records: [
        AdjustmentRecord(
          effectiveFrom: DateTime.utc(2024, 3, 1),
          effectiveTo: DateTime.utc(2024, 3, 31),
          adjustmentDays: 1,
          revision: 1,
          publishedAt: DateTime.utc(2024, 3, 10),
        ),
      ],
    );
  }
}

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: MyAdjustmentClient(),
);

final result = await calendar.fromGregorianOfficial(DateTime.utc(2024, 3, 11));
print(result.meta.source); // remote_adjusted/cache_adjusted/local
```

## 5) Source and Fallback Behavior

- `remote_adjusted`: adjustment applied from fresh API response.
- `cache_adjusted`: adjustment applied from local cache.
- `remote_anchor_adjusted`: anchor applied from fresh API response.
- `cache_anchor_adjusted`: anchor applied from local cache.
- `local`: no adjustment used (fallback).

Fallback priority:

1. remote adjustment
2. cached adjustment
3. local calculation

Anchor-first mode priority (implemented):

1. remote anchor
2. cached anchor
3. remote delta
4. cached delta
5. local

## 7) Syawal Boundary Example

Case:
- Base predicts `2026-01-30` as `1 Syawal`
- Official decides `2026-01-31` is `1 Syawal`

With anchor record:
- `official_gregorian_date = 2026-01-31`
- `hijri = 1447-10-01`

Expected:
- `2026-01-30` is not day 1 of Syawal
- `2026-01-31` is day 1 of Syawal

Runnable sample:
- `example/hijri_syawal_boundary_anchor_example.dart`

## 6) Integration Checklist

1. Start with `HijriCalendar()` for offline-safe integration.
2. Add `withOfficial(...)` when backend is ready.
3. Persist/replace in-memory cache for production apps.
4. Log `meta.source` and `meta.revision` for observability.
5. Add app-level tests for month-boundary dates.
