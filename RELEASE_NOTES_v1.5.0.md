# islamic_utility v1.5.0

## Summary

This release candidate improves official Hijri date resolution for anchor-first
API integrations. It prevents duplicate or skipped Hijri dates at month
boundaries and adds compatibility with the API's `predecessor` anchor field.

The package version is `1.5.0`. The package has been verified locally; no
publish or tag is performed by this change.

## Official Hijri Anchor Improvements

- Added support for the API `predecessor` field. The HTTP client includes the
  nearest active anchor before the requested range in the resolver dataset.
- Official range prefetch looks back up to 35 days for a preceding
  month-boundary anchor.
- Future anchors are never used to resolve an earlier Gregorian date.
- Consecutive results are validated for daily continuity.
- A range that would return a duplicate or skipped Hijri date now throws
  `StateError` instead of returning an unsafe result.
- A missing anchor can still produce `local_fallback` for single-date
  resolution, but it is marked provisional and must not be presented as final
  official data.

## Cache and API Compatibility

- Existing API responses containing only `records` remain supported.
- Anchor cache and ETag behavior remain compatible with existing clients.
- The preceding anchor is deduplicated when it is already present in
  `records`.
- Legacy adjustment support remains available only when explicitly enabled with
  `allowLegacyAdjustments: true`.

## Client Migration Notes

Clients using `fromGregorianOfficialRange(...)` should handle `StateError`:

```dart
try {
  final results = await calendar.fromGregorianOfficialRange(
    from: from,
    to: to,
  );
} on StateError {
  // Official anchor data is incomplete or inconsistent.
}
```

Clients should inspect `result.meta.isProvisional` and must not present
`local_fallback` or `*_provisional` as final official data.

## Documentation

- Updated README usage and release guidance.
- Updated API reference and integration guide.
- Added fallback and `StateError` behavior to the FAQ.
- Documented anchor predecessor, cache, revision, and timestamp expectations.

## Verification

- `flutter analyze`: pass.
- Full local test suite: pass.
- Local API smoke test for 2026-06-01 through 2026-07-31: pass.
- Local API continuity test for 2026-02-01 through 2026-09-07: pass.
- `flutter pub publish --dry-run`: package contents verified; no publish was
  performed.
