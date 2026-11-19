import 'package:islamic_utility/islamic_utility.dart';
import 'package:test/test.dart';

void main() {
  group('Timezone consistency contract', () {
    test('same UTC instant yields same prayer classification', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 5, 1),
        coordinates: const Coordinates(-6.2, 106.8),
        calculationParameters: CalculationMethod.indonesian.parameters,
        precision: true,
      );

      final utcInstant = times.dhuhr.add(const Duration(minutes: 5));
      final plus7Like = utcInstant.toLocal().toUtc();
      final minus4Like = utcInstant
          .add(const Duration(hours: -4))
          .toUtc()
          .add(const Duration(hours: 4));

      final a = times.currentPrayer(date: utcInstant);
      final b = times.currentPrayer(date: plus7Like);
      final c = times.currentPrayer(date: minus4Like);

      expect(a, Prayer.dhuhr);
      expect(b, a);
      expect(c, a);
    });

    test('next prayer remains stable for equivalent instants', () {
      final times = PrayerTimes(
        date: DateTime.utc(2026, 1, 15),
        coordinates: const Coordinates(40.7128, -74.0060),
        calculationParameters: CalculationMethod.northAmerica.parameters,
        precision: true,
      );

      final base = times.maghrib.add(const Duration(minutes: 2));
      final eq1 = DateTime.fromMillisecondsSinceEpoch(
        base.millisecondsSinceEpoch,
        isUtc: true,
      );
      final eq2 = base.toLocal().toUtc();

      expect(times.nextPrayer(date: base), Prayer.isha);
      expect(times.nextPrayer(date: eq1), Prayer.isha);
      expect(times.nextPrayer(date: eq2), Prayer.isha);
    });

    test(
      'explicit location date fixes classification across local midnight',
      () {
        const newYork = Coordinates(40.7128, -74.0060);
        final stale = PrayerTimes(
          date: DateTime.utc(2026, 5, 1),
          coordinates: newYork,
          calculationParameters: CalculationMethod.northAmerica.parameters,
          precision: true,
        );
        // 04:01 UTC is 00:01 on May 2 in New York (UTC-4). It is before
        // May 2 Fajr, even though the instant is later than May 1's Isha.
        final instant = DateTime.utc(2026, 5, 2, 4, 1);
        final localDate = DateTime.utc(2026, 5, 2);

        expect(stale.currentPrayer(date: instant), Prayer.isha);
        expect(
          stale.currentPrayer(date: instant, locationDate: localDate),
          Prayer.ishaBefore,
        );
        expect(
          stale.nextPrayer(date: instant, locationDate: localDate),
          Prayer.imsak,
        );
      },
    );
  });
}
