import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../text_to_path/domain/entities/geo_stroke.dart';
import '../../data/datasources/directions_api_datasource.dart';
import '../../data/datasources/roads_api_datasource.dart';
import '../entities/generated_route.dart';

enum GenerationStep {
  snappingToRoads,
  orderingStrokes,
  connectingRoute,
  assembling,
  done,
}

/// Orchestrator that generates a full runnable route from geo strokes.
class GenerateFullRoute {
  final RoadsApiDatasource _roadsApi;
  final DirectionsApiDatasource _directionsApi;

  GenerateFullRoute(this._roadsApi, this._directionsApi);

  /// Generates a complete route with progress callbacks.
  Future<GeneratedRoute> execute(
    String inputText,
    List<GeoStroke> geoStrokes,
    LatLngPoint userLocation, {
    void Function(GenerationStep step, double progress)? onProgress,
  }) async {
    if (geoStrokes.isEmpty) {
      throw Exception('No strokes to generate route from');
    }

    // Stage 1: Snap each stroke to roads
    onProgress?.call(GenerationStep.snappingToRoads, 0);
    final snappedStrokes = <List<LatLngPoint>>[];

    for (int i = 0; i < geoStrokes.length; i++) {
      final snapped = await _roadsApi.snapToRoads(geoStrokes[i].points);
      snappedStrokes.add(snapped);
      onProgress?.call(
        GenerationStep.snappingToRoads,
        (i + 1) / geoStrokes.length,
      );
    }

    // Stage 2: Order strokes by proximity (greedy nearest-neighbor)
    onProgress?.call(GenerationStep.orderingStrokes, 0);
    final orderedStrokes = _orderStrokesByProximity(
      snappedStrokes,
      userLocation,
    );
    onProgress?.call(GenerationStep.orderingStrokes, 1);

    // Stage 3: Connect strokes using Directions API
    onProgress?.call(GenerationStep.connectingRoute, 0);
    final segments = <RouteSegment>[];
    final fullPolyline = <LatLngPoint>[];

    for (int i = 0; i < orderedStrokes.length; i++) {
      final stroke = orderedStrokes[i];

      // Add character stroke segment
      segments.add(RouteSegment(
        points: stroke,
        type: RouteSegmentType.character,
      ));
      fullPolyline.addAll(stroke);

      // Connect to next stroke if not the last
      if (i < orderedStrokes.length - 1) {
        final nextStroke = orderedStrokes[i + 1];
        final connectorResult = await _directionsApi.getWalkingRoute(
          origin: stroke.last,
          destination: nextStroke.first,
        );

        if (connectorResult.polylinePoints.length > 1) {
          segments.add(RouteSegment(
            points: connectorResult.polylinePoints,
            type: RouteSegmentType.connector,
          ));
          // Skip first point of connector (same as last of stroke)
          fullPolyline.addAll(connectorResult.polylinePoints.skip(1));
        }
      }

      onProgress?.call(
        GenerationStep.connectingRoute,
        (i + 1) / orderedStrokes.length,
      );
    }

    // Stage 4: Assemble final route
    onProgress?.call(GenerationStep.assembling, 0);

    // Smooth route (remove points too close together)
    final smoothed = _smoothRoute(
      fullPolyline,
      AppConstants.routeSmoothingMinSpacingMeters,
    );

    // Calculate metadata
    final metadata = _calculateMetadata(segments);

    onProgress?.call(GenerationStep.assembling, 1);
    onProgress?.call(GenerationStep.done, 1);

    return GeneratedRoute(
      inputText: inputText,
      fullPolyline: smoothed,
      segments: segments,
      metadata: metadata,
      startPoint: smoothed.first,
      endPoint: smoothed.last,
      center: userLocation,
    );
  }

  /// Orders strokes using greedy nearest-endpoint heuristic.
  /// Each stroke can be traversed forward or reversed.
  List<List<LatLngPoint>> _orderStrokesByProximity(
    List<List<LatLngPoint>> strokes,
    LatLngPoint startPoint,
  ) {
    if (strokes.length <= 1) return strokes;

    final remaining = List<List<LatLngPoint>>.from(strokes);
    final ordered = <List<LatLngPoint>>[];

    // Start with stroke nearest to user location
    var currentEnd = startPoint;

    while (remaining.isNotEmpty) {
      int bestIndex = 0;
      bool bestReversed = false;
      double bestDistance = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final stroke = remaining[i];
        if (stroke.isEmpty) continue;

        // Check distance to start
        final distToStart = GeoMath.haversine(
          currentEnd.latitude,
          currentEnd.longitude,
          stroke.first.latitude,
          stroke.first.longitude,
        );

        // Check distance to end (reversed)
        final distToEnd = GeoMath.haversine(
          currentEnd.latitude,
          currentEnd.longitude,
          stroke.last.latitude,
          stroke.last.longitude,
        );

        if (distToStart < bestDistance) {
          bestDistance = distToStart;
          bestIndex = i;
          bestReversed = false;
        }
        if (distToEnd < bestDistance) {
          bestDistance = distToEnd;
          bestIndex = i;
          bestReversed = true;
        }
      }

      var bestStroke = remaining.removeAt(bestIndex);
      if (bestReversed) {
        bestStroke = bestStroke.reversed.toList();
      }

      ordered.add(bestStroke);
      currentEnd = bestStroke.last;
    }

    return ordered;
  }

  /// Remove points that are too close together.
  List<LatLngPoint> _smoothRoute(
    List<LatLngPoint> route,
    double minSpacingMeters,
  ) {
    if (route.length < 2) return route;

    final smoothed = <LatLngPoint>[route.first];

    for (int i = 1; i < route.length; i++) {
      final distance = GeoMath.haversine(
        smoothed.last.latitude,
        smoothed.last.longitude,
        route[i].latitude,
        route[i].longitude,
      );

      if (distance >= minSpacingMeters) {
        smoothed.add(route[i]);
      }
    }

    // Always include last point
    if (smoothed.last != route.last) {
      smoothed.add(route.last);
    }

    return smoothed;
  }

  /// Calculate route metadata from segments.
  RouteMetadata _calculateMetadata(List<RouteSegment> segments) {
    double characterDistance = 0;
    double connectorDistance = 0;

    for (final segment in segments) {
      double segmentDistance = 0;
      for (int i = 1; i < segment.points.length; i++) {
        segmentDistance += GeoMath.haversine(
          segment.points[i - 1].latitude,
          segment.points[i - 1].longitude,
          segment.points[i].latitude,
          segment.points[i].longitude,
        );
      }

      if (segment.type == RouteSegmentType.character) {
        characterDistance += segmentDistance;
      } else {
        connectorDistance += segmentDistance;
      }
    }

    final totalDistance = characterDistance + connectorDistance;
    // Estimated time at 6 min/km running pace
    final estimatedMinutes =
        (totalDistance / 1000) * AppConstants.runningPaceMinPerKm;

    return RouteMetadata(
      totalDistanceMeters: totalDistance,
      estimatedDurationMinutes: estimatedMinutes,
      characterDistanceMeters: characterDistance,
      connectorDistanceMeters: connectorDistance,
    );
  }
}
