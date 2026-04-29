## 1.4.0

- Improved official Hijri range resolution consistency:
  - range prefetch now falls back to `fetchLatestAnchors(...)` once when
    `fetchAnchorsRange(...)` returns empty records near boundary windows
  - prevents unexpected local fallback mismatch for range mode
- Kept range flow optimized (no per-day remote loop) while preserving
  anchor-based official result parity.
- Added/updated tests to lock boundary behavior:
  - range empty-anchor + latest-anchor fallback case
  - batch-only official range assertions remain enforced
- Added transition-ready unified calendar facade usage updates and examples
  alignment with official mode expectations.
- Cleaned examples and docs for release safety:
  - replaced hardcoded API keys with placeholders
  - synchronized README/API docs with current public surface.

## 1.3.0

- Added official Hijri range conversion API:
  - `HijriCalendar.fromGregorianOfficialRange({from, to})`
- Added range fetch contracts in `HijriAdjustmentClient`:
  - `fetchRange(...)`
  - `fetchAnchorsRange(...)`
- Added HTTP range fetch implementation in `HttpHijriAdjustmentClient`:
  - adjustments range endpoint
  - anchors range endpoint
- Optimized official range flow to avoid per-day remote fetch loops after range prefetch.
- Added persistent cache implementations using Hive:
  - `HiveHijriAdjustmentCache`
  - `HiveHijriAnchorCache`
- Added support for injecting `anchorCache` in `HijriCalendar.withOfficial(...)`.
- Added Javanese calendar module:
  - `JavaneseCalendar`
  - `Pasaran` (`Legi`, `Pahing`, `Pon`, `Wage`, `Kliwon`)
  - `JavaneseDate` (`pasaran`, `weton`)
- Added transition-friendly unified facade:
  - `UnifiedCalendar`
  - `CalendarResolveOptions`
  - `UnifiedCalendarDate`
- Added examples:
  - `example/hijri_official_range_hive_example.dart`
  - `example/hijri_official_range_hive_flutter_example.dart`
  - `example/javanese_pasaran_example.dart`
  - `example/unified_calendar_example.dart`
- Expanded and synchronized documentation:
  - `README.md`
  - `doc/01-public-api-spec.md`
  - `doc/11-api-reference.md`
  - `doc/13-hijri-integration-guide.md`
- Added and updated tests for:
  - HTTP range request behavior
  - official provider range prefetch behavior
  - no per-day anchor remote calls in range mode

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
