import 'dart:async';

import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/resolver/anchor_resolver.dart';

class KemenagOfficialHijriProvider implements HijriProvider {
  KemenagOfficialHijriProvider({
    required this.baseProvider,
    required this.adjustmentClient,
    HijriAdjustmentCache? adjustmentCache,
    HijriAnchorCache? anchorCache,
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
    this.cacheTtl = const Duration(hours: 24),
    this.allowLegacyAdjustments = false,
  }) : adjustmentCache = adjustmentCache ?? InMemoryHijriAdjustmentCache(),
       anchorCache = anchorCache ?? InMemoryHijriAnchorCache();

  final HijriProvider baseProvider;
  final HijriAdjustmentClient adjustmentClient;
  final HijriAdjustmentCache adjustmentCache;
  final HijriAnchorCache anchorCache;
  final String authority;
  final String regionScope;
  final Duration cacheTtl;

  /// Legacy compatibility switch. New integrations should leave this false.
  final bool allowLegacyAdjustments;
  final AnchorResolver _anchorResolver = const AnchorResolver();
  final Map<String, Future<void>> _refreshFlights = {};

  @override
  bool supports(HijriMethod method) => method == HijriMethod.kemenagRiOfficial;

  @override
  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    throw UnsupportedError('Use fromGregorianAsync for official provider');
  }

  Future<HijriDate> fromGregorianAsync(DateTime date) async {
    if (allowLegacyAdjustments) {
      return _fromGregorianAsync(date, allowRemote: true);
    }

    final day = _dateOnly(date);
    final cached = _resolveCachedAnchor(day);
    final entry = anchorCache.get(day);
    if (entry == null || !entry.isFresh || cached == null) {
      _scheduleDateRefresh(day);
    }
    return cached ?? _localFallback(day);
  }

  /// Fetches official data now and returns the best result after the refresh.
  /// Normal lookups remain cache-first; applications can use this method for
  /// an explicit refresh action and then update their UI with the returned value.
  Future<HijriDate> refreshOfficialAsync(DateTime date) async {
    final day = _dateOnly(date);
    await _singleFlight(_dateRefreshKey(day), () => _refreshDate(day));
    return _resolveCachedAnchor(day) ?? _localFallback(day);
  }

  Future<HijriDate> _fromGregorianAsync(
    DateTime date, {
    required bool allowRemote,
  }) async {
    final anchorResolved = await _resolveFromAnchor(
      date,
      allowRemote: allowRemote,
    );
    if (anchorResolved != null) {
      return anchorResolved;
    }

    final base = baseProvider.fromGregorian(
      date,
      method: HijriMethod.calculatedLocal,
    );

    if (!allowLegacyAdjustments) {
      return HijriDate(
        year: base.year,
        month: base.month,
        day: base.day,
        meta: const HijriResultMeta(
          source: 'local_fallback',
          isProvisional: true,
          validationStatus: 'provisional',
        ),
      );
    }

    final cached = adjustmentCache.get(date);
    List<AdjustmentRecord> candidateRecords = cached?.records ?? const [];
    String source = cached == null ? 'local' : 'cache_adjusted';

    if (cached != null && cached.isFresh) {
      final selectedFresh = _pickRecord(cached.records, date);
      if (selectedFresh != null && selectedFresh.adjustmentDays != 0) {
        return _buildAdjusted(date, selectedFresh, source: 'cache_adjusted');
      }
    }

    if (allowRemote) {
      try {
        final remote = await adjustmentClient.fetchByDate(
          date: date,
          etag: cached?.etag,
        );
        if (remote.statusCode == 200) {
          adjustmentCache.put(
            date,
            AdjustmentCacheEntry(
              records: remote.records,
              etag: remote.etag,
              cachedAt: DateTime.now().toUtc(),
              ttl: cacheTtl,
            ),
          );
          candidateRecords = remote.records;
          source = 'remote_adjusted';
        } else if (remote.statusCode == 304 && cached != null) {
          candidateRecords = cached.records;
          source = 'cache_adjusted';
        }
      } catch (_) {
        if (cached == null) {
          source = 'local';
        }
      }
    }

    final selected = _pickRecord(candidateRecords, date);
    if (selected == null || selected.adjustmentDays == 0) {
      final unadjustedSource = source == 'remote_adjusted'
          ? 'remote_noop'
          : source;
      return HijriDate(
        year: base.year,
        month: base.month,
        day: base.day,
        meta: HijriResultMeta(
          source: unadjustedSource,
          isAdjusted: false,
          adjustmentDays: 0,
        ),
      );
    }

    return _buildAdjusted(date, selected, source: source);
  }

  Future<List<HijriDate>> fromGregorianRangeAsync({
    required DateTime from,
    required DateTime to,
  }) async {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      throw ArgumentError.value(to, 'to', 'must be on or after from');
    }

    if (allowLegacyAdjustments) {
      await _prefetchRange(start: start, end: end);

      final legacyResults = <HijriDate>[];
      for (
        var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        legacyResults.add(await _fromGregorianAsync(day, allowRemote: false));
      }
      _validateOfficialContinuity(legacyResults, start: start);
      return legacyResults;
    }

    final cached = _resolveRangeFromCache(start: start, end: end);
    final needsRefresh =
        _rangeNeedsRefresh(start: start, end: end) || cached == null;
    if (needsRefresh) _scheduleRangeRefresh(start: start, end: end);
    return cached ?? _localFallbackRange(start: start, end: end);
  }

  /// Fetches a range now and returns a coherent refreshed range where possible.
  /// If the server is unavailable or cache coverage is incomplete, the result
  /// is a whole-range local provisional fallback.
  Future<List<HijriDate>> refreshOfficialRangeAsync({
    required DateTime from,
    required DateTime to,
  }) async {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    if (end.isBefore(start)) {
      throw ArgumentError.value(to, 'to', 'must be on or after from');
    }
    await _singleFlight(
      _rangeRefreshKey(start, end),
      () => _refreshRange(start: start, end: end),
    );
    return _resolveRangeFromCache(start: start, end: end) ??
        _localFallbackRange(start: start, end: end);
  }

  HijriDate? _resolveCachedAnchor(DateTime date) {
    final cached = anchorCache.get(date);
    if (cached == null || cached.records.isEmpty) return null;
    final resolved = _anchorResolver.resolve(
      date: date,
      records: cached.records,
      authority: authority,
      regionScope: regionScope,
    );
    if (resolved == null) return null;
    return _withCacheSource(resolved);
  }

  HijriDate _withCacheSource(HijriDate value) => HijriDate(
    year: value.year,
    month: value.month,
    day: value.day,
    meta: HijriResultMeta(
      source: value.meta.isProvisional
          ? 'cache_anchor_provisional'
          : 'cache_anchor',
      isAdjusted: false,
      adjustmentDays: value.meta.adjustmentDays,
      isProvisional: value.meta.isProvisional,
      anchorDate: value.meta.anchorDate,
      nextAnchorDate: value.meta.nextAnchorDate,
      authority: value.meta.authority,
      revision: value.meta.revision,
      validationStatus: value.meta.validationStatus,
    ),
  );

  HijriDate _localFallback(DateTime date) {
    final base = baseProvider.fromGregorian(
      date,
      method: HijriMethod.calculatedLocal,
    );
    return HijriDate(
      year: base.year,
      month: base.month,
      day: base.day,
      meta: const HijriResultMeta(
        source: 'local_fallback',
        isProvisional: true,
        validationStatus: 'provisional',
      ),
    );
  }

  List<HijriDate> _localFallbackRange({
    required DateTime start,
    required DateTime end,
  }) {
    final values = <HijriDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      values.add(_localFallback(day));
    }
    return values;
  }

  List<HijriDate>? _resolveRangeFromCache({
    required DateTime start,
    required DateTime end,
  }) {
    final results = <HijriDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final value = _resolveCachedAnchor(day);
      if (value == null) return null;
      results.add(value);
    }
    if (!_isContinuous(results)) return null;
    return results;
  }

  bool _rangeNeedsRefresh({required DateTime start, required DateTime end}) {
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final entry = anchorCache.get(day);
      if (entry == null || !entry.isFresh) return true;
    }
    return false;
  }

  bool _isContinuous(List<HijriDate> results) {
    for (var i = 1; i < results.length; i++) {
      final previous = results[i - 1];
      final current = results[i];
      final sameMonth =
          previous.year == current.year &&
          previous.month == current.month &&
          current.day == previous.day + 1;
      final monthBoundary =
          previous.day >= 29 &&
          current.day == 1 &&
          (current.month == previous.month + 1 ||
              (previous.month == 12 && current.month == 1));
      if (!sameMonth && !monthBoundary) return false;
    }
    return true;
  }

  void _scheduleDateRefresh(DateTime date) {
    unawaited(
      _singleFlight(
        _dateRefreshKey(date),
        () => _refreshDate(date),
      ).catchError((Object _) {}),
    );
  }

  void _scheduleRangeRefresh({required DateTime start, required DateTime end}) {
    unawaited(
      _singleFlight(
        _rangeRefreshKey(start, end),
        () => _refreshRange(start: start, end: end),
      ).catchError((Object _) {}),
    );
  }

  Future<void> _singleFlight(String key, Future<void> Function() action) {
    return _refreshFlights.putIfAbsent(key, () async {
      try {
        await action();
      } finally {
        _refreshFlights.remove(key);
      }
    });
  }

  String _dateRefreshKey(DateTime date) =>
      'date:${_isoDate(date)}:$authority:$regionScope';

  String _rangeRefreshKey(DateTime start, DateTime end) =>
      'range:${_isoDate(start.subtract(const Duration(days: 35)))}:'
      '${_isoDate(end)}:$authority:$regionScope';

  String _rangeEtagKey(DateTime start, DateTime end, {DateTime? queryStart}) =>
      'anchors:${_isoDate(queryStart ?? start.subtract(const Duration(days: 35)))}:'
      '${_isoDate(end)}:$authority:$regionScope';

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Future<void> _refreshDate(DateTime date) async {
    // Cache a small window around a single-date request so nearby Home,
    // schedule, and calendar lookups can all reuse the same persistent data.
    final start = date.subtract(const Duration(days: 35));
    final end = date.add(const Duration(days: 35));
    await _refreshRange(start: start, end: end, queryStart: start);
  }

  Future<void> _refreshRange({
    required DateTime start,
    required DateTime end,
    DateTime? queryStart,
  }) async {
    final queryFrom = queryStart ?? start.subtract(const Duration(days: 35));
    var etagKey = _rangeEtagKey(start, end, queryStart: queryFrom);
    final cached = anchorCache.get(start);
    final remote = await adjustmentClient.fetchAnchorsRange(
      from: queryFrom,
      to: end,
      etag: cached?.etagKey == etagKey ? cached?.etag : null,
    );
    List<HijriAnchorRecord> records;
    String? responseEtag;
    if (remote.statusCode == 200) {
      records = remote.records;
      responseEtag = remote.etag;
    } else if (remote.statusCode == 304 &&
        cached != null &&
        cached.etagKey == etagKey) {
      records = cached.records;
      responseEtag = remote.etag ?? cached.etag;
    } else {
      return;
    }

    if (records.isEmpty && remote.statusCode == 200) {
      final latestKey = 'anchors:latest:$authority:$regionScope';
      final latestCached = anchorCache.get(start);
      final latest = await adjustmentClient.fetchLatestAnchors(
        etag: latestCached?.etagKey == latestKey ? latestCached?.etag : null,
      );
      if (latest.statusCode == 200 && latest.records.isNotEmpty) {
        records = latest.records;
        responseEtag = latest.etag;
        etagKey = latestKey;
      } else if (latest.statusCode == 304 && latestCached != null) {
        _touchRange(start, end, latestCached, latestKey, latest.etag);
        return;
      } else {
        return;
      }
    }
    if (records.isEmpty) return;

    final resolvedRange = <HijriDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final resolved = _anchorResolver.resolve(
        date: day,
        records: records,
        authority: authority,
        regionScope: regionScope,
      );
      if (resolved == null) {
        throw StateError(
          'Official anchor response does not cover the full range '
          '${_isoDate(start)}..${_isoDate(end)}.',
        );
      }
      resolvedRange.add(resolved);
    }
    if (!_isContinuous(resolvedRange)) {
      throw StateError(
        'Official anchor response is not continuous for range '
        '${_isoDate(start)}..${_isoDate(end)}.',
      );
    }

    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      _putAnchorRecords(day, records, etag: responseEtag, etagKey: etagKey);
    }
  }

  void _putAnchorRecords(
    DateTime date,
    List<HijriAnchorRecord> records, {
    String? etag,
    required String etagKey,
  }) {
    final existing = anchorCache.get(date);
    final merged = <String, HijriAnchorRecord>{};
    for (final record in [...?existing?.records, ...records]) {
      final key =
          '${record.authority}|${record.regionScope}|'
          '${_isoDate(record.officialGregorianDate)}';
      final previous = merged[key];
      if (previous == null ||
          record.revision > previous.revision ||
          (record.revision == previous.revision &&
              record.publishedAt.isAfter(previous.publishedAt))) {
        merged[key] = record;
      }
    }
    anchorCache.put(
      date,
      AnchorCacheEntry(
        records: merged.values.toList(),
        etag: etag,
        etagKey: etagKey,
        cachedAt: DateTime.now().toUtc(),
        ttl: cacheTtl,
      ),
    );
  }

  void _touchEntry(
    DateTime date,
    AnchorCacheEntry entry, {
    required String etagKey,
    String? etag,
  }) {
    anchorCache.put(
      date,
      AnchorCacheEntry(
        records: entry.records,
        etag: etag ?? entry.etag,
        etagKey: etagKey,
        cachedAt: DateTime.now().toUtc(),
        ttl: cacheTtl,
      ),
    );
  }

  void _touchRange(
    DateTime start,
    DateTime end,
    AnchorCacheEntry entry,
    String etagKey,
    String? etag,
  ) {
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      _touchEntry(day, entry, etagKey: etagKey, etag: etag);
    }
  }

  void _validateOfficialContinuity(
    List<HijriDate> results, {
    required DateTime start,
  }) {
    for (var i = 1; i < results.length; i++) {
      final previous = results[i - 1];
      final current = results[i];
      final sameMonth =
          previous.year == current.year &&
          previous.month == current.month &&
          current.day == previous.day + 1;
      final monthBoundary =
          previous.day >= 29 &&
          current.day == 1 &&
          (current.month == previous.month + 1 ||
              (previous.month == 12 && current.month == 1));
      if (!sameMonth && !monthBoundary) {
        final previousDate = start.add(Duration(days: i - 1));
        final currentDate = start.add(Duration(days: i));
        throw StateError(
          'Official Hijri range is incomplete or inconsistent: '
          '${previousDate.toIso8601String().split('T').first} '
          '${previous.year}-${previous.month}-${previous.day} '
          '(${previous.meta.source}) -> '
          '${currentDate.toIso8601String().split('T').first} '
          '${current.year}-${current.month}-${current.day} '
          '(${current.meta.source}). '
          'Verify active anchor revisions and the Gregorian/Hijri boundary '
          'before resolving this range.',
        );
      }
    }
  }

  Future<void> _prefetchRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now().toUtc();
    // Include the preceding possible month boundary. Without this lookback,
    // a range that starts in the middle of a Hijri month has no prior anchor;
    // the resolver then falls back locally and can duplicate the next official
    // month-start anchor (for example, 1 Ramadan on two Gregorian dates).
    final anchorQueryStart = start.subtract(const Duration(days: 35));

    // ── Anchor prefetch ───────────────────────────────────────────────────────
    // Always perform a conditional anchor request for a range. This allows a
    // newly published revision to invalidate fresh-looking provisional cache
    // entries immediately; an unchanged dataset is still a cheap 304.
    try {
      // Entries are stored by requested range day, so use [start] rather
      // than [anchorQueryStart] to retrieve the cached ETag.
      final existingAnchorEntry = anchorCache.get(start);
      List<HijriAnchorRecord> anchorRecords = const [];
      String? anchorEtag;
      final remoteAnchors = await adjustmentClient.fetchAnchorsRange(
        from: anchorQueryStart,
        to: end,
        etag: existingAnchorEntry?.etag,
      );
      if (remoteAnchors.statusCode == 200) {
        anchorRecords = remoteAnchors.records;
        anchorEtag = remoteAnchors.etag;
      } else if (remoteAnchors.statusCode == 304 &&
          existingAnchorEntry != null) {
        // Server confirmed data unchanged — refresh TTL without re-fetching.
        anchorRecords = existingAnchorEntry.records;
        anchorEtag = existingAnchorEntry.etag;
      }

      // If range endpoint returns empty, use latest once. The resolver still
      // rejects a latest anchor that is in the future for the target date.
      if (anchorRecords.isEmpty) {
        final latest = await adjustmentClient.fetchLatestAnchors(
          etag: anchorEtag,
        );
        if (latest.statusCode == 200 && latest.records.isNotEmpty) {
          anchorRecords = latest.records;
          anchorEtag = latest.etag ?? anchorEtag;
        }
      }

      if (anchorRecords.isNotEmpty) {
        for (
          var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))
        ) {
          anchorCache.put(
            day,
            AnchorCacheEntry(
              records: anchorRecords,
              etag: anchorEtag,
              cachedAt: now,
              ttl: cacheTtl,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback to the existing cache/per-day flow in fromGregorianAsync.
    }

    // ── Legacy adjustment prefetch ─────────────────────────────────────────────
    final adjustmentMissing = _anyDayMissingAdjustment(start: start, end: end);
    if (allowLegacyAdjustments && adjustmentMissing) {
      try {
        final existingAdjEntry = adjustmentCache.get(start);
        final remoteAdjustments = await adjustmentClient.fetchRange(
          from: start,
          to: end,
          etag: existingAdjEntry?.etag,
        );
        if (remoteAdjustments.statusCode == 200) {
          for (
            var day = start;
            !day.isAfter(end);
            day = day.add(const Duration(days: 1))
          ) {
            adjustmentCache.put(
              day,
              AdjustmentCacheEntry(
                records: remoteAdjustments.records,
                etag: remoteAdjustments.etag,
                cachedAt: now,
                ttl: cacheTtl,
              ),
            );
          }
        } else if (remoteAdjustments.statusCode == 304 &&
            existingAdjEntry != null) {
          // Refresh TTL for all days using cached data.
          for (
            var day = start;
            !day.isAfter(end);
            day = day.add(const Duration(days: 1))
          ) {
            adjustmentCache.put(
              day,
              AdjustmentCacheEntry(
                records: existingAdjEntry.records,
                etag: existingAdjEntry.etag,
                cachedAt: now,
                ttl: cacheTtl,
              ),
            );
          }
        }
      } catch (_) {
        // Fallback to per-day flow in fromGregorianAsync.
      }
    }
  }

  /// Returns true if any day in [start]..[end] has no fresh adjustment cache entry.
  bool _anyDayMissingAdjustment({
    required DateTime start,
    required DateTime end,
  }) {
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final entry = adjustmentCache.get(day);
      if (entry == null || !entry.isFresh) return true;
    }
    return false;
  }

  Future<HijriDate?> _resolveFromAnchor(
    DateTime date, {
    required bool allowRemote,
  }) async {
    final cachedAnchor = anchorCache.get(date);
    if (cachedAnchor != null && cachedAnchor.isFresh) {
      final resolved = _anchorResolver.resolve(
        date: date,
        records: cachedAnchor.records,
        authority: authority,
        regionScope: regionScope,
      );
      if (resolved != null) {
        return HijriDate(
          year: resolved.year,
          month: resolved.month,
          day: resolved.day,
          meta: HijriResultMeta(
            source: resolved.meta.isProvisional
                ? 'cache_anchor_provisional'
                : 'cache_anchor',
            isAdjusted: false,
            adjustmentDays: resolved.meta.adjustmentDays,
            isProvisional: resolved.meta.isProvisional,
            anchorDate: resolved.meta.anchorDate,
            nextAnchorDate: resolved.meta.nextAnchorDate,
            authority: resolved.meta.authority,
            revision: resolved.meta.revision,
            validationStatus: resolved.meta.validationStatus,
          ),
        );
      }
    }

    if (!allowRemote) return null;

    try {
      final remote = await adjustmentClient.fetchAnchorsByDate(
        date: date,
        etag: cachedAnchor?.etag,
      );
      if (remote.statusCode == 200) {
        // Only cache non-empty records to avoid storing a miss that would
        // prevent fetchLatestAnchors fallback from caching its own result.
        if (remote.records.isNotEmpty) {
          anchorCache.put(
            date,
            AnchorCacheEntry(
              records: remote.records,
              etag: remote.etag,
              cachedAt: DateTime.now().toUtc(),
              ttl: cacheTtl,
            ),
          );
        }
        final resolved = _anchorResolver.resolve(
          date: date,
          records: remote.records,
          authority: authority,
          regionScope: regionScope,
        );
        if (resolved != null) {
          return HijriDate(
            year: resolved.year,
            month: resolved.month,
            day: resolved.day,
            meta: HijriResultMeta(
              source: resolved.meta.isProvisional
                  ? 'remote_anchor_provisional'
                  : 'remote_anchor',
              isAdjusted: false,
              adjustmentDays: resolved.meta.adjustmentDays,
              isProvisional: resolved.meta.isProvisional,
              anchorDate: resolved.meta.anchorDate,
              nextAnchorDate: resolved.meta.nextAnchorDate,
              authority: resolved.meta.authority,
              revision: resolved.meta.revision,
              validationStatus: resolved.meta.validationStatus,
            ),
          );
        }

        // fetchAnchorsByDate returned no matching records for this date
        // (e.g. no anchor exactly on this date). Look back far enough to find
        // the preceding month boundary before considering the latest set.
        final historical = await adjustmentClient.fetchAnchorsRange(
          from: date.subtract(const Duration(days: 35)),
          to: date,
          etag: remote.etag,
        );
        if (historical.statusCode == 200 && historical.records.isNotEmpty) {
          anchorCache.put(
            date,
            AnchorCacheEntry(
              records: historical.records,
              etag: historical.etag ?? remote.etag,
              cachedAt: DateTime.now().toUtc(),
              ttl: cacheTtl,
            ),
          );
          final historicalResolved = _anchorResolver.resolve(
            date: date,
            records: historical.records,
            authority: authority,
            regionScope: regionScope,
          );
          if (historicalResolved != null) {
            return HijriDate(
              year: historicalResolved.year,
              month: historicalResolved.month,
              day: historicalResolved.day,
              meta: HijriResultMeta(
                source: historicalResolved.meta.isProvisional
                    ? 'remote_anchor_provisional'
                    : 'remote_anchor',
                isAdjusted: false,
                adjustmentDays: historicalResolved.meta.adjustmentDays,
                isProvisional: historicalResolved.meta.isProvisional,
                anchorDate: historicalResolved.meta.anchorDate,
                nextAnchorDate: historicalResolved.meta.nextAnchorDate,
                authority: historicalResolved.meta.authority,
                revision: historicalResolved.meta.revision,
                validationStatus: historicalResolved.meta.validationStatus,
              ),
            );
          }
        }

        // No historical anchor was found — fall back to latest anchors.
        // Use remote.etag as the conditional ETag so the server can respond
        // with 304 if the latest data is unchanged since the previous fetch.
        final latest = await adjustmentClient.fetchLatestAnchors(
          etag: remote.etag,
        );
        if (latest.statusCode == 200 && latest.records.isNotEmpty) {
          // Persist the response for this queried calendar date. The resolver
          // still filters the record set by target date.
          anchorCache.put(
            date,
            AnchorCacheEntry(
              records: latest.records,
              etag: latest.etag ?? remote.etag,
              cachedAt: DateTime.now().toUtc(),
              ttl: cacheTtl,
            ),
          );
          final latestResolved = _anchorResolver.resolve(
            date: date,
            records: latest.records,
            authority: authority,
            regionScope: regionScope,
          );
          if (latestResolved != null) {
            return HijriDate(
              year: latestResolved.year,
              month: latestResolved.month,
              day: latestResolved.day,
              meta: HijriResultMeta(
                source: latestResolved.meta.isProvisional
                    ? 'remote_anchor_provisional'
                    : 'remote_anchor',
                isAdjusted: false,
                adjustmentDays: latestResolved.meta.adjustmentDays,
                isProvisional: latestResolved.meta.isProvisional,
                anchorDate: latestResolved.meta.anchorDate,
                nextAnchorDate: latestResolved.meta.nextAnchorDate,
                authority: latestResolved.meta.authority,
                revision: latestResolved.meta.revision,
                validationStatus: latestResolved.meta.validationStatus,
              ),
            );
          }
        }
      }

      if (remote.statusCode == 304 && cachedAnchor != null) {
        final resolved = _anchorResolver.resolve(
          date: date,
          records: cachedAnchor.records,
          authority: authority,
          regionScope: regionScope,
        );
        if (resolved != null) {
          return HijriDate(
            year: resolved.year,
            month: resolved.month,
            day: resolved.day,
            meta: HijriResultMeta(
              source: resolved.meta.isProvisional
                  ? 'cache_anchor_provisional'
                  : 'cache_anchor',
              isAdjusted: false,
              adjustmentDays: resolved.meta.adjustmentDays,
              isProvisional: resolved.meta.isProvisional,
              anchorDate: resolved.meta.anchorDate,
              nextAnchorDate: resolved.meta.nextAnchorDate,
              authority: resolved.meta.authority,
              revision: resolved.meta.revision,
              validationStatus: resolved.meta.validationStatus,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback to delta/local flow.
    }
    return null;
  }

  AdjustmentRecord? _pickRecord(List<AdjustmentRecord> records, DateTime date) {
    final matches = records
        .where(
          (r) =>
              r.appliesTo(date) &&
              r.authority == authority &&
              r.regionScope == regionScope,
        )
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final byRevision = b.revision.compareTo(a.revision);
      if (byRevision != 0) return byRevision;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return matches.first;
  }

  HijriDate _buildAdjusted(
    DateTime date,
    AdjustmentRecord selected, {
    required String source,
  }) {
    final shiftedDate = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: selected.adjustmentDays));
    final adjusted = baseProvider.fromGregorian(
      shiftedDate,
      method: HijriMethod.calculatedLocal,
    );

    return HijriDate(
      year: adjusted.year,
      month: adjusted.month,
      day: adjusted.day,
      meta: HijriResultMeta(
        source: source,
        isAdjusted: true,
        adjustmentDays: selected.adjustmentDays,
        authority: selected.authority,
        revision: selected.revision,
      ),
    );
  }
}
