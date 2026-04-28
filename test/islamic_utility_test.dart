import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('API and boundary behavior', () {
    final params = CalculationMethod.singapore.parameters;
    final times = PrayerTimes(
      date: DateTime.utc(2026, 4, 28),
      coordinates: const Coordinates(1.3521, 103.8198),
      calculationParameters: params,
      precision: true,
    );

    test('timeForPrayer maps every enum value', () {
      expect(times.timeForPrayer(Prayer.imsak), times.imsak);
      expect(times.timeForPrayer(Prayer.fajr), times.fajr);
      expect(times.timeForPrayer(Prayer.dhuha), times.dhuha);
      expect(times.timeForPrayer(Prayer.sunrise), times.sunrise);
      expect(times.timeForPrayer(Prayer.dhuhr), times.dhuhr);
      expect(times.timeForPrayer(Prayer.asr), times.asr);
      expect(times.timeForPrayer(Prayer.maghrib), times.maghrib);
      expect(times.timeForPrayer(Prayer.isha), times.isha);
      expect(times.timeForPrayer(Prayer.ishaBefore), times.ishaBefore);
      expect(times.timeForPrayer(Prayer.fajrAfter), times.fajrAfter);
    });

    test('imsak is 10 minutes before fajr and dhuha is 20 minutes after sunrise', () {
      expect(times.fajr.difference(times.imsak).inMinutes, 10);
      expect(times.dhuha.difference(times.sunrise).inMinutes, 20);
    });

    test('dhuha offset can be configured from parameters', () {
      final customParams = CalculationMethod.singapore.parameters.copyWith(
        dhuhaOffsetMinutes: 35,
      );
      final customTimes = PrayerTimes(
        date: DateTime.utc(2026, 4, 28),
        coordinates: const Coordinates(1.3521, 103.8198),
        calculationParameters: customParams,
        precision: true,
      );

      expect(customTimes.dhuha.difference(customTimes.sunrise).inMinutes, 35);
    });

    test('next prayer after isha is fajrAfter', () {
      final at = times.fajrAfter.subtract(const Duration(minutes: 1));
      expect(times.nextPrayer(date: at), Prayer.fajrAfter);
    });

    test('current prayer before fajr is ishaBefore', () {
      final at = times.fajr.subtract(const Duration(minutes: 10));
      expect(times.currentPrayer(date: at), Prayer.ishaBefore);
    });

    test('rounding contract precision false uses nearest minute', () {
      final rounded = PrayerTimes(
        date: DateTime.utc(2026, 4, 28),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: params,
        precision: false,
      );
      expect(rounded.fajr.second, 0);
      expect(rounded.fajr.millisecond, 0);
      expect(rounded.fajr.microsecond, 0);
    });

    test('sunnah times are inside night window', () {
      final sunnah = SunnahTimes(times);
      expect(sunnah.middleOfTheNight.isAfter(times.maghrib), isTrue);
      expect(sunnah.lastThirdOfTheNight.isAfter(sunnah.middleOfTheNight),
          isTrue);
      expect(sunnah.lastThirdOfTheNight.isBefore(times.fajrAfter), isTrue);
    });

    test('qibla bearing uses 0..360 domain', () {
      final q = Qibla.qibla(const Coordinates(-6.2, 106.8));
      expect(q >= 0 && q <= 360, isTrue);
    });
  });
}
