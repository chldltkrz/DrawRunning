import 'dart:ui';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../entities/geo_stroke.dart';

/// Projects pixel-space strokes to geographic (LatLng) coordinates
/// and densifies them for road snapping.
class ProjectStrokesToGeo {
  /// Projects strokes centered at [center] with given [metersPerUnit] scale.
  List<GeoStroke> execute(
    List<List<Offset>> pixelStrokes,
    LatLngPoint center,
    double metersPerUnit,
  ) {
    final geoStrokes = <GeoStroke>[];

    for (final stroke in pixelStrokes) {
      final geoPoints = <LatLngPoint>[];

      for (final point in stroke) {
        // Convert pixel offset to meters
        final dxMeters = point.dx * metersPerUnit; // East-West
        final dyMeters = -point.dy * metersPerUnit; // North-South (flip Y)

        // Convert meters to lat/lng offset
        final dLat = GeoMath.metersToLatDegrees(dyMeters);
        final dLng = GeoMath.metersToLngDegrees(dxMeters, center.latitude);

        geoPoints.add(LatLngPoint(
          latitude: center.latitude + dLat,
          longitude: center.longitude + dLng,
        ));
      }

      // Densify the stroke
      final densified = _densify(
        geoPoints,
        AppConstants.densificationSpacingMeters,
      );

      geoStrokes.add(GeoStroke(points: densified));
    }

    return geoStrokes;
  }

  /// Interpolate additional points along stroke so that consecutive points
  /// are no more than [maxSpacingMeters] apart.
  List<LatLngPoint> _densify(
    List<LatLngPoint> points,
    double maxSpacingMeters,
  ) {
    if (points.length < 2) return points;

    final densified = <LatLngPoint>[points.first];

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final distance = GeoMath.haversine(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      if (distance > maxSpacingMeters) {
        final numSegments = (distance / maxSpacingMeters).ceil();
        for (int j = 1; j <= numSegments; j++) {
          final t = j / numSegments;
          final (lat, lng) = GeoMath.interpolate(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude,
            t,
          );
          densified.add(LatLngPoint(latitude: lat, longitude: lng));
        }
      } else {
        densified.add(curr);
      }
    }

    return densified;
  }
}
