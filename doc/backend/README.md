# Backend API Spec (Hijri Adjustment Service)

Dokumen di folder ini adalah spesifikasi backend untuk fitur kalender Hijriyah dengan model **anchor-first API**. Endpoint adjustment lama tetap didokumentasikan untuk masa transisi dan kompatibilitas client lama.

Tujuan:
- Engine Hijriyah lokal di package tetap menjadi perhitungan dasar (offline-first).
- Backend mengirim anchor awal bulan Hijriah resmi sebagai sumber utama.
- Endpoint adjustment tetap dapat dipertahankan tanpa dipakai oleh client anchor-only.
- Integrasi backend bersifat optional (bisa free/paid tier).

## Scope

- API untuk membaca data anchor Hijriyah dan endpoint adjustment legacy.
- Autentikasi, kuota/rate limit, cache, error contract, dan SLA operasional.
- Aturan conflict resolution dan fallback untuk client package.

## Non-Scope

- Engine hisab/rukyat detail di backend.
- UI dashboard operator.
- Sinkronisasi lintas negara di versi awal.

## Assumption V1

- Authority awal: `kemenag_ri`.
- Scope awal: `national`.
- Auth: `Bearer` API key.
- Tanggal API: ISO `YYYY-MM-DD`.
- TTL cache rekomendasi: 24 jam.

## Implementation Baseline

- Language: TypeScript
- Framework: framework-agnostic (no hard dependency on Express/Fastify)
- Database: PostgreSQL with Prisma ORM
- Cache: Redis
- Deployment target: VPS

Prinsip baseline:
- HTTP contract tetap mengacu ke `doc/backend/openapi.v1.yaml`.
- Service architecture harus layered (api/application/domain/infrastructure).
- Integrasi Dart package menggunakan anchor-first contract; adjustment hanya legacy opt-in.

## Daftar Dokumen

- `doc/backend/01-architecture.md`
- `doc/backend/02-auth-and-billing.md`
- `doc/backend/03-adjustment-data-model.md`
- `doc/backend/04-endpoints.md`
- `doc/backend/05-conflict-and-priority-rules.md`
- `doc/backend/06-cache-and-sync.md`
- `doc/backend/07-error-codes.md`
- `doc/backend/08-security-and-observability.md`
- `doc/backend/09-sla-and-operational-policy.md`
- `doc/backend/10-integration-examples.md`
- `doc/backend/11-implementation-sprint-plan.md`
- `doc/backend/12-database-schema-draft.md`
- `doc/backend/13-typescript-service-architecture.md`
- `doc/backend/14-prisma-postgres-schema.md`
- `doc/backend/15-redis-cache-design.md`
- `doc/backend/16-vps-deployment-guide.md`
- `doc/backend/17-typescript-integration-snippets.md`
- `doc/backend/18-backend-migration-to-anchor-first.md`
- `doc/backend/19-anchor-api-contract.md`
- `doc/backend/openapi.v1.yaml`
