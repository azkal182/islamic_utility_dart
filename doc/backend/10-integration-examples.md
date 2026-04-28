# 10 - Integration Examples

## Example A: Resolve Hijri Date with Optional Remote Adjustment

Pseudo-flow di app/client:

```text
base = localEngine.fromGregorian(date)
records = cache.get(range)
if cache.staleOrEmpty:
  remote = api.fetchAdjustments(range, etag)
  if remote.status == 200: cache.save(remote)
  if remote.status == 304: cache.touch()
  records = cache.get(range)

adjustment = resolver.pick(records, date)
resolved = resolver.apply(base, adjustment)
return resolved
```

## Example B: Metadata to App Layer

```json
{
  "hijri": "1449-09-01",
  "is_adjusted": true,
  "adjustment_days": 1,
  "source": "remote_adjusted",
  "authority": "kemenag_ri",
  "revision": 3
}
```

## Example C: Fallback Scenario

- Network timeout
- Cache ada -> gunakan `cache_adjusted`
- Cache tidak ada -> gunakan `local`
