import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/hijri_provider.dart';

class KemenagOfficialHijriProvider implements HijriProvider {
  KemenagOfficialHijriProvider({
    required this.baseProvider,
    required this.adjustmentClient,
    required this.adjustmentCache,
    this.authority = 'kemenag_ri',
    this.regionScope = 'national',
    this.cacheTtl = const Duration(hours: 24),
  });

  final HijriProvider baseProvider;
  final HijriAdjustmentClient adjustmentClient;
  final HijriAdjustmentCache adjustmentCache;
  final String authority;
  final String regionScope;
  final Duration cacheTtl;

  @override
  bool supports(HijriMethod method) => method == HijriMethod.kemenagRiOfficial;

  @override
  HijriDate fromGregorian(DateTime date, {required HijriMethod method}) {
    throw UnsupportedError('Use fromGregorianAsync for official provider');
  }

  Future<HijriDate> fromGregorianAsync(DateTime date) async {
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

    final selected = _pickRecord(candidateRecords, date);
    if (selected == null || selected.adjustmentDays == 0) {
      return HijriDate(
        year: base.year,
        month: base.month,
        day: base.day,
        meta: HijriResultMeta(
          source: source == 'local' ? 'local' : source,
          isAdjusted: false,
          adjustmentDays: 0,
        ),
      );
    }

    return _buildAdjusted(date, selected, source: source);
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
