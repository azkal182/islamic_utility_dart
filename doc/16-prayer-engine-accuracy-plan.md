# Prayer engine accuracy plan — evidence and phase gates

This document is the active plan for prayer-engine accuracy work. Each phase
must satisfy its gate before the next phase begins. The older roadmap in
`09-implementation-roadmap.md` tracks a different set of package features and
does not establish completion of these accuracy phases.

## Phase 1 — Reference dataset and baseline

### Astronomical reference

`test/data/reference/astronomy/noaa-2026.json` is a reproducible dataset of 32
location/date pairs: eight representative coordinates and four seasonal dates
in 2026. It records latitude, longitude, IANA civil timezone, UTC timestamps,
calculation assumptions, and NOAA source metadata. The generator is
`scripts/generate_noaa_solar_reference.py`.

The source is NOAA Global Monitoring Laboratory's *General Solar Position
Calculations* document: <https://www.gml.noaa.gov/grad/solcalc/solareqns.PDF>.
The generator independently implements the published fractional-year
equations of time and solar declination, solves altitude crossings by bisection,
and uses geometric solar-center altitudes of −0.833° for sunrise/sunset, −18°
for Fajr, and −17° for Isha. Shafi'i Asr uses shadow factor 1. Coordinates are
the package's representative test points, not surveyed observer locations.
Elevation is zero. UTC is the comparison scale; IANA zones are recorded to
identify the local civil date. Crossings are stored to whole seconds without
minute rounding.

This NOAA implementation is an independent, lower-precision validation source,
not a high-precision ephemeris or an observation record. Near-grazing high-
latitude events can be sensitive to small declination differences. A more
precise JPL reference is now also available for phase 4.

`test/data/reference/astronomy/jpl-de421-2026.json` uses NASA/JPL DE421,
evaluated with Skyfield 1.55. JPL describes DE421 as an ephemeris containing
planetary positions and related data: <https://ssd.jpl.nasa.gov/planets/eph_export.html>.
Skyfield's topocentric altitude and almanac routines are documented at
<https://rhodesmill.org/skyfield/almanac.html>. The fixture records the same
locations and seasonal dates, the solar-center threshold assumptions, IANA
zones, and UTC results. `scripts/generate_jpl_solar_reference.py` regenerates
it for six profiles (MWL, Egyptian, Indonesian, Karachi, North American, and
Hanafi Asr), yielding 192 method/location/season schedules. Run with `uv run
--with skyfield==1.55 python scripts/generate_jpl_solar_reference.py`. Skyfield
stores the public DE421 file in `/tmp/islamic-utility-skyfield` by default, or
in the directory named by `SKYFIELD_CACHE_DIR`. The ephemeris is a
development-time reference only; it is not a package runtime dependency.

### Official Indonesian schedule reference

The Kemenag SIHAT source remains separate from the astronomical reference.
`test/data/reference/kemenag/national-2026.jsonl.gz` stores 6,204 monthly
records and 188,705 daily schedules for 517 listed city/regency points. The
source API response and its reference coordinates are preserved. This data
measures agreement with published Indonesian schedules, not astronomical
accuracy at the coordinates used for the official timetable.

### Captured engine baseline

`test/data/reference/astronomy/current-engine-baseline.json` is the archived
phase-1 engine snapshot against the NOAA records, captured before phase 2–4
changes under this plan. Human-readable metrics are in
`test/data/reference/astronomy/current-engine-baseline.md`. Do not overwrite
this historical snapshot when measuring a new engine version. Generate a new
comparison with:

```bash
python3 scripts/generate_noaa_solar_reference.py
/home/azkal/develop/flutter/bin/cache/dart-sdk/bin/dart run scripts/analyze_astronomical_reference.dart \
  test/data/reference/astronomy/noaa-2026.json \
  /tmp/noaa-current-engine.json \
  /tmp/noaa-current-engine.md
```

The Dart executable above bypasses Flutter's wrapper because it attempts to
update an SDK cache outside the writable package workspace. Use the installed
Dart SDK path appropriate to the local environment if it differs.

The archived astronomy snapshot uses the generic 18°/17° profile. The
historical Kemenag baseline separately covers the Indonesian preset and all
188,705 official schedule days. The expanded six-profile JPL dataset is used
for current per-profile regression; historical per-profile outputs were not
captured for all six profiles before phase 4.

### Candidate tolerances for validation

These are acceptance limits for phase 4 comparisons, not claims about NOAA
uncertainty. They were fixed before solver changes and are evaluated against
the JPL reference.

| Event | Candidate absolute error | Conditions |
|---|---:|---|
| Transit | ≤ 60 seconds | All records |
| Sunrise/sunset | ≤ 2 minutes | `|latitude| < 55°` |
| Sunrise/sunset | ≤ 5 minutes | `|latitude| ≥ 55°`, with an available event |
| Asr | ≤ 2 minutes | `|latitude| < 55°` |
| Asr | ≤ 5 minutes | `|latitude| ≥ 55°`, when reference and engine event are available |
| Fajr/Isha | ≤ 3 minutes | `|latitude| < 55°`, when the geometric angle is reached |
| Fajr/Isha | ≤ 10 minutes | `|latitude| ≥ 55°`, when the geometric angle is reached |

An unavailable reference event is not a numeric error sample. It is counted as
a separate availability/fallback case. This prevents a high-latitude fallback
from being mistaken for an event at the impossible geometric angle.

### Original NOAA baseline results

| Event | Samples | MAE | P95 absolute | Max absolute | NOAA unavailable, engine fallback |
|---|---:|---:|---:|---:|---:|
| Transit | 32 | 0.50 min | 0.78 min | 0.78 min | 0 |
| Sunrise | 30 | 1.48 min | 4.73 min | 5.22 min | 2 |
| Sunset | 30 | 1.41 min | 3.78 min | 4.77 min | 2 |
| Asr Shafi'i | 32 | 2.53 min | 6.95 min | 32.42 min | 0 |
| Fajr 18° | 28 | 2.07 min | 9.75 min | 12.03 min | 4 |
| Isha 17° | 28 | 2.00 min | 7.63 min | 9.70 min | 4 |

These results show why NOAA's simplified equations were insufficient around
high latitudes. They remain the phase-1 snapshot and were not replaced by later
engine outputs.

**Status: Selesai sebagai baseline awal.** The reference datasets, metadata,
tolerances, and current-engine outputs are recorded and reproducible. The
dataset's low-precision limits are explicitly documented.

## Phase 2 — Unavailable astronomical events

Status: **Selesai; fallback policy extended after phase review.**
`PrayerTimes.eventForPrayer` reports time and provenance. Fajr/Isha use the
configured high-latitude fallback when twilight angles are unreachable.
Sunrise/sunset horizon crossings that do not occur use an estimate six hours
around transit; unavailable Asr uses the midpoint between transit and sunset.
Dhuha and Maghrib derive from those anchors. Every event is therefore populated
and included in `nextPrayerDetails`, while estimated values are labeled
`highLatitudeFallback`. The `unavailable` source remains for future providers
that have no fallback policy.

Regression tests cover twilight fallback, polar-day populated events and their
provenance, the method-interval source, and next-event availability.

## Phase 3 — Adjacent-day consistency and adjustments

Status: **Selesai.** `fajrAfter` now uses the next day's Fajr calculation and
the same Fajr adjustments; `ishaBefore` uses the previous day's Isha
calculation and the same Isha adjustments. Dedicated adjustment entries for
these boundary aliases do not override their owning prayer. Imsak is derived
from adjusted Fajr and applies its own adjustment; Dhuha is derived from
adjusted sunrise plus the configured offset and applies its own adjustment.
Regression coverage checks all calculation presets for exact adjacent-day
equality, explicit Imsak/Dhuha adjustments, and Sunnah times between Maghrib
and the next Fajr boundary.

## Phase 4 — Astronomical model validation

Status: **Selesai.** The JPL DE421 dataset was used to identify two model
problems: the single Newton correction was inaccurate near grazing solar
altitudes, and event availability/Asr altitude used declination from UTC
midnight instead of interpolated solar declination at transit. Solar-altitude
crossings now use a bracketed bisection solver over the requested half-day.
Unreachable horizon/Asr crossings use marked high-latitude estimates in public
schedule results so no prayer-time event is left empty.

The pre-change comparison is
`test/data/reference/astronomy/jpl-de421-pre-phase4.md`; the updated comparison
is `test/data/reference/astronomy/jpl-de421-updated.md`, with per-record values
in the corresponding JSON files. The result is:

| Event | Before MAE | After MAE | Before max | After max | Availability mismatches after |
|---|---:|---:|---:|---:|---:|
| Transit | 0.011 min | 0.011 min | 0.033 min | 0.033 min | 0 |
| Sunrise | 0.256 min | 0.033 min | 7.300 min | 0.400 min | 0 |
| Sunset | 0.276 min | 0.037 min | 7.867 min | 0.400 min | 0 |
| Asr Shafi'i | 1.609 min | 0.059 min | 31.617 min | 1.050 min | 0 |
| Fajr 18° | 0.028 min | 0.023 min | 0.117 min | 0.117 min | 0 |
| Isha 17° | 0.078 min | 0.026 min | 0.517 min | 0.100 min | 0 |

All numeric event errors satisfy the candidate tolerances. The regression test
`test/astronomical_reference_test.dart` checks all 192 profile/location/season
schedules and the availability/fallback status of each event.
As a non-regression check, the Indonesian preset was also compared with all
188,705 Kemenag days; rounded MAE changes were 0.00 minutes and the largest
P95 change was +0.03 minutes for Asr. See
`test/data/reference/kemenag/2026-phase4-comparison.md`. This non-regression
check does not apply or define official Indonesian corrections; phase 5 is
limited to comparison under the product requirement that Kemenag values are
never used to alter calculations.

## Phase 5 — Compare with the official Indonesia schedule

Status: **Selesai dalam mode pembanding saja.** Kemenag schedule values are
comparison references only; they are never calculation inputs or corrections.
This is the agreed product boundary: the dataset is not a lookup table and no
Kemenag-derived offset is applied. The Kemenag reference coordinates are
supplied to the engine to calculate the schedule at the same location, then
calculated times are compared with the preserved official values. The complete
2026 re-run is documented in
`test/data/reference/kemenag/2026-phase5-comparison.md` and its
machine-readable result is `2026-phase5-comparison.json`. Source metadata,
coordinate caveats, collection instructions, and the full 2026 exports are
documented in `test/data/reference/kemenag/README.md`.

The engine result uses `CalculationMethod.indonesian` with no schedule lookup
or Kemenag-derived correction layer. Against 6,204 location-month records
(188,705 days), the rounded MAE and P95 deltas from the historical baseline
remain 0.00 minutes for all events except Asr P95 (+0.03 minutes). The separate
high-latitude fallback change does not affect this Indonesia dataset. Any
future difference from Kemenag remains an evaluation finding; it does not
trigger a data-derived correction to the astronomical calculation.

The separate LFNU parity reference is `test/data/reference/lfnu/`: 365 daily
records from 12 NU Online PDFs for Bangsri in 2026, at the supplied point and
64 m elevation. Its exact method settings, Ramadan classification, PDF-only
minute precision, and comparison policies are recorded next to the data. It
validates one point/year and is not a national or second-precision astronomy
reference.

## Phase 6 — Regression and documentation

Status: **Selesai.** Regression coverage now includes:

- all method presets × 7 locations × 4 seasonal dates (420 schedules), event
  ordering, and nearest-minute precision tolerance;
- JPL DE421 comparisons across 192 method/location/season schedules, plus
  event availability and marked high-latitude fallbacks;
- adjacent-day `fajrAfter`/`ishaBefore`, Imsak/Dhuha adjustments, Sunnah night
  boundaries, method-specific LFNU parameters, elevation, and Ramadan callback;
- the full 365-day LFNU Bangsri dataset with the documented diagnostic rounding
  policy (Terbit nearest-minute; other events round-up), locking event mismatch
  counts at 0/0/0/1/0/32/0/2;
- Kemenag 2026 comparison of all 188,705 city/regency-point dates, kept
  separate from the astronomical references and runtime calculations.

The API reference, calculation parameter contract, pipeline/rounding behavior,
reference dataset readmes, and package README document inputs, sources,
rounding (including LFNU client display guidance), fallback provenance, and
the limits of each comparison. Validation
for this phase: `dart analyze lib test scripts` reports no issues and `dart
test` passes with 109 tests passed and 2 external API smoke tests intentionally
skipped because live credentials are not configured.
