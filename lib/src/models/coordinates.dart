class Coordinates {
  const Coordinates(this.latitude, this.longitude, {this.elevation = 0})
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;

  /// Elevation above mean sea level, in meters. Defaults to sea level.
  final double elevation;
}
