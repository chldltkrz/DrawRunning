import 'package:equatable/equatable.dart';

class LatLngPoint extends Equatable {
  final double latitude;
  final double longitude;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
  });

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  String toApiString() => '$latitude,$longitude';

  @override
  List<Object?> get props => [latitude, longitude];
}
