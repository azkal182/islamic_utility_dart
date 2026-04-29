import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/kemenag_official_hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/local_hijri_provider.dart';
import 'package:test/test.dart';

class _MockClient implements HijriAdjustmentClient {
  _MockClient(this.result, {this.throwError = false});

  final AdjustmentFetchResult result;
  final bool throwError;
  int calls = 0;

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
  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  }) async {
    return const AnchorFetchResult(statusCode: 200);
  }

  @override
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) async {
    return const AnchorFetchResult(statusCode: 200);
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
      );

      final result = await provider.fromGregorianAsync(date);
      expect(result.meta.adjustmentDays, -1);
      expect(result.meta.revision, 2);
    });
  });
}
