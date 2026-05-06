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

  /// Key is per Gregorian year-month because anchor records represent
  /// month-boundary data (awal bulan) that is valid for the whole month.
  /// Using per-day keys caused cache misses on every new day even when
  /// the anchor for that month was already fetched.
  /// UTC is used to avoid date boundary mismatches for WIB (UTC+7) users.
  String _key(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}-${utc.month}';
  }
}
