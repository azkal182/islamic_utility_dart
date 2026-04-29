import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';

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

class AnchorFetchResult {
  const AnchorFetchResult({
    required this.statusCode,
    this.records = const <HijriAnchorRecord>[],
    this.etag,
    this.retryAfter,
  });

  final int statusCode;
  final List<HijriAnchorRecord> records;
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

  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    return fetchByDate(date: from, etag: etag);
  }

  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  });

  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) {
    return fetchAnchorsByDate(date: DateTime.now().toUtc(), etag: etag);
  }

  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    return fetchAnchorsByDate(date: from, etag: etag);
  }
}
