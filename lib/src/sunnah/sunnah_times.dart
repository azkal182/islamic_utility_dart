import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/prayer/prayer_times.dart';

class SunnahTimes {
  SunnahTimes(PrayerTimes prayerTimes, {bool precision = true})
      : middleOfTheNight = roundedMinute(
          prayerTimes.maghrib
              .add(prayerTimes.fajrAfter.difference(prayerTimes.maghrib) ~/ 2),
          precision: precision,
        ),
        lastThirdOfTheNight = roundedMinute(
          prayerTimes.maghrib
              .add((prayerTimes.fajrAfter.difference(prayerTimes.maghrib) * 2) ~/ 3),
          precision: precision,
        );

  final DateTime middleOfTheNight;
  final DateTime lastThirdOfTheNight;
}
