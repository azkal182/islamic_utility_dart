import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/kemenag_official_hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/local_hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/umm_al_qura_provider.dart';

class HijriCalendar {
  HijriCalendar()
    : _local = LocalHijriProvider(),
      _ummAlQura = UmmAlQuraProvider(),
      _official = null;

  HijriCalendar.withOfficial({
    required HijriAdjustmentClient adjustmentClient,
    HijriAdjustmentCache? cache,
    HijriAnchorCache? anchorCache,
    String authority = 'kemenag_ri',
    String regionScope = 'national',
    Duration cacheTtl = const Duration(hours: 24),
    bool allowLegacyAdjustments = false,
  }) : _local = LocalHijriProvider(),
       _ummAlQura = UmmAlQuraProvider(),
       _official = KemenagOfficialHijriProvider(
         baseProvider: LocalHijriProvider(),
         adjustmentClient: adjustmentClient,
         adjustmentCache: cache ?? InMemoryHijriAdjustmentCache(),
         anchorCache: anchorCache,
         authority: authority,
         regionScope: regionScope,
         cacheTtl: cacheTtl,
         allowLegacyAdjustments: allowLegacyAdjustments,
       );

  final LocalHijriProvider _local;
  final UmmAlQuraProvider _ummAlQura;
  final KemenagOfficialHijriProvider? _official;

  HijriDate fromGregorian(
    DateTime date, {
    HijriMethod method = HijriMethod.calculatedLocal,
  }) {
    switch (method) {
      case HijriMethod.calculatedLocal:
        return _local.fromGregorian(date, method: method);
      case HijriMethod.ummAlQura:
        return _ummAlQura.fromGregorian(date, method: method);
      case HijriMethod.kemenagRiOfficial:
        throw StateError(
          'Use fromGregorianOfficial(...) for kemenagRiOfficial method',
        );
    }
  }

  Future<HijriDate> fromGregorianOfficial(DateTime date) async {
    if (_official == null) {
      throw StateError(
        'HijriCalendar.withOfficial(...) is required for official method',
      );
    }
    return _official.fromGregorianAsync(date);
  }

  /// Forces an official-data refresh and returns the best result afterward.
  /// A cache-first lookup already refreshes stale/missing data in background;
  /// use this method when the caller wants to await that refresh explicitly.
  Future<HijriDate> refreshGregorianOfficial(DateTime date) async {
    if (_official == null) {
      throw StateError(
        'HijriCalendar.withOfficial(...) is required for official method',
      );
    }
    return _official.refreshOfficialAsync(date);
  }

  Future<List<HijriDate>> fromGregorianOfficialRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_official == null) {
      throw StateError(
        'HijriCalendar.withOfficial(...) is required for official method',
      );
    }
    return _official.fromGregorianRangeAsync(from: from, to: to);
  }

  /// Forces an official range refresh and returns the best coherent range
  /// afterward. Normal range lookups remain cache-first and do not wait for
  /// the network.
  Future<List<HijriDate>> refreshGregorianOfficialRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (_official == null) {
      throw StateError(
        'HijriCalendar.withOfficial(...) is required for official method',
      );
    }
    return _official.refreshOfficialRangeAsync(from: from, to: to);
  }
}
