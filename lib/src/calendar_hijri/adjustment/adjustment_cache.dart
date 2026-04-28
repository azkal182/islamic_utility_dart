import 'package:islamic_utility/src/calendar_hijri/adjustment/adjustment_record.dart';

class AdjustmentCacheEntry {
  const AdjustmentCacheEntry({
    required this.records,
    this.etag,
    required this.cachedAt,
    required this.ttl,
  });

  final List<AdjustmentRecord> records;
  final String? etag;
  final DateTime cachedAt;
  final Duration ttl;

  bool get isFresh => DateTime.now().toUtc().isBefore(cachedAt.add(ttl));
}

abstract class HijriAdjustmentCache {
  AdjustmentCacheEntry? get(DateTime date);

  void put(DateTime date, AdjustmentCacheEntry entry);
}

class InMemoryHijriAdjustmentCache implements HijriAdjustmentCache {
  final Map<String, AdjustmentCacheEntry> _store = {};

  @override
  AdjustmentCacheEntry? get(DateTime date) => _store[_key(date)];

  @override
  void put(DateTime date, AdjustmentCacheEntry entry) {
    _store[_key(date)] = entry;
  }

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
