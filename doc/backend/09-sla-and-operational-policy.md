# 09 - SLA and Operational Policy

## Data Update Policy

- Authority V1: `kemenag_ri`.
- Data adjustment harus dipublish sesegera mungkin setelah keputusan resmi.
- Setiap perubahan menaikkan `revision`.

## SLA Suggestion

- Free tier:
  - Best effort
  - No strict uptime guarantee
- Pro tier:
  - Uptime target 99.9%
  - Priority support

## Incident Policy

- Jika data salah terpublikasi:
  1. publish revision koreksi
  2. log incident internal
  3. catat root cause

## Compatibility Policy

- `schema_version` wajib di response.
- Breaking changes hanya di major version endpoint (`/v2/...`).
- Field lama tidak dihapus tanpa masa deprecate.

## VPS Operational Baseline

- Jalankan service sebagai process terkontrol (systemd/pm2/supervisor).
- Sediakan health endpoint:
  - `/health` (liveness)
  - `/ready` (readiness: DB + Redis check)
- Terapkan log rotation dan retention policy.

## Backup Policy

- PostgreSQL:
  - daily logical backup
  - weekly restore drill
- Redis:
  - snapshot periodik jika dipakai sebagai cache penting
  - treat Redis as rebuildable cache (source of truth tetap DB)
