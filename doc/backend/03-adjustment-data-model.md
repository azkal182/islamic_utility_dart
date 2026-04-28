# 03 - Adjustment Data Model

## Record Schema (V1)

```json
{
  "id": "adj_2027_1449_09_v1",
  "authority": "kemenag_ri",
  "country": "ID",
  "region_scope": "national",
  "effective_from": "2027-02-08",
  "effective_to": "2027-03-10",
  "adjustment_days": 1,
  "reason": "isbat_hilal",
  "revision": 3,
  "published_at": "2027-02-07T12:10:00Z",
  "notes": "Ramadan starts one day later than base method"
}
```

## Field Rules

- `id`: unik global.
- `authority`: default `kemenag_ri`.
- `country`: ISO-3166 alpha-2 (`ID`).
- `region_scope`: `national` (V1), dapat diperluas.
- `effective_from`: tanggal awal (inclusive).
- `effective_to`: tanggal akhir (inclusive), opsional untuk 1 hari.
- `adjustment_days`: integer, rekomendasi nilai `-1`, `0`, `1`.
- `reason`: kode alasan (mis. `isbat_hilal`, `policy_update`).
- `revision`: naik monoton untuk record yang sama.
- `published_at`: timestamp UTC RFC3339.

## Dataset Envelope

```json
{
  "schema_version": "1.0.0",
  "authority": "kemenag_ri",
  "generated_at": "2027-02-07T12:12:00Z",
  "records": []
}
```

## Validation

- `effective_from <= effective_to`.
- `adjustment_days` integer.
- `revision >= 1`.
- Tidak boleh ada dua record aktif konflik pada tanggal yang sama dengan revision sama.

## TypeScript + Prisma Mapping

Mapping yang disarankan untuk backend TypeScript (Prisma/PostgreSQL):

- `effective_from` -> `DateTime @db.Date`
- `effective_to` -> `DateTime? @db.Date`
- `published_at` -> `DateTime @db.Timestamptz`
- `adjustment_days` -> `Int` dengan constraint app-level `[-1, 0, 1]`
- `revision` -> `Int` (>= 1)

Aturan uniqueness yang disarankan:
- unique natural key parsial: `(authority, country, region_scope, effective_from, coalesce(effective_to), revision)`
- index query utama: `(country, authority, region_scope, effective_from, effective_to, revision)`
