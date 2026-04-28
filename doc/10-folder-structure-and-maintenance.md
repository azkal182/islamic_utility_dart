# Folder Structure and Maintenance Guide

Dokumen ini menjelaskan struktur folder package `islamic_utility` agar maintenance dan debugging lebih mudah.

## Struktur Folder

```text
islamic_utility/
├─ lib/
│  ├─ islamic_utility.dart
│  └─ src/
│     ├─ core/
│     │  ├─ astronomy.dart
│     │  └─ solar_time.dart
│     ├─ models/
│     │  ├─ calculation_method.dart
│     │  ├─ calculation_parameters.dart
│     │  ├─ coordinates.dart
│     │  ├─ high_latitude_rule.dart
│     │  ├─ madhab.dart
│     │  ├─ prayer.dart
│     │  └─ shafaq.dart
│     ├─ prayer/
│     │  └─ prayer_times.dart
│     ├─ sunnah/
│     │  └─ sunnah_times.dart
│     └─ qibla/
│        └─ qibla.dart
├─ test/
│  └─ islamic_utility_test.dart
├─ example/
│  └─ islamic_utility_example.dart
└─ docs/
   ├─ 00-overview.md
   ├─ ...
   └─ 10-folder-structure-and-maintenance.md
```

## Tanggung Jawab Tiap Modul

- `lib/islamic_utility.dart`
  - Entry point export API publik.
  - Jangan taruh logic kalkulasi di file ini.

- `lib/src/core/`
  - Formula matematis/astronomis murni.
  - Harus bebas dari policy business (method preset, boundary policy).

- `lib/src/models/`
  - Kontrak data: enum, parameter, immutable model.
  - Jika ada perubahan API publik, review kompatibilitas dulu.

- `lib/src/prayer/`
  - Orkestrasi pipeline waktu sholat.
  - Tempat rule urutan: astronomy -> fallback -> adjustment -> rounding.

- `lib/src/sunnah/`
  - Turunan waktu dari `PrayerTimes`.
  - Tidak boleh memodifikasi hasil core prayer.

- `lib/src/qibla/`
  - Rumus arah kiblat.
  - Independen dari engine prayer.

## Aturan Maintenance

- Saat bug waktu sholat:
  1. Reproduksi di `test/` dulu.
  2. Tentukan layer bug (`core`, `prayer`, atau `params`).
  3. Fix sekecil mungkin di layer terkait.
  4. Tambah regression test sebelum merge.

- Saat menambah method baru:
  1. Tambahkan di `CalculationMethod` dan preset parameter.
  2. Tambahkan test preset + smoke parity.
  3. Dokumentasikan perubahan di docs terkait.

- Saat refactor formula:
  1. Jaga signature API tetap.
  2. Jalankan parity test untuk lokasi/musim representatif.
  3. Hindari ubah urutan operasi jika tidak perlu.

## Checklist Debug Cepat

- Cek input tanggal: konsisten untuk hari target.
- Cek koordinat: latitude/longitude valid.
- Cek `CalculationMethod` dan `highLatitudeRule`.
- Cek `precision` mode (`true` atau `false`).
- Cek boundary `currentPrayer`/`nextPrayer` dengan `date` eksplisit.

## Rencana Ekspansi V2

- Tambah `calendar_hijri/` dan `calendar_javanese/` sebagai modul terpisah.
- Pertahankan dependency direction: core tidak bergantung ke modul tambahan.
- Jika butuh facade gabungan, tambah modul `integration_facade/` tanpa mengubah output core.
