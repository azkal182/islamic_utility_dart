import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

class _MockOfficialClient implements HijriAdjustmentClient {
  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) async {
    return AdjustmentFetchResult(
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
    );
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
  }) {
    return fetchByDate(date: from, etag: etag);
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

  @override
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    return fetchAnchorsByDate(date: from, etag: etag);
  }
}

void main() {
  group('Hijri public API', () {
    test('supports local and umm al-qura methods', () {
      final calendar = HijriCalendar();
      final date = DateTime.utc(2024, 3, 11);

      final local = calendar.fromGregorian(
        date,
        method: HijriMethod.calculatedLocal,
      );
      final umm = calendar.fromGregorian(date, method: HijriMethod.ummAlQura);

      expect(local.month, 9);
      expect(umm.month, 9);
    });

    test('official method works via withOfficial constructor', () async {
      final calendar = HijriCalendar.withOfficial(
        adjustmentClient: _MockOfficialClient(),
        allowLegacyAdjustments: true,
      );

      final result = await calendar.fromGregorianOfficial(
        DateTime.utc(2024, 3, 11),
      );

      expect(result.meta.isAdjusted, isTrue);
      expect(result.meta.source, 'remote_adjusted');
    });
  });
}
