import 'package:equatable/equatable.dart';

import '../../../../shared/models/lat_lng_point.dart';

enum RouteSegmentType { character, connector }

class RouteSegment extends Equatable {
  final List<LatLngPoint> points;
  final RouteSegmentType type;
  final String? characterLabel;

  const RouteSegment({
    required this.points,
    required this.type,
    this.characterLabel,
  });

  @override
  List<Object?> get props => [points, type, characterLabel];
}

class RouteMetadata extends Equatable {
  final double totalDistanceMeters;
  final double estimatedDurationMinutes;
  final double characterDistanceMeters;
  final double connectorDistanceMeters;

  const RouteMetadata({
    required this.totalDistanceMeters,
    required this.estimatedDurationMinutes,
    required this.characterDistanceMeters,
    required this.connectorDistanceMeters,
  });

  @override
  List<Object?> get props => [
        totalDistanceMeters,
        estimatedDurationMinutes,
        characterDistanceMeters,
        connectorDistanceMeters,
      ];
}

class GeneratedRoute extends Equatable {
  final String inputText;
  final List<LatLngPoint> fullPolyline;
  final List<RouteSegment> segments;
  final RouteMetadata metadata;
  final LatLngPoint startPoint;
  final LatLngPoint endPoint;
  final LatLngPoint center;

  const GeneratedRoute({
    required this.inputText,
    required this.fullPolyline,
    required this.segments,
    required this.metadata,
    required this.startPoint,
    required this.endPoint,
    required this.center,
  });

  @override
  List<Object?> get props => [
        inputText,
        fullPolyline,
        segments,
        metadata,
        startPoint,
        endPoint,
        center,
      ];
}
