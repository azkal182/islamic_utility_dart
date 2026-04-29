import 'package:hive/hive.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_cache.dart';
import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';

class HiveHijriAdjustmentCache implements HijriAdjustmentCache {
  HiveHijriAdjustmentCache(this.box);

  final Box<dynamic> box;

  @override
  AdjustmentCacheEntry? get(DateTime date) {
    final raw = box.get(_key(date));
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      final cachedAt = DateTime.parse(map['cached_at'] as String).toUtc();
      final ttlMs = map['ttl_ms'] as int;
      final rawRecords = map['records'];
      if (rawRecords is! List) return null;

      final records = <AdjustmentRecord>[];
      for (final item in rawRecords) {
        if (item is! Map) continue;
        final row = Map<String, dynamic>.from(item);
        final effectiveFrom = row['effective_from'] as String?;
        final adjustmentDays = row['adjustment_days'] as int?;
        final revision = row['revision'] as int?;
        final publishedAt = row['published_at'] as String?;
        if (effectiveFrom == null ||
            adjustmentDays == null ||
            revision == null ||
            publishedAt == null) {
          continue;
        }
        records.add(
          AdjustmentRecord(
            effectiveFrom: DateTime.parse(effectiveFrom).toUtc(),
            effectiveTo: row['effective_to'] == null
                ? null
                : DateTime.parse(row['effective_to'] as String).toUtc(),
            adjustmentDays: adjustmentDays,
            revision: revision,
            publishedAt: DateTime.parse(publishedAt).toUtc(),
            authority: (row['authority'] as String?) ?? 'kemenag_ri',
            regionScope: (row['region_scope'] as String?) ?? 'national',
          ),
        );
      }

      return AdjustmentCacheEntry(
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
  void put(DateTime date, AdjustmentCacheEntry entry) {
    box.put(_key(date), {
      'etag': entry.etag,
      'cached_at': entry.cachedAt.toUtc().toIso8601String(),
      'ttl_ms': entry.ttl.inMilliseconds,
      'records': entry.records
          .map(
            (r) => {
              'effective_from': r.effectiveFrom.toUtc().toIso8601String(),
              'effective_to': r.effectiveTo?.toUtc().toIso8601String(),
              'adjustment_days': r.adjustmentDays,
              'revision': r.revision,
              'published_at': r.publishedAt.toUtc().toIso8601String(),
              'authority': r.authority,
              'region_scope': r.regionScope,
            },
          )
          .toList(),
    });
  }

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
