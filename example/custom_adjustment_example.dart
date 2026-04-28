import 'package:islamic_utility/islamic_utility.dart';

void main() {
  final coordinates = const Coordinates(-6.3141, 110.4617);
  final base = CalculationMethod.indonesian.parameters;
  final params = base.copyWith(
    madhab: Madhab.hanafi,
    highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
    dhuhaOffsetMinutes: 30,
  );

  params.adjustments[Prayer.fajr] = 2;
  params.adjustments[Prayer.maghrib] = 1;
  params.adjustments[Prayer.isha] = 2;

  final times = PrayerTimes(
    date: DateTime.utc(2026, 5, 1),
    coordinates: coordinates,
    calculationParameters: params,
    precision: true,
  );

  print('Custom local adjustments (Bangsri Jepara):');
  print('Imsak: ${times.imsak}');
  print('Fajr: ${times.fajr}');
  print('Dhuha (+30m dari sunrise): ${times.dhuha}');
  print('Asr (Hanafi): ${times.asr}');
  print('Maghrib: ${times.maghrib}');
  print('Isha: ${times.isha}');
}
