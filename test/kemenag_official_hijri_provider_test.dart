import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/kemenag_official_hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/local_hijri_provider.dart';
import 'package:test/test.dart';

class _MockClient implements HijriAdjustmentClient {
  _MockClient(
    this.result, {
    this.throwError = false,
    this.anchorRangeResult = const AnchorFetchResult(statusCode: 200),
    this.latestAnchorResult = const AnchorFetchResult(statusCode: 200),
  });

  final AdjustmentFetchResult result;
  final bool throwError;
  final AnchorFetchResult anchorRangeResult;
  final AnchorFetchResult latestAnchorResult;
  int calls = 0;
  int anchorByDateCalls = 0;
  int anchorLatestCalls = 0;
  int rangeCalls = 0;
  int anchorRangeCalls = 0;

  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) async {
    calls += 1;
    if (throwError) throw Exception('network');
    return result;
  }

  @override
  Future<AdjustmentFetchResult> fetchLatest({String? etag}) {
    return fetchByDate(date: DateTime.now().toUtc(), etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) async {
    rangeCalls += 1;
    if (throwError) throw Exception('network');
    return result;
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  }) async {
    anchorByDateCalls += 1;
    return const AnchorFetchResult(statusCode: 200);
  }

  @override
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) async {
    anchorLatestCalls += 1;
    return latestAnchorResult;
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) async {
    anchorRangeCalls += 1;
    return anchorRangeResult;
  }
}

void main() {
  group('KemenagOfficialHijriProvider', () {
    final date = DateTime.utc(2024, 3, 11);

    test('applies remote adjustment on 200', () async {
      final client = _MockClient(
        AdjustmentFetchResult(
          statusCode: 200,
          etag: 'v1',
          records: [
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: 1,
              revision: 1,
              publishedAt: DateTime.utc(2024, 3, 10),
            ),
          ],
        ),
      );

      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: client,
        adjustmentCache: InMemoryHijriAdjustmentCache(),
        allowLegacyAdjustments: true,
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.isAdjusted, isTrue);
      expect(result.meta.source, 'remote_adjusted');
      expect(result.meta.adjustmentDays, 1);
    });

    test('uses cache on 304', () async {
      final cache = InMemoryHijriAdjustmentCache();
      cache.put(
        date,
        AdjustmentCacheEntry(
          etag: 'v1',
          cachedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
          ttl: const Duration(hours: 24),
          records: [
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: -1,
              revision: 2,
              publishedAt: DateTime.utc(2024, 3, 10),
            ),
          ],
        ),
      );

      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: _MockClient(
          const AdjustmentFetchResult(statusCode: 304),
        ),
        adjustmentCache: cache,
        allowLegacyAdjustments: true,
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.isAdjusted, isTrue);
      expect(result.meta.source, 'cache_adjusted');
      expect(result.meta.adjustmentDays, -1);
    });

    test('falls back to local on error without cache', () async {
      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: _MockClient(
          const AdjustmentFetchResult(statusCode: 500),
          throwError: true,
        ),
        adjustmentCache: InMemoryHijriAdjustmentCache(),
        allowLegacyAdjustments: true,
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.isAdjusted, isFalse);
      expect(result.meta.source, 'local');
    });

    test('uses fresh cache without remote call', () async {
      final cache = InMemoryHijriAdjustmentCache();
      cache.put(
        date,
        AdjustmentCacheEntry(
          etag: 'v1',
          cachedAt: DateTime.now().toUtc(),
          ttl: const Duration(hours: 24),
          records: [
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: 1,
              revision: 1,
              publishedAt: DateTime.utc(2024, 3, 10),
            ),
          ],
        ),
      );
      final client = _MockClient(const AdjustmentFetchResult(statusCode: 500));
      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: client,
        adjustmentCache: cache,
        allowLegacyAdjustments: true,
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.source, 'cache_adjusted');
      expect(result.meta.isAdjusted, isTrue);
      expect(client.calls, 0);
    });

    test('picks highest revision then latest publishedAt', () async {
      final client = _MockClient(
        AdjustmentFetchResult(
          statusCode: 200,
          records: [
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: -1,
              revision: 1,
              publishedAt: DateTime.utc(2024, 3, 9),
            ),
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: 1,
              revision: 2,
              publishedAt: DateTime.utc(2024, 3, 8),
            ),
            AdjustmentRecord(
              effectiveFrom: DateTime.utc(2024, 3, 1),
              effectiveTo: DateTime.utc(2024, 3, 31),
              adjustmentDays: -1,
              revision: 2,
              publishedAt: DateTime.utc(2024, 3, 10),
            ),
          ],
        ),
      );
      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: client,
        adjustmentCache: InMemoryHijriAdjustmentCache(),
        allowLegacyAdjustments: true,
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.adjustmentDays, -1);
      expect(result.meta.revision, 2);
    });

    test(
      'range conversion prefetches once and avoids per-day fetch loop',
      () async {
        final client = _MockClient(
          AdjustmentFetchResult(
            statusCode: 200,
            records: [
              AdjustmentRecord(
                effectiveFrom: DateTime.utc(2024, 3, 1),
                effectiveTo: DateTime.utc(2024, 3, 31),
                adjustmentDays: 1,
                revision: 1,
                publishedAt: DateTime.utc(2024, 3, 10),
              ),
            ],
          ),
          anchorRangeResult: AnchorFetchResult(
            statusCode: 200,
            records: [
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 3, 21),
                hijriYear: 1447,
                hijriMonth: 10,
                revision: 1,
                publishedAt: DateTime.utc(2026, 3, 20),
              ),
            ],
          ),
        );

        final provider = KemenagOfficialHijriProvider(
          baseProvider: LocalHijriProvider(),
          adjustmentClient: client,
          adjustmentCache: InMemoryHijriAdjustmentCache(),
          allowLegacyAdjustments: true,
        );

        final result = await provider.fromGregorianRangeAsync(
          from: DateTime.utc(2024, 3, 11),
          to: DateTime.utc(2024, 3, 13),
        );

        expect(result.length, 3);
        expect(client.rangeCalls, 1);
        expect(client.anchorRangeCalls, 1);
        expect(client.calls, 0);
        expect(client.anchorByDateCalls, 0);
        expect(client.anchorLatestCalls, 0);
      },
    );

    test('does not use a future latest anchor for an earlier range', () async {
      final client = _MockClient(
        const AdjustmentFetchResult(statusCode: 200, records: []),
        anchorRangeResult: const AnchorFetchResult(
          statusCode: 200,
          records: [],
        ),
        latestAnchorResult: AnchorFetchResult(
          statusCode: 200,
          records: [
            HijriAnchorRecord(
              officialGregorianDate: DateTime.utc(2026, 3, 21),
              hijriYear: 1447,
              hijriMonth: 10,
              revision: 1,
              publishedAt: DateTime.utc(2026, 3, 20),
            ),
          ],
        ),
      );

      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: client,
        adjustmentCache: InMemoryHijriAdjustmentCache(),
      );

      final results = await provider.fromGregorianRangeAsync(
        from: DateTime.utc(2026, 3, 15),
        to: DateTime.utc(2026, 3, 16),
      );

      expect(results[0].meta.source, 'local_fallback');
      expect(results[0].meta.isProvisional, isTrue);
      expect(client.anchorRangeCalls, 1);
      expect(client.anchorLatestCalls, 1);
      expect(client.anchorByDateCalls, 0);
    });

    test(
      'explicit refresh uses a preceding anchor for a mid-month range',
      () async {
        final client = _MockClient(
          const AdjustmentFetchResult(statusCode: 200, records: []),
          anchorRangeResult: AnchorFetchResult(
            statusCode: 200,
            records: [
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 1, 20),
                hijriYear: 1447,
                hijriMonth: 8,
                revision: 1,
                publishedAt: DateTime.utc(2026, 1, 19),
              ),
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 2, 19),
                hijriYear: 1447,
                hijriMonth: 9,
                revision: 1,
                publishedAt: DateTime.utc(2026, 2, 18),
              ),
            ],
          ),
        );

        final provider = KemenagOfficialHijriProvider(
          baseProvider: LocalHijriProvider(),
          adjustmentClient: client,
          anchorCache: InMemoryHijriAnchorCache(),
        );

        final results = await provider.refreshOfficialRangeAsync(
          from: DateTime.utc(2026, 2, 18),
          to: DateTime.utc(2026, 2, 19),
        );

        expect(results[0].year, 1447);
        expect(results[0].month, 8);
        expect(results[0].day, 30);
        expect(results[1].year, 1447);
        expect(results[1].month, 9);
        expect(results[1].day, 1);
        expect(results[0].meta.source, 'cache_anchor');
        expect(results[1].meta.source, 'cache_anchor_provisional');
      },
    );

    test(
      'uses stale official cache immediately when refreshing offline',
      () async {
        final cache = InMemoryHijriAnchorCache();
        final target = DateTime.utc(2026, 6, 1);
        cache.put(
          target,
          AnchorCacheEntry(
            records: [
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 5, 18),
                hijriYear: 1447,
                hijriMonth: 12,
                revision: 1,
                publishedAt: DateTime.utc(2026, 5, 17),
              ),
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 6, 17),
                hijriYear: 1448,
                hijriMonth: 1,
                revision: 1,
                publishedAt: DateTime.utc(2026, 6, 16),
              ),
            ],
            cachedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
            ttl: const Duration(hours: 24),
          ),
        );
        final provider = KemenagOfficialHijriProvider(
          baseProvider: LocalHijriProvider(),
          adjustmentClient: _MockClient(
            const AdjustmentFetchResult(statusCode: 500),
            anchorRangeResult: const AnchorFetchResult(statusCode: 500),
          ),
          anchorCache: cache,
        );

        final result = await provider.fromGregorianAsync(target);

        expect(result.year, 1447);
        expect(result.month, 12);
        expect(result.day, 15);
        expect(result.meta.source, 'cache_anchor');
      },
    );

    test('complete cached range resolves without a network request', () async {
      final cache = InMemoryHijriAnchorCache();
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 5, 18),
          hijriYear: 1447,
          hijriMonth: 12,
          revision: 1,
          publishedAt: DateTime.utc(2026, 5, 17),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 17),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 16),
        ),
      ];
      final entry = AnchorCacheEntry(
        records: records,
        cachedAt: DateTime.now().toUtc(),
        ttl: const Duration(hours: 24),
      );
      for (var day = 1; day <= 3; day++) {
        cache.put(DateTime.utc(2026, 6, day), entry);
      }
      final client = _MockClient(
        const AdjustmentFetchResult(statusCode: 200),
        anchorRangeResult: const AnchorFetchResult(statusCode: 500),
      );
      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: client,
        anchorCache: cache,
      );

      final results = await provider.fromGregorianRangeAsync(
        from: DateTime.utc(2026, 6, 1),
        to: DateTime.utc(2026, 6, 3),
      );

      expect(results.length, 3);
      expect(results.first.day, 15);
      expect(results.first.meta.source, 'cache_anchor');
      expect(client.anchorRangeCalls, 0);
      expect(client.anchorLatestCalls, 0);
    });

    test(
      'partial cached range falls back locally as one coherent range',
      () async {
        final cache = InMemoryHijriAnchorCache();
        cache.put(
          DateTime.utc(2026, 6, 1),
          AnchorCacheEntry(
            records: [
              HijriAnchorRecord(
                officialGregorianDate: DateTime.utc(2026, 5, 18),
                hijriYear: 1447,
                hijriMonth: 12,
                revision: 1,
                publishedAt: DateTime.utc(2026, 5, 17),
              ),
            ],
            cachedAt: DateTime.now().toUtc(),
            ttl: const Duration(hours: 24),
          ),
        );
        final provider = KemenagOfficialHijriProvider(
          baseProvider: LocalHijriProvider(),
          adjustmentClient: _MockClient(
            const AdjustmentFetchResult(statusCode: 200),
          ),
          anchorCache: cache,
        );

        final results = await provider.fromGregorianRangeAsync(
          from: DateTime.utc(2026, 6, 1),
          to: DateTime.utc(2026, 6, 2),
        );

        expect(results.length, 2);
        expect(results[0].meta.source, 'local_fallback');
        expect(results[1].meta.source, 'local_fallback');
        expect(results.every((item) => item.meta.isProvisional), isTrue);
      },
    );

    test('304 refreshes TTL only for the matching anchor range ETag', () async {
      final cache = InMemoryHijriAnchorCache();
      final start = DateTime.utc(2026, 6, 1);
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 5, 18),
          hijriYear: 1447,
          hijriMonth: 12,
          revision: 1,
          publishedAt: DateTime.utc(2026, 5, 17),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 17),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 16),
        ),
      ];
      const etagKey = 'anchors:2026-04-27:2026-06-03:kemenag_ri:national';
      cache.put(
        start,
        AnchorCacheEntry(
          records: records,
          etag: 'range-v1',
          etagKey: etagKey,
          cachedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
          ttl: const Duration(hours: 24),
        ),
      );
      final provider = KemenagOfficialHijriProvider(
        baseProvider: LocalHijriProvider(),
        adjustmentClient: _MockClient(
          const AdjustmentFetchResult(statusCode: 200),
          anchorRangeResult: const AnchorFetchResult(statusCode: 304),
        ),
        anchorCache: cache,
      );

      final results = await provider.refreshOfficialRangeAsync(
        from: start,
        to: DateTime.utc(2026, 6, 3),
      );

      expect(results.length, 3);
      expect(cache.get(start)!.isFresh, isTrue);
      expect(cache.get(DateTime.utc(2026, 6, 2))!.etagKey, etagKey);
    });
  });
}
