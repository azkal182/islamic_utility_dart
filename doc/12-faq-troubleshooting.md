# FAQ & Troubleshooting (Bilingual)

Dokumen ini berisi masalah yang paling sering terjadi saat integrasi `islamic_utility`.
This document covers the most common issues when integrating `islamic_utility`.

## 1) Kenapa hasil waktu terlihat "geser" dari aplikasi lain?

ID:
- Pastikan method sama (`CalculationMethod`).
- Pastikan parameter sama (`madhab`, `highLatitudeRule`, `adjustments`, `ishaInterval`).
- Pastikan timezone handling konsisten (semua output package ini UTC).

EN:
- Ensure the same calculation method is used.
- Ensure matching parameters (`madhab`, `highLatitudeRule`, `adjustments`, `ishaInterval`).
- Ensure timezone handling is consistent (this package outputs UTC times).

## 2) Kenapa `nextPrayer()` kadang tidak sesuai ekspektasi?

ID:
- Selalu kirim argumen `date` eksplisit: `nextPrayer(date: DateTime.now().toUtc())`.
- Hindari bergantung pada `DateTime.now()` tanpa konversi timezone yang benar.

EN:
- Always pass an explicit `date` argument.
- Avoid relying on raw `DateTime.now()` without proper timezone conversion.

## 3) Bagaimana cara menampilkan waktu lokal (WIB/WITA/WIT)?

ID:
- `PrayerTimes` menyimpan waktu dalam UTC.
- Konversi ke timezone lokal di layer presentasi (UI/app layer).

EN:
- `PrayerTimes` stores times in UTC.
- Convert to local timezone in your presentation layer.

## 4) Kenapa `dhuha` berbeda dengan referensi lokal?

ID:
- Default `dhuha` adalah `sunrise + 20 menit`.
- Sesuaikan dengan `dhuhaOffsetMinutes`:

```dart
final params = CalculationMethod.indonesian.parameters.copyWith(
  dhuhaOffsetMinutes: 30,
);
```

EN:
- Default `dhuha` is `sunrise + 20 minutes`.
- Adjust it using `dhuhaOffsetMinutes`.

## 5) Bagaimana aturan `imsak` dihitung?

ID:
- Saat ini `imsak = fajr - 10 menit`.

EN:
- Currently `imsak = fajr - 10 minutes`.

## 6) Kenapa ada `ishaBefore` dan `fajrAfter`?

ID:
- Itu adalah nilai boundary lintas hari.
- Berguna untuk kasus sebelum fajr dan setelah isha saat menentukan current/next prayer.

EN:
- These are cross-day boundary values.
- They are useful for before-fajr and after-isha current/next prayer logic.

## 7) Bagaimana mengatur lintang tinggi (high latitude)?

ID:
- Gunakan `highLatitudeRule`:
  - `middleOfTheNight`
  - `seventhOfTheNight`
  - `twilightAngle`
- Untuk `moonsightingCommittee`, seasonal adjustment dan aturan latitude tinggi diterapkan.

EN:
- Use `highLatitudeRule`:
  - `middleOfTheNight`
  - `seventhOfTheNight`
  - `twilightAngle`
- For `moonsightingCommittee`, seasonal adjustments and high-latitude rules apply.

## 8) Precision mode sebaiknya pakai yang mana?

ID:
- `precision: true` untuk kebutuhan detik-level/parity test.
- `precision: false` untuk display user yang lebih sederhana.

EN:
- Use `precision: true` for second-level precision/parity testing.
- Use `precision: false` for simplified user display.

## 9) Cara cepat debug mismatch

ID:
1. Cek `CalculationMethod`.
2. Cek semua override `CalculationParameters`.
3. Cek UTC vs local conversion.
4. Cek `precision` mode.
5. Bandingkan menggunakan timestamp UTC mentah.

EN:
1. Check `CalculationMethod`.
2. Check all `CalculationParameters` overrides.
3. Check UTC vs local conversion.
4. Check `precision` mode.
5. Compare raw UTC timestamps.

## 10) Menjalankan validasi cepat

```bash
dart test
dart run example/islamic_utility_example.dart
```

ID: Jika test gagal, cek perubahan terbaru di `doc/03*` dan `doc/11-api-reference.md`.
EN: If tests fail, review recent changes in `doc/03*` and `doc/11-api-reference.md`.

## 11) Metode Hijriyah mana yang sebaiknya dipakai?

ID:
- `calculatedLocal`: aman untuk offline, deterministic.
- `ummAlQura`: bagus untuk kebutuhan kompatibilitas Umm al-Qura.
- official (`withOfficial`): gunakan saat butuh koreksi authority (`kemenag_ri`) jika tersedia.

EN:
- `calculatedLocal`: safe offline, deterministic.
- `ummAlQura`: useful for Umm al-Qura compatibility.
- official (`withOfficial`): use when authority-based Hijri anchors (`kemenag_ri`) are needed.

## 12) Apa yang terjadi jika backend official down?

ID:
- Sistem fallback otomatis: remote -> cache -> local.
- Jika anchor tersedia, source akan `cache_anchor` atau `cache_anchor_provisional`.
- Jika anchor belum cukup, source akan `local_fallback` dengan `meta.isProvisional == true`.
- Untuk pemanggilan range, sistem memvalidasi urutan harian. Jika terjadi tanggal duplikat atau lompat, method melempar `StateError`; client harus menangani error tersebut dan tidak menampilkan hasil parsial sebagai data official.

EN:
- Fallback chain is automatic: remote -> cache -> local.
- If a valid anchor exists, source becomes `cache_anchor` or `cache_anchor_provisional`.
- If anchors are incomplete, source becomes `local_fallback` with `meta.isProvisional == true`.
- For range calls, daily continuity is validated. If a duplicate or skipped Hijri date is detected, the method throws `StateError`; the client must handle it and must not present partial output as official data.

## 13) Kenapa hasil Hijriyah bisa berbeda antar metode?

ID:
- Perbedaan metode adalah hal normal.
- Metode official dapat berbeda dari metode lokal/dataset karena keputusan authority.

EN:
- Method differences are expected.
- Official method may differ from local/dataset methods due to authority decisions.
