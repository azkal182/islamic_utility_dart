# Implementation Roadmap

Roadmap ini memandu tim dari parity hingga fitur lanjutan.

## Phase 1 - Parity Foundation

- Implement `core_astronomy` setara referensi.
- Implement `prayer_engine` dengan API kompatibel.
- Tambahkan preset method dan adjustment map.
- Lulus parity test minimum untuk method populer.

Deliverable:

- API dasar berjalan.
- Hasil waktu setara baseline pada dataset awal.

## Phase 2 - Boundary Hardening

- Kunci spesifikasi `currentPrayer`/`nextPrayer` lintas hari.
- Perbaiki jalur yang rentan mismatch timezone.
- Tambah test `after isha`, `after midnight`, `before fajr`.

Deliverable:

- Tidak ada next prayer invalid pada boundary harian.

Status: **Selesai**. API lintas hari menerima tanggal sipil lokasi melalui
`locationDate`; `nextPrayerDetails(at, locationDate)` juga menyertakan waktu
occurrence dan penanda `isNextDay`. API lama tetap kompatibel. Tes regresi
mengunci event tepat pada boundary, Imsak, setelah Isya, sebelum Fajr, jadwal
stale, dan pergantian tengah malam ketika tanggal UTC berbeda dari tanggal
lokal.

## Phase 3 - Full Parity Coverage

- Port seluruh matrix test method+lokasi+musim.
- Stabilkan toleransi numerik.
- Audit rounding dan fallback lintang tinggi.

Deliverable:

- Laporan parity lengkap dan reproducible.

Status: **Selesai untuk matrix regresi engine**. Matrix mencakup 15 preset,
7 koordinat, dan 4 tanggal musiman (420 kombinasi), toleransi pembulatan, serta
fallback sudut twilight yang tidak tercapai. Pembandingan jadwal resmi yang
tersedia mencakup preset Indonesia terhadap dataset Kemenag 2026. Referensi
otoritatif untuk setiap preset di semua negara belum tersedia; batas cakupan ini
dicatat pada laporan [matrix parity](15-prayer-parity-matrix.md).

## Phase 4 - Modular Expansion

- Tambah `calendar_hijri`.
- Tambah `calendar_javanese`.
- Sediakan facade gabungan untuk konsumsi app.

Deliverable:

- Fitur tambahan aktif tanpa mengubah output core prayer.

Status: **Selesai**. Modul Hijri, kalender Jawa, dan `UnifiedCalendar` sudah
tersedia melalui public API, disertai tes provider lokal/resmi, rentang tanggal,
kalender Jawa, dan facade gabungan. Implementasi ini terpisah dari engine
`PrayerTimes`.

## Quality Gates

- Semua unit test lulus.
- Tidak ada perubahan hasil core tanpa approval.
- Dokumen spesifikasi dan changelog selalu sinkron.

## Definition of Done

- Kontrak API terdokumentasi dan diuji.
- Parity test pass sesuai toleransi.
- Boundary test lintas hari pass.
- Arsitektur modular siap ditambah fitur.
