import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';

class AnchorCacheEntry {
  const AnchorCacheEntry({
    required this.records,
    this.etag,
    required this.cachedAt,
    required this.ttl,
  });

  final List<HijriAnchorRecord> records;
  final String? etag;
  final DateTime cachedAt;
  final Duration ttl;

  bool get isFresh => DateTime.now().toUtc().isBefore(cachedAt.add(ttl));
}

abstract class HijriAnchorCache {
  AnchorCacheEntry? get(DateTime date);

  void put(DateTime date, AnchorCacheEntry entry);
}

class InMemoryHijriAnchorCache implements HijriAnchorCache {
  final Map<String, AnchorCacheEntry> _store = {};

  @override
  AnchorCacheEntry? get(DateTime date) => _store[_key(date)];

  @override
  void put(DateTime date, AnchorCacheEntry entry) {
    _store[_key(date)] = entry;
  }

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
