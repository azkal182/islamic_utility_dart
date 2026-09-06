import 'package:islamic_utility/src/calendar_hijri/adjustment/anchor_record.dart';
import 'package:islamic_utility/src/calendar_hijri/resolver/anchor_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('AnchorResolver', () {
    final resolver = const AnchorResolver();

    test('resolves anchor day as day 1', () {
      final result = resolver.resolve(
        date: DateTime.utc(2026, 1, 31),
        records: [
          HijriAnchorRecord(
            officialGregorianDate: DateTime.utc(2026, 1, 31),
            hijriYear: 1447,
            hijriMonth: 10,
            revision: 1,
            publishedAt: DateTime.utc(2026, 1, 30),
          ),
        ],
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.year, 1447);
      expect(result.month, 10);
      expect(result.day, 1);
    });

    test('does not resolve a date before the anchor', () {
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 1, 31),
          hijriYear: 1447,
          hijriMonth: 10,
          revision: 1,
          publishedAt: DateTime.utc(2026, 1, 30),
        ),
      ];

      final jan30 = resolver.resolve(
        date: DateTime.utc(2026, 1, 30),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );
      final jan31 = resolver.resolve(
        date: DateTime.utc(2026, 1, 31),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(jan30, isNull);
      expect(jan31, isNotNull);
      expect(jan31!.day, 1);
    });

    test('ignores a future anchor and selects the latest valid anchor', () {
      final result = resolver.resolve(
        date: DateTime.utc(2026, 1, 31),
        records: [
          HijriAnchorRecord(
            officialGregorianDate: DateTime.utc(2026, 1, 31),
            hijriYear: 1447,
            hijriMonth: 10,
            revision: 2,
            publishedAt: DateTime.utc(2026, 1, 29),
          ),
          HijriAnchorRecord(
            officialGregorianDate: DateTime.utc(2026, 3, 1),
            hijriYear: 1447,
            hijriMonth: 11,
            revision: 99,
            publishedAt: DateTime.utc(2026, 1, 30),
          ),
        ],
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      final resolved = result;
      if (resolved == null) fail('Expected a valid anchor resolution');
      expect(resolved.month, 10);
      expect(resolved.day, 1);
    });

    test('uses anchor boundaries to support a 29-day month', () {
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 5, 18),
          hijriYear: 1447,
          hijriMonth: 12,
          revision: 1,
          publishedAt: DateTime.utc(2026, 5, 18),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 16),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 16),
        ),
      ];

      final june1 = resolver.resolve(
        date: DateTime.utc(2026, 6, 1),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );
      final june15 = resolver.resolve(
        date: DateTime.utc(2026, 6, 15),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(june1!.month, 12);
      expect(june1.day, 15);
      expect(june15!.month, 12);
      expect(june15.day, 29);
      expect(june15.meta.isProvisional, isFalse);
    });
  });
}
