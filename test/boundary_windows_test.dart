import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('Boundary windows A-G', () {
    final times = PrayerTimes(
      date: DateTime.utc(2026, 5, 1),
      coordinates: const Coordinates(-6.2, 106.8),
      calculationParameters: CalculationMethod.indonesian.parameters,
      precision: true,
    );

    test('window A: before fajr', () {
      final at = times.fajr.subtract(const Duration(seconds: 1));
      expect(times.currentPrayer(date: at), Prayer.ishaBefore);
      expect(times.nextPrayer(date: at), Prayer.fajr);
    });

    test('window B: fajr to sunrise', () {
      final at = times.fajr.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.fajr);
      expect(times.nextPrayer(date: at), Prayer.sunrise);
    });

    test('window C: sunrise to dhuhr', () {
      final at = times.sunrise.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.sunrise);
      expect(times.nextPrayer(date: at), Prayer.dhuhr);
    });

    test('window D: dhuhr to asr', () {
      final at = times.dhuhr.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.dhuhr);
      expect(times.nextPrayer(date: at), Prayer.asr);
    });

    test('window E: asr to maghrib', () {
      final at = times.asr.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.asr);
      expect(times.nextPrayer(date: at), Prayer.maghrib);
    });

    test('window F: maghrib to isha', () {
      final at = times.maghrib.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.maghrib);
      expect(times.nextPrayer(date: at), Prayer.isha);
    });

    test('window G: after isha', () {
      final at = times.isha.add(const Duration(minutes: 1));
      expect(times.currentPrayer(date: at), Prayer.isha);
      expect(times.nextPrayer(date: at), Prayer.fajrAfter);
    });
  });
}
