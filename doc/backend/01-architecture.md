# 01 - Architecture

## Prinsip Utama

1. **Offline-first**: hasil Hijriyah dasar selalu tersedia dari local engine.
2. **Adjustment-only**: backend tidak mengirim full kalender, hanya koreksi resmi.
3. **Deterministic merge**: hasil final harus konsisten untuk input yang sama.

## High-Level Flow

1. Client menghitung `baseHijri` dari metode lokal.
2. Client cek cache adjustment lokal (berdasarkan rentang tanggal).
3. Jika cache stale/empty, client request API adjustment.
4. Client apply adjustment jika record cocok.
5. Client mengembalikan hasil final + metadata sumber.

## Component Diagram

- `LocalHijriEngine`
  - Hitung tanggal Hijriyah dasar.
- `AdjustmentResolver`
  - Apply data adjustment ke hasil lokal.
- `AdjustmentCache`
  - Menyimpan response backend + ETag.
- `RemoteAdjustmentClient`
  - Fetch adjustment dari API.

## Contract Hasil ke App Layer

Objek hasil disarankan memuat:
- `hijriDate`
- `isAdjusted` (`bool`)
- `adjustmentDays` (`int`)
- `source` (`local` | `remote_adjusted` | `cache_adjusted`)
- `authority` (mis. `kemenag_ri`)
- `revision`

## Failure Strategy

- API down -> pakai cache terakhir jika ada.
- Cache tidak ada -> pakai hasil lokal (tanpa adjust).
- Invalid response -> ignore record invalid, log warning.
