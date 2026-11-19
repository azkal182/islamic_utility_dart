# Current engine baseline against NOAA reference

- Source: NOAA GML published solar-position equations.
- Coverage: 32 location/date records; 8 locations × 4 seasonal dates.
- Parameters: Fajr 18°, Isha 17°, Shafi Asr, sea level; no civil-time conversion.
- Delta: package output minus NOAA reference, minutes.
- Current engine results are captured before phase 2–4 changes under the supplied roadmap.

| Event | Samples | MAE min | P95 abs min | Max abs min | NOAA unavailable / engine fallback |
|---|---:|---:|---:|---:|---:|
| transit | 32 | 0.50 | 0.78 | 0.78 | 0 |
| sunrise | 30 | 1.48 | 4.73 | 5.22 | 2 |
| sunset | 30 | 1.41 | 3.78 | 4.77 | 2 |
| asr_shafii | 32 | 2.53 | 6.95 | 32.42 | 0 |
| fajr_18 | 28 | 2.07 | 9.75 | 12.03 | 4 |
| isha_17 | 28 | 2.00 | 7.63 | 9.70 | 4 |
