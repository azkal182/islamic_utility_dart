# Prayer engine parity and regression matrix

This report records the repeatable engine matrix used for Phase 3. The matrix
checks schedule ordering and numerical precision over all calculation presets,
representative locations, and seasonal dates. It is a regression and stability
matrix; the independent official schedule comparison is the Kemenag report
linked below.

## Matrix coverage

- 15 `CalculationMethod` values. The `other` preset is exercised with explicit
  18° Fajr and 17° Isha angles.
- 7 representative coordinates: Jakarta, Singapore, Makkah, London, Reykjavik,
  Sydney, and Ushuaia.
- 4 seasonal dates in 2026: January 15, April 15, July 15, and October 15.
- 420 method × location × season schedules, checked both at second precision
  and minute precision.
- 3 explicit high-latitude rules checked where the 15° twilight angle is
  unreachable, with Fajr and Isha verified against each rule's night fraction.

The matrix checks that all returned events are UTC, daily events remain ordered,
adjacent-night Isha/Fajr boundaries remain ordered, and rounded events are at
most 30 seconds from their second-precision counterparts. Unreachable Fajr or
Isha twilight angles now select the configured high-latitude fallback instead
of being treated as a real event near solar transit.

## Official schedule comparison

The Kemenag SIHAT comparison covers 517 Indonesian city/regency reference
points across all 12 months of 2026 for the Indonesian preset: 188,705 daily
observations. Its baseline metrics and reproducible comparison command are in
[`2026-baseline.md`](../test/data/reference/kemenag/2026-baseline.md). This is
an official-schedule comparison, not an independent astronomical ephemeris.
The first post-engine-update comparison is saved as
[`2026-phase3-comparison.md`](../test/data/reference/kemenag/2026-phase3-comparison.md)
with machine-readable output in the same directory.

Other calculation presets do not have a complete set of official reference
schedules in this package. The matrix therefore verifies their consistency and
fallback behavior but does not claim that their results have been validated
against every local religious authority.

## Reproduce

From the package root:

```bash
dart test test/prayer_parity_matrix_test.dart
dart test test/prayer_parity_baseline_test.dart
dart test test/golden_parity_dataset_test.dart
dart test test/precision_tolerance_test.dart
dart run scripts/analyze_kemenag_parity.dart
```

The Kemenag analysis can also compare a future engine version against the
machine-readable baseline using the command in the linked report.
