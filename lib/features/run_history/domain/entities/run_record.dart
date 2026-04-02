import 'package:equatable/equatable.dart';

import '../../../../shared/models/lat_lng_point.dart';

class RunRecord extends Equatable {
  final int? id;
  final String inputText;
  final DateTime date;
  final double totalDistanceMeters;
  final int durationSeconds;
  final double paceSecondsPerKm;
  final String routePolyline;
  final String segmentsJson;
  final LatLngPoint startPoint;
  final LatLngPoint endPoint;

  const RunRecord({
    this.id,
    required this.inputText,
    required this.date,
    required this.totalDistanceMeters,
    required this.durationSeconds,
    required this.paceSecondsPerKm,
    required this.routePolyline,
    required this.segmentsJson,
    required this.startPoint,
    required this.endPoint,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inputText': inputText,
        'date': date.toIso8601String(),
        'totalDistanceMeters': totalDistanceMeters,
        'durationSeconds': durationSeconds,
        'paceSecondsPerKm': paceSecondsPerKm,
        'routePolyline': routePolyline,
        'segmentsJson': segmentsJson,
        'startLatitude': startPoint.latitude,
        'startLongitude': startPoint.longitude,
        'endLatitude': endPoint.latitude,
        'endLongitude': endPoint.longitude,
      };

  factory RunRecord.fromMap(Map<String, dynamic> map) {
    return RunRecord(
      id: map['id'] as int?,
      inputText: map['inputText'] as String,
      date: DateTime.parse(map['date'] as String),
      totalDistanceMeters: (map['totalDistanceMeters'] as num).toDouble(),
      durationSeconds: map['durationSeconds'] as int,
      paceSecondsPerKm: (map['paceSecondsPerKm'] as num).toDouble(),
      routePolyline: map['routePolyline'] as String,
      segmentsJson: map['segmentsJson'] as String,
      startPoint: LatLngPoint(
        latitude: (map['startLatitude'] as num).toDouble(),
        longitude: (map['startLongitude'] as num).toDouble(),
      ),
      endPoint: LatLngPoint(
        latitude: (map['endLatitude'] as num).toDouble(),
        longitude: (map['endLongitude'] as num).toDouble(),
      ),
    );
  }

  String get formattedDistance =>
      '${(totalDistanceMeters / 1000).toStringAsFixed(2)} km';

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedPace {
    if (paceSecondsPerKm <= 0) return '--:--';
    final paceMinutes = (paceSecondsPerKm / 60).floor();
    final paceRemainder = (paceSecondsPerKm % 60).floor();
    return '$paceMinutes:${paceRemainder.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        inputText,
        date,
        totalDistanceMeters,
        durationSeconds,
        paceSecondsPerKm,
        routePolyline,
        segmentsJson,
        startPoint,
        endPoint,
      ];
}
