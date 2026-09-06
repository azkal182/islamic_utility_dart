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

    // An anchor without its following boundary is safe only as a provisional
    // result. We deliberately stop before the unknown 29/30-day boundary.
    final isProvisional = next == null;
    if (monthLength != null && (monthLength < 29 || monthLength > 30)) {
      return null;
    }
    if (monthLength == null && dayOffset > 28) return null;

    final day = selected.hijriDay + dayOffset;
    if (day < 1 || day > 30) return null;

    return HijriDate(
      year: selected.hijriYear,
      month: selected.hijriMonth,
      day: day,
      meta: HijriResultMeta(
        source: isProvisional ? 'anchor_provisional' : 'anchor_resolved',
        isAdjusted: false,
        adjustmentDays: 0,
        isProvisional: isProvisional,
        anchorDate: anchorDate,
        nextAnchorDate: next == null
            ? null
            : DateTime.utc(
                next.officialGregorianDate.year,
                next.officialGregorianDate.month,
                next.officialGregorianDate.day,
              ),
        authority: selected.authority,
        revision: selected.revision,
      ),
    );
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
    final matches = records
        .where(
          (r) =>
              r.authority == authority &&
              r.regionScope == regionScope &&
              _dateOnly(r.officialGregorianDate).isAfter(
                _dateOnly(after.officialGregorianDate),
              ),
        )
        .toList()
      ..sort((a, b) => a.officialGregorianDate.compareTo(b.officialGregorianDate));
    return matches.isEmpty ? null : matches.first;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}
