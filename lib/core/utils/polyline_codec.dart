/// Decodes Google's encoded polyline format into a list of (lat, lng) pairs.
/// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
class PolylineCodec {
  PolylineCodec._();

  static List<(double lat, double lng)> decode(String encoded) {
    final points = <(double, double)>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add((lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
