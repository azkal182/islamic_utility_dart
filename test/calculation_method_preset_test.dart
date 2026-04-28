import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('CalculationMethod preset contract', () {
    test('ummAlQura uses fixed isha interval', () {
      final p = CalculationMethod.ummAlQura.parameters;
      expect(p.fajrAngle, 18.5);
      expect(p.ishaInterval, 90);
    });

    test('tehran has maghrib angle', () {
      final p = CalculationMethod.tehran.parameters;
      expect(p.fajrAngle, 17.7);
      expect(p.ishaAngle, 14);
      expect(p.maghribAngle, 4.5);
    });

    test('dubai method adjustments follow spec', () {
      final p = CalculationMethod.dubai.parameters;
      expect(p.methodAdjustments[Prayer.sunrise], -3);
      expect(p.methodAdjustments[Prayer.dhuhr], 3);
      expect(p.methodAdjustments[Prayer.asr], 3);
      expect(p.methodAdjustments[Prayer.maghrib], 3);
    });

    test('night portions obey high latitude rules', () {
      final middle = CalculationMethod.other.parameters
          .copyWith(highLatitudeRule: HighLatitudeRule.middleOfTheNight)
          .nightPortions();
      final seventh = CalculationMethod.other.parameters
          .copyWith(highLatitudeRule: HighLatitudeRule.seventhOfTheNight)
          .nightPortions();
      final twilight = CalculationMethod.other.parameters
          .copyWith(
            highLatitudeRule: HighLatitudeRule.twilightAngle,
            fajrAngle: 18,
            ishaAngle: 18,
          )
          .nightPortions();

      expect(middle[Prayer.fajr], 0.5);
      expect(middle[Prayer.isha], 0.5);
      expect(seventh[Prayer.fajr], closeTo(1 / 7, 1e-10));
      expect(seventh[Prayer.isha], closeTo(1 / 7, 1e-10));
      expect(twilight[Prayer.fajr], 0.3);
      expect(twilight[Prayer.isha], 0.3);
    });
  });
}
