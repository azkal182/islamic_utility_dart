import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';

class AdjustmentFetchResult {
  const AdjustmentFetchResult({
    required this.statusCode,
    this.records = const <AdjustmentRecord>[],
    this.etag,
    this.retryAfter,
  });

  final int statusCode;
  final List<AdjustmentRecord> records;
  final String? etag;
  final Duration? retryAfter;
}

abstract class HijriAdjustmentClient {
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  });

  Future<AdjustmentFetchResult> fetchLatest({String? etag}) {
    return fetchByDate(date: DateTime.now().toUtc(), etag: etag);
  }
}
