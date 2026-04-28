import 'package:islamic_utility/src/calendar_hijri/models/hijri_method.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/local_hijri_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/providers/umm_al_qura_provider.dart';
import 'package:islamic_utility/src/calendar_hijri/resolver/hijri_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('HijriResolver', () {
    final resolver = HijriResolver([
      LocalHijriProvider(),
      UmmAlQuraProvider(),
    ]);

    test('routes to local provider', () {
      final h = resolver.fromGregorian(
        DateTime.utc(2024, 3, 11),
        method: HijriMethod.calculatedLocal,
      );
      expect(h.month, 9);
    });

    test('routes to umm al-qura provider', () {
      final h = resolver.fromGregorian(
        DateTime.utc(2024, 3, 11),
        method: HijriMethod.ummAlQura,
      );
      expect(h.month, 9);
    });

    test('throws when no provider available', () {
      expect(
        () => resolver.fromGregorian(
          DateTime.utc(2024, 3, 11),
          method: HijriMethod.kemenagRiOfficial,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
