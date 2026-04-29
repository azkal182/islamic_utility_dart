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

    test('syawal delayed case: previous day is not day 1', () {
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

      expect(jan30, isNotNull);
      expect(jan31, isNotNull);
      expect(jan30!.day, isNot(1));
      expect(jan31!.day, 1);
      expect(jan30.month == jan31.month && jan30.day == jan31.day, isFalse);
    });

    test('picks highest revision then latest publishedAt', () {
      final result = resolver.resolve(
        date: DateTime.utc(2026, 1, 31),
        records: [
          HijriAnchorRecord(
            officialGregorianDate: DateTime.utc(2026, 2, 1),
            hijriYear: 1447,
            hijriMonth: 10,
            revision: 1,
            publishedAt: DateTime.utc(2026, 1, 29),
          ),
          HijriAnchorRecord(
            officialGregorianDate: DateTime.utc(2026, 1, 31),
            hijriYear: 1447,
            hijriMonth: 10,
            revision: 2,
            publishedAt: DateTime.utc(2026, 1, 30),
          ),
        ],
        authority: 'kemenag_ri',
        regionScope: 'national',
      );

      expect(result, isNotNull);
      expect(result!.day, 1);
    });
  });
}
