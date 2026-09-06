import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_date.dart';
import 'package:islamic_utility/src/calendar_hijri/models/hijri_result_meta.dart';

class AnchorResolver {
  const AnchorResolver();

  HijriDate? resolve({
    required DateTime date,
    required List<HijriAnchorRecord> records,
    required String authority,
    required String regionScope,
  }) {
    if (records.isEmpty) return null;
    final dayDate = DateTime.utc(date.year, date.month, date.day);
    final selected = _pickBest(
      records,
      date: dayDate,
      authority: authority,
      regionScope: regionScope,
    );
    if (selected == null) return null;

    final anchorDate = DateTime.utc(
      selected.officialGregorianDate.year,
      selected.officialGregorianDate.month,
      selected.officialGregorianDate.day,
    );
    final dayOffset = dayDate.difference(anchorDate).inDays;

    final next = _nextAnchor(
      records,
      after: selected,
      authority: authority,
      regionScope: regionScope,
    );
    final monthLength = next == null
        ? null
        : DateTime.utc(
            next.officialGregorianDate.year,
            next.officialGregorianDate.month,
            next.officialGregorianDate.day,
          ).difference(anchorDate).inDays;

    final nextDate = next == null
        ? null
        : _dateOnly(next.officialGregorianDate);

    // A missing following anchor is not an error. Continue from the last
    // official anchor using the same civil month pattern as the local
    // provider, but make the result explicitly provisional.
    if (monthLength == null || monthLength < 29 || monthLength > 30) {
      final inferred = _resolveFromLocalPattern(
        date: dayDate,
        anchorDate: anchorDate,
        anchor: selected,
        nextAnchor: next,
      );
      if (inferred == null) return null;

      final projectedNext = next == null
          ? null
          : _resolveFromLocalPattern(
              date: nextDate!,
              anchorDate: anchorDate,
              anchor: selected,
            );
      final validated =
          next != null &&
          projectedNext != null &&
          _matchesAnchor(projectedNext, next);

      var reconciled = inferred;
      if (next != null && _compareHijri(inferred, next) >= 0) {
        final previous = _previousCivilDay(next);
        reconciled = HijriDate(
          year: previous.$1,
          month: previous.$2,
          day: previous.$3,
          meta: inferred.meta,
        );
      }

      return _buildResult(
        reconciled,
        selected: selected,
        anchorDate: anchorDate,
        nextDate: nextDate,
        validationStatus: validated ? 'inferred_validated' : 'provisional',
      );
    }

    final day = selected.hijriDay + dayOffset;
    if (day < 1 || day > 30) return null;

    return HijriDate(
      year: selected.hijriYear,
      month: selected.hijriMonth,
      day: day,
      meta: HijriResultMeta(
        source: 'anchor_resolved',
        isAdjusted: false,
        adjustmentDays: 0,
        isProvisional: false,
        anchorDate: anchorDate,
        nextAnchorDate: nextDate,
        authority: selected.authority,
        revision: selected.revision,
        validationStatus: 'official',
      ),
    );
  }

  bool _matchesAnchor(HijriDate value, HijriAnchorRecord anchor) {
    return value.year == anchor.hijriYear &&
        value.month == anchor.hijriMonth &&
        value.day == anchor.hijriDay;
  }

  int _compareHijri(HijriDate value, HijriAnchorRecord anchor) {
    if (value.year != anchor.hijriYear) {
      return value.year.compareTo(anchor.hijriYear);
    }
    if (value.month != anchor.hijriMonth) {
      return value.month.compareTo(anchor.hijriMonth);
    }
    return value.day.compareTo(anchor.hijriDay);
  }

  (int, int, int) _previousCivilDay(HijriAnchorRecord anchor) {
    var year = anchor.hijriYear;
    var month = anchor.hijriMonth;
    var day = anchor.hijriDay - 1;
    if (day == 0) {
      month--;
      if (month == 0) {
        month = 12;
        year--;
      }
      day = _civilMonthLength(year, month);
    }
    return (year, month, day);
  }

  HijriDate? _resolveFromLocalPattern({
    required DateTime date,
    required DateTime anchorDate,
    required HijriAnchorRecord anchor,
    HijriAnchorRecord? nextAnchor,
  }) {
    final offset = date.difference(anchorDate).inDays;
    if (offset < 0) return null;
    if (nextAnchor != null) {
      final interval = _resolveUsingAnchorInterval(
        offset: offset,
        anchor: anchor,
        nextAnchor: nextAnchor,
        actualGregorianDays: _dateOnly(
          nextAnchor.officialGregorianDate,
        ).difference(anchorDate).inDays,
      );
      if (interval != null) return interval;
    }

    return _resolveWithCivilPattern(offset: offset, anchor: anchor);
  }

  HijriDate? _resolveUsingAnchorInterval({
    required int offset,
    required HijriAnchorRecord anchor,
    required HijriAnchorRecord nextAnchor,
    required int actualGregorianDays,
  }) {
    final months = <(int, int)>[];
    var year = anchor.hijriYear;
    var month = anchor.hijriMonth;
    while (year != nextAnchor.hijriYear || month != nextAnchor.hijriMonth) {
      months.add((year, month));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      if (months.length > 24) return null;
    }
    if (months.length < 2) return null;

    final localDays = months.fold<int>(
      0,
      (total, item) => total + _civilMonthLength(item.$1, item.$2),
    );
    final delta = actualGregorianDays - localDays;
    if (delta == 0) return null;

    final lengths = [
      for (final item in months) _civilMonthLength(item.$1, item.$2),
    ];
    if (delta < 0) {
      lengths[0] += delta;
    } else {
      lengths[lengths.length - 1] += delta;
    }
    if (lengths.any((length) => length < 29 || length > 30)) return null;

    var remaining = offset;
    for (var index = 0; index < months.length; index++) {
      final length = lengths[index];
      if (remaining < length) {
        return HijriDate(
          year: months[index].$1,
          month: months[index].$2,
          day: remaining + 1,
          meta: const HijriResultMeta(
            source: 'anchor_local_fallback',
            isProvisional: true,
            validationStatus: 'provisional',
          ),
        );
      }
      remaining -= length;
    }
    return null;
  }

  HijriDate _resolveWithCivilPattern({
    required int offset,
    required HijriAnchorRecord anchor,
  }) {
    final civil = _addCivilDays(
      year: anchor.hijriYear,
      month: anchor.hijriMonth,
      day: anchor.hijriDay,
      offset: offset,
    );
    return HijriDate(
      year: civil.$1,
      month: civil.$2,
      day: civil.$3,
      meta: const HijriResultMeta(
        source: 'anchor_local_fallback',
        isProvisional: true,
        validationStatus: 'provisional',
      ),
    );
  }

  HijriDate _buildResult(
    HijriDate value, {
    required HijriAnchorRecord selected,
    required DateTime anchorDate,
    required DateTime? nextDate,
    required String validationStatus,
  }) {
    return HijriDate(
      year: value.year,
      month: value.month,
      day: value.day,
      meta: HijriResultMeta(
        source: 'anchor_local_fallback',
        isProvisional: true,
        anchorDate: anchorDate,
        nextAnchorDate: nextDate,
        authority: selected.authority,
        revision: selected.revision,
        validationStatus: validationStatus,
      ),
    );
  }

  (int, int, int) _addCivilDays({
    required int year,
    required int month,
    required int day,
    required int offset,
  }) {
    var currentYear = year;
    var currentMonth = month;
    var currentDay = day;
    var remaining = offset;
    while (remaining > 0) {
      currentDay++;
      if (currentDay > _civilMonthLength(currentYear, currentMonth)) {
        currentDay = 1;
        currentMonth++;
        if (currentMonth > 12) {
          currentMonth = 1;
          currentYear++;
        }
      }
      remaining--;
    }
    return (currentYear, currentMonth, currentDay);
  }

  int _civilMonthLength(int year, int month) {
    if (month.isOdd) return 30;
    if (month != 12) return 29;
    final cycleYear = year % 30;
    return const {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29}.contains(cycleYear)
        ? 30
        : 29;
  }

  HijriAnchorRecord? _pickBest(
    List<HijriAnchorRecord> records, {
    required DateTime date,
    required String authority,
    required String regionScope,
  }) {
    final matches = records
        .where(
          (r) =>
              r.authority == authority &&
              r.regionScope == regionScope &&
              !_dateOnly(r.officialGregorianDate).isAfter(date),
        )
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final byDate = b.officialGregorianDate.compareTo(a.officialGregorianDate);
      if (byDate != 0) return byDate;
      final byRevision = b.revision.compareTo(a.revision);
      if (byRevision != 0) return byRevision;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return matches.first;
  }

  HijriAnchorRecord? _nextAnchor(
    List<HijriAnchorRecord> records, {
    required HijriAnchorRecord after,
    required String authority,
    required String regionScope,
  }) {
    final matches =
        records
            .where(
              (r) =>
                  r.authority == authority &&
                  r.regionScope == regionScope &&
                  _dateOnly(
                    r.officialGregorianDate,
                  ).isAfter(_dateOnly(after.officialGregorianDate)),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.officialGregorianDate.compareTo(b.officialGregorianDate),
          );
    return matches.isEmpty ? null : matches.first;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}
