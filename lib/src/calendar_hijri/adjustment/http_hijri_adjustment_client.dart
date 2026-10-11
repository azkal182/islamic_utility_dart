import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';

typedef RetryAttemptLogger =
    void Function(
      int attempt,
      Uri uri,
      int? statusCode,
      Duration nextDelay,
      Object? error,
    );

class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 3),
    this.backoffMultiplier = 2.0,
    this.jitter = const Duration(milliseconds: 120),
    this.timeoutPerAttempt = const Duration(seconds: 8),
    this.maxRetryAfter = const Duration(seconds: 30),
  });

  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final Duration jitter;
  final Duration timeoutPerAttempt;
  final Duration maxRetryAfter;
}

class HttpHijriAdjustmentClient implements HijriAdjustmentClient {
  HttpHijriAdjustmentClient({
    required this.baseUrl,
    required this.apiKey,
    this.country = 'ID',
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
    this.retryPolicy = const RetryPolicy(),
    this.onRetryAttempt,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final String apiKey;
  final String country;
  final String authority;
  final String regionScope;
  final RetryPolicy retryPolicy;
  final RetryAttemptLogger? onRetryAttempt;
  final HttpClient _httpClient;

  @override
  Future<AdjustmentFetchResult> fetchByDate({
    required DateTime date,
    String? etag,
  }) async {
    final day = _isoDate(date);
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/adjustments?country=$country&from=$day&to=$day&authority=$authority&region_scope=$regionScope',
    );

    return _fetchWithRetry(uri, etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    final fromDay = _isoDate(from);
    final toDay = _isoDate(to);
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/adjustments?country=$country&from=$fromDay&to=$toDay&authority=$authority&region_scope=$regionScope',
    );
    return _fetchWithRetry(uri, etag: etag);
  }

  @override
  Future<AdjustmentFetchResult> fetchLatest({String? etag}) {
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/adjustments/latest?country=$country&authority=$authority&region_scope=$regionScope',
    );
    return _fetchWithRetry(uri, etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsByDate({
    required DateTime date,
    String? etag,
  }) {
    final day = _isoDate(date);
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/anchors?country=$country&from=$day&to=$day&authority=$authority&region_scope=$regionScope',
    );

    return _fetchAnchorWithRetry(uri, etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchAnchorsRange({
    required DateTime from,
    required DateTime to,
    String? etag,
  }) {
    final fromDay = _isoDate(from);
    final toDay = _isoDate(to);
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/anchors?country=$country&from=$fromDay&to=$toDay&authority=$authority&region_scope=$regionScope',
    );
    return _fetchAnchorWithRetry(uri, etag: etag);
  }

  @override
  Future<AnchorFetchResult> fetchLatestAnchors({String? etag}) {
    final uri = Uri.parse(
      '$baseUrl/v1/hijri/anchors/latest?country=$country&authority=$authority&region_scope=$regionScope',
    );
    return _fetchAnchorWithRetry(uri, etag: etag);
  }

  Future<AdjustmentFetchResult> _fetchWithRetry(Uri uri, {String? etag}) async {
    var attempt = 0;
    var delay = retryPolicy.initialDelay;
    while (true) {
      try {
        final result = await _fetchOnce(uri, etag: etag);
        final shouldRetryStatus =
            result.statusCode == HttpStatus.tooManyRequests ||
            (result.statusCode >= 500 && result.statusCode <= 599);
        if (!shouldRetryStatus || attempt >= retryPolicy.maxRetries) {
          return result;
        }
        final retryAfter = _clampRetryAfter(result.retryAfter);
        final nextDelay = retryAfter ?? _withJitter(delay);
        onRetryAttempt?.call(
          attempt + 1,
          uri,
          result.statusCode,
          nextDelay,
          null,
        );
        await Future<void>.delayed(nextDelay);
      } on SocketException catch (error) {
        if (attempt >= retryPolicy.maxRetries) rethrow;
        final nextDelay = _withJitter(delay);
        onRetryAttempt?.call(attempt + 1, uri, null, nextDelay, error);
        await Future<void>.delayed(nextDelay);
      } on TimeoutException catch (error) {
        if (attempt >= retryPolicy.maxRetries) rethrow;
        final nextDelay = _withJitter(delay);
        onRetryAttempt?.call(attempt + 1, uri, null, nextDelay, error);
        await Future<void>.delayed(nextDelay);
      }

      attempt += 1;
      final nextMs = (delay.inMilliseconds * retryPolicy.backoffMultiplier)
          .round();
      delay = Duration(milliseconds: nextMs);
      if (delay > retryPolicy.maxDelay) {
        delay = retryPolicy.maxDelay;
      }
    }
  }

  Future<AnchorFetchResult> _fetchAnchorWithRetry(
    Uri uri, {
    String? etag,
  }) async {
    var attempt = 0;
    var delay = retryPolicy.initialDelay;
    while (true) {
      try {
        final result = await _fetchAnchorOnce(uri, etag: etag);
        final shouldRetryStatus =
            result.statusCode == HttpStatus.tooManyRequests ||
            (result.statusCode >= 500 && result.statusCode <= 599);
        if (!shouldRetryStatus || attempt >= retryPolicy.maxRetries) {
          return result;
        }
        final retryAfter = _clampRetryAfter(result.retryAfter);
        final nextDelay = retryAfter ?? _withJitter(delay);
        onRetryAttempt?.call(
          attempt + 1,
          uri,
          result.statusCode,
          nextDelay,
          null,
        );
        await Future<void>.delayed(nextDelay);
      } on SocketException catch (error) {
        if (attempt >= retryPolicy.maxRetries) rethrow;
        final nextDelay = _withJitter(delay);
        onRetryAttempt?.call(attempt + 1, uri, null, nextDelay, error);
        await Future<void>.delayed(nextDelay);
      } on TimeoutException catch (error) {
        if (attempt >= retryPolicy.maxRetries) rethrow;
        final nextDelay = _withJitter(delay);
        onRetryAttempt?.call(attempt + 1, uri, null, nextDelay, error);
        await Future<void>.delayed(nextDelay);
      }

      attempt += 1;
      final nextMs = (delay.inMilliseconds * retryPolicy.backoffMultiplier)
          .round();
      delay = Duration(milliseconds: nextMs);
      if (delay > retryPolicy.maxDelay) {
        delay = retryPolicy.maxDelay;
      }
    }
  }

  Future<AdjustmentFetchResult> _fetchOnce(Uri uri, {String? etag}) async {
    final request = await _httpClient.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (etag != null && etag.isNotEmpty) {
      request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    }

    final attemptTimer = Stopwatch()..start();
    final response = await _closeWithTimeout(
      request,
      timeout: _remainingTimeout(attemptTimer),
    );
    final responseEtag = response.headers.value(HttpHeaders.etagHeader);

    if (response.statusCode == HttpStatus.notModified) {
      return AdjustmentFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag ?? etag,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    final body = await _readBodyWithTimeout(
      response,
      request,
      timeout: _remainingTimeout(attemptTimer),
    );
    if (response.statusCode != HttpStatus.ok) {
      return AdjustmentFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return AdjustmentFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
      );
    }

    final rawRecords = decoded['records'];
    if (rawRecords is! List) {
      return AdjustmentFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
      );
    }

    final records = <AdjustmentRecord>[];
    for (final row in rawRecords) {
      if (row is! Map<String, dynamic>) continue;
      final from = row['effective_from'];
      final to = row['effective_to'];
      final adjustmentDays = row['adjustment_days'];
      final revision = row['revision'];
      final publishedAt = row['published_at'];
      if (from is! String ||
          adjustmentDays is! int ||
          revision is! int ||
          publishedAt is! String) {
        continue;
      }
      records.add(
        AdjustmentRecord(
          effectiveFrom: _parseDateOnlyUtc(from),
          effectiveTo: to is String ? _parseDateOnlyUtc(to) : null,
          adjustmentDays: adjustmentDays,
          revision: revision,
          publishedAt: DateTime.parse(publishedAt).toUtc(),
          authority: (row['authority'] as String?) ?? authority,
          regionScope: (row['region_scope'] as String?) ?? regionScope,
        ),
      );
    }

    return AdjustmentFetchResult(
      statusCode: response.statusCode,
      records: records,
      etag: responseEtag,
      retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
    );
  }

  Future<AnchorFetchResult> _fetchAnchorOnce(Uri uri, {String? etag}) async {
    final request = await _httpClient.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (etag != null && etag.isNotEmpty) {
      request.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
    }

    final attemptTimer = Stopwatch()..start();
    final response = await _closeWithTimeout(
      request,
      timeout: _remainingTimeout(attemptTimer),
    );
    final responseEtag = response.headers.value(HttpHeaders.etagHeader);

    if (response.statusCode == HttpStatus.notModified) {
      return AnchorFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag ?? etag,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    final body = await _readBodyWithTimeout(
      response,
      request,
      timeout: _remainingTimeout(attemptTimer),
    );
    if (response.statusCode != HttpStatus.ok) {
      return AnchorFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
        retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return AnchorFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
      );
    }

    final rawRecords = decoded['records'];
    if (rawRecords is! List) {
      return AnchorFetchResult(
        statusCode: response.statusCode,
        etag: responseEtag,
      );
    }

    final records = <HijriAnchorRecord>[];
    for (final row in rawRecords) {
      if (row is! Map<String, dynamic>) continue;
      final officialDate = row['official_gregorian_date'];
      final hijriYear = row['hijri_year'];
      final hijriMonth = row['hijri_month'];
      final hijriDay = row['hijri_day'];
      final revision = row['revision'];
      final publishedAt = row['published_at'];
      if (officialDate is! String ||
          hijriYear is! int ||
          hijriMonth is! int ||
          revision is! int ||
          publishedAt is! String) {
        continue;
      }
      records.add(
        HijriAnchorRecord(
          officialGregorianDate: _parseDateOnlyUtc(officialDate),
          hijriYear: hijriYear,
          hijriMonth: hijriMonth,
          hijriDay: hijriDay is int ? hijriDay : 1,
          revision: revision,
          publishedAt: DateTime.parse(publishedAt).toUtc(),
          authority: (row['authority'] as String?) ?? authority,
          regionScope: (row['region_scope'] as String?) ?? regionScope,
          notes: row['notes'] as String?,
        ),
      );
    }

    // The API exposes the nearest active anchor before the requested range as
    // `predecessor`. Include it in the resolver dataset so callers can start
    // a range in the middle of a Hijri month without mixing in local fallback.
    final rawPredecessor = decoded['predecessor'];
    if (rawPredecessor is Map<String, dynamic>) {
      final predecessor = _parseAnchorRecord(rawPredecessor);
      if (predecessor != null &&
          !records.any((record) => _sameAnchor(record, predecessor))) {
        records.insert(0, predecessor);
      }
    }

    return AnchorFetchResult(
      statusCode: response.statusCode,
      records: records,
      etag: responseEtag,
      retryAfter: _parseRetryAfter(response.headers.value('retry-after')),
    );
  }

  Duration? _parseRetryAfter(String? value) {
    if (value == null || value.isEmpty) return null;
    final seconds = int.tryParse(value);
    if (seconds != null && seconds >= 0) {
      return Duration(seconds: seconds);
    }
    final dt = DateTime.tryParse(value);
    if (dt == null) return null;
    final diff = dt.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  Future<HttpClientResponse> _closeWithTimeout(
    HttpClientRequest request, {
    required Duration timeout,
  }) {
    return request.close().timeout(
      timeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException(
          'HTTP request timed out after $timeout',
          timeout,
        );
      },
    );
  }

  Future<String> _readBodyWithTimeout(
    HttpClientResponse response,
    HttpClientRequest request, {
    required Duration timeout,
  }) {
    return utf8.decoder
        .bind(response)
        .join()
        .timeout(
          timeout,
          onTimeout: () {
            request.abort();
            throw TimeoutException(
              'HTTP response body timed out after $timeout',
              timeout,
            );
          },
        );
  }

  Duration _remainingTimeout(Stopwatch timer) {
    final remaining = retryPolicy.timeoutPerAttempt - timer.elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration? _clampRetryAfter(Duration? value) {
    if (value == null) return null;
    if (value > retryPolicy.maxRetryAfter) return retryPolicy.maxRetryAfter;
    return value;
  }

  Duration _withJitter(Duration base) {
    if (retryPolicy.jitter == Duration.zero) return base;
    final maxJitterMs = retryPolicy.jitter.inMilliseconds;
    final jitterMs = DateTime.now().microsecond % (maxJitterMs + 1);
    return base + Duration(milliseconds: jitterMs);
  }

  DateTime _parseDateOnlyUtc(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.parse(value).toUtc();
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return DateTime.parse(value).toUtc();
    }
    return DateTime.utc(year, month, day);
  }

  HijriAnchorRecord? _parseAnchorRecord(Map<String, dynamic> row) {
    final officialDate = row['official_gregorian_date'];
    final hijriYear = row['hijri_year'];
    final hijriMonth = row['hijri_month'];
    final hijriDay = row['hijri_day'];
    final revision = row['revision'];
    final publishedAt = row['published_at'];
    if (officialDate is! String ||
        hijriYear is! int ||
        hijriMonth is! int ||
        revision is! int ||
        publishedAt is! String) {
      return null;
    }
    return HijriAnchorRecord(
      officialGregorianDate: _parseDateOnlyUtc(officialDate),
      hijriYear: hijriYear,
      hijriMonth: hijriMonth,
      hijriDay: hijriDay is int ? hijriDay : 1,
      revision: revision,
      publishedAt: DateTime.parse(publishedAt).toUtc(),
      authority: (row['authority'] as String?) ?? authority,
      regionScope: (row['region_scope'] as String?) ?? regionScope,
      notes: row['notes'] as String?,
    );
  }

  bool _sameAnchor(HijriAnchorRecord left, HijriAnchorRecord right) {
    return left.officialGregorianDate == right.officialGregorianDate &&
        left.hijriYear == right.hijriYear &&
        left.hijriMonth == right.hijriMonth &&
        left.revision == right.revision &&
        left.authority == right.authority &&
        left.regionScope == right.regionScope;
  }

  String _isoDate(DateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
    ).toIso8601String().split('T').first;
  }
}
