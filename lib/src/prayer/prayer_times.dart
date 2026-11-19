import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/core/solar_time.dart';
import 'package:islamic_utility/src/models/calculation_method.dart';
import 'package:islamic_utility/src/models/calculation_parameters.dart';
import 'package:islamic_utility/src/models/coordinates.dart';
import 'package:islamic_utility/src/models/madhab.dart';
import 'package:islamic_utility/src/models/prayer.dart';
import 'package:islamic_utility/src/models/shafaq.dart';
import 'package:islamic_utility/src/prayer/next_prayer_details.dart';
import 'package:islamic_utility/src/prayer/prayer_event_result.dart';
import 'package:islamic_utility/src/prayer/next_prayer_options.dart';

bool _neverRamadan(DateTime _) => false;

class PrayerTimes {
  PrayerTimes({
    required DateTime date,
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
    bool precision = false,
    bool Function(DateTime date)? isRamadanOn,
  }) : _date = DateTime.utc(date.year, date.month, date.day),
       _coordinates = coordinates,
       _parameters = calculationParameters,
       _precision = precision,
       _isRamadanOn = isRamadanOn ?? _neverRamadan {
    final dateBefore = _date.subtract(const Duration(days: 1));
    final dateAfter = _date.add(const Duration(days: 1));

    final solarTime = SolarTime(_date, _coordinates);
    final solarTimeBefore = SolarTime(dateBefore, _coordinates);
    final solarTimeAfter = SolarTime(dateAfter, _coordinates);

    final sunriseAvailable = solarTime.canReachAltitude(
      solarTime.horizonAltitude,
      afterTransit: false,
    );
    final sunsetAvailable = solarTime.canReachAltitude(
      solarTime.horizonAltitude,
      afterTransit: true,
    );
    final sunriseAfterAvailable = solarTimeAfter.canReachAltitude(
      solarTimeAfter.horizonAltitude,
      afterTransit: false,
    );
    final sunsetBeforeAvailable = solarTimeBefore.canReachAltitude(
      solarTimeBefore.horizonAltitude,
      afterTransit: true,
    );
    final fajrAngleAvailable = solarTime.canReachAltitude(
      -_parameters.fajrAngle,
      afterTransit: false,
    );
    final fajrAfterAngleAvailable = solarTimeAfter.canReachAltitude(
      -_parameters.fajrAngle,
      afterTransit: false,
    );
    final ishaAngleAvailable = solarTime.canReachAltitude(
      -_parameters.ishaAngle,
      afterTransit: true,
    );
    final ishaBeforeAngleAvailable = solarTimeBefore.canReachAltitude(
      -_parameters.ishaAngle,
      afterTransit: true,
    );

    final dhuhrTime = TimeComponents(
      solarTime.transit,
    ).utcDate(_date.year, _date.month, _date.day);
    final sunriseTime = _solarAnchor(
      solarTime,
      beforeTransit: true,
      isAvailable: sunriseAvailable,
      date: _date,
    );
    final sunsetTime = _solarAnchor(
      solarTime,
      beforeTransit: false,
      isAvailable: sunsetAvailable,
      date: _date,
    );
    final sunriseAfterTime = _solarAnchor(
      solarTimeAfter,
      beforeTransit: true,
      isAvailable: sunriseAfterAvailable,
      date: dateAfter,
    );
    final sunsetBeforeTime = _solarAnchor(
      solarTimeBefore,
      beforeTransit: false,
      isAvailable: sunsetBeforeAvailable,
      date: dateBefore,
    );

    final madhab = _parameters.madhab ?? Madhab.shafi;
    final asrAltitude = solarTime.afternoonAltitude(
      madhab.shadowLength.toDouble(),
    );
    final asrAvailable = solarTime.canReachAltitude(
      asrAltitude,
      afterTransit: true,
    );
    final asrFallbackTime = dhuhrTime.add(
      Duration(
        microseconds: sunsetTime.difference(dhuhrTime).inMicroseconds ~/ 2,
      ),
    );
    final dhuhaAngle = _parameters.dhuhaAngle;
    final dhuhaAngleAvailable =
        dhuhaAngle != null &&
        solarTime.canReachAltitude(dhuhaAngle, afterTransit: false);
    final dhuhaTime = dhuhaAngleAvailable
        ? TimeComponents(
            solarTime.hourAngle(dhuhaAngle, false),
          ).utcDate(_date.year, _date.month, _date.day)
        : null;
    final asrTime = asrAvailable
        ? TimeComponents(
            solarTime.afternoon(madhab.shadowLength.toDouble()),
          ).utcDate(_date.year, _date.month, _date.day)
        : asrFallbackTime;

    final tomorrowSolarTime = SolarTime(
      _date.add(const Duration(days: 1)),
      _coordinates,
    );
    final tomorrowSunrise = _solarAnchor(
      tomorrowSolarTime,
      beforeTransit: true,
      isAvailable: tomorrowSolarTime.canReachAltitude(
        tomorrowSolarTime.horizonAltitude,
        afterTransit: false,
      ),
      date: _date.add(const Duration(days: 1)),
    );
    final previousNightDuration = sunriseTime.difference(sunsetBeforeTime);
    final currentNightDuration = tomorrowSunrise.difference(sunsetTime);

    DateTime? fajrCandidate;
    if (fajrAngleAvailable) {
      fajrCandidate = TimeComponents(
        solarTime.hourAngle(-_parameters.fajrAngle, false),
      ).utcDate(_date.year, _date.month, _date.day);
    }
    DateTime? fajrAfterCandidate;
    if (fajrAfterAngleAvailable) {
      fajrAfterCandidate = TimeComponents(
        solarTimeAfter.hourAngle(-_parameters.fajrAngle, false),
      ).utcDate(dateAfter.year, dateAfter.month, dateAfter.day);
    }

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final previousNightFraction = Duration(
        seconds: (previousNightDuration.inSeconds / 7).round(),
      );
      final currentNightFraction = Duration(
        seconds: (currentNightDuration.inSeconds / 7).round(),
      );
      fajrCandidate = sunriseTime.subtract(previousNightFraction);
      fajrAfterCandidate = sunriseAfterTime.subtract(currentNightFraction);
    }

    final safeFajrTime = _safeFajr(sunriseTime, previousNightDuration);
    final fajrFallbackApplied =
        fajrCandidate == null || safeFajrTime.isAfter(fajrCandidate);
    var fajrTime = fajrCandidate ?? safeFajrTime;
    if (safeFajrTime.isAfter(fajrTime)) {
      fajrTime = safeFajrTime;
    }
    final safeFajrAfterTime = _safeFajr(
      sunriseAfterTime,
      currentNightDuration,
      year: dateAfter.year,
      dayOfYearValue: dayOfYear(dateAfter),
    );
    final fajrAfterFallbackApplied =
        fajrAfterCandidate == null ||
        safeFajrAfterTime.isAfter(fajrAfterCandidate);
    var fajrAfterTime = fajrAfterCandidate ?? safeFajrAfterTime;
    if (safeFajrAfterTime.isAfter(fajrAfterTime)) {
      fajrAfterTime = safeFajrAfterTime;
    }

    DateTime? ishaCandidate;
    DateTime? ishaBeforeCandidate;
    final ishaInterval = _parameters.ishaInterval ?? 0;
    if (ishaInterval > 0) {
      ishaCandidate = dateByAddingMinutes(sunsetTime, ishaInterval);
      ishaBeforeCandidate = dateByAddingMinutes(sunsetBeforeTime, ishaInterval);
    } else {
      if (ishaAngleAvailable) {
        ishaCandidate = TimeComponents(
          solarTime.hourAngle(-_parameters.ishaAngle, true),
        ).utcDate(_date.year, _date.month, _date.day);
      }
      if (ishaBeforeAngleAvailable) {
        ishaBeforeCandidate = TimeComponents(
          solarTimeBefore.hourAngle(-_parameters.ishaAngle, true),
        ).utcDate(dateBefore.year, dateBefore.month, dateBefore.day);
      }
    }

    if (_parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55) {
      final previousNightFraction = Duration(
        seconds: (previousNightDuration.inSeconds / 7).round(),
      );
      final currentNightFraction = Duration(
        seconds: (currentNightDuration.inSeconds / 7).round(),
      );
      ishaCandidate = sunsetTime.add(currentNightFraction);
      ishaBeforeCandidate = sunsetBeforeTime.add(previousNightFraction);
    }

    final safeIshaTime = _safeIsha(sunsetTime, currentNightDuration);
    final ishaFallbackApplied =
        ishaCandidate == null || safeIshaTime.isBefore(ishaCandidate);
    var ishaTime = ishaCandidate ?? safeIshaTime;
    if (safeIshaTime.isBefore(ishaTime)) {
      ishaTime = safeIshaTime;
    }
    final safeIshaBeforeTime = _safeIsha(
      sunsetBeforeTime,
      previousNightDuration,
      year: dateBefore.year,
      dayOfYearValue: dayOfYear(dateBefore),
    );
    final ishaBeforeFallbackApplied =
        ishaBeforeCandidate == null ||
        safeIshaBeforeTime.isBefore(ishaBeforeCandidate);
    var ishaBeforeTime = ishaBeforeCandidate ?? safeIshaBeforeTime;
    if (safeIshaBeforeTime.isBefore(ishaBeforeTime)) {
      ishaBeforeTime = safeIshaBeforeTime;
    }

    var maghribTime = sunsetTime;
    if (_parameters.maghribAngle != null &&
        solarTime.canReachAltitude(
          -_parameters.maghribAngle!,
          afterTransit: true,
        )) {
      final angleBased = TimeComponents(
        solarTime.hourAngle(-1 * _parameters.maghribAngle!, true),
      ).utcDate(_date.year, _date.month, _date.day);
      if (sunsetTime.isBefore(angleBased) && ishaTime.isAfter(angleBased)) {
        maghribTime = angleBased;
      }
    }

    final fajrValue = _apply(Prayer.fajr, fajrTime);
    final sunriseValue = _apply(Prayer.sunrise, sunriseTime);
    final maghribValue = _apply(
      Prayer.maghrib,
      maghribTime,
      extraMinutes: _isRamadanOn(_date)
          ? _parameters.ramadanMaghribAdjustmentMinutes
          : 0,
    );

    final usesMoonsightingHighLatitudeRule =
        _parameters.method == CalculationMethod.moonsightingCommittee &&
        _coordinates.latitude >= 55;
    _eventSources = {
      Prayer.imsak: (fajrFallbackApplied || usesMoonsightingHighLatitudeRule)
          ? PrayerEventSource.highLatitudeFallback
          : PrayerEventSource.astronomical,
      Prayer.fajr: (fajrFallbackApplied || usesMoonsightingHighLatitudeRule)
          ? PrayerEventSource.highLatitudeFallback
          : PrayerEventSource.astronomical,
      Prayer.sunrise: sunriseAvailable
          ? PrayerEventSource.astronomical
          : PrayerEventSource.highLatitudeFallback,
      Prayer.dhuha:
          sunriseAvailable &&
              (_parameters.dhuhaAngle == null || dhuhaAngleAvailable)
          ? PrayerEventSource.astronomical
          : PrayerEventSource.highLatitudeFallback,
      Prayer.dhuhr: PrayerEventSource.astronomical,
      Prayer.asr: asrAvailable
          ? PrayerEventSource.astronomical
          : PrayerEventSource.highLatitudeFallback,
      Prayer.maghrib: sunsetAvailable
          ? PrayerEventSource.astronomical
          : PrayerEventSource.highLatitudeFallback,
      Prayer.isha: ishaInterval > 0
          ? (!sunsetAvailable
                ? PrayerEventSource.highLatitudeFallback
                : (ishaFallbackApplied
                      ? PrayerEventSource.highLatitudeFallback
                      : PrayerEventSource.calculationInterval))
          : ((ishaFallbackApplied || usesMoonsightingHighLatitudeRule)
                ? PrayerEventSource.highLatitudeFallback
                : PrayerEventSource.astronomical),
      Prayer.ishaBefore: ishaInterval > 0
          ? (!sunsetBeforeAvailable
                ? PrayerEventSource.highLatitudeFallback
                : (ishaBeforeFallbackApplied
                      ? PrayerEventSource.highLatitudeFallback
                      : PrayerEventSource.calculationInterval))
          : ((ishaBeforeFallbackApplied || usesMoonsightingHighLatitudeRule)
                ? PrayerEventSource.highLatitudeFallback
                : PrayerEventSource.astronomical),
      Prayer.fajrAfter:
          (fajrAfterFallbackApplied || usesMoonsightingHighLatitudeRule)
          ? PrayerEventSource.highLatitudeFallback
          : PrayerEventSource.astronomical,
    };
    _times = {
      Prayer.imsak: _apply(
        Prayer.imsak,
        fajrValue.subtract(const Duration(minutes: 10)),
      ),
      Prayer.fajr: fajrValue,
      Prayer.sunrise: sunriseValue,
      Prayer.dhuha: _apply(
        Prayer.dhuha,
        dhuhaTime ??
            sunriseValue.add(Duration(minutes: _parameters.dhuhaOffsetMinutes)),
      ),
      Prayer.dhuhr: _apply(Prayer.dhuhr, dhuhrTime),
      Prayer.asr: _apply(Prayer.asr, asrTime),
      Prayer.maghrib: maghribValue,
      Prayer.isha: _apply(Prayer.isha, ishaTime),
      Prayer.ishaBefore: _apply(Prayer.isha, ishaBeforeTime),
      Prayer.fajrAfter: _apply(Prayer.fajr, fajrAfterTime),
    };
  }

  final DateTime _date;
  final Coordinates _coordinates;
  final CalculationParameters _parameters;
  final bool _precision;
  final bool Function(DateTime date) _isRamadanOn;
  late final Map<Prayer, PrayerEventSource> _eventSources;
  late final Map<Prayer, DateTime> _times;

  DateTime get imsak => _requiredTime(Prayer.imsak);
  DateTime get fajr => _requiredTime(Prayer.fajr);
  DateTime get dhuha => _requiredTime(Prayer.dhuha);
  DateTime get sunrise => _requiredTime(Prayer.sunrise);
  DateTime get dhuhr => _requiredTime(Prayer.dhuhr);
  DateTime get asr => _requiredTime(Prayer.asr);
  DateTime get maghrib => _requiredTime(Prayer.maghrib);
  DateTime get isha => _requiredTime(Prayer.isha);
  DateTime get ishaBefore => _requiredTime(Prayer.ishaBefore);
  DateTime get fajrAfter => _requiredTime(Prayer.fajrAfter);

  DateTime _requiredTime(Prayer prayer) {
    final source = _eventSources[prayer];
    if (source == PrayerEventSource.unavailable) {
      throw StateError(
        'The ${prayer.name} event is unavailable for this date and location. '
        'Use eventForPrayer() to inspect event availability.',
      );
    }
    return _times[prayer]!;
  }

  /// Returns the computed value and its provenance for [prayer].
  ///
  /// A null time with [PrayerEventSource.unavailable] means the requested
  /// solar event does not occur on this date. Use this method where a caller
  /// must not treat a legacy placeholder as an observed solar event.
  PrayerEventResult eventForPrayer(Prayer prayer) {
    final source = _eventSources[prayer] ?? PrayerEventSource.unavailable;
    final time = source == PrayerEventSource.unavailable
        ? null
        : _times[prayer];
    return PrayerEventResult(prayer: prayer, time: time, source: source);
  }

  /// Returns the prayer window containing [date].
  ///
  /// Pass [locationDate] when [date] is an instant in UTC or another timezone
  /// and its civil date at the target location differs. Its year, month, and
  /// day select the location's prayer schedule.
  Prayer currentPrayer({required DateTime date, DateTime? locationDate}) {
    final at = date.toUtc();
    final schedule = locationDate == null
        ? _scheduleForInstant(at)
        : _scheduleForLocationDate(_calendarDate(locationDate));
    if (at.isBefore(schedule.fajr)) {
      return schedule.eventForPrayer(Prayer.ishaBefore).isAvailable
          ? Prayer.ishaBefore
          : Prayer.isha;
    }
    final sunriseAvailable = schedule
        .eventForPrayer(Prayer.sunrise)
        .isAvailable;
    if (sunriseAvailable && at.isBefore(schedule.sunrise)) return Prayer.fajr;
    if (at.isBefore(schedule.dhuhr)) {
      return sunriseAvailable ? Prayer.sunrise : Prayer.fajr;
    }
    final asrAvailable = schedule.eventForPrayer(Prayer.asr).isAvailable;
    if (asrAvailable && at.isBefore(schedule.asr)) return Prayer.dhuhr;
    final maghribAvailable = schedule
        .eventForPrayer(Prayer.maghrib)
        .isAvailable;
    if (maghribAvailable && at.isBefore(schedule.maghrib)) return Prayer.asr;
    final ishaAvailable = schedule.eventForPrayer(Prayer.isha).isAvailable;
    if (!ishaAvailable || at.isBefore(schedule.isha)) {
      return maghribAvailable ? Prayer.maghrib : Prayer.asr;
    }
    return Prayer.isha;
  }

  /// Returns the next prayer event by name.
  ///
  /// Pass [locationDate] when [date] is an instant in UTC or another timezone
  /// and its civil date at the target location differs. Use
  /// [nextPrayerDetails] when the event time or whether it falls on another
  /// local day is also needed.
  Prayer nextPrayer({
    DateTime? date,
    DateTime? locationDate,
    NextPrayerOptions options = const NextPrayerOptions(),
  }) {
    final at = date ?? DateTime.now();
    final instant = at.toUtc();
    final schedule = locationDate == null
        ? _scheduleForInstant(instant)
        : _scheduleForLocationDate(_calendarDate(locationDate));
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
      for (final prayer in [
        Prayer.fajr,
        Prayer.sunrise,
        Prayer.dhuha,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        final result = schedule.eventForPrayer(prayer);
        if (result.time == null) continue;
        events.add((prayer: prayer, time: result.time!, isNextDay: isNextDay));
      }
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
      isRamadanOn: _isRamadanOn,
    );
  }

  DateTime _calendarDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  /// Supplies a usable anchor when a horizon crossing does not occur.
  /// The fallback convention places sunrise and sunset six hours around
  /// transit; callers can identify these estimates through event provenance.
  DateTime _solarAnchor(
    SolarTime solarTime, {
    required bool beforeTransit,
    required bool isAvailable,
    required DateTime date,
  }) {
    final fractionalHour = isAvailable
        ? (beforeTransit ? solarTime.sunrise : solarTime.sunset)
        : solarTime.transit + (beforeTransit ? -6 : 6);
    return TimeComponents(
      fractionalHour,
    ).utcDate(date.year, date.month, date.day);
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
      case Prayer.fajr:
      case Prayer.dhuha:
      case Prayer.sunrise:
      case Prayer.dhuhr:
      case Prayer.asr:
      case Prayer.maghrib:
      case Prayer.isha:
      case Prayer.ishaBefore:
      case Prayer.fajrAfter:
        return _requiredTime(prayer);
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

  DateTime _apply(Prayer prayer, DateTime value, {int extraMinutes = 0}) {
    final user = _parameters.adjustments[prayer] ?? 0;
    final method = _parameters.methodAdjustments[prayer] ?? 0;
    final adjusted = dateByAddingMinutes(value, user + method + extraMinutes);
    return roundedMinute(adjusted.toUtc(), precision: _precision);
  }
}
