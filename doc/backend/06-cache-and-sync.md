# 06 - Cache and Sync

## Client Cache Strategy

- TTL default: 24 jam.
- Key cache:
  - `country`
  - `authority`
  - `region_scope`
  - `from`
- `to`

## Redis-First Server Cache (Backend)

Untuk backend Node TypeScript, gunakan Redis sebagai shared cache:

- key dataset range:
  - `hijri:adj:v1:{country}:{authority}:{region_scope}:{from}:{to}`
- key latest:
  - `hijri:adj:v1:{country}:{authority}:{region_scope}:latest`
- key etag mirror:
  - `hijri:adj:v1:{...}:etag`

Payload Redis disarankan berisi:
- `schema_version`
- `generated_at`
- `records`
- `etag`

## HTTP Cache Strategy

Backend disarankan mengirim:
- `ETag`
- `Cache-Control: max-age=86400`
- `Last-Modified`

Client disarankan mengirim:
- `If-None-Match`

## Sync Flow

1. Baca cache.
2. Jika cache valid & belum expired, gunakan langsung.
3. Jika expired, panggil API dengan `If-None-Match`.
4. Jika `304`, refresh timestamp cache.
5. Jika `200`, simpan body + ETag baru.

## Offline Behavior

- Jika network gagal:
  - gunakan cache terakhir jika ada,
  - jika tidak ada cache, pakai local-only.

## Redis Failure Strategy

- Jika Redis down, API tetap melayani dari database langsung.
- Jika DB juga lambat/down, return error standar `INTERNAL_ERROR`.
- Jangan block request karena cache write failure (best-effort write).
