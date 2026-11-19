# Kemenag prayer schedule reference

`national-2026.jsonl.gz` contains the monthly SIHAT Kemenag schedule snapshots
for all 517 province/city entries returned by the API in 2026: 6,204 unique
location-month records. Each JSONL record preserves the API response and adds
decimal coordinates plus the original DMS coordinate strings.

The coordinates are the Kemenag reference points for each listed city or
regency. They are not village-level coordinates. For a controlled engine
comparison, use the exact coordinates stored in the selected record. The
coordinate lookup script is a convenience that selects the nearest Kemenag
reference point and reports its distance.

```bash
python3 scripts/lookup_kemenag_by_coordinates.py \
  --dataset test/data/reference/kemenag/national-2026.jsonl.gz \
  --latitude -6.2 --longitude 106.8 --date 2026-11-19
```

These schedules are an official Kemenag parity reference, not an independent
astronomical ephemeris. The API response is preserved for comparison only:
published prayer-time values are never passed into the calculation engine.
The coordinates returned by Kemenag identify the location supplied to the
engine so that its calculated schedule can be compared at the same reference
point.

This is phase 5's agreed scope: measure differences from the official schedule
without using those differences to modify astronomical results. The comparison
uses `CalculationMethod.indonesian`; it does not implement a separate Kemenag
runtime provider or a data-derived correction layer. The 2026 comparison
reports are validation artifacts, not a claim that Kemenag's city/regency
reference point is the observer's exact village coordinate.

To collect or resume an uncompressed JSONL dataset:

```bash
python3 scripts/collect_kemenag_dataset.py \
  --year 2026 --output /tmp/kemenag-2026.jsonl --workers 6
```

The first full-year baseline comparison against the Indonesian calculation preset
is documented in [`2026-baseline.md`](2026-baseline.md) and can be reproduced
with `dart run scripts/analyze_kemenag_parity.dart` from the package root.
The post-Phase-3 comparison against that baseline is in
[`2026-phase3-comparison.md`](2026-phase3-comparison.md).
The comparison after phases 1–5 is in
[`2026-phase5-comparison.md`](2026-phase5-comparison.md); it uses the
Indonesian calculation preset and does not apply Kemenag schedule values as
corrections.
The current engine's absolute differences for all eight events and all
188,705 location-days are summarized in
[`2026-engine-vs-kemenag.md`](2026-engine-vs-kemenag.md). The complete row-level
comparison, including both clock times and delta per event, is in the compressed
[`CSV export`](2026-engine-vs-kemenag.csv.gz).
