import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/lat_lng_point.dart';

class SnappedPoint {
  final LatLngPoint location;
  final String placeId;
  final int? originalIndex;

  const SnappedPoint({
    required this.location,
    required this.placeId,
    this.originalIndex,
  });

  factory SnappedPoint.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>;
    return SnappedPoint(
      location: LatLngPoint(
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
      ),
      placeId: json['placeId'] as String? ?? '',
      originalIndex: json['originalIndex'] as int?,
    );
  }
}

class RoadsApiException implements Exception {
  final String message;
  final bool isTimeout;
  const RoadsApiException(this.message, {this.isTimeout = false});
  @override
  String toString() => message;
}

class RoadsApiDatasource {
  final Dio _dio;
  int _consecutiveErrors = 0;

  RoadsApiDatasource(this._dio);

  /// Snaps a list of points to the nearest roads.
  /// Handles chunking for the 100-point API limit.
  Future<List<LatLngPoint>> snapToRoads(List<LatLngPoint> path) async {
    if (path.isEmpty) return [];

    final allSnapped = <LatLngPoint>[];
    const chunkSize = ApiConstants.roadsApiChunkSize;
    const overlap = ApiConstants.roadsApiChunkOverlap;

    for (int i = 0; i < path.length; i += chunkSize) {
      final start = i == 0 ? 0 : i - overlap;
      final end =
          (i + chunkSize).clamp(0, path.length);
      final chunk = path.sublist(start, end);

      final snappedChunk = await _snapChunk(chunk);

      if (allSnapped.isNotEmpty && i > 0) {
        // Skip overlapping points from previous chunk
        final skipCount = overlap.clamp(0, snappedChunk.length);
        allSnapped.addAll(snappedChunk.skip(skipCount));
      } else {
        allSnapped.addAll(snappedChunk);
      }
    }

    return allSnapped;
  }

  Future<List<LatLngPoint>> _snapChunk(List<LatLngPoint> chunk) async {
    final pathStr = chunk.map((p) => p.toApiString()).join('|');

    try {
      final response = await _dio.get(
        '${ApiConstants.roadsApiBaseUrl}/v1/snapToRoads',
        queryParameters: {
          'path': pathStr,
          'interpolate': 'true',
          'key': ApiConstants.googleMapsApiKey,
        },
      );

      _consecutiveErrors = 0;

      final data = response.data as Map<String, dynamic>;
      final snappedPoints = data['snappedPoints'] as List<dynamic>?;

      if (snappedPoints == null || snappedPoints.isEmpty) {
        return chunk;
      }

      return snappedPoints
          .map((sp) => SnappedPoint.fromJson(sp as Map<String, dynamic>))
          .map((sp) => sp.location)
          .toList();
    } on DioException catch (e) {
      _consecutiveErrors++;

      if (_consecutiveErrors >= 3) {
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;
        throw RoadsApiException(
          isTimeout ? 'timeout' : 'network',
          isTimeout: isTimeout,
        );
      }

      // Fallback to original points for isolated errors
      return chunk;
    }
  }

  void resetErrorCount() {
    _consecutiveErrors = 0;
  }
}
