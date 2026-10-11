// Cache behavior test script for islamic_utility v1.4.1
//
// Tests three scenarios:
//   1. Single-date query — verifies fetchLatestAnchors result is cached
//      (month-based key) so day+1 hits cache without any HTTP call.
//   2. Range query (Hive) — verifies prefetchRange populates cache and
//      subsequent per-day resolution uses cache_anchor_adjusted.
//   3. Cold-start range — clears Hive box, runs range again to confirm
//      the first run fetches and the second run is fully cached.
//
// Run: dart run example/cache_behavior_test.dart

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:islamic_utility/islamic_utility.dart';

const _baseUrl = 'https://your-api-host/api';
const _apiKey = 'replace-with-your-api-key';


// ─── HTTP call counter ────────────────────────────────────────────────────────

int _httpCallCount = 0;

/// Wraps HttpHijriAdjustmentClient and counts every HTTP attempt.
class _CountingClient implements HijriAdjustmentClient {
  _CountingClient(this._inner);
  final HttpHijriAdjustmentClient _inner;

  void resetCount() => _httpCallCount = 0;

  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) {
    _httpCallCount++;
    _log('  [HTTP] fetchByDate → ${_isoDate(date)}');
    return _inner.fetchByDate(date: date, etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    _httpCallCount++;
    _log('  [HTTP] fetchRange → ${_isoDate(from)} .. ${_isoDate(to)}');
    return _inner.fetchRange(from: from, to: to, etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchLatest({String? etag}) {
    _httpCallCount++;
    _log('  [HTTP] fetchLatest');
    return _inner.fetchLatest(etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  }) {
    _httpCallCount++;
    _log('  [HTTP] fetchAnchorsByDate → ${_isoDate(date)}');
    return _inner.fetchAnchorsByDate(date: date, etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    _httpCallCount++;
    _log('  [HTTP] fetchAnchorsRange → ${_isoDate(from)} .. ${_isoDate(to)}');
    return _inner.fetchAnchorsRange(from: from, to: to, etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) {
    _httpCallCount++;
    _log('  [HTTP] fetchLatestAnchors');
    return _inner.fetchLatestAnchors(etag: etag);
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

void _log(String msg) => print(msg);

void _header(String title) {
  _log('');
  _log('╔══════════════════════════════════════════════════════════════╗');
  _log('║  $title');
  _log('╚══════════════════════════════════════════════════════════════╝');
}

void _result(HijriDate d, String label) {
  _log(
    '  $label → ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
    '  source=${d.meta.source}'
    '  adj=${d.meta.adjustmentDays}'
    '  rev=${d.meta.revision}',
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  // Hive setup
  final hiveDir = Directory('.hive_cache_test');
  if (!hiveDir.existsSync()) hiveDir.createSync(recursive: true);
  Hive.init(hiveDir.path);

  final adjustmentBox = await Hive.openBox<dynamic>(
    'ciu_test_adjustment',
  );
  final anchorBox = await Hive.openBox<dynamic>('ciu_test_anchor');

  // Clear any stale data from previous runs
  await adjustmentBox.clear();
  await anchorBox.clear();

  final inner = HttpHijriAdjustmentClient(
    baseUrl: _baseUrl,
    apiKey: _apiKey,
    retryPolicy: const RetryPolicy(maxRetries: 1),
    onRetryAttempt: (attempt, uri, statusCode, nextDelay, error) {
      _log('  [RETRY] #$attempt $uri status=$statusCode error=$error');
    },
  );
  final client = _CountingClient(inner);

  // Dates to test — use current month to ensure anchors are available
  final today = DateTime.utc(2026, 5, 6);
  final tomorrow = DateTime.utc(2026, 5, 7);
  final dayAfter = DateTime.utc(2026, 5, 8);
  final rangeStart = DateTime.utc(2026, 5, 1);
  final rangeEnd = DateTime.utc(2026, 5, 7);

  // ── Test 1: Single-date — cold start ────────────────────────────────────────
  _header('TEST 1A — Single date (cold, today = ${today.toIso8601String().split("T").first})');
  final calSingle = HijriCalendar.withOfficial(
    adjustmentClient: client,
    cache: InMemoryHijriAdjustmentCache(),
    anchorCache: InMemoryHijriAnchorCache(),
  );

  client.resetCount();
  final r1 = await calSingle.refreshGregorianOfficial(today);
  _result(r1, 'today');
  _log('  HTTP calls: $_httpCallCount  (expected: 1–2 for cold start)');
  final callsT1cold = _httpCallCount;

  // ── Test 1B: Single-date — warm (same month) ─────────────────────────────
  _header('TEST 1B — Single date (warm, tomorrow = ${tomorrow.toIso8601String().split("T").first})');
  _log('  [EXPECT] source=cache_anchor or cache_anchor_provisional, HTTP calls=0');
  client.resetCount();
  final r1b = await calSingle.fromGregorianOfficial(tomorrow);
  _result(r1b, 'tomorrow');
  _log('  HTTP calls: $_httpCallCount  (expected: 0 — month-based cache hit)');
  final callsT1warm = _httpCallCount;

  // ── Test 1C: Single-date — warm day after ────────────────────────────────
  _header('TEST 1C — Single date (warm, day after = ${dayAfter.toIso8601String().split("T").first})');
  _log('  [EXPECT] source=cache_anchor_adjusted, HTTP calls=0');
  client.resetCount();
  final r1c = await calSingle.fromGregorianOfficial(dayAfter);
  _result(r1c, 'day-after');
  _log('  HTTP calls: $_httpCallCount  (expected: 0 — month-based cache hit)');
  final callsT1c = _httpCallCount;

  // ── Test 2A: Range (Hive) — cold start ───────────────────────────────────
  _header(
    'TEST 2A — Range with Hive (cold, '
    '${rangeStart.toIso8601String().split("T").first} .. '
    '${rangeEnd.toIso8601String().split("T").first})',
  );
  final calRange = HijriCalendar.withOfficial(
    adjustmentClient: client,
    cache: HiveHijriAdjustmentCache(adjustmentBox),
    anchorCache: HiveHijriAnchorCache(anchorBox),
  );

  client.resetCount();
  final results2a = await calRange.refreshGregorianOfficialRange(
    from: rangeStart,
    to: rangeEnd,
  );
  _log('  HTTP calls: $_httpCallCount  (expected: 1–2 range fetch + possible latest)');
  final callsRange1 = _httpCallCount;
  var day = rangeStart;
  for (final r in results2a) {
    _result(r, day.toIso8601String().split('T').first);
    day = day.add(const Duration(days: 1));
  }

  // ── Test 2B: Range (Hive) — warm (second call, same range) ───────────────
  _header('TEST 2B — Range with Hive (warm, same range)');
  _log('  [EXPECT] source=cache_anchor or cache_anchor_provisional for all days, HTTP calls=0');
  client.resetCount();
  final results2b = await calRange.fromGregorianOfficialRange(
    from: rangeStart,
    to: rangeEnd,
  );
  _log('  HTTP calls: $_httpCallCount  (expected: 0 — all days in Hive cache)');
  final callsRange2 = _httpCallCount;
  day = rangeStart;
  for (final r in results2b) {
    _result(r, day.toIso8601String().split('T').first);
    day = day.add(const Duration(days: 1));
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  _header('SUMMARY');
  _log('');
  _log('  Test 1A (single, cold):             $callsT1cold HTTP call(s)');
  _log(
    '  Test 1B (single, warm +1 day):      $callsT1warm HTTP call(s)'
    '${callsT1warm == 0 ? "  ✅ PASS" : "  ❌ FAIL — cache miss"}',
  );
  _log(
    '  Test 1C (single, warm +2 days):     $callsT1c HTTP call(s)'
    '${callsT1c == 0 ? "  ✅ PASS" : "  ❌ FAIL — cache miss"}',
  );
  _log('  Test 2A (range, cold):              $callsRange1 HTTP call(s)');
  _log(
    '  Test 2B (range, warm second run):   $callsRange2 HTTP call(s)'
    '${callsRange2 == 0 ? "  ✅ PASS" : "  ❌ FAIL — cache miss"}',
  );
  _log('');

  final allPass = callsT1warm == 0 && callsT1c == 0 && callsRange2 == 0;
  if (allPass) {
    _log('  🎉 ALL CACHE TESTS PASSED');
  } else {
    _log('  ⚠️  SOME CACHE TESTS FAILED — check HTTP call counts above');
    exitCode = 1;
  }

  await Hive.close();

  // Cleanup test hive directory
  hiveDir.deleteSync(recursive: true);
}
