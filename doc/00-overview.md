# Prayer Engine Docs Overview

## Tujuan

Dokumen ini menjadi spesifikasi teknis untuk membangun package baru dengan hasil kalkulasi setara `adhan_dart`, namun dengan arsitektur lebih modular agar mudah ditambah fitur (Hijriyah, Pasaran Jawa, dan lainnya) tanpa mengubah hasil inti waktu sholat.

## Scope

- Kalkulasi waktu sholat wajib (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`) dan `sunrise`.
- Utilitas jadwal (`currentPrayer`, `nextPrayer`, `timeForPrayer`).
- `SunnahTimes` (middle of night, last third of night).
- Arah kiblat (`Qibla`).
- Spesifikasi parameter dan method preset.
- Strategi parity test agar output tidak berbeda dari package referensi.

## Non-Scope (sementara)

- Implementasi kalender Hijriyah.
- Implementasi kalender Jawa/Pasaran.
- UI/Flutter component.

Fitur di atas disiapkan pada desain modular v2 (lihat `docs/08-modular-architecture-for-v2.md`).

## Prinsip Kompatibilitas Hasil

- Hasil waktu harus setara dengan referensi pada input yang sama: `date`, `coordinates`, `calculationParameters`, dan mode `precision`.
- Perbandingan hasil dilakukan pada UTC `DateTime` internal; display timezone adalah layer terpisah.
- Semua aturan fallback lintang tinggi dan seasonal adjustment harus dipertahankan.

## Definisi "Tidak Berbeda"

- `precision: true`: selisih ideal 0 detik, toleransi implementasi maksimal 1 detik.
- `precision: false`: hasil dibulatkan menit terdekat, toleransi maksimal 1 menit.
- Khusus dataset tertentu (mis. adhan-js compatibility), ikuti toleransi uji per skenario.

## Daftar Dokumen

- `docs/01-public-api-spec.md`
- `docs/02-calculation-core-spec.md`
- `docs/03-astronomical-formulas.md`
- `docs/04-calculation-parameters.md`
- `docs/05-timezone-and-datetime-contract.md`
- `docs/06-next-prayer-boundary-spec.md`
- `docs/07-test-parity-strategy.md`
- `docs/08-modular-architecture-for-v2.md`
- `docs/09-implementation-roadmap.md`
