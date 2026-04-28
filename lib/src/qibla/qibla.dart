import 'dart:math' as math;

import 'package:islamic_utility/src/core/astronomy.dart';
import 'package:islamic_utility/src/models/coordinates.dart';

class Qibla {
  static const _makkahLatitude = 21.4225241;
  static const _makkahLongitude = 39.8261818;

  static double qibla(Coordinates coordinates) {
    final lat = degreesToRadians(coordinates.latitude);
    final lon = degreesToRadians(coordinates.longitude);
    final makkahLat = degreesToRadians(_makkahLatitude);
    final makkahLon = degreesToRadians(_makkahLongitude);
    final deltaLon = makkahLon - lon;

    final y = math.sin(deltaLon);
    final x = math.cos(lat) * math.tan(makkahLat) - math.sin(lat) * math.cos(deltaLon);
    final bearing = radiansToDegrees(math.atan2(y, x));
    return unwindAngle(bearing);
  }
}
