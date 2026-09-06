import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

class _UnifiedMockClient implements HijriAdjustmentClient {
  int fetchByDateCalls = 0;
  int fetchRangeCalls = 0;
  int fetchAnchorsByDateCalls = 0;
  int fetchLatestAnchorsCalls = 0;
  int fetchAnchorsRangeCalls = 0;

  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) async {
    fetchByDateCalls += 1;
    return const AdjustmentFetchResult(statusCode: 200, records: []);
  }

  @override
  Future<AdjustmentFetchResult> fetchLatest({String? etag}) async {
    return fetchByDate(date: DateTime.now().toUtc(), etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) async {
    fetchRangeCalls += 1;
    return const AdjustmentFetchResult(statusCode: 200, records: []);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  }) async {
    fetchAnchorsByDateCalls += 1;
    return const AnchorFetchResult(statusCode: 200, records: []);
  }

  @override
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) async {
    fetchLatestAnchorsCalls += 1;
    return const AnchorFetchResult(statusCode: 200, records: []);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) async {
    fetchAnchorsRangeCalls += 1;
    return AnchorFetchResult(
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
    );
  }
}

void main() {
  group('UnifiedCalendar', () {
    test('default options return gregorian only', () async {
      final calendar = UnifiedCalendar();
      final result = await calendar.resolve(DateTime.utc(2026, 3, 21));

      expect(result.gregorian, DateTime.utc(2026, 3, 21));
      expect(result.hijri, isNull);
      expect(result.javanese, isNull);
    });

    test('can include local hijri and javanese', () async {
      final calendar = UnifiedCalendar();
      final result = await calendar.resolve(
        DateTime.utc(2026, 3, 21),
        options: const CalendarResolveOptions(
          includeHijri: true,
          includeJavanese: true,
          hijriMethod: HijriMethod.calculatedLocal,
        ),
      );

      expect(result.hijri, isNotNull);
      expect(result.javanese, isNotNull);
    });

    test('official range uses batch fetch (no per-day remote calls)', () async {
      final client = _UnifiedMockClient();
      final calendar = UnifiedCalendar.withOfficialHijri(
        adjustmentClient: client,
      );

      final results = await calendar.resolveRange(
        from: DateTime.utc(2026, 3, 15),
        to: DateTime.utc(2026, 3, 20),
        options: const CalendarResolveOptions(
          includeHijri: true,
          includeJavanese: true,
          hijriMethod: HijriMethod.kemenagRiOfficial,
        ),
      );

      expect(results.length, 6);
      expect(client.fetchRangeCalls, 0);
      expect(client.fetchAnchorsRangeCalls, 1);
      expect(client.fetchByDateCalls, 0);
      expect(client.fetchAnchorsByDateCalls, 0);
      expect(client.fetchLatestAnchorsCalls, 0);
    });
  });
}
