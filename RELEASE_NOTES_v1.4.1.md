# islamic_utility v1.4.1

## Summary

Bugfix release targeting the anchor-priority cache layer. Users relying on
`fromGregorianOfficial` (single-date) would experience a full HTTP fetch on
every call despite previous successful fetches, because the anchor cache
was keyed per-day while anchor records are month-scope data. Additionally,
the `fetchLatestAnchors` fallback result was never persisted, causing a
permanent double-HTTP-call cycle for any month not covered by the
`fetchAnchorsRange` endpoint.

## Bug Fixes

### Anchor Cache Key Strategy (Bug A)

**Files:** `adjustment/anchor_cache.dart`, `adjustment/hive_anchor_cache.dart`

The anchor cache key was `YYYY-M-D` (per day). Anchor records represent the
official start of a Hijri month (`official_gregorian_date`), so the same record
is valid for the entire Gregorian month. Changing the key to `YYYY-M` means:

- Querying 2026-03-15 populates key `2026-3`
- Querying 2026-03-16 the next day → **cache hit** (same key `2026-3`)
- Previously: always cache miss → always HTTP fetch

### `fetchLatestAnchors` Result Not Persisted (Bug B)

**File:** `providers/kemenag_official_hijri_provider.dart`

When `fetchAnchorsByDate` returned empty/non-matching records and the code
fell back to `fetchLatestAnchors`, the resolved result was returned immediately
without writing to `anchorCache`. This caused every subsequent call for a
different day in the same month to go through the same double-HTTP-call
sequence.

**Fix:** `anchorCache.put(...)` is now called before returning from the
`fetchLatestAnchors` branch.

### Stale ETag Passed to `fetchLatestAnchors` (Bug B — ETag)

**File:** `providers/kemenag_official_hijri_provider.dart`

`fetchLatestAnchors(etag: cachedAnchor?.etag)` was using the ETag from the
previous cache entry (possibly from a prior session or a different month).
The correct ETag to use for conditional revalidation is the one returned by
the preceding `fetchAnchorsByDate` call (`remote.etag`).

### Empty Records Cached in Anchor Cache (Bug B — Pollution)

**File:** `providers/kemenag_official_hijri_provider.dart`

When `fetchAnchorsByDate` returned HTTP 200 with `records: []`, those empty
records were stored in the anchor cache. On the next call (with `allowRemote:
false`, e.g. inside `fromGregorianRangeAsync`), the cached empty-records entry
would cause `_anchorResolver.resolve()` to return null, and since no remote
fetch is allowed in that path, the date would silently fall back to the
adjustment/local flow.

**Fix:** `anchorCache.put(...)` is now guarded by `if (remote.records.isNotEmpty)`.

### Cache Key UTC Normalization (Bug C)

**Files:** All four cache implementations

`_key(DateTime date)` previously used `date.year / date.month / date.day`
directly. A caller in WIB (UTC+7) passing `DateTime.now()` at 00:30 local
time is still on the previous UTC day, causing a different key than a call
at 08:00 local time for what the user considers the same day.

**Fix:** All `_key()` methods now derive from `date.toUtc()`.

### `_prefetchRange` Always Re-fetched Regardless of Cache State (Bug F)

**File:** `providers/kemenag_official_hijri_provider.dart`

`_prefetchRange` (called by `fromGregorianOfficialRange`) unconditionally
executed HTTP fetches every time it was called, even when all days in the
requested range were already covered by a fresh cache entry (e.g. via Hive).
This meant the second call to `fromGregorianOfficialRange` with the same date
range would still trigger 3 HTTP requests.

**Fix:** Added `_anyDayMissingAnchor` and `_anyDayMissingAdjustment` helper
methods that check the cache before fetching. Fetches are now skipped entirely
when all days in the range have fresh cache entries. ETag is also threaded
through the range fetch to enable 304 conditional-request support.

## Quality

- `dart analyze`: pass
- All existing tests: pass
- Live integration test against real API: all warm-cache scenarios return 0 HTTP calls
