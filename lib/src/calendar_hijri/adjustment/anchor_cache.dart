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

  /// The key represents the calendar date supplied by the caller.
  ///
  /// Do not call `toUtc()` before extracting the date components: a local
  /// midnight such as 2026-06-01 in WIB becomes the previous UTC date.
  String _key(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
