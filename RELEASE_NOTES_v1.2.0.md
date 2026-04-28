# islamic_utility v1.2.0

## Highlights

- Added `calendar_hijri` foundation module with isolated architecture.
- Added public `HijriCalendar` facade with multi-method support:
  - `calculatedLocal`
  - `ummAlQura`
  - `kemenagRiOfficial` (official adjustment flow)
- Added Umm al-Qura local dataset organization and provider.
- Added local civil Hijri provider for offline-first usage.
- Added official adjustment domain contracts:
  - `HijriAdjustmentClient`
  - `HijriAdjustmentCache`
  - `AdjustmentRecord`
- Added mock-first official provider with fallback chain:
  - `remote_adjusted -> cache_adjusted -> local`
- Added HTTP adapter:
  - `HttpHijriAdjustmentClient`

## Examples

- `example/hijri_methods_example.dart`
- `example/hijri_official_mock_example.dart`
- `example/hijri_official_http_example.dart`

## Documentation

- Added `doc/13-hijri-integration-guide.md`
- Updated `doc/12-faq-troubleshooting.md` with Hijri topics

## Quality

- `dart analyze`: pass
- `dart test`: pass
