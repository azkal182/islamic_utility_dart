import 'package:islamic_utility/islamic_utility.dart';

class MockAdjustmentClient implements HijriAdjustmentClient {
  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) async {
    return AdjustmentFetchResult(
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

void main() async {
  final calendar = HijriCalendar.withOfficial(
    adjustmentClient: MockAdjustmentClient(),
  );

  final date = DateTime.utc(2024, 3, 11);
  final result = await calendar.fromGregorianOfficial(date);

  print('Gregorian: ${date.toIso8601String()}');
  print(
    'Official adjusted Hijri: ${result.year}-${result.month}-${result.day}',
  );
  print('Source: ${result.meta.source}');
  print('Adjusted days: ${result.meta.adjustmentDays}');
}
