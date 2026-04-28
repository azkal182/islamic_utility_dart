import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

DateTime z(String value) => DateTime.parse(value).toUtc();

void main() {
  group('Golden parity dataset (UTC)', () {
    test('jakarta indonesian 2026-05-01', () {
      final p = PrayerTimes(
        date: DateTime.utc(2026, 5, 1),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.indonesian.parameters,
        precision: true,
      );

      expect(p.fajr, z('2026-04-30T21:33:36.000Z'));
      expect(p.sunrise, z('2026-04-30T22:53:10.000Z'));
      expect(p.dhuhr, z('2026-05-01T04:50:56.000Z'));
      expect(p.asr, z('2026-05-01T08:11:11.000Z'));
      expect(p.maghrib, z('2026-05-01T10:46:38.000Z'));
      expect(p.isha, z('2026-05-01T11:57:57.000Z'));
    });

    test('new york northAmerica 2026-01-15', () {
      final p = PrayerTimes(
        date: DateTime.utc(2026, 1, 15),
        coordinates: const Coordinates(40.7128, -74.0060),
        calculationParameters: CalculationMethod.northAmerica.parameters,
        precision: true,
      );

      expect(p.fajr, z('2026-01-15T10:57:33.000Z'));
      expect(p.sunrise, z('2026-01-15T12:17:53.000Z'));
      expect(p.dhuhr, z('2026-01-15T17:06:30.000Z'));
      expect(p.asr, z('2026-01-15T19:34:52.000Z'));
      expect(p.maghrib, z('2026-01-15T21:53:25.000Z'));
      expect(p.isha, z('2026-01-15T23:13:48.000Z'));
    });

    test('london moonsightingCommittee 2026-07-10', () {
      final p = PrayerTimes(
        date: DateTime.utc(2026, 7, 10),
        coordinates: const Coordinates(51.5072, -0.1276),
        calculationParameters: CalculationMethod.moonsightingCommittee.parameters,
        precision: true,
      );

      expect(p.fajr, z('2026-07-10T02:00:55.000Z'));
      expect(p.sunrise, z('2026-07-10T03:55:20.000Z'));
      expect(p.dhuhr, z('2026-07-10T12:10:55.000Z'));
      expect(p.asr, z('2026-07-10T16:25:34.000Z'));
      expect(p.maghrib, z('2026-07-10T20:18:54.000Z'));
      expect(p.isha, z('2026-07-10T21:31:02.000Z'));
    });
  });
}
