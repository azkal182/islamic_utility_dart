## 1.2.0

- Added Hijri calendar foundation module (`calendar_hijri`) with modular structure.
- Added `HijriCalendar` public facade API.
- Added `HijriMethod` options:
  - `calculatedLocal`
  - `ummAlQura`
  - `kemenagRiOfficial` (via official adjustment flow)
- Added Umm al-Qura provider implementation and dataset organization.
- Added local civil Hijri provider implementation.
- Added mock-first official adjustment flow:
  - adjustment client contract
  - in-memory cache contract
  - fallback chain: remote -> cache -> local
- Added Hijri examples:
  - `example/hijri_methods_example.dart`
  - `example/hijri_official_mock_example.dart`
- Added Hijri docs:
  - `doc/13-hijri-integration-guide.md`
  - FAQ updates in `doc/12-faq-troubleshooting.md`

## 1.1.0

- Refactored astronomical engine to a Meeus-based pipeline with higher precision and 3-day interpolation.
- Added `imsak` and `dhuha` prayer outputs.
- Added configurable `dhuhaOffsetMinutes` in `CalculationParameters`.
- Expanded runnable examples, including Bangsri Jepara coordinates.
- Added bilingual documentation:
  - Updated `README.md` (Indonesia + English)
  - Added `docs/11-api-reference.md` (bilingual API reference)
  - Added `docs/12-faq-troubleshooting.md` (bilingual FAQ/troubleshooting)

## 1.0.0

- Initial version.
