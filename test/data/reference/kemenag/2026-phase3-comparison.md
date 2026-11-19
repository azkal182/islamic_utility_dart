# Kemenag SIHAT 2026 parity comparison

- Dataset: `test/data/reference/kemenag/national-2026.jsonl.gz`
- Location-month records: 6204
- Location-days: 188705
- Method: `CalculationMethod.indonesian`, `precision=true`
- Delta sign: package result minus Kemenag, in minutes

Negative MAE/P95 change means the updated engine is closer to Kemenag.

| Prayer | Baseline MAE | Updated MAE | MAE change | Baseline P95 | Updated P95 | P95 change |
|---|---:|---:|---:|---:|---:|---:|
| Imsak | 2.49 | 2.49 | 0.00 | 2.95 | 2.95 | 0.00 |
| Fajr/Subuh | 2.49 | 2.49 | 0.00 | 2.95 | 2.95 | 0.00 |
| Sunrise/Terbit | 3.66 | 3.66 | 0.00 | 7.43 | 7.43 | 0.00 |
| Dhuha | 4.85 | 4.85 | 0.00 | 6.08 | 6.08 | 0.00 |
| Dhuhr/Zuhur | 2.50 | 2.50 | 0.00 | 2.95 | 2.95 | 0.00 |
| Asr/Ashar | 2.50 | 2.50 | 0.00 | 2.95 | 2.95 | 0.00 |
| Maghrib | 3.65 | 3.65 | 0.00 | 7.42 | 7.42 | 0.00 |
| Isha/Isya | 2.55 | 2.55 | 0.00 | 2.95 | 2.95 | 0.00 |
