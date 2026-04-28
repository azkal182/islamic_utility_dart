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
      final minus4Like = utcInstant.add(const Duration(hours: -4)).toUtc().add(
            const Duration(hours: 4),
          );

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
  });
}
