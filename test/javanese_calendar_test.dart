import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('JavaneseCalendar', () {
    final calendar = const JavaneseCalendar();

    test('anchor date maps to Pahing', () {
      final result = calendar.fromGregorian(DateTime.utc(2024, 1, 1));
      expect(result.pasaran, Pasaran.pahing);
      expect(result.weton, 'Senin Pahing');
    });

    test('pasaran cycles forward every day', () {
      final d1 = calendar.fromGregorian(DateTime.utc(2024, 1, 1));
      final d2 = calendar.fromGregorian(DateTime.utc(2024, 1, 2));
      final d3 = calendar.fromGregorian(DateTime.utc(2024, 1, 3));
      final d4 = calendar.fromGregorian(DateTime.utc(2024, 1, 4));
      final d5 = calendar.fromGregorian(DateTime.utc(2024, 1, 5));
      final d6 = calendar.fromGregorian(DateTime.utc(2024, 1, 6));

      expect(d1.pasaran, Pasaran.pahing);
      expect(d2.pasaran, Pasaran.pon);
      expect(d3.pasaran, Pasaran.wage);
      expect(d4.pasaran, Pasaran.kliwon);
      expect(d5.pasaran, Pasaran.legi);
      expect(d6.pasaran, Pasaran.pahing);
    });

    test('range returns inclusive number of days', () {
      final results = calendar.fromGregorianRange(
        from: DateTime.utc(2024, 1, 1),
        to: DateTime.utc(2024, 1, 5),
      );
      expect(results.length, 5);
      expect(results.first.pasaran, Pasaran.pahing);
      expect(results.last.pasaran, Pasaran.legi);
    });

    test('matches known sample around 2026-03-15', () {
      final d1 = calendar.fromGregorian(DateTime.utc(2026, 3, 15));
      final d2 = calendar.fromGregorian(DateTime.utc(2026, 3, 16));
      final d3 = calendar.fromGregorian(DateTime.utc(2026, 3, 17));
      final d4 = calendar.fromGregorian(DateTime.utc(2026, 3, 18));
      final d5 = calendar.fromGregorian(DateTime.utc(2026, 3, 19));

      expect(d1.weton, 'Ahad Legi');
      expect(d2.weton, 'Senin Pahing');
      expect(d3.weton, 'Selasa Pon');
      expect(d4.weton, 'Rabu Wage');
      expect(d5.weton, 'Kamis Kliwon');
    });
  });
}
