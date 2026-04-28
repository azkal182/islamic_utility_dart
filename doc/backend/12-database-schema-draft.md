# 12 - Database Schema Draft

Draft skema database untuk backend Hijri adjustment API.

## 1) Table: `adjustments`

Purpose:
- Menyimpan record koreksi Hijriyah resmi.

Suggested columns:
- `id` (uuid / text, PK)
- `authority` (text, not null) -> default `kemenag_ri`
- `country` (char(2), not null) -> `ID`
- `region_scope` (text, not null) -> `national`
- `effective_from` (date, not null)
- `effective_to` (date, null)
- `adjustment_days` (smallint, not null)
- `reason` (text, not null)
- `revision` (int, not null)
- `published_at` (timestamptz, not null)
- `notes` (text, null)
- `is_active` (bool, not null, default true)
- `created_at` (timestamptz, not null)
- `updated_at` (timestamptz, not null)

Constraints:
- `adjustment_days in (-1, 0, 1)`
- `revision >= 1`
- `effective_to is null or effective_to >= effective_from`

Indexes:
- `(country, authority, region_scope, effective_from)`
- `(country, authority, region_scope, effective_to)`
- `(country, authority, region_scope, revision, published_at desc)`

## 2) Table: `api_keys`

Purpose:
- Menyimpan key pelanggan untuk autentikasi + plan.

Suggested columns:
- `id` (uuid, PK)
- `key_hash` (text, unique, not null)
- `label` (text, null)
- `plan` (text, not null) -> `free` / `pro`
- `is_active` (bool, not null, default true)
- `rate_limit_per_hour` (int, not null)
- `created_at` (timestamptz, not null)
- `expires_at` (timestamptz, null)
- `last_used_at` (timestamptz, null)

Indexes:
- unique `(key_hash)`
- `(is_active, expires_at)`

## 3) Table: `request_logs` (optional high-volume)

Purpose:
- Audit dan observability request.

Suggested columns:
- `id` (bigserial, PK)
- `request_id` (text, unique)
- `api_key_id` (uuid, null)
- `endpoint` (text)
- `method` (text)
- `status_code` (int)
- `latency_ms` (int)
- `ip_address` (inet, null)
- `created_at` (timestamptz)

Retention:
- Simpan 14-30 hari (tergantung kebutuhan biaya).

## 4) Table: `adjustment_audit_events`

Purpose:
- Jejak perubahan data adjustment (siapa, kapan, apa).

Suggested columns:
- `id` (bigserial, PK)
- `adjustment_id` (text, FK to adjustments.id)
- `event_type` (text) -> `create`, `update`, `deactivate`, `delete`
- `actor` (text)
- `before_payload` (jsonb, null)
- `after_payload` (jsonb, null)
- `created_at` (timestamptz)

## Query Pattern Utama

Untuk tanggal `D`:
- Filter:
  - `country = 'ID'`
  - `authority = 'kemenag_ri'`
  - `region_scope = 'national'`
  - `effective_from <= D`
  - `(effective_to is null or effective_to >= D)`
  - `is_active = true`
- Order:
  - `revision desc, published_at desc`
- Ambil 1 record terbaik.
