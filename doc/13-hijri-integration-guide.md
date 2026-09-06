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
  - EN: Anchor-first official flow with API + cache + explicit provisional fallback.
  - ID: Alur official anchor-first dengan API + cache + fallback provisional yang eksplisit.

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
- EN: Range flow prefetches anchors once, then resolves daily values from cache.
- ID: Alur range melakukan prefetch anchor sekali, lalu resolusi harian dari cache.
- EN: The client never uses an anchor dated after the requested Gregorian date.
- ID: Client tidak pernah menggunakan anchor yang tanggalnya berada setelah tanggal Gregorian target.
- EN: An anchor without a following boundary may produce only a provisional result; the client does not assume every Hijri month has 30 days.
- ID: Anchor tanpa batas bulan berikutnya hanya boleh menghasilkan data provisional; client tidak mengasumsikan semua bulan Hijriah memiliki 30 hari.
- EN: For an official result across a Hijri month boundary, the cache/API must contain the preceding and following month anchors.
- ID: Untuk hasil official yang melewati pergantian bulan Hijriah, cache/API harus memiliki anchor bulan sebelumnya dan berikutnya.
- EN: Range resolution validates daily continuity. If fallback and official anchors create a duplicate or skipped Hijri date, it throws `StateError` instead of returning an unsafe range.
- ID: Resolusi range memvalidasi kontinuitas harian. Jika fallback dan anchor official menghasilkan tanggal Hijriah duplikat atau lompat, method melempar `StateError` dan tidak mengembalikan range yang berbahaya.
- EN: A single-date lookup may return `local_fallback` when no official anchor is available; this is different from range behavior and must be treated as provisional.
- ID: Lookup satu tanggal dapat mengembalikan `local_fallback` ketika anchor official belum tersedia; ini berbeda dari perilaku range dan wajib diperlakukan sebagai provisional.

The anchor response can contain a `predecessor` outside the requested range.
The HTTP client merges it into the resolver dataset, so a range beginning in
the middle of a Hijri month can be resolved without repeating the first day.
Responses from older API versions that contain only `records` remain supported.

Handle the range error explicitly:

```dart
try {
  final results = await calendar.fromGregorianOfficialRange(
    from: from,
    to: to,
  );
} on StateError {
  // Request/publish the preceding official anchor, or show that
  // official data is incomplete. Do not silently present the range as final.
}
```

## 6) Persistent Cache (Hive)

### Dart CLI / Server

```dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:islamic_utility/islamic_utility.dart';

final dir = Directory('.hive_cache')..createSync(recursive: true);
Hive.init(dir.path);

final anchorBox = await Hive.openBox<dynamic>('islamic_utility_anchor_cache');

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
  anchorCache: HiveHijriAnchorCache(anchorBox),
);
```

### Flutter App

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:islamic_utility/islamic_utility.dart';

await Hive.initFlutter();
final anchorBox = await Hive.openBox<dynamic>('islamic_utility_anchor_cache');

final calendar = HijriCalendar.withOfficial(
  adjustmentClient: client,
  anchorCache: HiveHijriAnchorCache(anchorBox),
);
```

## 7) Source Metadata and Fallback

Common `meta.source` values:
- `remote_anchor`
- `cache_anchor`
- `remote_anchor_provisional`
- `cache_anchor_provisional`
- `local_fallback`
- `local`
- `remote_adjusted` / `cache_adjusted` (legacy only)

Meaning:
- EN: `*_anchor` means the result was resolved from an anchor that is not in the future.
- ID: `*_anchor` berarti hasil dihitung dari anchor yang tidak berada di masa depan.
- EN: `*_provisional` means the result is extrapolated from the last anchor or
  is not backed by a direct monthly anchor; do not present it as final official data.
- ID: `*_provisional` berarti hasil diekstrapolasi dari anchor terakhir atau
  tidak memiliki anchor bulanan langsung; jangan menampilkannya sebagai data official final.
- EN: `meta.validationStatus == inferred_validated` means a missing
  intermediate anchor is consistent with a later official anchor.
- ID: `meta.validationStatus == inferred_validated` berarti anchor antara yang
  hilang konsisten dengan anchor resmi berikutnya.
- EN: `local_fallback` is still a usable calculated date, but it is provisional and is not an official authority result.
- ID: `local_fallback` tetap menghasilkan tanggal kalkulasi yang dapat dipakai, tetapi bersifat provisional dan bukan hasil official authority.

## 8) Fallback Priority

For official mode:
1. valid anchor from cache (`anchorDate <= targetDate`)
2. valid anchor from remote
3. provisional anchor result when the next boundary is not known
4. anchored local fallback (`meta.isProvisional == true`)

Legacy adjustment mode is disabled by default. It can be enabled temporarily with
`allowLegacyAdjustments: true`, but it should not be used for new integrations.

For official range mode:
1. prefetch anchors range
2. resolve each day from cache/local without per-day remote loop
3. continue missing future months as provisional anchored fallback
4. reject only an inconsistent sequence with `StateError`

## 9) Production Checklist

1. Use `HijriCalendar.withOfficial(...)`.
2. Use persistent anchor cache (`HiveHijriAnchorCache`).
3. Prefer `fromGregorianOfficialRange(...)` for calendar pages/list views.
4. Keep `authority`, `regionScope`, and `country` consistent with backend policy.
5. Log `meta.source`, `meta.revision`, and request IDs for observability.
6. Add boundary tests (Ramadan/Syawal/Zulhijjah transitions).
7. Treat `local_fallback` and `*_provisional` as non-final data.
8. When publishing a revised anchor, increase `revision`; old records must be superseded.

## 10) Runnable Examples

- `example/hijri_official_mock_example.dart`
- `example/hijri_official_http_example.dart`
- `example/hijri_official_range_hive_example.dart`
- `example/hijri_official_range_hive_flutter_example.dart`
