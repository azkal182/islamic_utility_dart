import 'dart:math' as math;

import 'package:islamic_utility/src/models/coordinates.dart';
import 'package:islamic_utility/src/models/shafaq.dart';

double degreesToRadians(double degrees) => (degrees * math.pi) / 180.0;

double radiansToDegrees(double radians) => (radians * 180.0) / math.pi;

double normalizeToScale(double number, double max) {
  return number - (max * (number / max).floor());
}

double unwindAngle(double angle) => normalizeToScale(angle, 360.0);

double quadrantShiftAngle(double angle) {
  if (angle >= -180 && angle <= 180) {
    return angle;
  }
  return angle - (360 * (angle / 360).round());
}

double julianDay(int year, int month, int day, [double hours = 0]) {
  final y = (month > 2 ? year : year - 1).truncate();
  final m = (month > 2 ? month : month + 12).truncate();
  final d = day + (hours / 24.0);
  final a = (y / 100).truncate();
  final b = (2 - a + (a / 4).truncate()).truncate();
  final i0 = (365.25 * (y + 4716)).truncate();
  final i1 = (30.6001 * (m + 1)).truncate();
  return i0 + i1 + d + b - 1524.5;
}

double julianCentury(double jd) => (jd - 2451545.0) / 36525.0;

double meanSolarLongitude(double t) {
  final l0 = 280.4664567 + (36000.76983 * t) + (0.0003032 * t * t);
  return unwindAngle(l0);
}

double meanLunarLongitude(double t) {
  return unwindAngle(218.3165 + (481267.8813 * t));
}

double ascendingLunarNodeLongitude(double t) {
  final omega =
      125.04452 - (1934.136261 * t) + (0.0020708 * t * t) + ((t * t * t) / 450000);
  return unwindAngle(omega);
}

double meanSolarAnomaly(double t) {
  return unwindAngle(357.52911 + (35999.05029 * t) - (0.0001537 * t * t));
}

double solarEquationOfTheCenter(double t, double m) {
  final mRad = degreesToRadians(m);
  final term1 = (1.914602 - (0.004817 * t) - (0.000014 * t * t)) * math.sin(mRad);
  final term2 = (0.019993 - (0.000101 * t)) * math.sin(2 * mRad);
  final term3 = 0.000289 * math.sin(3 * mRad);
  return term1 + term2 + term3;
}

double apparentSolarLongitude(double t, double l0) {
  final longitude = l0 + solarEquationOfTheCenter(t, meanSolarAnomaly(t));
  final omega = 125.04 - (1934.136 * t);
  final lambda = longitude - 0.00569 - (0.00478 * math.sin(degreesToRadians(omega)));
  return unwindAngle(lambda);
}

double meanObliquityOfTheEcliptic(double t) {
  return 23.439291 -
      (0.013004167 * t) -
      (0.0000001639 * t * t) +
      (0.0000005036 * t * t * t);
}

double apparentObliquityOfTheEcliptic(double t, double epsilon0) {
  final o = 125.04 - (1934.136 * t);
  return epsilon0 + (0.00256 * math.cos(degreesToRadians(o)));
}

double meanSiderealTime(double t) {
  final jd = (t * 36525) + 2451545.0;
  final theta = 280.46061837 +
      (360.98564736629 * (jd - 2451545)) +
      (0.000387933 * t * t) -
      ((t * t * t) / 38710000);
  return unwindAngle(theta);
}

double nutationInLongitude(double t, double l0, double lp, double omega) {
  final term1 = (-17.2 / 3600) * math.sin(degreesToRadians(omega));
  final term2 = (1.32 / 3600) * math.sin(2 * degreesToRadians(l0));
  final term3 = (0.23 / 3600) * math.sin(2 * degreesToRadians(lp));
  final term4 = (0.21 / 3600) * math.sin(2 * degreesToRadians(omega));
  return term1 - term2 - term3 + term4;
}

double nutationInObliquity(double t, double l0, double lp, double omega) {
  final term1 = (9.2 / 3600) * math.cos(degreesToRadians(omega));
  final term2 = (0.57 / 3600) * math.cos(2 * degreesToRadians(l0));
  final term3 = (0.10 / 3600) * math.cos(2 * degreesToRadians(lp));
  final term4 = (0.09 / 3600) * math.cos(2 * degreesToRadians(omega));
  return term1 + term2 + term3 - term4;
}

double? interpolate(double y2, double? y1, double y3, double n) {
  final a = y2 - (y1 ?? 0);
  final b = y3 - y2;
  final c = b - a;
  return y2 + ((n / 2.0) * (a + b + (n * c)));
}

double? interpolateAngles(double y2, double? y1, double y3, double n) {
  final a = unwindAngle(y2 - (y1 ?? 0));
  final b = unwindAngle(y3 - y2);
  final c = b - a;
  return y2 + ((n / 2.0) * (a + b + (n * c)));
}

double altitudeOfCelestialBody(double latitude, double declination, double localHourAngle) {
  return radiansToDegrees(
    math.asin(
      (math.sin(degreesToRadians(latitude)) * math.sin(degreesToRadians(declination))) +
          (math.cos(degreesToRadians(latitude)) *
              math.cos(degreesToRadians(declination)) *
              math.cos(degreesToRadians(localHourAngle))),
    ),
  );
}

double approximateTransit(double longitude, double siderealTime, double rightAscension) {
  final lw = longitude * -1;
  return normalizeToScale((rightAscension + lw - siderealTime) / 360.0, 1.0);
}

double correctedTransit(
  double m0,
  double longitude,
  double siderealTime,
  double rightAscension,
  double? previousRightAscension,
  double nextRightAscension,
) {
  final lw = longitude * -1;
  final theta = unwindAngle(siderealTime + (360.985647 * m0));
  final a = unwindAngle(
    interpolateAngles(rightAscension, previousRightAscension, nextRightAscension, m0)!,
  );
  final h = quadrantShiftAngle(theta - lw - a);
  final dm = h / -360.0;
  return (m0 + dm) * 24.0;
}

double correctedHourAngle(
  double m0,
  double h0,
  Coordinates coordinates,
  bool afterTransit,
  double siderealTime,
  double rightAscension,
  double? previousRightAscension,
  double nextRightAscension,
  double declination,
  double? previousDeclination,
  double nextDeclination,
) {
  final lw = coordinates.longitude * -1;
  final term1 = math.sin(degreesToRadians(h0)) -
      (math.sin(degreesToRadians(coordinates.latitude)) *
          math.sin(degreesToRadians(declination)));
  final term2 =
      math.cos(degreesToRadians(coordinates.latitude)) * math.cos(degreesToRadians(declination));
  final ratio = term1 / term2;
  final h0Angle = ratio.abs() > 1 ? 1.0 : radiansToDegrees(math.acos(ratio));

  final m = afterTransit ? m0 + (h0Angle / 360.0) : m0 - (h0Angle / 360.0);
  final theta = unwindAngle(siderealTime + (360.985647 * m));
  final a = unwindAngle(
    interpolateAngles(rightAscension, previousRightAscension, nextRightAscension, m)!,
  );
  final delta = interpolate(declination, previousDeclination, nextDeclination, m)!;
  final h = theta - lw - a;
  final altitude = altitudeOfCelestialBody(coordinates.latitude, delta, h);
  final term3 = altitude - h0;
  final term4 =
      360.0 * math.cos(degreesToRadians(delta)) * math.cos(degreesToRadians(coordinates.latitude)) * math.sin(degreesToRadians(h));
  final dm = term3 / term4;
  return (m + dm) * 24.0;
}

class SolarCoordinates {
  SolarCoordinates(double jd) {
    final t = julianCentury(jd);
    final l0 = meanSolarLongitude(t);
    final lp = meanLunarLongitude(t);
    final omega = ascendingLunarNodeLongitude(t);
    final lambda = degreesToRadians(apparentSolarLongitude(t, l0));
    final theta0 = meanSiderealTime(t);
    final dPsi = nutationInLongitude(t, l0, lp, omega);
    final dEpsilon = nutationInObliquity(t, l0, lp, omega);
    final epsilon0 = meanObliquityOfTheEcliptic(t);
    final epsilonApparent =
        degreesToRadians(apparentObliquityOfTheEcliptic(t, epsilon0));

    declination =
        radiansToDegrees(math.asin(math.sin(epsilonApparent) * math.sin(lambda)));
    rightAscension = unwindAngle(
      radiansToDegrees(math.atan2(math.cos(epsilonApparent) * math.sin(lambda), math.cos(lambda))),
    );
    apparentSiderealTime =
        theta0 + ((dPsi * 3600) * math.cos(degreesToRadians(epsilon0 + dEpsilon)) / 3600);
  }

  late double declination;
  late double rightAscension;
  late double apparentSiderealTime;
}

class TimeComponents {
  TimeComponents(double value) {
    hours = value.floor();
    minutes = ((value - hours) * 60).floor();
    seconds = ((value - (hours + (minutes / 60))) * 3600).floor();
  }

  late int hours;
  late int minutes;
  late int seconds;

  DateTime utcDate(int year, int month, int day) {
    return DateTime.utc(year, month, day, hours, minutes, seconds);
  }
}

DateTime dateByAddingSeconds(DateTime date, int seconds) => date.add(Duration(seconds: seconds));

DateTime dateByAddingMinutes(DateTime date, int minutes) => dateByAddingSeconds(date, minutes * 60);

int dayOfYear(DateTime date) {
  final diff = date.difference(DateTime.utc(date.year, 1, 1));
  return diff.inDays + 1;
}

bool _isLeapYear(int year) {
  if (year % 400 == 0) return true;
  if (year % 100 == 0) return false;
  return year % 4 == 0;
}

int daysSinceSolstice(int dayOfYearValue, int year, double latitude) {
  final daysInYear = _isLeapYear(year) ? 366 : 365;
  const northernOffset = 10;
  final southernOffset = _isLeapYear(year) ? 173 : 172;

  if (latitude >= 0) {
    var d = dayOfYearValue + northernOffset;
    if (d >= daysInYear) d -= daysInYear;
    return d;
  }

  var d = dayOfYearValue - southernOffset;
  if (d < 0) d += daysInYear;
  return d;
}

double _seasonalAdjustment(double a, double b, double c, double d, int dyy) {
  if (dyy < 91) return a + ((b - a) / 91.0 * dyy);
  if (dyy < 137) return b + ((c - b) / 46.0 * (dyy - 91));
  if (dyy < 183) return c + ((d - c) / 46.0 * (dyy - 137));
  if (dyy < 229) return d + ((c - d) / 46.0 * (dyy - 183));
  if (dyy < 275) return c + ((b - c) / 46.0 * (dyy - 229));
  return b + ((a - b) / 91.0 * (dyy - 275));
}

DateTime seasonAdjustedMorningTwilight(
  double latitude,
  int dayOfYearValue,
  int year,
  DateTime sunrise,
) {
  final lat = latitude.abs();
  final a = 75 + ((28.65 / 55.0) * lat);
  final b = 75 + ((19.44 / 55.0) * lat);
  final c = 75 + ((32.74 / 55.0) * lat);
  final d = 75 + ((48.10 / 55.0) * lat);
  final dyy = daysSinceSolstice(dayOfYearValue, year, latitude);
  final adjustment = _seasonalAdjustment(a, b, c, d, dyy);
  return dateByAddingSeconds(sunrise, (adjustment * -60.0).round());
}

DateTime seasonAdjustedEveningTwilight(
  double latitude,
  int dayOfYearValue,
  int year,
  DateTime sunset, {
  Shafaq shafaq = Shafaq.general,
}) {
  final lat = latitude.abs();
  late final double a;
  late final double b;
  late final double c;
  late final double d;

  if (shafaq == Shafaq.ahmer) {
    a = 62 + ((17.4 / 55.0) * lat);
    b = 62 - ((7.16 / 55.0) * lat);
    c = 62 + ((5.12 / 55.0) * lat);
    d = 62 + ((19.44 / 55.0) * lat);
  } else if (shafaq == Shafaq.abyad) {
    a = 75 + ((25.60 / 55.0) * lat);
    b = 75 + ((7.16 / 55.0) * lat);
    c = 75 + ((36.84 / 55.0) * lat);
    d = 75 + ((81.84 / 55.0) * lat);
  } else {
    a = 75 + ((25.60 / 55.0) * lat);
    b = 75 + ((2.050 / 55.0) * lat);
    c = 75 - ((9.210 / 55.0) * lat);
    d = 75 + ((6.140 / 55.0) * lat);
  }

  final dyy = daysSinceSolstice(dayOfYearValue, year, latitude);
  final adjustment = _seasonalAdjustment(a, b, c, d, dyy);
  return dateByAddingSeconds(sunset, (adjustment * 60.0).round());
}

DateTime roundedMinute(DateTime date, {required bool precision}) {
  if (precision) return date;
  final seconds = date.toUtc().second % 60;
  final offset = seconds >= 30 ? 60 - seconds : -seconds;
  return dateByAddingSeconds(date, offset);
}
