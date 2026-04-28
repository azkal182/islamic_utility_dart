import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/umm_al_qura_provider.dart';
import 'package:test/test.dart';

void main() {
  group('UmmAlQuraProvider', () {
    final provider = UmmAlQuraProvider();

    test('supports only ummAlQura method', () {
      expect(provider.supports(HijriMethod.ummAlQura), isTrue);
      expect(provider.supports(HijriMethod.calculatedLocal), isFalse);
      expect(provider.supports(HijriMethod.kemenagRiOfficial), isFalse);
    });

    test('converts known Ramadan starts correctly', () {
      final h1445 = provider.fromGregorian(
        DateTime.utc(2024, 3, 11),
        method: HijriMethod.ummAlQura,
      );
      final h1444 = provider.fromGregorian(
        DateTime.utc(2023, 3, 23),
        method: HijriMethod.ummAlQura,
      );

      expect(h1445.year, 1445);
      expect(h1445.month, 9);
      expect(h1445.day, 1);

      expect(h1444.year, 1444);
      expect(h1444.month, 9);
      expect(h1444.day, 1);
    });

    test('returns valid Hijri range for normal date', () {
      final h = provider.fromGregorian(
        DateTime.utc(2026, 4, 28),
        method: HijriMethod.ummAlQura,
      );

      expect(h.year > 1300, isTrue);
      expect(h.month >= 1 && h.month <= 12, isTrue);
      expect(h.day >= 1 && h.day <= 30, isTrue);
      expect(h.meta.source, 'ummalqura_local');
    });

    test('throws for out of supported range', () {
      expect(
        () => provider.fromGregorian(
          DateTime.utc(2200, 1, 1),
          method: HijriMethod.ummAlQura,
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
