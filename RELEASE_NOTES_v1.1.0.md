# islamic_utility v1.1.0

## Highlights

- Refactored the astronomical engine to a Meeus-based pipeline with 3-day interpolation for improved accuracy.
- Added new prayer outputs:
  - `imsak` (10 minutes before `fajr`)
  - `dhuha` (configurable via `dhuhaOffsetMinutes`, default `20`)
- Added `dhuhaOffsetMinutes` to `CalculationParameters`.
- Expanded runnable examples, including Bangsri Jepara coordinates.
- Added bilingual documentation:
  - Updated `README.md` (English-first + Indonesian support)
  - `doc/11-api-reference.md` (bilingual API reference)
  - `doc/12-faq-troubleshooting.md` (bilingual troubleshooting guide)

## Compatibility Notes

- Prayer enum now includes `imsak` and `dhuha`.
- Use explicit `date` in `currentPrayer` and `nextPrayer` for timezone-safe behavior.
- All `PrayerTimes` outputs remain UTC `DateTime`.

## Quality

- `dart analyze`: pass
- `dart test`: pass
- `dart pub publish --dry-run`: pass (0 warnings)
