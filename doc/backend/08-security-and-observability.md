# 08 - Security and Observability

## Security Baseline

- HTTPS only (TLS 1.2+).
- API key via `Authorization: Bearer`.
- Key hashing at rest.
- Rate limit per key + per IP.

## Optional Hardening

- Response signature/checksum untuk integritas payload.
- IP allowlist untuk enterprise plan.
- Request replay protection untuk endpoint sensitif.

## Observability

- Setiap request punya `request_id`.
- Log fields minimum:
  - timestamp
  - request_id
  - api_key_id (masked)
  - endpoint
  - status
- latency_ms

## TypeScript Service Instrumentation (Generic)

- Middleware request context:
  - generate/read `request_id`
  - capture auth subject (`api_key_id`)
  - capture start time
- Structured logs (JSON) wajib konsisten untuk semua route.
- Domain/application layer tidak menulis langsung ke transport log; gunakan logger abstraction.

## Metrics

- request rate per endpoint
- success/error ratio
- p95 latency
- cache hit ratio
- 304 ratio (efektivitas ETag)

## Security Notes for VPS Deployment

- Batasi akses DB/Redis hanya private network atau loopback.
- Gunakan reverse proxy TLS termination.
- Rotasi API key dan secret env secara berkala.
