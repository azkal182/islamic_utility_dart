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

    test('continues several future months from the last anchor', () {
      final anchor = HijriAnchorRecord(
        officialGregorianDate: DateTime.utc(2026, 6, 17),
        hijriYear: 1448,
        hijriMonth: 1,
        revision: 1,
        publishedAt: DateTime.utc(2026, 6, 17),
      );

      final result = resolver.resolve(
        date: DateTime.utc(2026, 8, 15),
        records: [anchor],
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.year, 1448);
      expect(result.month, 3);
      expect(result.day, 1);
      expect(result.meta.source, 'anchor_local_fallback');
      expect(result.meta.validationStatus, 'provisional');
      expect(result.meta.isProvisional, isTrue);
    });

    test('marks a missing intermediate anchor validated by a later anchor', () {
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 17),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 17),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 8, 15),
          hijriYear: 1448,
          hijriMonth: 3,
          revision: 1,
          publishedAt: DateTime.utc(2026, 8, 15),
        ),
      ];

      final result = resolver.resolve(
        date: DateTime.utc(2026, 7, 17),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.year, 1448);
      expect(result.month, 2);
      expect(result.day, 1);
      expect(result.meta.validationStatus, 'inferred_validated');
      expect(result.meta.isProvisional, isTrue);
    });

    test('reconciles a late +1 anchor without duplicating day one', () {
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 17),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 17),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 8, 16),
          hijriYear: 1448,
          hijriMonth: 3,
          revision: 1,
          publishedAt: DateTime.utc(2026, 8, 16),
        ),
      ];

      final result = resolver.resolve(
        date: DateTime.utc(2026, 8, 15),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.year, 1448);
      expect(result.month, 2);
      expect(result.day, 30);
      expect(result.meta.validationStatus, 'provisional');

      final official = resolver.resolve(
        date: DateTime.utc(2026, 8, 16),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );
      expect(official!.month, 3);
      expect(official.day, 1);
    });

    test('reconciles an early -1 anchor without skipping a day', () {
      final records = [
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 6, 17),
          hijriYear: 1448,
          hijriMonth: 1,
          revision: 1,
          publishedAt: DateTime.utc(2026, 6, 17),
        ),
        HijriAnchorRecord(
          officialGregorianDate: DateTime.utc(2026, 8, 14),
          hijriYear: 1448,
          hijriMonth: 3,
          revision: 1,
          publishedAt: DateTime.utc(2026, 8, 14),
        ),
      ];

      final result = resolver.resolve(
        date: DateTime.utc(2026, 8, 13),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.year, 1448);
      expect(result.month, 2);
      expect(result.day, 29);

      final official = resolver.resolve(
        date: DateTime.utc(2026, 8, 14),
        records: records,
        authority: 'kemenag_ri',
        regionScope: 'national',
      );
      expect(official!.month, 3);
      expect(official.day, 1);
    });
  });
}
