import 'package:islamic_utility/islamic_utility.dart';

void main() {
  final coordinates = const Coordinates(-6.3141, 110.4617);
  final params = CalculationMethod.indonesian.parameters;
  final today = DateTime.now().toUtc();

  final times = PrayerTimes(
    date: DateTime.utc(today.year, today.month, today.day),
    coordinates: coordinates,
    calculationParameters: params,
    precision: true,
  );

  final now = DateTime.now().toUtc();
  final current = times.currentPrayer(date: now);
  final next = times.nextPrayer(date: now);
  final sunnah = SunnahTimes(times);
  final qibla = Qibla.qibla(coordinates);

  print('Lokasi: Bangsri, Jepara (-6.3141, 110.4617)');
  print('Imsak   : ${times.imsak}');
  print('Fajr    : ${times.fajr}');
  print('Dhuha   : ${times.dhuha}');
  print('Sunrise : ${times.sunrise}');
  print('Dhuhr   : ${times.dhuhr}');
  print('Asr     : ${times.asr}');
  print('Maghrib : ${times.maghrib}');
  print('Isha    : ${times.isha}');
  print('Current : $current');
  print('Next    : $next at ${times.timeForPrayer(next)}');
  print('Middle of night : ${sunnah.middleOfTheNight}');
  print('Last third      : ${sunnah.lastThirdOfTheNight}');
  print('Qibla (degrees) : $qibla');
}
