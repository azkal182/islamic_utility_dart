import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/core/solar_time.dart';
import 'package:islamic_utility/src/models/calculation_method.dart';
import 'package:islamic_utility/src/models/calculation_parameters.dart';
import 'package:islamic_utility/src/models/coordinates.dart';
import 'package:islamic_utility/src/models/madhab.dart';
import 'package:islamic_utility/src/models/prayer.dart';
import 'package:islamic_utility/src/models/shafaq.dart';

class PrayerTimes {
  PrayerTimes({
    required DateTime date,
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
    bool precision = false,
  })  : _date = DateTime.utc(date.year, date.month, date.day),
        _coordinates = coordinates,
        _parameters = calculationParameters,
        _precision = precision {
    final dateBefore = _date.subtract(const Duration(days: 1));
    final dateAfter = _date.add(const Duration(days: 1));

    final solarTime = SolarTime(_date, _coordinates);
    final solarTimeBefore = SolarTime(dateBefore, _coordinates);
    final solarTimeAfter = SolarTime(dateAfter, _coordinates);

    final dhuhrTime = TimeComponents(solarTime.transit).utcDate(_date.year, _date.month, _date.day);
    final sunriseTime = TimeComponents(solarTime.sunrise).utcDate(_date.year, _date.month, _date.day);
    final sunsetTime = TimeComponents(solarTime.sunset).utcDate(_date.year, _date.month, _date.day);
    final sunriseAfterTime =
        TimeComponents(solarTimeAfter.sunrise).utcDate(dateAfter.year, dateAfter.month, dateAfter.day);
    final sunsetBeforeTime =
        TimeComponents(solarTimeBefore.sunset).utcDate(dateBefore.year, dateBefore.month, dateBefore.day);

    final madhab = _parameters.madhab ?? Madhab.shafi;
    final asrTime =
        TimeComponents(solarTime.afternoon(madhab.shadowLength.toDouble())).utcDate(_date.year, _date.month, _date.day);

    final tomorrowSolarTime = SolarTime(_date.add(const Duration(days: 1)), _coordinates);
    final tomorrowSunrise = TimeComponents(tomorrowSolarTime.sunrise).utcDate(
      _date.add(const Duration(days: 1)).year,
      _date.add(const Duration(days: 1)).month,
      _date.add(const Duration(days: 1)).day,
    );
    final nightDuration = tomorrowSunrise.difference(sunsetTime);

    var fajrTime =
        TimeComponents(solarTime.hourAngle(-1 * _parameters.fajrAngle, false)).utcDate(_date.year, _date.month, _date.day);
    var fajrAfterTime = TimeComponents(solarTimeAfter.hourAngle(-1 * _parameters.fajrAngle, false))
        .utcDate(dateAfter.year, dateAfter.month, dateAfter.day);

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final nf = Duration(seconds: (nightDuration.inSeconds / 7).round());
      fajrTime = sunriseTime.subtract(nf);
      fajrAfterTime = sunriseAfterTime.subtract(nf);
    }

    final safeFajrTime = _safeFajr(sunriseTime, nightDuration);
    if (safeFajrTime.isAfter(fajrTime)) {
      fajrTime = safeFajrTime;
    }
    final safeFajrAfterTime = _safeFajr(sunriseAfterTime, nightDuration,
        year: dateAfter.year, dayOfYearValue: dayOfYear(dateAfter));
    if (safeFajrAfterTime.isAfter(fajrAfterTime)) {
      fajrAfterTime = safeFajrAfterTime;
    }

    late DateTime ishaTime;
    late DateTime ishaBeforeTime;
    final ishaInterval = _parameters.ishaInterval ?? 0;
    if (ishaInterval > 0) {
      ishaTime = dateByAddingMinutes(sunsetTime, ishaInterval);
      ishaBeforeTime = dateByAddingMinutes(sunsetBeforeTime, ishaInterval);
    } else {
      ishaTime =
          TimeComponents(solarTime.hourAngle(-1 * _parameters.ishaAngle, true)).utcDate(_date.year, _date.month, _date.day);
      ishaBeforeTime = TimeComponents(solarTimeBefore.hourAngle(-1 * _parameters.ishaAngle, true))
          .utcDate(dateBefore.year, dateBefore.month, dateBefore.day);
    }

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final nf = Duration(seconds: (nightDuration.inSeconds / 7).round());
      ishaTime = sunsetTime.add(nf);
      ishaBeforeTime = sunsetBeforeTime.add(nf);
    }

    final safeIshaTime = _safeIsha(sunsetTime, nightDuration);
    if (safeIshaTime.isBefore(ishaTime)) {
      ishaTime = safeIshaTime;
    }
    final safeIshaBeforeTime = _safeIsha(
      sunsetBeforeTime,
      nightDuration,
      year: dateBefore.year,
      dayOfYearValue: dayOfYear(dateBefore),
    );
    if (safeIshaBeforeTime.isBefore(ishaBeforeTime)) {
      ishaBeforeTime = safeIshaBeforeTime;
    }

    var maghribTime = sunsetTime;
    if (_parameters.maghribAngle != null) {
      final angleBased = TimeComponents(
        solarTime.hourAngle(-1 * _parameters.maghribAngle!, true),
      ).utcDate(_date.year, _date.month, _date.day);
      if (sunsetTime.isBefore(angleBased) && ishaTime.isAfter(angleBased)) {
        maghribTime = angleBased;
      }
    }

    fajr = _apply(Prayer.fajr, fajrTime);
    imsak = fajr.subtract(const Duration(minutes: 10));
    sunrise = _apply(Prayer.sunrise, sunriseTime);
    dhuha = sunrise.add(Duration(minutes: _parameters.dhuhaOffsetMinutes));
    dhuhr = _apply(Prayer.dhuhr, dhuhrTime);
    asr = _apply(Prayer.asr, asrTime);
    maghrib = _apply(Prayer.maghrib, maghribTime);
    isha = _apply(Prayer.isha, ishaTime);
    fajrAfter = _apply(Prayer.fajrAfter, fajrAfterTime);
    ishaBefore = _apply(Prayer.ishaBefore, ishaBeforeTime);
  }

  final DateTime _date;
  final Coordinates _coordinates;
  final CalculationParameters _parameters;
  final bool _precision;

  late DateTime imsak;
  late DateTime fajr;
  late DateTime dhuha;
  late DateTime sunrise;
  late DateTime dhuhr;
  late DateTime asr;
  late DateTime maghrib;
  late DateTime isha;
  late DateTime ishaBefore;
  late DateTime fajrAfter;

  Prayer currentPrayer({required DateTime date}) {
    final at = date.toUtc();
    if (at.isBefore(fajr)) return Prayer.ishaBefore;
    if (at.isBefore(sunrise)) return Prayer.fajr;
    if (at.isBefore(dhuhr)) return Prayer.sunrise;
    if (at.isBefore(asr)) return Prayer.dhuhr;
    if (at.isBefore(maghrib)) return Prayer.asr;
    if (at.isBefore(isha)) return Prayer.maghrib;
    return Prayer.isha;
  }

  Prayer nextPrayer({DateTime? date}) {
    final at = (date ?? DateTime.now()).toUtc();
    if (at.isBefore(fajr)) return Prayer.fajr;
    if (at.isBefore(sunrise)) return Prayer.sunrise;
    if (at.isBefore(dhuhr)) return Prayer.dhuhr;
    if (at.isBefore(asr)) return Prayer.asr;
    if (at.isBefore(maghrib)) return Prayer.maghrib;
    if (at.isBefore(isha)) return Prayer.isha;
    return Prayer.fajrAfter;
  }

  DateTime timeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.imsak:
        return imsak;
      case Prayer.fajr:
        return fajr;
      case Prayer.dhuha:
        return dhuha;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
      case Prayer.ishaBefore:
        return ishaBefore;
      case Prayer.fajrAfter:
        return fajrAfter;
    }
  }

  DateTime _safeFajr(
    DateTime sunrise,
    Duration night, {
    int? year,
    int? dayOfYearValue,
  }) {
    if (_parameters.method == CalculationMethod.moonsightingCommittee) {
      return seasonAdjustedMorningTwilight(
        _coordinates.latitude,
        dayOfYearValue ?? dayOfYear(_date),
        year ?? _date.year,
        sunrise,
      );
    }
    final portion = _parameters.nightPortions()[Prayer.fajr] ?? 0.5;
    final nf = Duration(seconds: (night.inSeconds * portion).round());
    return sunrise.subtract(nf);
  }

  DateTime _safeIsha(
    DateTime sunset,
    Duration night, {
    int? year,
    int? dayOfYearValue,
  }) {
    if (_parameters.method == CalculationMethod.moonsightingCommittee) {
      return seasonAdjustedEveningTwilight(
        _coordinates.latitude,
        dayOfYearValue ?? dayOfYear(_date),
        year ?? _date.year,
        sunset,
        shafaq: _parameters.shafaq ?? Shafaq.general,
      );
    }
    final portion = _parameters.nightPortions()[Prayer.isha] ?? 0.5;
    final nf = Duration(seconds: (night.inSeconds * portion).round());
    return sunset.add(nf);
  }

  DateTime _apply(Prayer prayer, DateTime value) {
    final user = _parameters.adjustments[prayer] ?? 0;
    final method = _parameters.methodAdjustments[prayer] ?? 0;
    final adjusted = dateByAddingMinutes(value, user + method);
    return roundedMinute(adjusted.toUtc(), precision: _precision);
  }
}
