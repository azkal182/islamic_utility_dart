import 'dart:math' as math;

import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/models/coordinates.dart';

class SolarTime {
  SolarTime(DateTime date, Coordinates coordinates)
    : observer = coordinates,
      julianDayValue = julianDay(date.year, date.month, date.day, 0),
      date = DateTime.utc(date.year, date.month, date.day) {
    solar = SolarCoordinates(julianDayValue);
    prevSolar = SolarCoordinates(julianDayValue - 1);
    nextSolar = SolarCoordinates(julianDayValue + 1);

    approxTransit = approximateTransit(
      observer.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
    );

    transit = correctedTransit(
      approxTransit,
      observer.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
    );

    final signedDip = observer.elevation == 0
        ? 0.0
        : observer.elevation.sign * 1.76 * math.sqrt(observer.elevation.abs());
    horizonAltitude = -(50 + signedDip) / 60.0;
    sunrise = canReachAltitude(horizonAltitude, afterTransit: false)
        ? correctedHourAngle(
            approxTransit,
            horizonAltitude,
            observer,
            false,
            solar.apparentSiderealTime,
            solar.rightAscension,
            prevSolar.rightAscension,
            nextSolar.rightAscension,
            solar.declination,
            prevSolar.declination,
            nextSolar.declination,
          )
        : transit - 6.0;

    sunset = canReachAltitude(horizonAltitude, afterTransit: true)
        ? correctedHourAngle(
            approxTransit,
            horizonAltitude,
            observer,
            true,
            solar.apparentSiderealTime,
            solar.rightAscension,
            prevSolar.rightAscension,
            nextSolar.rightAscension,
            solar.declination,
            prevSolar.declination,
            nextSolar.declination,
          )
        : transit + 6.0;
  }

  final Coordinates observer;
  final DateTime date;
  final double julianDayValue;
  late final double horizonAltitude;

  late SolarCoordinates solar;
  late SolarCoordinates prevSolar;
  late SolarCoordinates nextSolar;
  late double approxTransit;
  late double transit;
  late double sunrise;
  late double sunset;

  double hourAngle(double angle, bool afterTransit) {
    return correctedHourAngle(
      approxTransit,
      angle,
      observer,
      afterTransit,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );
  }

  /// Whether the Sun reaches [altitude] on this date at this latitude.
  ///
  /// This lets the prayer engine select its high-latitude fallback instead of
  /// treating an unreachable twilight angle as a real event near transit.
  bool canReachAltitude(double altitude, {required bool afterTransit}) {
    return correctedHourAngle(
      approxTransit,
      altitude,
      observer,
      afterTransit,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    ).isFinite;
  }

  /// Solar-center altitude for [shadowLength] at Asr.
  double afternoonAltitude(double shadowLength) {
    final declinationAtTransit = interpolate(
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
      approxTransit,
    )!;
    final tangent = (observer.latitude - declinationAtTransit).abs();
    final inverse = shadowLength + math.tan(degreesToRadians(tangent));
    return radiansToDegrees(math.atan(1.0 / inverse));
  }

  double afternoon(double shadowLength) {
    return hourAngle(afternoonAltitude(shadowLength), true);
  }
}
