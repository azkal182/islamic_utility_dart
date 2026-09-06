## 1.5.1

- Official Hijri ranges now continue several future months from the last
  available anchor using an anchored local fallback instead of failing only
  because a future anchor is missing.
- Added `HijriResultMeta.validationStatus` with `official`,
  `inferred_validated`, and `provisional` states.
- Reconciled provisional results when a later anchor moves by `+1` or `-1`
  day, preventing duplicate or skipped Hijri day 1 values.
- Range prefetch now uses conditional ETag requests to detect new anchor
  revisions before the previous cache TTL expires.

## 1.5.0

- Added support for the official anchor API `predecessor` field. The HTTP
  client now includes the preceding active anchor in the resolver dataset while
  preserving compatibility with responses that only contain `records`.
- Improved official range safety: ranges are validated for daily continuity and
  reject duplicate or skipped Hijri dates instead of returning an unsafe
  result.
- Official range prefetch now looks back up to 35 days for the preceding
  month-boundary anchor.
- Documented provisional local fallback, `StateError` handling, anchor
  requirements, cache behavior, and UTC timestamp expectations.

## 1.4.1

- Fixed anchor cache key strategy: switched from per-day to per Gregorian
  year-month (`YYYY-MM`), since anchor records represent month-boundary data
  valid for the entire month. The old per-day key caused a cache miss on
  every new day even when the anchor for that month had already been fetched.
- Fixed `fetchLatestAnchors` result not being saved to `anchorCache` in
  `_resolveFromAnchor`: subsequent single-date queries for other days in the
  same month now hit the cache instead of triggering a double HTTP call cycle.
- Fixed stale ETag passed to `fetchLatestAnchors` in `_resolveFromAnchor`:
  now uses `remote.etag` (from `fetchAnchorsByDate`) instead of the outdated
  `cachedAnchor?.etag`, enabling correct `304 Not Modified` handling.
- Fixed `fetchAnchorsByDate` response with empty records being stored in cache:
  empty records are no longer cached, preventing a stale cache entry that would
  block the `fetchLatestAnchors` fallback from persisting its result.
- Fixed cache key UTC normalization across all four cache implementations
  (`InMemoryHijriAdjustmentCache`, `HiveHijriAdjustmentCache`,
  `InMemoryHijriAnchorCache`, `HiveHijriAnchorCache`): keys are now derived
  from `date.toUtc()` to prevent cache misses for WIB (UTC+7) callers who
  pass a local `DateTime` near midnight.
- Fixed `_prefetchRange` always re-fetching regardless of cache state:
  added `_anyDayMissingAnchor` and `_anyDayMissingAdjustment` guards so the
  method skips HTTP calls entirely when all days in the requested range are
  already covered by a fresh cache entry. Also threads ETag through the range
  fetch for proper 304 conditional-request support.

## 1.4.0


- Improved official Hijri range resolution consistency:
  - range prefetch now falls back to `fetchLatestAnchors(...)` once when
    `fetchAnchorsRange(...)` returns empty records near boundary windows
  - prevents unexpected local fallback mismatch for range mode
- Kept range flow optimized (no per-day remote loop) while preserving
  anchor-based official result parity.
- Added/updated tests to lock boundary behavior:
  - range empty-anchor + latest-anchor fallback case
  - batch-only official range assertions remain enforced
- Added transition-ready unified calendar facade usage updates and examples
  alignment with official mode expectations.
- Cleaned examples and docs for release safety:
  - replaced hardcoded API keys with placeholders
  - synchronized README/API docs with current public surface.

## 1.3.0

- Added official Hijri range conversion API:
  - `HijriCalendar.fromGregorianOfficialRange({from, to})`
- Added range fetch contracts in `HijriAdjustmentClient`:
  - `fetchRange(...)`
  - `fetchAnchorsRange(...)`
- Added HTTP range fetch implementation in `HttpHijriAdjustmentClient`:
  - adjustments range endpoint
  - anchors range endpoint
- Optimized official range flow to avoid per-day remote fetch loops after range prefetch.
- Added persistent cache implementations using Hive:
  - `HiveHijriAdjustmentCache`
  - `HiveHijriAnchorCache`
- Added support for injecting `anchorCache` in `HijriCalendar.withOfficial(...)`.
- Added Javanese calendar module:
  - `JavaneseCalendar`
  - `Pasaran` (`Legi`, `Pahing`, `Pon`, `Wage`, `Kliwon`)
  - `JavaneseDate` (`pasaran`, `weton`)
- Added transition-friendly unified facade:
  - `UnifiedCalendar`
  - `CalendarResolveOptions`
  - `UnifiedCalendarDate`
- Added examples:
  - `example/hijri_official_range_hive_example.dart`
  - `example/hijri_official_range_hive_flutter_example.dart`
  - `example/javanese_pasaran_example.dart`
  - `example/unified_calendar_example.dart`
- Expanded and synchronized documentation:
  - `README.md`
  - `doc/01-public-api-spec.md`
  - `doc/11-api-reference.md`
  - `doc/13-hijri-integration-guide.md`
- Added and updated tests for:
  - HTTP range request behavior
  - official provider range prefetch behavior
  - no per-day anchor remote calls in range mode

## 1.2.0

- Added Hijri calendar foundation module (`calendar_hijri`) with modular structure.
- Added `HijriCalendar` public facade API.
- Added `HijriMethod` options:
  - `calculatedLocal`
  - `ummAlQura`
  - `kemenagRiOfficial` (via official adjustment flow)
- Added Umm al-Qura provider implementation and dataset organization.
- Added local civil Hijri provider implementation.
- Added mock-first official adjustment flow:
  - adjustment client contract
  - in-memory cache contract
  - fallback chain: remote -> cache -> local
- Added Hijri examples:
  - `example/hijri_methods_example.dart`
  - `example/hijri_official_mock_example.dart`
- Added Hijri docs:
  - `doc/13-hijri-integration-guide.md`
  - FAQ updates in `doc/12-faq-troubleshooting.md`

## 1.1.0

- Refactored astronomical engine to a Meeus-based pipeline with higher precision and 3-day interpolation.
- Added `imsak` and `dhuha` prayer outputs.
- Added configurable `dhuhaOffsetMinutes` in `CalculationParameters`.
- Expanded runnable examples, including Bangsri Jepara coordinates.
- Added bilingual documentation:
  - Updated `README.md` (Indonesia + English)
  - Added `docs/11-api-reference.md` (bilingual API reference)
  - Added `docs/12-faq-troubleshooting.md` (bilingual FAQ/troubleshooting)

## 1.0.0

- Initial version.
