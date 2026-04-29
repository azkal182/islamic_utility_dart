import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/resolver/anchor_resolver.dart';

class KemenagOfficialHijriProvider implements HijriProvider {
  KemenagOfficialHijriProvider({
    required this.baseProvider,
    required this.adjustmentClient,
    required this.adjustmentCache,
    HijriAnchorCache? anchorCache,
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
    this.cacheTtl = const Duration(hours: 24),
  }) : anchorCache = anchorCache ?? InMemoryHijriAnchorCache();

  final HijriProvider baseProvider;
  final HijriAdjustmentClient adjustmentClient;
  final HijriAdjustmentCache adjustmentCache;
  final HijriAnchorCache anchorCache;
  final String authority;
  final String regionScope;
  final Duration cacheTtl;
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
    return results;
  }

  Future<void> _prefetchRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now().toUtc();
    try {
      final remoteAnchors = await adjustmentClient.fetchAnchorsRange(
        from: start,
        to: end,
      );
      if (remoteAnchors.statusCode == 200) {
        for (
          var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))
        ) {
          anchorCache.put(
            day,
            AnchorCacheEntry(
              records: remoteAnchors.records,
              etag: remoteAnchors.etag,
              cachedAt: now,
              ttl: cacheTtl,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback to per-day flow in fromGregorianAsync.
    }

    try {
      final remoteAdjustments = await adjustmentClient.fetchRange(
        from: start,
        to: end,
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
      }
    } catch (_) {
      // Fallback to per-day flow in fromGregorianAsync.
    }
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
            source: 'cache_anchor_adjusted',
            isAdjusted: true,
            adjustmentDays: resolved.meta.adjustmentDays,
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
        anchorCache.put(
          date,
          AnchorCacheEntry(
            records: remote.records,
            etag: remote.etag,
            cachedAt: DateTime.now().toUtc(),
            ttl: cacheTtl,
          ),
        );
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
              source: 'remote_anchor_adjusted',
              isAdjusted: true,
              adjustmentDays: resolved.meta.adjustmentDays,
              authority: resolved.meta.authority,
              revision: resolved.meta.revision,
            ),
          );
        }

        final latest = await adjustmentClient.fetchLatestAnchors(
          etag: cachedAnchor?.etag,
        );
        if (latest.statusCode == 200) {
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
                source: 'remote_anchor_adjusted',
                isAdjusted: true,
                adjustmentDays: latestResolved.meta.adjustmentDays,
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
              source: 'cache_anchor_adjusted',
              isAdjusted: true,
              adjustmentDays: resolved.meta.adjustmentDays,
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
