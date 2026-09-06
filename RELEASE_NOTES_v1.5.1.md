# islamic_utility v1.5.1

## Summary

Patch release for official Hijri range resolution when future month anchors
are not yet available or are later corrected.

## Changes

- Future dates continue from the last available official anchor using an
  anchored local fallback instead of failing only because a future anchor is
  missing.
- Added `HijriResultMeta.validationStatus`:
  - `official`
  - `inferred_validated`
  - `provisional`
- A later anchor that moves by `+1` or `-1` day becomes the source of truth and
  recalculates the affected provisional segment.
- Prevented duplicate or skipped Hijri day `1` values during anchor
  reconciliation.
- Range prefetch now uses conditional ETag requests so new anchor revisions
  can replace provisional cache data before the previous TTL expires.
- Updated client documentation and AI-agent usage guidance.

## Compatibility

- No public method was removed.
- Existing client calls remain compatible.
- `StateError` remains reserved for conflicting, duplicate, skipped, or
  otherwise invalid anchor sequences.
- Missing future anchors return provisional results instead of failing.

## Verification

- `flutter analyze`: passed.
- Full Flutter test suite: passed.
- Added tests for several future months, inferred validation, and `+1`/`-1`
  anchor corrections.
- No publish or tag has been performed automatically.
