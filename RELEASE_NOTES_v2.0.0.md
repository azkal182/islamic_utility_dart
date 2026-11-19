# islamic_utility v2.0.0 (draft)

This release collects the work accumulated after the `v1.6.0` tag. It includes
official Hijri cache and refresh improvements, prayer API and boundary updates,
the astronomy and high-latitude accuracy work, the LFNU preset, comparison
datasets, and expanded documentation and regression coverage.

## Breaking changes

- `PrayerTimes` event values are now read-only getters rather than writable
  public fields. Remove assignments to values such as `times.fajr`; provide
  calculation inputs through `CalculationParameters` and `PrayerTimes` instead.
- `CalculationMethod.lfnu` is a new enum value. Update exhaustive switches over
  `CalculationMethod` to handle it.

## Changes

- Official Hijri lookups now return cached anchors immediately, including stale
  entries, and refresh in the background. Without usable cache, lookups return
  a local provisional result while refresh proceeds.
- Added explicit single-date and date-range refresh APIs to `HijriCalendar` and
  `UnifiedCalendar`. Range results use complete cached coverage or one
  consistent provisional range.
- Improved anchor reuse and merging, scoped ETags to authority/region/query,
  and cancel timed-out HTTP requests before retrying.
- Added target `locationDate` support to current/next prayer selection and
  refined next-day schedule handling. The Imsak and Dhuha candidate options
  were introduced in v1.6.0.
- Added event provenance through `PrayerEventResult` and
  `eventForPrayer(...)`, and explicit high-latitude fallback behavior. When the
  Asr altitude is unreachable while sunset is available, fallback Asr is the
  midpoint between transit and sunset.
- Improved the solar-altitude solver and transit declination handling for event
  availability and Asr calculations.
- Added optional observer elevation and the LFNU calculation preset, including
  Fajr −20°, Isha −18°, Shafi'i Asr, Dhuhr +1 minute, Dhuha +4.5°, and an
  optional Ramadan Maghrib adjustment.
- Aligned `fajrAfter` and `ishaBefore` with adjacent-day events and applied
  configured Imsak and Dhuha adjustments.
- Added comparison-only astronomical, Kemenag SIHAT 2026, and LFNU Bangsri
  2026 reference datasets. These datasets are not runtime calculation inputs.
- Documented the accuracy methodology, tolerances, source limitations, event
  rounding, LFNU client minute-display guidance, and fallback behavior.

## Verification

- `dart analyze .`: passed with no issues.
- `dart test`: 109 passed; 2 external API smoke tests skipped because live
  credentials were not configured.
- `dart format --output=none --set-exit-if-changed lib test scripts`: passed.
- `dart doc`: generated with 0 warnings and 0 errors.
- `dart pub publish --dry-run`: passed with 0 package warnings.
- `git diff --check`: passed.
