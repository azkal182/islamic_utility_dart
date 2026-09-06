import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  test('anchor cache keys preserve the supplied calendar date', () {
    final cache = InMemoryHijriAnchorCache();
    final entry = AnchorCacheEntry(
      records: [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 16),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 16),
        ),
      ],
      cachedAt: DateTime.now().toUtc(),
      ttl: const Duration(hours: 1),
    );

    cache.put(DateTime(2026, 6, 1), entry);

    expect(cache.get(DateTime.utc(2026, 6, 1)), same(entry));
  });

  test('adjustment cache keys preserve the supplied calendar date', () {
    final cache = InMemoryHijriAdjustmentCache();
    final entry = AdjustmentCacheEntry(
      records: const [],
      cachedAt: DateTime.now().toUtc(),
      ttl: const Duration(hours: 1),
    );

    cache.put(DateTime(2026, 6, 1), entry);

    expect(cache.get(DateTime.utc(2026, 6, 1)), same(entry));
  });
}
