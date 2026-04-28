import 'package:islamic_utility/islamic_utility.dart';

void main() {
  final coordinates = const Coordinates(-6.3141, 110.4617);
  final date = DateTime.utc(2026, 5, 1);

  final methods = [
    CalculationMethod.indonesian,
    CalculationMethod.singapore,
    CalculationMethod.muslimWorldLeague,
  ];

  for (final method in methods) {
    final times = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationParameters: method.parameters,
      precision: false,
    );

    print('--- ${method.name} ---');
    print('Imsak: ${times.imsak}');
    print('Fajr: ${times.fajr}');
    print('Dhuha: ${times.dhuha}');
    print('Dhuhr: ${times.dhuhr}');
    print('Maghrib: ${times.maghrib}');
    print('Isha: ${times.isha}');
  }
}
