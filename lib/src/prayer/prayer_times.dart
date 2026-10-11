import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/core/solar_time.dart';
import 'package:islamic_utility/src/models/calculation_method.dart';
import 'package:islamic_utility/src/models/calculation_parameters.dart';
import 'package:islamic_utility/src/models/coordinates.dart';
import 'package:islamic_utility/src/models/madhab.dart';
import 'package:islamic_utility/src/models/prayer.dart';
import 'package:islamic_utility/src/models/shafaq.dart';
import 'package:islamic_utility/src/prayer/next_prayer_details.dart';
import 'package:islamic_utility/src/prayer/next_prayer_options.dart';

class PrayerTimes {
  PrayerTimes({
    required DateTime date,
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
    bool precision = false,
  }) : _date = DateTime.utc(date.year, date.month, date.day),
       _coordinates = coordinates,
       _parameters = calculationParameters,
       _precision = precision {
    final dateBefore = _date.subtract(const Duration(days: 1));
    final dateAfter = _date.add(const Duration(days: 1));

    final solarTime = SolarTime(_date, _coordinates);
    final solarTimeBefore = SolarTime(dateBefore, _coordinates);
    final solarTimeAfter = SolarTime(dateAfter, _coordinates);

    final dhuhrTime = TimeComponents(
      solarTime.transit,
    ).utcDate(_date.year, _date.month, _date.day);
    final sunriseTime = TimeComponents(
      solarTime.sunrise,
    ).utcDate(_date.year, _date.month, _date.day);
    final sunsetTime = TimeComponents(
      solarTime.sunset,
    ).utcDate(_date.year, _date.month, _date.day);
    final sunriseAfterTime = TimeComponents(
      solarTimeAfter.sunrise,
    ).utcDate(dateAfter.year, dateAfter.month, dateAfter.day);
    final sunsetBeforeTime = TimeComponents(
      solarTimeBefore.sunset,
    ).utcDate(dateBefore.year, dateBefore.month, dateBefore.day);

    final madhab = _parameters.madhab ?? Madhab.shafi;
    final asrTime = TimeComponents(
      solarTime.afternoon(madhab.shadowLength.toDouble()),
    ).utcDate(_date.year, _date.month, _date.day);

    final tomorrowSolarTime = SolarTime(
      _date.add(const Duration(days: 1)),
      _coordinates,
    );
    final tomorrowSunrise = TimeComponents(tomorrowSolarTime.sunrise).utcDate(
      _date.add(const Duration(days: 1)).year,
      _date.add(const Duration(days: 1)).month,
      _date.add(const Duration(days: 1)).day,
    );
    final previousNightDuration = sunriseTime.difference(sunsetBeforeTime);
    final currentNightDuration = tomorrowSunrise.difference(sunsetTime);

    var fajrTime = TimeComponents(
      solarTime.hourAngle(-1 * _parameters.fajrAngle, false),
    ).utcDate(_date.year, _date.month, _date.day);
    var fajrAfterTime = TimeComponents(
      solarTimeAfter.hourAngle(-1 * _parameters.fajrAngle, false),
    ).utcDate(dateAfter.year, dateAfter.month, dateAfter.day);

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final previousNightFraction = Duration(
        seconds: (previousNightDuration.inSeconds / 7).round(),
      );
      final currentNightFraction = Duration(
        seconds: (currentNightDuration.inSeconds / 7).round(),
      );
      fajrTime = sunriseTime.subtract(previousNightFraction);
      fajrAfterTime = sunriseAfterTime.subtract(currentNightFraction);
    }

    final safeFajrTime = _safeFajr(sunriseTime, previousNightDuration);
    if (safeFajrTime.isAfter(fajrTime)) {
      fajrTime = safeFajrTime;
    }
    final safeFajrAfterTime = _safeFajr(
      sunriseAfterTime,
      currentNightDuration,
      year: dateAfter.year,
      dayOfYearValue: dayOfYear(dateAfter),
    );
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
      ishaTime = TimeComponents(
        solarTime.hourAngle(-1 * _parameters.ishaAngle, true),
      ).utcDate(_date.year, _date.month, _date.day);
      ishaBeforeTime = TimeComponents(
        solarTimeBefore.hourAngle(-1 * _parameters.ishaAngle, true),
      ).utcDate(dateBefore.year, dateBefore.month, dateBefore.day);
    }

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final previousNightFraction = Duration(
        seconds: (previousNightDuration.inSeconds / 7).round(),
      );
      final currentNightFraction = Duration(
        seconds: (currentNightDuration.inSeconds / 7).round(),
      );
      ishaTime = sunsetTime.add(currentNightFraction);
      ishaBeforeTime = sunsetBeforeTime.add(previousNightFraction);
    }

    final safeIshaTime = _safeIsha(sunsetTime, currentNightDuration);
    if (safeIshaTime.isBefore(ishaTime)) {
      ishaTime = safeIshaTime;
    }
    final safeIshaBeforeTime = _safeIsha(
      sunsetBeforeTime,
      previousNightDuration,
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
    final schedule = _scheduleForInstant(at);
    if (at.isBefore(schedule.fajr)) return Prayer.ishaBefore;
    if (at.isBefore(schedule.sunrise)) return Prayer.fajr;
    if (at.isBefore(schedule.dhuhr)) return Prayer.sunrise;
    if (at.isBefore(schedule.asr)) return Prayer.dhuhr;
    if (at.isBefore(schedule.maghrib)) return Prayer.asr;
    if (at.isBefore(schedule.isha)) return Prayer.maghrib;
    return Prayer.isha;
  }

  Prayer nextPrayer({
    DateTime? date,
    NextPrayerOptions options = const NextPrayerOptions(),
  }) {
    final at = date ?? DateTime.now();
    final instant = at.toUtc();
    final schedule = _scheduleForInstant(instant);
    final details = schedule.nextPrayerDetails(
      at: at,
      locationDate: schedule._date,
      options: options,
    );
    if (details.isNextDay && details.prayer == Prayer.fajr) {
      return Prayer.fajrAfter;
    }
    return details.prayer;
  }

  /// Returns the next prayer-time event and whether it falls on the next
  /// calendar day at the target location.
  ///
  /// [at] is the instant to compare against. [locationDate] must represent
  /// that same instant in the target location's calendar (for example, a
  /// `TZDateTime` from the app's timezone package). Its year, month, and day
  /// select the local schedule date. This explicit local date is needed because
  /// this package does not resolve timezone identifiers from coordinates.
  ///
  /// The default event sequence includes Imsak, Fajr, sunrise, Dhuha, Dhuhr,
  /// Asr, Maghrib, and Isha. [options] can skip events or make Imsak
  /// conditional on Ramadan.
  NextPrayerDetails nextPrayerDetails({
    required DateTime at,
    required DateTime locationDate,
    NextPrayerOptions options = const NextPrayerOptions(),
  }) {
    final instant = at.toUtc();
    final todayDate = DateTime.utc(
      locationDate.year,
      locationDate.month,
      locationDate.day,
    );
    final today = _scheduleForLocationDate(todayDate);
    final tomorrowDate = DateTime.utc(
      todayDate.year,
      todayDate.month,
      todayDate.day + 1,
    );
    final tomorrow = _scheduleForLocationDate(tomorrowDate);
    final events = <({Prayer prayer, DateTime time, bool isNextDay})>[];

    void addDayEvents(
      PrayerTimes schedule,
      DateTime localDate,
      bool isNextDay,
    ) {
      if (options.imsakPolicy != ImsakPolicy.never &&
          !options.skip.contains(Prayer.imsak) &&
          options.includesImsak(localDate)) {
        events.add((
          prayer: Prayer.imsak,
          time: schedule.imsak,
          isNextDay: isNextDay,
        ));
      }
      events.addAll([
        (prayer: Prayer.fajr, time: schedule.fajr, isNextDay: isNextDay),
        (prayer: Prayer.sunrise, time: schedule.sunrise, isNextDay: isNextDay),
        (prayer: Prayer.dhuha, time: schedule.dhuha, isNextDay: isNextDay),
        (prayer: Prayer.dhuhr, time: schedule.dhuhr, isNextDay: isNextDay),
        (prayer: Prayer.asr, time: schedule.asr, isNextDay: isNextDay),
        (prayer: Prayer.maghrib, time: schedule.maghrib, isNextDay: isNextDay),
        (prayer: Prayer.isha, time: schedule.isha, isNextDay: isNextDay),
      ]);
    }

    addDayEvents(today, todayDate, false);
    addDayEvents(tomorrow, tomorrowDate, true);
    events.sort((a, b) => a.time.compareTo(b.time));

    for (final event in events) {
      final isSkipped =
          options.skip.contains(event.prayer) ||
          (event.prayer == Prayer.fajr &&
              event.isNextDay &&
              options.skip.contains(Prayer.fajrAfter));
      if (!isSkipped && event.time.isAfter(instant)) {
        return NextPrayerDetails(
          prayer: event.prayer,
          time: event.time,
          isNextDay: event.isNextDay,
        );
      }
    }

    throw ArgumentError.value(
      todayDate,
      'locationDate',
      'must be the target location calendar date for the instant in at',
    );
  }

  PrayerTimes _scheduleForLocationDate(DateTime locationDate) {
    if (locationDate.year == _date.year &&
        locationDate.month == _date.month &&
        locationDate.day == _date.day) {
      return this;
    }
    return PrayerTimes(
      date: locationDate,
      coordinates: _coordinates,
      calculationParameters: _parameters,
      precision: _precision,
    );
  }

  PrayerTimes _scheduleForInstant(DateTime instant) {
    var schedule = this;
    while (!instant.isBefore(schedule.fajrAfter)) {
      schedule = schedule._scheduleForLocationDate(
        schedule._date.add(const Duration(days: 1)),
      );
    }
    return schedule;
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
