# AI Agent Client Usage Guide

This file is a context guide for an AI agent that helps a client application
use the `islamic_utility` package. It is not a guide for modifying the package
and is not a running MCP server.

## Client responsibilities

The agent should help the client application:

- choose the correct Hijri method;
- configure the official API client safely;
- use persistent anchor cache where appropriate;
- distinguish official, provisional, and local results;
- handle `StateError` for an unsafe official range;
- avoid presenting provisional data as a final authority decision.

Do not hardcode API keys. Read them from secure client configuration or an
environment variable. Never print the key in logs.

## Which method should the client use?

```dart
// Offline deterministic calculation.
final local = HijriCalendar();

// Authority-based Indonesian official dates.
final official = HijriCalendar.withOfficial(
  adjustmentClient: HttpHijriAdjustmentClient(
    baseUrl: apiBaseUrl,
    apiKey: apiKey,
  ),
);
```

Use `calculatedLocal` when the client explicitly wants an offline calculated
calendar. Use `kemenagRiOfficial`/`withOfficial` when the client needs the
authority-based Indonesian calendar.

## Official single-date usage

```dart
final result = await official.fromGregorianOfficial(
  DateTime.utc(2026, 3, 21),
);

if (result.meta.isProvisional) {
  // Show a provisional/offline status, not a final official label.
}
```

Single-date resolution may return `local_fallback` when no usable official
anchor is available. It still returns a date, but the result is provisional.
Inspect `result.meta.source` and `result.meta.isProvisional`.

Common sources:

- `cache_anchor` / `remote_anchor`: resolved from an official anchor.
- `cache_anchor_provisional` / `remote_anchor_provisional`: official anchor
  exists but the following month boundary is not known yet.
- `anchor_local_fallback`: calculated from the last official anchor using the
  local month pattern; it remains provisional until a later anchor validates
  the gap. Never present this as final official data.

`result.meta.validationStatus` has three important values:

- `official`: resolved inside a directly anchored official segment;
- `inferred_validated`: an intermediate anchor is missing, but a later official
  anchor confirms the inferred boundaries;
- `provisional`: no later anchor has validated the extrapolation yet.

## Official range usage

```dart
try {
  final results = await official.fromGregorianOfficialRange(
    from: DateTime.utc(2026, 2, 1),
    to: DateTime.utc(2026, 9, 7),
  );
} on StateError {
  // The anchor sequence is invalid or contains a duplicate/skip.
  // Do not use a partial result.
}
```

Range behavior:

- The client prefetches anchors once and looks back up to 35 days before
  `from` for the preceding month boundary.
- The API may also return a `predecessor` outside the requested range; the
  Dart HTTP client merges it into the resolver dataset.
- Future anchors are never used for earlier Gregorian dates.
- Every adjacent Gregorian day is checked for continuous Hijri progression.
- Only `Hijri day + 1` or a valid `29/30 -> 1` month boundary is accepted.
- Missing future anchors continue from the last anchor as provisional.
- A duplicate, skipped date, or conflicting anchor throws `StateError`; no
  unsafe partial range is returned.

## API configuration

For local client development:

```text
http://localhost:3000/api
```

For production, use the production API URL only after the application owner
explicitly approves the environment. Recommended configuration names:

```text
IUK_API_BASE_URL
IUK_API_KEY
```

The client should send and honor ETags. A `304 Not Modified` response means
the cached anchor dataset remains valid and its TTL may be refreshed.

## Anchor concepts the client must understand

- `official_gregorian_date` is the Gregorian date of Hijri day `1`.
- `hijri_day` for an anchor is always `1`.
- `published_at` is metadata about official publication/correction; it is not
  used to calculate the Hijri date.
- `generated_at` describes when the API response dataset was generated.
- `revision` identifies the active official revision.
- A month can have 29 or 30 days; clients must not assume 30.
- The client must not apply an anchor as a `+1`/`-1` adjustment.

## Version migration context

### Client behavior before v1.5.0

- Official range resolution used anchor records and cache/ETag support.
- API responses were primarily consumed through `records`.
- An incomplete range could mix local fallback and an official anchor at a
  month boundary, producing a duplicate or skipped Hijri date.
- Client guidance for provisional single-date results and range errors was
  less explicit.

### Client behavior in v1.5.0

- The HTTP client consumes the API `predecessor` field and deduplicates it with
  `records`.
- Range prefetch looks back up to 35 days for a preceding anchor.
- Range continuity is validated before results are returned.
- Missing future anchors use anchored local fallback and remain provisional.
- Duplicate, skipped, or conflicting official ranges throw `StateError`.
- Single-date `local_fallback` remains available but is explicitly
  provisional.
- Existing API responses containing only `records` remain compatible.

## Client troubleshooting

If a range throws `StateError`:

1. Check for duplicate, conflicting, or out-of-order active anchors.
2. Check the transition around the reported Gregorian date.
3. Check `meta.source`, `meta.isProvisional`, and `meta.anchorDate` in any
   single-date result.
4. Do not silently convert the failed official range to final local dates.
5. Show an invalid-data state or explicitly let the user choose offline local
   calculation.

## Client-facing references

- `README.md`: quick start and official range examples.
- `doc/11-api-reference.md`: public methods and response semantics.
- `doc/12-faq-troubleshooting.md`: fallback and error handling.
- `doc/13-hijri-integration-guide.md`: cache and client integration.
- `doc/backend/19-anchor-api-contract.md`: API response contract.
- `RELEASE_NOTES_v1.5.0.md`: client migration notes.
