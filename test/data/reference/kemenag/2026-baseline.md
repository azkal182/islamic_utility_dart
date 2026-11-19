# Baseline parity: prayer-time engine vs Kemenag SIHAT 2026

This is Phase 1's official-schedule parity baseline. It measures the current
`CalculationMethod.indonesian` implementation against the Kemenag SIHAT monthly
schedules collected in `national-2026.jsonl.gz`; it does not establish
astronomical accuracy against an independent ephemeris or observation.

## Reproduce

From the package root:

```bash
dart run scripts/analyze_kemenag_parity.dart
```

The machine-readable baseline is saved in `2026-baseline.json`. After changing
the engine, generate a before/after report with:

```bash
dart run scripts/analyze_kemenag_parity.dart \
  --compare test/data/reference/kemenag/2026-baseline.json \
  --json-output test/data/reference/kemenag/2026-updated.json \
  --output test/data/reference/kemenag/2026-comparison.md
```

To export every location-day with Kemenag time, engine time, and signed delta
for all eight events, add `--details-output path/to/details.csv.gz`. The export
is CSV compressed with gzip; delta is engine minus Kemenag in minutes.

The comparison report gives baseline and updated MAE/P95 plus their changes;
negative changes mean the updated engine is closer to Kemenag. The command
checks that the dataset path and coverage match the baseline. Optionally pass a
different `.jsonl.gz` dataset path as the only argument for a standalone
analysis. Both modes use each Kemenag city/regency reference coordinate, the
province's civil timezone, `CalculationMethod.indonesian.parameters`, and
`precision: true`.
A positive delta means the package returns a later time than Kemenag. The
summary reports signed mean/median, mean absolute error (MAE), 95th percentile
absolute error, share within ±1 minute, share beyond 5 minutes, and the maximum
absolute-error example. Since the source schedule is published to whole
minutes, sub-minute precision should not be interpreted as source accuracy.

## Coverage

- 6,204 location-month records (517 province/city-regency entries × 12 months)
- 188,705 location-days
- 188,705 comparisons for each of the eight events below

## Results

| Event | Mean delta (min) | Median (min) | MAE (min) | P95 abs (min) | Within ±1 min | >5 min |
|---|---:|---:|---:|---:|---:|---:|
| Imsak | -2.45 | -2.48 | 2.49 | 2.95 | 0.05% | 0.05% |
| Fajr/Subuh | -2.45 | -2.48 | 2.49 | 2.95 | 0.05% | 0.05% |
| Sunrise/Terbit | +3.66 | +3.27 | 3.66 | 7.43 | 0.05% | 10.89% |
| Dhuha | -4.85 | -4.83 | 4.85 | 6.08 | 0.00% | 43.95% |
| Dhuhr/Zuhur | -2.50 | -2.50 | 2.50 | 2.95 | 0.00% | 0.00% |
| Asr/Ashar | -2.50 | -2.50 | 2.50 | 2.95 | 0.03% | 0.01% |
| Maghrib | -3.65 | -3.25 | 3.65 | 7.42 | 0.05% | 10.89% |
| Isha/Isya | -2.55 | -2.50 | 2.55 | 2.95 | 0.05% | 1.21% |

## Reading the result

The Indonesia preset is systematically about 2.5 minutes earlier than Kemenag
for Fajr, Dhuhr, Asr, and Isha. Dhuha is about 4.85 minutes earlier on average.
Sunrise and Maghrib have wider tails and location-dependent differences. These
are candidate parity gaps to investigate; they should not be “fixed” by applying
a blanket offset until the source conventions and coordinate/timezone handling
are confirmed.

This comparison uses city/regency reference coordinates, not the exact
coordinates used to generate every official timetable. Nearest-reference
coordinate errors can be material, especially across large or geographically
complex regencies and islands. The Kemenag API schedule is the official
comparator for its listed region, while this baseline does not separate
coordinate mismatch from calculation-method, rounding, or official ihtiyath
conventions. The dataset and its coverage limitations are documented in
[`README.md`](README.md).
