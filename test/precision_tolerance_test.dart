import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

int deltaSeconds(DateTime a, DateTime b) =>
    (a.millisecondsSinceEpoch - b.millisecondsSinceEpoch).abs() ~/ 1000;

void main() {
  group('Precision tolerance', () {
    test('precision false differs at most 30 seconds from precision true', () {
      final exact = PrayerTimes(
        date: DateTime.utc(2026, 9, 17),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.indonesian.parameters,
        precision: true,
      );
      final rounded = PrayerTimes(
        date: DateTime.utc(2026, 9, 17),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.indonesian.parameters,
        precision: false,
      );

      final exactList = [
        exact.fajr,
        exact.sunrise,
        exact.dhuhr,
        exact.asr,
        exact.maghrib,
        exact.isha,
      ];
      final roundedList = [
        rounded.fajr,
        rounded.sunrise,
        rounded.dhuhr,
        rounded.asr,
        rounded.maghrib,
        rounded.isha,
      ];

      for (var i = 0; i < exactList.length; i++) {
        expect(deltaSeconds(exactList[i], roundedList[i]) <= 30, isTrue);
        expect(roundedList[i].second, 0);
      }
    });

    test('precision true keeps sub-minute detail for at least one prayer', () {
      final exact = PrayerTimes(
        date: DateTime.utc(2026, 2, 11),
        coordinates: const Coordinates(40.7128, -74.0060),
        calculationParameters: CalculationMethod.northAmerica.parameters,
        precision: true,
      );

      final hasSeconds = [
        exact.fajr,
        exact.sunrise,
        exact.dhuhr,
        exact.asr,
        exact.maghrib,
        exact.isha,
      ].any((d) => d.second != 0);

      expect(hasSeconds, isTrue);
    });
  });
}
