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

    sunrise = correctedHourAngle(
      approxTransit,
      -50.0 / 60.0,
      observer,
      false,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );

    sunset = correctedHourAngle(
      approxTransit,
      -50.0 / 60.0,
      observer,
      true,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );
  }

  final Coordinates observer;
  final DateTime date;
  final double julianDayValue;

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

  double afternoon(double shadowLength) {
    final tangent = (observer.latitude - solar.declination).abs();
    final inverse = shadowLength + math.tan(degreesToRadians(tangent));
    final angle = radiansToDegrees(math.atan(1.0 / inverse));
    return hourAngle(angle, true);
  }
}
