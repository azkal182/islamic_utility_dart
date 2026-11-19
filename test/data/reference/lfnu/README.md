# LFNU Bangsri 2026 reference dataset

This folder contains one full year of published NU Online prayer times for Bangsri, Kabupaten Jepara, Jawa Tengah. The 12 monthly source PDFs are preserved in `source/`; the normalized files contain all 365 Gregorian dates in 2026.

## Reference metadata

- Coordinates: 6°31′22″ S, 110°45′36″ E (`-6.522777777777778`, `110.76`)
- Elevation: 64 m above sea level
- Time zone: `Asia/Jakarta` (WIB, UTC+07:00)
- Method: Lembaga Falakiyah NU (LFNU)
- Fajr: solar altitude −20°; Isha: −18°
- Asr: Shafi'i shadow factor
- Dhuhr: transit +1 minute
- Imsak: 10 minutes before Fajr
- Dhuha: solar altitude +4.5°
- Routine ihtiyath: 0 minutes; Ramadan Maghrib ihtiyath: +1 minute
- Sunrise/Maghrib horizon: −1°4′, as supplied with the LFNU method details

The PDFs publish whole-minute values, not source seconds. The dataset therefore cannot establish second-level source accuracy. `bangsri-2026-round-up-comparison.*` applies round-up to every engine event. The mixed comparison applies nearest-minute rounding for Terbit and round-up for the other events, matching the manual test requested for this reference. This mixed diagnostic is not a global engine setting and does not claim every NU Online surface uses the same PDF export policy. The NU Online FAQ describes round-up for the app: <https://app.nu.or.id/faq/jadwal-shalat/seberapa-akurat-jadwal-shalat-di-aplikasi-nu-online>.

For the supplied PDF fixture, the mixed policy produces 35 mismatches across
2,920 event-days; round-up for all events produces 216 and nearest-minute for
all events produces 1,191. These counts compare minute displays, not underlying
astronomical errors. A client should use the policy for its intended target:
PDF parity or the NU Online application's stated round-up behavior.

This is a single-location, single-year parity reference, not a universal proof of accuracy. The LFNU preset uses the settings supplied for Bangsri, including Ramadan Maghrib +1 minute; the NU Online FAQ describes default ihtiyath as 0 minutes. Keep that distinction explicit when interpreting the comparison.

Ramadan dates are inferred from the Hijri day/month printed in the PDFs: 19 February through 20 March 2026 (30 days). This classification is used only to turn on the LFNU Ramadan Maghrib adjustment in the comparison script.

## Files and regeneration

- `bangsri-2026.json`: full dataset, metadata, source hashes, and daily records.
- `bangsri-2026.csv`: compact daily table.
- `bangsri-2026-comparison.md` and `.json`: per-event summary statistics against `CalculationMethod.lfnu`.
- `bangsri-2026-engine-comparison.csv`: source time, engine time (including seconds), and signed delta for each date/event.
- `bangsri-2026-round-up-comparison.md` and `.json`: comparison after rounding every engine event up to the next whole minute.
- `bangsri-2026-round-up-comparison.csv`: daily source, rounded engine, and delta in seconds.
- `bangsri-2026-mixed-rounding-comparison.md`, `.json`, and `.csv`: diagnostic run with Terbit rounded to the nearest minute and all other events rounded up. The Dart regression test locks its expected per-event mismatch counts.
- `source/`: the 12 original monthly PDFs.

Regenerate the normalized dataset with:

```sh
python3 scripts/import_lfnu_schedule_pdfs.py \
  --source-dir test/data/reference/lfnu/source \
  --output-dir test/data/reference/lfnu
```

Regenerate the engine comparison with:

```sh
dart run scripts/analyze_lfnu_parity.dart
```

Regenerate the round-up comparison with:

```sh
python3 scripts/analyze_lfnu_roundup_comparison.py
```

Regenerate the diagnostic run that rounds Terbit to nearest minute and rounds
other events up with:

```sh
python3 scripts/analyze_lfnu_roundup_comparison.py --sunrise-nearest
```

The dataset is a reference for measuring the astronomical engine. It is not used as a lookup table or as input to prayer-time calculations.
