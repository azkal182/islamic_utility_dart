import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('Baseline schedule matrix', () {
    final matrix =
        <({CalculationMethod method, Coordinates coordinates, DateTime date})>[
          (
            method: CalculationMethod.northAmerica,
            coordinates: const Coordinates(40.7128, -74.0060),
            date: DateTime.utc(2026, 1, 15),
          ),
          (
            method: CalculationMethod.moonsightingCommittee,
            coordinates: const Coordinates(51.5072, -0.1276),
            date: DateTime.utc(2026, 7, 10),
          ),
          (
            method: CalculationMethod.turkiye,
            coordinates: const Coordinates(41.0082, 28.9784),
            date: DateTime.utc(2026, 3, 12),
          ),
          (
            method: CalculationMethod.singapore,
            coordinates: const Coordinates(1.3521, 103.8198),
            date: DateTime.utc(2026, 10, 20),
          ),
        ];

    for (final row in matrix) {
      test('${row.method.name} produces ordered daily schedule', () {
        final times = PrayerTimes(
          date: row.date,
          coordinates: row.coordinates,
          calculationParameters: row.method.parameters,
          precision: true,
        );

        expect(times.fajr.isBefore(times.sunrise), isTrue);
        expect(times.sunrise.isBefore(times.dhuhr), isTrue);
        expect(times.dhuhr.isBefore(times.asr), isTrue);
        expect(times.asr.isBefore(times.maghrib), isTrue);
        expect(times.maghrib.isBefore(times.isha), isTrue);
        expect(times.ishaBefore.isBefore(times.sunrise), isTrue);
        expect(times.fajrAfter.isBefore(times.isha), isFalse);
      });
    }
  });

  group('High latitude guard rails', () {
    test('moonsightingCommittee at latitude >= 55 stays in night window', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 6, 21),
        coordinates: const Coordinates(59.3293, 18.0686),
        calculationParameters:
            CalculationMethod.moonsightingCommittee.parameters,
        precision: true,
      );

      expect(times.fajr.isBefore(times.sunrise), isTrue);
      expect(times.isha.isAfter(times.maghrib), isTrue);
      expect(times.fajrAfter.isAfter(times.isha), isTrue);
    });

    test(
      'unreachable twilight angles use the selected night-fraction rule',
      () {
        const reykjavik = Coordinates(64.1466, -21.9426);
        for (final rule in HighLatitudeRule.values) {
          final parameters = CalculationMethod.northAmerica.parameters.copyWith(
            highLatitudeRule: rule,
          );
          final times = PrayerTimes(
            date: DateTime.utc(2026, 7, 15),
            coordinates: reykjavik,
            calculationParameters: parameters,
            precision: true,
          );
          final yesterday = PrayerTimes(
            date: DateTime.utc(2026, 7, 14),
            coordinates: reykjavik,
            calculationParameters: parameters,
            precision: true,
          );
          final tomorrow = PrayerTimes(
            date: DateTime.utc(2026, 7, 16),
            coordinates: reykjavik,
            calculationParameters: parameters,
            precision: true,
          );

          expect(
            times.fajr.isBefore(times.sunrise),
            isTrue,
            reason: '$rule must not turn unreachable Fajr into a daytime time',
          );
          expect(
            times.isha.isAfter(times.maghrib),
            isTrue,
            reason: '$rule must not turn unreachable Isha into a daytime time',
          );

          final portions = parameters.nightPortions();
          final previousNight = times.sunrise.difference(yesterday.maghrib);
          final currentNight = tomorrow.sunrise.difference(times.maghrib);
          final expectedFajr = times.sunrise.subtract(
            Duration(
              seconds: (previousNight.inSeconds * portions[Prayer.fajr]!)
                  .round(),
            ),
          );
          final expectedIsha = times.maghrib.add(
            Duration(
              seconds: (currentNight.inSeconds * portions[Prayer.isha]!)
                  .round(),
            ),
          );

          expect(times.fajr, expectedFajr, reason: '$rule Fajr night fraction');
          expect(times.isha, expectedIsha, reason: '$rule Isha night fraction');
        }
      },
    );
  });
}
