import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_client.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/hijri_calendar.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_javanese/javanese_calendar.dart';
import 'package:islamic_utility/src/calendar_unified/models/calendar_resolve_options.dart';
import 'package:islamic_utility/src/calendar_unified/models/unified_calendar_date.dart';

class UnifiedCalendar {
  UnifiedCalendar()
    : _hijri = HijriCalendar(),
      _javanese = const JavaneseCalendar();

  UnifiedCalendar.withOfficialHijri({
    required HijriAdjustmentClient adjustmentClient,
    HijriAdjustmentCache? cache,
    HijriAnchorCache? anchorCache,
    String authority = 'kemenag_ri',
    String regionScope = 'national',
    Duration cacheTtl = const Duration(hours: 24),
  }) : _hijri = HijriCalendar.withOfficial(
         adjustmentClient: adjustmentClient,
         cache: cache,
         anchorCache: anchorCache,
         authority: authority,
         regionScope: regionScope,
         cacheTtl: cacheTtl,
       ),
       _javanese = const JavaneseCalendar();

  final HijriCalendar _hijri;
  final JavaneseCalendar _javanese;

  Future<UnifiedCalendarDate> resolve(
    DateTime date, {
    CalendarResolveOptions options = const CalendarResolveOptions(),
  }) async {
    final day = DateTime.utc(date.year, date.month, date.day);
    final hijri = await _resolveHijri(day, options);
    final javanese = options.includeJavanese
        ? _javanese.fromGregorian(day)
        : null;

    return UnifiedCalendarDate(
      gregorian: day,
      hijri: hijri,
      javanese: javanese,
    );
  }

  Future<List<UnifiedCalendarDate>> resolveRange({
    required DateTime from,
    required DateTime to,
    CalendarResolveOptions options = const CalendarResolveOptions(),
  }) async {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      throw ArgumentError.value(to, 'to', 'must be on or after from');
    }

    final days = <DateTime>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(day);
    }

    List<HijriDate?> hijriResults = List<HijriDate?>.filled(days.length, null);
    if (options.includeHijri) {
      if (options.hijriMethod == HijriMethod.kemenagRiOfficial) {
        final official = await _hijri.fromGregorianOfficialRange(
          from: start,
          to: end,
        );
        hijriResults = official;
      } else {
        hijriResults = days
            .map(
              (day) => _hijri.fromGregorian(day, method: options.hijriMethod),
            )
            .toList();
      }
    }

    final results = <UnifiedCalendarDate>[];
    for (var i = 0; i < days.length; i++) {
      results.add(
        UnifiedCalendarDate(
          gregorian: days[i],
          hijri: hijriResults[i],
          javanese: options.includeJavanese
              ? _javanese.fromGregorian(days[i])
              : null,
        ),
      );
    }
    return results;
  }

  Future<HijriDate?> _resolveHijri(
    DateTime day,
    CalendarResolveOptions options,
  ) async {
    if (!options.includeHijri) return null;
    if (options.hijriMethod == HijriMethod.kemenagRiOfficial) {
      return _hijri.fromGregorianOfficial(day);
    }
    return _hijri.fromGregorian(day, method: options.hijriMethod);
  }
}
