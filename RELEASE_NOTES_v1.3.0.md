# islamic_utility v1.3.0

## Highlights

- Added official Hijri range conversion:
  - `HijriCalendar.fromGregorianOfficialRange({from, to})`
- Added persistent cache support with Hive:
  - `HiveHijriAdjustmentCache`
  - `HiveHijriAnchorCache`
- Optimized official range flow to avoid per-day remote fetch loops.
- Added Javanese pasaran module:
  - `JavaneseCalendar`
  - `Pasaran`
  - `JavaneseDate`
- Added transition-friendly unified facade:
  - `UnifiedCalendar`
  - `CalendarResolveOptions`
  - `UnifiedCalendarDate`

## Examples

- `example/hijri_official_range_hive_example.dart`
- `example/hijri_official_range_hive_flutter_example.dart`
- `example/javanese_pasaran_example.dart`
- `example/unified_calendar_example.dart`

## Documentation

- Updated `README.md`
- Updated `doc/01-public-api-spec.md`
- Updated `doc/11-api-reference.md`
- Updated `doc/13-hijri-integration-guide.md`

## Quality

- `dart analyze`: pass
- `dart test`: pass
