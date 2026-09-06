import 'package:hive/hive.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';

class HiveHijriAnchorCache implements HijriAnchorCache {
  HiveHijriAnchorCache(this.box);

  final Box<dynamic> box;

  @override
  AnchorCacheEntry? get(DateTime date) {
    final raw = box.get(_key(date));
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      final cachedAt = DateTime.parse(map['cached_at'] as String).toUtc();
      final ttlMs = map['ttl_ms'] as int;
      final rawRecords = map['records'];
      if (rawRecords is! List) return null;

      final records = <HijriAnchorRecord>[];
      for (final item in rawRecords) {
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        final officialDate = row['official_gregorian_date'] as String?;
        final hijriYear = row['hijri_year'] as int?;
        final hijriMonth = row['hijri_month'] as int?;
        final revision = row['revision'] as int?;
        final publishedAt = row['published_at'] as String?;
        if (officialDate == null ||
            hijriYear == null ||
            hijriMonth == null ||
            revision == null ||
            publishedAt == null) {
          continue;
        }
        records.add(
          HijriAnchorRecord(
            officialGregorianDate: DateTime.parse(officialDate).toUtc(),
            hijriYear: hijriYear,
            hijriMonth: hijriMonth,
            hijriDay: (row['hijri_day'] as int?) ?? 1,
            revision: revision,
            publishedAt: DateTime.parse(publishedAt).toUtc(),
            authority: (row['authority'] as String?) ?? 'kemenag_ri',
            regionScope: (row['region_scope'] as String?) ?? 'national',
            notes: row['notes'] as String?,
          ),
        );
      }

      return AnchorCacheEntry(
        records: records,
        etag: map['etag'] as String?,
        cachedAt: cachedAt,
        ttl: Duration(milliseconds: ttlMs),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void put(DateTime date, AnchorCacheEntry entry) {
    box.put(_key(date), {
      'etag': entry.etag,
      'cached_at': entry.cachedAt.toUtc().toIso8601String(),
      'ttl_ms': entry.ttl.inMilliseconds,
      'records': entry.records
          .map(
            (r) => {
              'official_gregorian_date': r.officialGregorianDate
                  .toUtc()
                  .toIso8601String(),
              'hijri_year': r.hijriYear,
              'hijri_month': r.hijriMonth,
              'hijri_day': r.hijriDay,
              'revision': r.revision,
              'published_at': r.publishedAt.toUtc().toIso8601String(),
              'authority': r.authority,
              'region_scope': r.regionScope,
              'notes': r.notes,
            },
          )
          .toList(),
    });
  }

  /// The key represents the calendar date supplied by the caller.
  ///
  /// Do not call `toUtc()` before extracting the date components: a local
  /// midnight such as 2026-06-01 in WIB becomes the previous UTC date.
  String _key(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
