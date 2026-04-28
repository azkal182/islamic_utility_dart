# 05 - Conflict and Priority Rules

## Priority Chain

1. `remote_adjusted` (fresh API data)
2. `cache_adjusted` (cached API data)
3. `local` (no adjustment)

## Conflict Resolution

Jika beberapa record cocok pada tanggal yang sama:

1. Pilih `authority` yang diminta client.
2. Pilih `region_scope` paling spesifik (V1: hanya `national`).
3. Pilih `revision` paling tinggi.
4. Jika revision sama, pilih `published_at` terbaru.
5. Jika masih konflik, pilih `id` lexicographically terbesar dan log warning.

## Merge Rule

- Adjustment diterapkan pada hasil Hijriyah lokal, bukan mengganti seluruh dataset.
- Formula sederhana V1:
  - `resolvedDate = baseDate + adjustment_days`

## Data Safety

- Abaikan record invalid (tanggal tidak valid, revision tidak valid).
- Jangan crash app bila response parsial rusak.
