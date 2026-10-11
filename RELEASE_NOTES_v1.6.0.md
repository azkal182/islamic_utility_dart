# islamic_utility v1.6.0 (draft)

## Summary

Draft release notes for Hijri official-data cache/offline improvements and
prayer next-event API changes. The package version is prepared as 1.6.0; no
release tag has been created and the package has not been published.

## Changes

- Official Hijri lookups now prefer cached anchors for immediate results,
  including stale cache entries, and start a background refresh. If there is no
  usable cache, the lookup returns a local provisional result while refresh
  proceeds.
- Added `HijriCalendar.refreshGregorianOfficial(...)` and
  `HijriCalendar.refreshGregorianOfficialRange(...)` for callers that need to
  await a refresh and use the returned result to update the UI.
- Added corresponding explicit refresh methods to `UnifiedCalendar`.
- Range lookups use the full cached range when available. If cached coverage is
  incomplete, they return a consistent local provisional range rather than
  mixing official cached dates with local fallback dates.
- Single-date refreshes fetch and cache neighboring anchor records to improve
  reuse for nearby dates.
- Cached anchors merge within their authority and region scope, retaining the
  record with the newer revision and publication timestamp.
- ETag metadata is scoped to the exact authority, region, and query range.
- HTTP timeout now cancels the in-flight request before a retry.
- Added `PrayerTimes.nextPrayerDetails(...)`, returning the next event, its UTC
  time, and `isNextDay` based on the target location's calendar date. Existing
  current/next prayer calls also advance to the following schedule after
  `fajrAfter`.
- Next-event candidates now include Imsak by default and Dhuha. Callers can
  skip events and choose whether Imsak applies always, only on Ramadan dates
  supplied by a callback, or never.
- The default `nextPrayer` candidate sequence has changed. Applications that
  relied on the previous sequence can pass `NextPrayerOptions.skip`. Use
  `nextPrayerDetails` to get the actual occurrence time and day; the legacy
  enum and `timeForPrayer` cannot distinguish tomorrow's occurrence from
  today's same event.
- Corrected high-latitude fallback calculations to use separate durations for
  the preceding and current night intervals at Fajr and Isha boundaries.
- Updated docs, examples, and regression tests for offline, stale-cache,
  refresh, range, ETag, timeout, high-latitude, and next-day boundary behavior.

## Integration note

The default cache is in-memory. Applications that need cache persistence across
process restarts should provide a `HiveHijriAnchorCache` to the official Hijri
calendar configuration. Applications should call the explicit refresh API and
apply its returned value when they need the current screen to reflect refreshed
data.

## Compatibility

- Existing lookup APIs remain available; normal lookup now returns promptly
  from cache or local provisional calculation while remote refresh runs in the
  background.
- Package version is set to 1.6.0 for release preparation. No git tag or
  publication has been made.

## Verification

- `dart analyze`: passed.
- `dart test`: passed (90 tests); live API smoke tests were skipped because
  `IUK_API_KEY` was not set in this run.
- `git diff --check`: passed.
