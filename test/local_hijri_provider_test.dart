import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/local_hijri_provider.dart';
import 'package:test/test.dart';

void main() {
  group('LocalHijriProvider', () {
    final provider = LocalHijriProvider();

    test('supports only calculatedLocal method', () {
      expect(provider.supports(HijriMethod.calculatedLocal), isTrue);
      expect(provider.supports(HijriMethod.ummAlQura), isFalse);
      expect(provider.supports(HijriMethod.kemenagRiOfficial), isFalse);
    });

    test('converts known date to expected civil hijri', () {
      final h = provider.fromGregorian(
        DateTime.utc(2024, 3, 11),
        method: HijriMethod.calculatedLocal,
      );

      expect(h.year, 1445);
      expect(h.month, 9);
      expect(h.day, 1);
      expect(h.meta.source, 'local_calculated_civil');
    });

    test('returns deterministic and valid ranges', () {
      final d = DateTime.utc(2026, 4, 28);
      final h1 = provider.fromGregorian(d, method: HijriMethod.calculatedLocal);
      final h2 = provider.fromGregorian(d, method: HijriMethod.calculatedLocal);

      expect(h1.year, h2.year);
      expect(h1.month, h2.month);
      expect(h1.day, h2.day);
      expect(h1.month >= 1 && h1.month <= 12, isTrue);
      expect(h1.day >= 1 && h1.day <= 30, isTrue);
    });
  });
}
