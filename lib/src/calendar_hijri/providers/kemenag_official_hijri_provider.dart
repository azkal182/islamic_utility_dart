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

  @override
  bool supports(HijriMethod method) => method == HijriMethod.kemenagRiOfficial;

  @override
  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    throw UnsupportedError('Use fromGregorianAsync for official provider');
  }

  Future<HijriDate> fromGregorianAsync(DateTime date) async {
    return _fromGregorianAsync(date, allowRemote: true);
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

    await _prefetchRange(start: start, end: end);

    final results = <HijriDate>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      results.add(await _fromGregorianAsync(day, allowRemote: false));
    }
    _validateOfficialContinuity(results, start: start);
    return results;
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
          'Publish/fetch the preceding Hijri anchor before resolving this range.',
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
    // Check if every day in the range already has a fresh anchor cache entry.
    // With the month-based key, a single cached entry covers the whole month,
    // so this check is O(days) but nearly always a single Hive lookup.
    final anchorMissing = _anyDayMissingAnchor(start: start, end: end);
    if (anchorMissing) {
      try {
        // Use the existing ETag (if any) for a conditional request so the
        // server can respond 304 when data is unchanged.
        final existingAnchorEntry = anchorCache.get(anchorQueryStart);
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
        // Fallback to per-day flow in fromGregorianAsync.
      }
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

  /// Returns true if any day in [start]..[end] has no fresh anchor cache entry.
  bool _anyDayMissingAnchor({required DateTime start, required DateTime end}) {
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
            source: resolved.meta.source == 'anchor_provisional'
                ? 'cache_anchor_provisional'
                : 'cache_anchor',
            isAdjusted: false,
            adjustmentDays: resolved.meta.adjustmentDays,
            isProvisional: resolved.meta.isProvisional,
            anchorDate: resolved.meta.anchorDate,
            nextAnchorDate: resolved.meta.nextAnchorDate,
            authority: resolved.meta.authority,
            revision: resolved.meta.revision,
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
              source: resolved.meta.source == 'anchor_provisional'
                  ? 'remote_anchor_provisional'
                  : 'remote_anchor',
              isAdjusted: false,
              adjustmentDays: resolved.meta.adjustmentDays,
              isProvisional: resolved.meta.isProvisional,
              anchorDate: resolved.meta.anchorDate,
              nextAnchorDate: resolved.meta.nextAnchorDate,
              authority: resolved.meta.authority,
              revision: resolved.meta.revision,
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
                source: historicalResolved.meta.source == 'anchor_provisional'
                    ? 'remote_anchor_provisional'
                    : 'remote_anchor',
                isAdjusted: false,
                adjustmentDays: historicalResolved.meta.adjustmentDays,
                isProvisional: historicalResolved.meta.isProvisional,
                anchorDate: historicalResolved.meta.anchorDate,
                nextAnchorDate: historicalResolved.meta.nextAnchorDate,
                authority: historicalResolved.meta.authority,
                revision: historicalResolved.meta.revision,
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
                source: latestResolved.meta.source == 'anchor_provisional'
                    ? 'remote_anchor_provisional'
                    : 'remote_anchor',
                isAdjusted: false,
                adjustmentDays: latestResolved.meta.adjustmentDays,
                isProvisional: latestResolved.meta.isProvisional,
                anchorDate: latestResolved.meta.anchorDate,
                nextAnchorDate: latestResolved.meta.nextAnchorDate,
                authority: latestResolved.meta.authority,
                revision: latestResolved.meta.revision,
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
              source: resolved.meta.source == 'anchor_provisional'
                  ? 'cache_anchor_provisional'
                  : 'cache_anchor',
              isAdjusted: false,
              adjustmentDays: resolved.meta.adjustmentDays,
              isProvisional: resolved.meta.isProvisional,
              anchorDate: resolved.meta.anchorDate,
              nextAnchorDate: resolved.meta.nextAnchorDate,
              authority: resolved.meta.authority,
              revision: resolved.meta.revision,
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
