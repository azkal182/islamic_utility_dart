# Backend Migration Guide: Delta -> Anchor-First

Dokumen ini ditujukan untuk tim backend Node.js/TypeScript (Prisma + PostgreSQL + Redis) yang sudah mengimplementasikan docs backend saat ini, dan ingin migrasi ke model official yang lebih tepat untuk sidang isbat.

## 1. Kenapa Backend Perlu Diubah

Model lama (`effective_from/effective_to/adjustment_days`) cocok untuk date shifting, tetapi kurang tepat untuk statement official seperti:

> "Tanggal 19 Feb 2026 adalah 1 Ramadan 1447."

Agar lebih jelas dan minim error operator, backend perlu mendukung **anchor-first model**.

## 2. Apa yang Berubah

## 2.1 Data Model Baru (Anchor)

Tambahkan tabel/entitas baru (contoh): `hijri_anchors`

Field minimum:

- `id`
- `authority` (`kemenag_ri`)
- `country` (`ID`)
- `region_scope` (`national`)
- `official_gregorian_date` (`YYYY-MM-DD`)
- `hijri_year` (int)
- `hijri_month` (int)
- `hijri_day` (int, default 1)
- `reason` (mis. `isbat_hilal`)
- `revision` (int)
- `published_at` (datetime)
- `notes` (optional)
- `status` (`provisional|final`)

## 2.2 Endpoint Baru

Tambahkan endpoint anchor:

1. `GET /v1/hijri/anchors`
   - query: `country`, `from`, `to`, `authority`, `region_scope`
2. `GET /v1/hijri/anchors/latest`
   - query: `country`, `authority`, `region_scope`

Endpoint lama (`/adjustments`) tetap dipertahankan selama masa transisi.

Status package saat ini:
- endpoint anchor di client sudah terimplementasi.
- backend perlu menyediakan endpoint ini agar mode official anchor-first aktif penuh.

## 2.3 Flow Resolver di Client/Package

Flow baru yang harus didukung backend output:

1. package request anchor data,
2. jika anchor tersedia -> apply anchor,
3. jika tidak tersedia -> package boleh fallback ke delta,
4. jika delta juga tidak ada -> fallback local.

## 3. Perubahan Flow Operasional Admin

### Lama (Delta)

- admin isi `effective_from/effective_to/adjustment_days`

### Baru (Anchor-First)

- admin isi titik official:
  - `official_gregorian_date`
  - `hijri_year`
  - `hijri_month`
  - `hijri_day`

Dengan model ini, admin tidak perlu menghitung `+1/-1` untuk kasus awal bulan.

## 4. SOP Input untuk Sidang Isbat

Contoh: sidang menetapkan 1 Ramadan 1447 = 2026-02-19

Input record:

- `official_gregorian_date`: `2026-02-19`
- `hijri_year`: `1447`
- `hijri_month`: `9`
- `hijri_day`: `1`
- `reason`: `isbat_hilal`
- `status`: `final` (atau `provisional` jika perlu)

## 5. Backward Compatibility Strategy

Tahap migrasi disarankan:

1. Tambah tabel + endpoint anchor (tanpa mematikan delta).
2. Publish anchor untuk bulan-bulan kunci (Ramadan, Syawal, Dzulhijjah).
3. Client package memprioritaskan anchor.
4. Delta tetap hidup sebagai fallback sementara.
5. Setelah stabil, delta bisa diturunkan prioritasnya atau dipensiunkan bertahap.

## 6. Prisma/PostgreSQL Change Summary

Tambahan model Prisma (contoh):

```prisma
model HijriAnchor {
  id                    String   @id
  authority             String
  country               String   @db.Char(2)
  regionScope           String
  officialGregorianDate DateTime @db.Date
  hijriYear             Int
  hijriMonth            Int
  hijriDay              Int      @default(1)
  reason                String
  revision              Int
  publishedAt           DateTime @db.Timestamptz(6)
  notes                 String?
  status                String
  createdAt             DateTime @default(now()) @db.Timestamptz(6)
  updatedAt             DateTime @updatedAt @db.Timestamptz(6)

  @@index([country, authority, regionScope, officialGregorianDate])
  @@index([country, authority, regionScope, revision, publishedAt])
}
```

## 7. Redis Cache Update

Tambahkan key namespace baru:

- `hijri:anchor:v1:{country}:{authority}:{region_scope}:{from}:{to}`
- `hijri:anchor:v1:{country}:{authority}:{region_scope}:latest`

Delta cache tetap dipertahankan selama transisi.

## 8. Error/Validation Rules Baru

Validasi untuk anchor:

- `hijri_month` harus `1..12`
- `hijri_day` harus `1..30`
- `revision >= 1`
- kombinasi authority/country/region/date/revision tidak konflik

## 9. Rekomendasi Urutan Implementasi Tim Backend

1. Tambah schema Prisma + migration.
2. Tambah repository/service anchor.
3. Tambah endpoint `/anchors` dan `/anchors/latest`.
4. Tambah cache Redis untuk anchor.
5. Tambah admin form input anchor.
6. Tambah audit log untuk perubahan anchor.
7. UAT dengan kasus nyata Ramadan/Syawal.

## 10. Checklist Go-Live

- Endpoint anchor live dan tervalidasi.
- Monitoring 200/304/4xx/5xx aktif.
- Redis hit ratio untuk anchor normal.
- SOP operator anchor disetujui.
- Client package sudah siap consume anchor-first.

## 11. Flow Runtime Final (Expected)

Pada mode official, client package akan menjalankan urutan:

1. fetch anchor remote
2. pakai anchor cache jika 304/offline
3. fallback ke adjustment delta remote/cache
4. fallback ke local jika semua tidak tersedia

Artinya backend idealnya menyediakan:
- endpoint anchor lengkap
- etag/304 support
- revision monotonic untuk conflict resolution
