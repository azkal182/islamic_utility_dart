# LFNU Bangsri 2026 — mixed-rounding comparison

- Days: 365
- Rule: round up all events except Terbit, which uses nearest-minute rounding; exact minute values remain unchanged.
- Delta: rounded engine minus NU Online PDF, in seconds; positive means later.
- The engine used the LFNU preset, including its configured Ramadan Maghrib +1 minute.
- PDF values are minute-only; this is a schedule parity check, not a second-precision source validation.

| Jadwal | Hari tidak cocok | Selisih absolut terbesar | Tanggal | Engine | PDF | Cocok persis |
|---|---:|---:|---|---|---|---:|
| Imsak | 0/365 | 0 dtk | 2026-01-01 | 03:51 | 03:51 | 365/365 |
| Subuh | 0/365 | 0 dtk | 2026-01-01 | 04:01 | 04:01 | 365/365 |
| Terbit | 0/365 | 0 dtk | 2026-01-01 | 05:24 | 05:24 | 365/365 |
| Dhuha | 1/365 | 60 dtk | 2026-11-05 | 05:33 | 05:32 | 364/365 |
| Zuhur | 0/365 | 0 dtk | 2026-01-01 | 11:42 | 11:42 | 365/365 |
| Asar | 32/365 | 60 dtk | 2026-01-09 | 15:10 | 15:11 | 333/365 |
| Maghrib | 0/365 | 0 dtk | 2026-01-01 | 17:57 | 17:57 | 365/365 |
| Isya | 2/365 | 60 dtk | 2026-03-01 | 19:07 | 19:06 | 363/365 |

## Rentang selisih bertanda

| Jadwal | Paling awal | Paling akhir |
|---|---:|---:|
| Imsak | 0 dtk | +0 dtk |
| Subuh | 0 dtk | +0 dtk |
| Terbit | 0 dtk | +0 dtk |
| Dhuha | 0 dtk | +60 dtk |
| Zuhur | 0 dtk | +0 dtk |
| Asar | -60 dtk | +60 dtk |
| Maghrib | 0 dtk | +0 dtk |
| Isya | -60 dtk | +60 dtk |
