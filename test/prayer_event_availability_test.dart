import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('Prayer event availability', () {
    test(
      'reports high-latitude twilight fallback separately from astronomy',
      () {
        final times = PrayerTimes(
          date: DateTime.utc(2026, 6, 21),
          coordinates: const Coordinates(64.1466, -21.9426),
          calculationParameters: CalculationMethod.other.parameters.copyWith(
            fajrAngle: 18,
            ishaAngle: 17,
            highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
          ),
          precision: true,
        );

        final fajr = times.eventForPrayer(Prayer.fajr);
        final isha = times.eventForPrayer(Prayer.isha);
        expect(fajr.time, isNotNull);
        expect(fajr.source, PrayerEventSource.highLatitudeFallback);
        expect(isha.time, isNotNull);
        expect(isha.source, PrayerEventSource.highLatitudeFallback);
      },
    );

    test('provides marked fallbacks for all events during polar day', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 6, 21),
        coordinates: const Coordinates(69.6492, 18.9553),
        calculationParameters: CalculationMethod.other.parameters.copyWith(
          fajrAngle: 18,
          ishaAngle: 17,
          highLatitudeRule: HighLatitudeRule.middleOfTheNight,
        ),
        precision: true,
      );

      for (final prayer in [
        Prayer.imsak,
        Prayer.fajr,
        Prayer.sunrise,
        Prayer.dhuha,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        final result = times.eventForPrayer(prayer);
        expect(result.time, isNotNull, reason: prayer.name);
      }
      for (final prayer in [Prayer.sunrise, Prayer.dhuha, Prayer.maghrib]) {
        expect(
          times.eventForPrayer(prayer).source,
          PrayerEventSource.highLatitudeFallback,
          reason: prayer.name,
        );
        expect(times.timeForPrayer(prayer), isNotNull, reason: prayer.name);
      }
      expect(times.asr, isNotNull);
    });

    test(
      'falls back to midpoint between transit and sunset when Asr is absent',
      () {
        final times = PrayerTimes(
          date: DateTime.utc(2026, 1, 1),
          coordinates: const Coordinates(67, 0),
          calculationParameters: CalculationMethod.other.parameters.copyWith(
            fajrAngle: 18,
            ishaAngle: 17,
          ),
          precision: true,
        );

        final asr = times.eventForPrayer(Prayer.asr);
        final sunset = times.eventForPrayer(Prayer.maghrib);
        expect(asr.source, PrayerEventSource.highLatitudeFallback);
        expect(sunset.source, PrayerEventSource.astronomical);
        expect(asr.time, isNotNull);
        expect(sunset.time, isNotNull);
        expect(asr.time!.isAfter(times.dhuhr), isTrue);
        expect(asr.time!.isBefore(sunset.time!), isTrue);
        expect(
          asr.time,
          times.dhuhr.add(
            Duration(
              microseconds:
                  sunset.time!.difference(times.dhuhr).inMicroseconds ~/ 2,
            ),
          ),
        );
      },
    );

    test('reports method interval for available sunset-based Isha', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 6, 21),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.ummAlQura.parameters,
        precision: true,
      );
      expect(
        times.eventForPrayer(Prayer.isha).source,
        PrayerEventSource.calculationInterval,
      );
    });

    test('next prayer can include marked high-latitude fallback events', () {
      final date = DateTime.utc(2026, 6, 21);
      final times = PrayerTimes(
        date: date,
        coordinates: const Coordinates(69.6492, 18.9553),
        calculationParameters: CalculationMethod.other.parameters.copyWith(
          fajrAngle: 18,
          ishaAngle: 17,
          highLatitudeRule: HighLatitudeRule.middleOfTheNight,
        ),
        precision: true,
      );
      final next = times.nextPrayerDetails(
        at: DateTime.utc(2026, 6, 21, 10),
        locationDate: date,
      );
      expect(next.time, isNotNull);
    });

    test('adjacent-day Fajr and Isha equal their owner-day values', () {
      for (final method in CalculationMethod.values) {
        final parameters = method.parameters.copyWith(
          adjustments: {
            Prayer.fajr: 3,
            Prayer.fajrAfter: -11,
            Prayer.isha: 4,
            Prayer.ishaBefore: 13,
          },
        );
        final current = PrayerTimes(
          date: DateTime.utc(2026, 4, 15),
          coordinates: const Coordinates(40.7128, -74.0060),
          calculationParameters: parameters,
          precision: true,
        );
        final previous = PrayerTimes(
          date: DateTime.utc(2026, 4, 14),
          coordinates: const Coordinates(40.7128, -74.0060),
          calculationParameters: parameters,
          precision: true,
        );
        final next = PrayerTimes(
          date: DateTime.utc(2026, 4, 16),
          coordinates: const Coordinates(40.7128, -74.0060),
          calculationParameters: parameters,
          precision: true,
        );
        expect(current.fajrAfter, next.fajr, reason: method.name);
        expect(current.ishaBefore, previous.isha, reason: method.name);
      }
    });

    test('Imsak and Dhuha adjustments are applied after their base events', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 4, 15),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.other.parameters.copyWith(
          fajrAngle: 18,
          ishaAngle: 17,
          adjustments: {Prayer.imsak: 2, Prayer.fajr: 3, Prayer.dhuha: 4},
          methodAdjustments: {Prayer.sunrise: 5},
        ),
        precision: true,
      );
      expect(times.imsak, times.fajr.subtract(const Duration(minutes: 8)));
      expect(times.dhuha, times.sunrise.add(const Duration(minutes: 24)));
      final sunnah = SunnahTimes(times);
      expect(sunnah.middleOfTheNight.isAfter(times.maghrib), isTrue);
      expect(sunnah.middleOfTheNight.isBefore(times.fajrAfter), isTrue);
      expect(sunnah.lastThirdOfTheNight.isAfter(times.maghrib), isTrue);
      expect(sunnah.lastThirdOfTheNight.isBefore(times.fajrAfter), isTrue);
    });
  });
}
