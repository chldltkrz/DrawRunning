import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../../../shared/models/lat_lng_point.dart';

class DirectionsResult {
  final List<LatLngPoint> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;

  const DirectionsResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class DirectionsApiDatasource {
  final Dio _dio;

  DirectionsApiDatasource(this._dio);

  /// Gets a walking route between two points.
  Future<DirectionsResult> getWalkingRoute({
    required LatLngPoint origin,
    required LatLngPoint destination,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.directionsApiBaseUrl,
        queryParameters: {
          'origin': origin.toApiString(),
          'destination': destination.toApiString(),
          'mode': 'walking',
          'key': ApiConstants.googleMapsApiKey,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        // Return direct line if no route found
        return DirectionsResult(
          polylinePoints: [origin, destination],
          distanceMeters: 0,
          durationSeconds: 0,
        );
      }

      final route = routes[0] as Map<String, dynamic>;
      final overviewPolyline =
          route['overview_polyline'] as Map<String, dynamic>;
      final encodedPoints = overviewPolyline['points'] as String;

      final decodedPoints = PolylineCodec.decode(encodedPoints);
      final points = decodedPoints
          .map((p) => LatLngPoint(latitude: p.$1, longitude: p.$2))
          .toList();

      // Sum up leg distances
      final legs = route['legs'] as List<dynamic>;
      double totalDistance = 0;
      double totalDuration = 0;
      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        totalDistance +=
            ((legMap['distance'] as Map<String, dynamic>)['value'] as num)
                .toDouble();
        totalDuration +=
            ((legMap['duration'] as Map<String, dynamic>)['value'] as num)
                .toDouble();
      }

      return DirectionsResult(
        polylinePoints: points,
        distanceMeters: totalDistance,
        durationSeconds: totalDuration,
      );
    } on DioException {
      // Fallback to direct line
      return DirectionsResult(
        polylinePoints: [origin, destination],
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }
  }
}
