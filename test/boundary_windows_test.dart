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
      expect(times.nextPrayer(date: at), Prayer.dhuha);
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
      expect(times.nextPrayer(date: at), Prayer.imsak);
    });

    test('exact event instants enter the new current-prayer window', () {
      final boundaries = <({DateTime at, Prayer current, Prayer next})>[
        (at: times.fajr, current: Prayer.fajr, next: Prayer.sunrise),
        (at: times.sunrise, current: Prayer.sunrise, next: Prayer.dhuha),
        (at: times.dhuhr, current: Prayer.dhuhr, next: Prayer.asr),
        (at: times.asr, current: Prayer.asr, next: Prayer.maghrib),
        (at: times.maghrib, current: Prayer.maghrib, next: Prayer.isha),
        (at: times.isha, current: Prayer.isha, next: Prayer.imsak),
      ];

      for (final boundary in boundaries) {
        expect(
          times.currentPrayer(date: boundary.at),
          boundary.current,
          reason: 'current prayer at ${boundary.at}',
        );
        expect(
          times.nextPrayer(date: boundary.at),
          boundary.next,
          reason: 'next prayer at ${boundary.at}',
        );
      }
    });

    test('at Imsak, the next event is Fajr', () {
      expect(times.nextPrayer(date: times.imsak), Prayer.fajr);
    });
  });
}
