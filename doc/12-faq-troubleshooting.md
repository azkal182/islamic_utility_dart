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

ID: Jika test gagal, cek perubahan terbaru di `docs/03*` dan `docs/11-api-reference.md`.
EN: If tests fail, review recent changes in `docs/03*` and `docs/11-api-reference.md`.
