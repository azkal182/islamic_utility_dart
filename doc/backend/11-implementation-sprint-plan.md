# 11 - Implementation Sprint Plan (Backend MVP)

Dokumen ini adalah checklist implementasi backend adjustment API per sprint.

## Sprint 1 (Foundation)

Target:
- API service skeleton siap jalan.
- Auth + rate limit dasar aktif.

Tasks:
- Setup project backend (framework, env config, logger).
- Implement middleware auth `Bearer API key`.
- Implement rate limit per API key.
- Implement endpoint:
  - `GET /v1/hijri/adjustments/latest`
- Implement error envelope standar.
- Setup observability dasar (`request_id`, latency, status).

Definition of Done:
- Endpoint latest bisa diakses dengan key valid.
- `401/403/429` behavior sesuai spec.

## Sprint 2 (Core Data + Range Endpoint)

Target:
- Data model adjustment siap dipakai.
- Endpoint range siap produksi awal.

Tasks:
- Implement tabel `adjustments` dan query index.
- Implement endpoint:
  - `GET /v1/hijri/adjustments`
- Validasi query `country`, `from`, `to`, `authority`, `region_scope`.
- Implement headers:
  - `ETag`
  - `Cache-Control`
  - `X-RateLimit-*`
- Tambahkan `request_id` di response.

Definition of Done:
- Dataset valid keluar dari endpoint range.
- `304 Not Modified` berjalan via `If-None-Match`.

## Sprint 3 (Operational Hardening)

Target:
- Reliability dan operasional siap launch.

Tasks:
- Implement conflict resolution berdasarkan `revision` dan `published_at`.
- Tambahkan audit log untuk perubahan adjustment.
- Tambahkan dashboard metrics:
  - request rate
  - error ratio
  - p95 latency
  - 304 ratio
- Tambahkan alarm basic (5xx spike, auth failures, latency spike).
- Tambahkan backup/restore prosedur data adjustment.

Definition of Done:
- Monitoring aktif.
- Runbook incident tersedia.

## Sprint 4 (Commercial Readiness - Optional)

Target:
- Siap untuk model free/pro.

Tasks:
- Plan-based permission (`free`, `pro`).
- Usage metering per key.
- Key rotation endpoint/operator tools.
- Billing event integration (jika diperlukan).

Definition of Done:
- Perbedaan akses free/pro berjalan sesuai policy.
