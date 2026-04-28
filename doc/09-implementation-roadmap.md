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

## Phase 3 - Full Parity Coverage

- Port seluruh matrix test method+lokasi+musim.
- Stabilkan toleransi numerik.
- Audit rounding dan fallback lintang tinggi.

Deliverable:

- Laporan parity lengkap dan reproducible.

## Phase 4 - Modular Expansion

- Tambah `calendar_hijri`.
- Tambah `calendar_javanese`.
- Sediakan facade gabungan untuk konsumsi app.

Deliverable:

- Fitur tambahan aktif tanpa mengubah output core prayer.

## Quality Gates

- Semua unit test lulus.
- Tidak ada perubahan hasil core tanpa approval.
- Dokumen spesifikasi dan changelog selalu sinkron.

## Definition of Done

- Kontrak API terdokumentasi dan diuji.
- Parity test pass sesuai toleransi.
- Boundary test lintas hari pass.
- Arsitektur modular siap ditambah fitur.
