# 15 - Redis Cache Design

## Key Naming

- Range dataset:
  - `hijri:adj:v1:{country}:{authority}:{region_scope}:{from}:{to}`
- Latest dataset:
  - `hijri:adj:v1:{country}:{authority}:{region_scope}:latest`

## Value Shape

```json
{
  "etag": "W/\"abc123\"",
  "cached_at": "2027-02-07T12:12:00Z",
  "ttl_seconds": 86400,
  "dataset": {
    "schema_version": "1.0.0",
    "authority": "kemenag_ri",
    "generated_at": "2027-02-07T12:12:00Z",
    "records": []
  }
}
```

## TTL Strategy

- Default TTL: 24 jam.
- Untuk endpoint latest, boleh gunakan TTL lebih pendek (mis. 1-6 jam) tergantung traffic.

## Invalidation

- Saat ada revision baru dipublish:
  - invalidate key `latest`
  - invalidate range keys yang overlap tanggal affected

## Failure Handling

- Cache read miss -> query database.
- Cache write failure -> log warning, lanjutkan response normal.
