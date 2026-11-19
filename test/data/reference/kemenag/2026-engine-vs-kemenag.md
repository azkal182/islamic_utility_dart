# Kemenag SIHAT 2026 parity baseline

- Dataset: `test/data/reference/kemenag/national-2026.jsonl.gz`
- Location-month records: 6204
- Location-days: 188705
- Method: `CalculationMethod.indonesian`, `precision=true`
- Delta sign: package result minus Kemenag, in minutes

| Prayer | Samples | Mean | Median | MAE | P95 abs | Within ±1 min | >5 min | Max abs case |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Imsak | 188705 | -2.45 | -2.48 | 2.49 | 2.95 | 104 (0.06%) | 89 (0.05%) | 2026-12-22, PEKAJANG KAB. LINGGA, KEPULAUAN RIAU (-6.63) |
| Fajr/Subuh | 188705 | -2.45 | -2.48 | 2.49 | 2.95 | 104 (0.06%) | 89 (0.05%) | 2026-12-22, PEKAJANG KAB. LINGGA, KEPULAUAN RIAU (-6.63) |
| Sunrise/Terbit | 188705 | 3.66 | 3.27 | 3.66 | 7.43 | 95 (0.05%) | 20558 (10.89%) | 2026-12-24, KAB. TIMOR TENGAH SELATAN, NUSA TENGGARA TIMUR (8.18) |
| Dhuha | 188705 | -4.85 | -4.83 | 4.85 | 6.08 | 0 (0.00%) | 82932 (43.95%) | 2026-12-30, PEKAJANG KAB. LINGGA, KEPULAUAN RIAU (-9.52) |
| Dhuhr/Zuhur | 188705 | -2.50 | -2.50 | 2.50 | 2.95 | 0 (0.00%) | 0 (0.00%) | 2026-03-21, KAB. PEMALANG, JAWA TENGAH (-3.28) |
| Asr/Ashar | 188705 | -2.50 | -2.50 | 2.50 | 2.98 | 53 (0.03%) | 27 (0.01%) | 2026-09-26, PEKAJANG KAB. LINGGA, KEPULAUAN RIAU (-6.57) |
| Maghrib | 188705 | -3.65 | -3.25 | 3.65 | 7.42 | 96 (0.05%) | 20554 (10.89%) | 2026-12-15, KAB. TIMOR TENGAH SELATAN, NUSA TENGGARA TIMUR (-8.17) |
| Isha/Isya | 188705 | -2.55 | -2.50 | 2.55 | 2.95 | 96 (0.05%) | 2281 (1.21%) | 2026-12-13, KAB. INTAN JAYA, PAPUA (-7.47) |
