# 16 - VPS Deployment Guide

## Runtime Checklist

- Node.js LTS installed
- Environment variables configured
- PostgreSQL reachable
- Redis reachable
- Reverse proxy TLS configured

## Required Env Vars (Example)

```text
PORT=8080
NODE_ENV=production
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
API_KEY_HASH_SALT=...
LOG_LEVEL=info
```

## Process Supervision

Gunakan salah satu:
- systemd
- PM2
- supervisor

Target behavior:
- auto-restart on crash
- restart on deploy
- graceful shutdown support

## Health Endpoints

- `/health` -> basic liveness
- `/ready` -> dependency readiness (DB + Redis)

## Backup and Recovery

- PostgreSQL daily backup
- Simpan backup di lokasi terpisah
- Lakukan restore drill mingguan/bulanan
