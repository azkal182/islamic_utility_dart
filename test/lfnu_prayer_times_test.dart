import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('LFNU prayer-time preset', () {
    final date = DateTime.utc(2026, 3, 21);
    const seaLevel = Coordinates(-6.5227778, 110.76);
    const elevated = Coordinates(-6.5227778, 110.76, elevation: 64);

    test('uses altitude-based Dhuha and elevation-adjusted horizon', () {
      final parameters = CalculationMethod.lfnu.parameters;
      final atSeaLevel = PrayerTimes(
        date: date,
        coordinates: seaLevel,
        calculationParameters: parameters,
        precision: true,
      );
      final atJeparaElevation = PrayerTimes(
        date: date,
        coordinates: elevated,
        calculationParameters: parameters,
        precision: true,
      );

      expect(atJeparaElevation.sunrise.isBefore(atSeaLevel.sunrise), isTrue);
      expect(atJeparaElevation.maghrib.isAfter(atSeaLevel.maghrib), isTrue);
      expect(
        atJeparaElevation.imsak,
        atJeparaElevation.fajr.subtract(const Duration(minutes: 10)),
      );
      expect(
        atJeparaElevation.dhuha.difference(atJeparaElevation.sunrise),
        isNot(const Duration(minutes: 20)),
      );
      final transitOnly = PrayerTimes(
        date: date,
        coordinates: elevated,
        calculationParameters: CalculationMethod.other.parameters,
        precision: true,
      );
      expect(
        atJeparaElevation.dhuhr,
        transitOnly.dhuhr.add(const Duration(minutes: 1)),
      );
    });

    test(
      'applies one-minute Maghrib ihtiyath only when Ramadan callback says so',
      () {
        final parameters = CalculationMethod.lfnu.parameters;
        final ordinary = PrayerTimes(
          date: date,
          coordinates: elevated,
          calculationParameters: parameters,
          precision: true,
        );
        final ramadan = PrayerTimes(
          date: date,
          coordinates: elevated,
          calculationParameters: parameters,
          precision: true,
          isRamadanOn: (day) => day == date,
        );

        expect(
          ramadan.maghrib,
          ordinary.maghrib.add(const Duration(minutes: 1)),
        );
      },
    );
  });
}
