import '../../../../shared/models/lat_lng_point.dart';

class GeoStroke {
  final List<LatLngPoint> points;
  final bool isCharacterStroke;

  const GeoStroke({
    required this.points,
    this.isCharacterStroke = true,
  });
}
