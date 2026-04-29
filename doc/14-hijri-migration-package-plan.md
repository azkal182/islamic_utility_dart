# Hijri Package Migration Plan (Anchor-First)

Dokumen ini menjelaskan perubahan yang akan dikerjakan di package `islamic_utility` untuk migrasi dari model adjustment berbasis `delta_days` ke model **anchor-first** untuk mode official (`kemenag_ri`).

## 1. Latar Belakang

Saat ini mode official masih memakai model:

- `effective_from`
- `effective_to`
- `adjustment_days`

Dengan cara apply: `resolved = base(date + adjustment_days)`.

Model ini valid untuk pergeseran harian, tetapi kurang natural untuk kasus sidang isbat awal bulan (mis. "2026-02-19 adalah 1 Ramadan").

## 2. Masalah pada Model Lama (Delta)

Masalah utama yang ditemukan:

1. Sulit untuk operator backend menentukan `adjustment_days` secara konsisten.
2. Sulit memastikan tanggal tertentu menjadi 1 bulan Hijriyah resmi.
3. Risiko error boundary lintas bulan (Ramadan -> Syawal, dll).
4. Sulit dijelaskan ke non-teknis karena delta bekerja sebagai shifting, bukan month-start override.

## 3. Metode Baru: Anchor-First

### Prinsip

Untuk keputusan official, backend mengirim **anchor bulan**:

- `official_gregorian_date` (contoh: `2026-02-19`)
- `hijri_year` (contoh: `1447`)
- `hijri_month` (contoh: `9`)
- `hijri_day` (umumnya `1`)

Arti: tanggal Gregorian tersebut dipatok menjadi tanggal Hijriyah official tersebut.

### Dampak

- Lebih mudah dipahami operator.
- Lebih presisi untuk sidang isbat.
- Boundary antar bulan menjadi jelas.

## 4. Flow Saat Ini vs Flow Baru

### Flow Saat Ini (Delta)

1. Hitung base local.
2. Ambil adjustment record.
3. Shift tanggal dengan `adjustment_days`.
4. Hitung ulang base dari tanggal yang sudah digeser.

### Flow Baru (Anchor-First)

1. Hitung base local (fallback).
2. Ambil anchor record untuk bulan terkait.
3. Jika anchor tersedia dan valid:
   - gunakan anchor sebagai titik referensi bulan,
   - derive hari-hari berikutnya dari anchor.
4. Jika anchor tidak tersedia:
   - fallback ke chain existing: remote delta/cache/local (sementara transisi).

## 5. Perubahan yang Akan Dikerjakan di Package

### 5.1 Model & Contract Baru

Tambahkan model baru:

- `HijriAnchorRecord`
  - `authority`
  - `country`
  - `regionScope`
  - `officialGregorianDate`
  - `hijriYear`
  - `hijriMonth`
  - `hijriDay`
  - `revision`
  - `publishedAt`

Tambahkan contract client:

- `fetchAnchorsByDate(...)`
- `fetchLatestAnchors(...)`

### 5.2 Resolver Logic

Tambahkan `AnchorResolver`:

- cari anchor paling relevan untuk tanggal input,
- apply priority rule (`revision` highest, `publishedAt` latest),
- hasilkan `HijriDate` final dari anchor.

### 5.3 Provider Official

`KemenagOfficialHijriProvider` akan:

1. prioritas pakai anchor record,
2. jika belum ada anchor, fallback ke delta record (backward compatibility),
3. jika keduanya tidak ada, fallback local.

### 5.4 Backward Compatibility

Selama migrasi, package tetap mendukung delta agar backend lama tidak putus.

Prioritas resolver selama transisi:

1. anchor official
2. delta official
3. cache
4. local

## 6. Metadata Output yang Diperbarui

`HijriResultMeta.source` akan diperluas:

- `remote_anchor_adjusted`
- `cache_anchor_adjusted`
- `remote_adjusted` (delta)
- `cache_adjusted` (delta)
- `local`

## 7. Testing Plan di Package

Tambahkan test baru:

1. anchor map correct start day (official 1 Ramadan).
2. anchor boundary month transition.
3. conflict resolution antar anchor revision.
4. fallback anchor -> delta -> local.
5. regression: existing prayer tests tetap hijau.

## 8. Kenapa Perubahan Ini Dibutuhkan

1. Menurunkan risiko human error di backend input.
2. Menyamakan model data dengan cara kerja sidang isbat.
3. Memudahkan audit dan explainability ke stakeholder non-teknis.
4. Menjaga package tetap robust (offline-first + optional official override).

## 9. Status Implementasi Saat Ini

Sudah tersedia:

- `HijriCalendar`
- local provider
- Umm al-Qura provider
- official provider (anchor-first + delta fallback)
- HTTP adjustment client + retry/backoff

Implementasi anchor-first yang sudah aktif:

- model `HijriAnchorRecord`
- anchor cache contract
- anchor resolver
- official provider flow:
  1. remote anchor
  2. cached anchor
  3. remote delta
  4. cached delta
  5. local
- HTTP client endpoint:
  - `/v1/hijri/anchors`
  - `/v1/hijri/anchors/latest`

Fase berikutnya:

- hardening formula month transition anchor untuk panjang bulan 29/30 berbasis data authority jika tersedia.
- tambah integration tests dengan fixture official real-world multi bulan.
