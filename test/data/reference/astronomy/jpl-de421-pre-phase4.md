# Current engine comparison against NASA/JPL DE421 planetary ephemeris, evaluated with Skyfield

- Input reference: `test/data/reference/astronomy/jpl-de421-2026.json`.
- Coverage: 32 location/date records; 8 locations × 4 seasonal dates.
- Parameters: Fajr 18°, Isha 17°, Shafi Asr, sea level; times compared in UTC.
- Delta: package output minus reference, minutes.

| Event | Samples | MAE min | P95 abs min | Max abs min | Availability mismatches |
|---|---:|---:|---:|---:|---:|
| transit | 32 | 0.01 | 0.02 | 0.03 | 0 |
| sunrise | 31 | 0.26 | 0.08 | 7.30 | 0 |
| sunset | 31 | 0.28 | 0.08 | 7.87 | 0 |
| asr_shafii | 32 | 1.61 | 5.25 | 31.62 | 0 |
| fajr_18 | 28 | 0.03 | 0.10 | 0.12 | 4 |
| isha_17 | 28 | 0.08 | 0.23 | 0.52 | 4 |
