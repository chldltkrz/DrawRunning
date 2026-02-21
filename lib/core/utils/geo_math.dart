import 'dart:math';

class GeoMath {
  GeoMath._();

  static const double _earthRadiusMeters = 6371000.0;
  static const double _metersPerDegreeLat = 111320.0;

  /// Haversine distance between two points in meters
  static double haversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Convert meter offset to latitude offset
  static double metersToLatDegrees(double meters) {
    return meters / _metersPerDegreeLat;
  }

  /// Convert meter offset to longitude offset at a given latitude
  static double metersToLngDegrees(double meters, double atLatitude) {
    final metersPerDegreeLng =
        _metersPerDegreeLat * cos(_toRadians(atLatitude));
    if (metersPerDegreeLng == 0) return 0;
    return meters / metersPerDegreeLng;
  }

  /// Interpolate between two points
  static (double lat, double lng) interpolate(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double t,
  ) {
    return (
      lat1 + t * (lat2 - lat1),
      lng1 + t * (lng2 - lng1),
    );
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}
