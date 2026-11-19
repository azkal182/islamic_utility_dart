# LFNU Bangsri 2026: engine comparison

- Dataset: `test/data/reference/lfnu/bangsri-2026.json`
- Location: Bangsri, Kabupaten Jepara, Jawa Tengah
- Coordinates: -6.522777777777778, 110.76; elevation 64 m
- Method: `CalculationMethod.lfnu`, `precision=true`; Ramadan Maghrib adjustment follows each PDF Hijri month
- Samples: 365 days per event
- Delta sign: engine minus NU Online, in minutes; negative means engine is earlier
- Engine retains second precision; NU Online publishes whole-minute times, so up to ±0.5 minute may come from source rounding.

| Event | Mean delta | Median | MAE | P95 abs | Within ±1 min | >5 min | Max abs case |
|---|---:|---:|---:|---:|---:|---:|---|
| Imsak | -0.48 | -0.47 | 0.48 | 0.92 | 365 (100.00%) | 0 (0.00%) | 2026-01-16 (-0.98) |
| Fajr/Subuh | -0.48 | -0.47 | 0.48 | 0.92 | 365 (100.00%) | 0 (0.00%) | 2026-01-16 (-0.98) |
| Sunrise/Terbit | -0.01 | 0.00 | 0.26 | 0.48 | 365 (100.00%) | 0 (0.00%) | 2026-01-05 (-0.50) |
| Dhuha | -0.48 | -0.45 | 0.48 | 0.93 | 365 (100.00%) | 0 (0.00%) | 2026-09-13 (-0.98) |
| Dhuhr/Zuhur | -0.50 | -0.50 | 0.50 | 0.95 | 365 (100.00%) | 0 (0.00%) | 2026-02-25 (-0.98) |
| Asr/Ashar | -0.51 | -0.48 | 0.51 | 0.98 | 351 (96.16%) | 0 (0.00%) | 2026-02-08 (-1.12) |
| Maghrib | -0.50 | -0.50 | 0.50 | 0.95 | 365 (100.00%) | 0 (0.00%) | 2026-01-29 (-0.98) |
| Isha/Isya | -0.47 | -0.47 | 0.47 | 0.92 | 365 (100.00%) | 0 (0.00%) | 2026-07-13 (-1.00) |
