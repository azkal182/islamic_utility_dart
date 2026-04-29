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
    final selected = _pickBest(records, authority: authority, regionScope: regionScope);
    if (selected == null) return null;

    final dayDate = DateTime.utc(date.year, date.month, date.day);
    final anchorDate = DateTime.utc(
      selected.officialGregorianDate.year,
      selected.officialGregorianDate.month,
      selected.officialGregorianDate.day,
    );
    final dayOffset = dayDate.difference(anchorDate).inDays;

    var year = selected.hijriYear;
    var month = selected.hijriMonth;
    var day = selected.hijriDay + dayOffset;

    while (day > 30) {
      day -= 30;
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }

    while (day < 1) {
      month -= 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
      day += 30;
    }

    return HijriDate(
      year: year,
      month: month,
      day: day,
      meta: HijriResultMeta(
        source: 'anchor_resolved',
        isAdjusted: true,
        adjustmentDays: dayOffset,
        authority: selected.authority,
        revision: selected.revision,
      ),
    );
  }

  HijriAnchorRecord? _pickBest(
    List<HijriAnchorRecord> records, {
    required String authority,
    required String regionScope,
  }) {
    final matches = records
        .where((r) => r.authority == authority && r.regionScope == regionScope)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final byRevision = b.revision.compareTo(a.revision);
      if (byRevision != 0) return byRevision;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return matches.first;
  }
}
