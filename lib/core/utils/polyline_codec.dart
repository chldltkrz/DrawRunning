/// Encodes/decodes Google's encoded polyline format.
/// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
class PolylineCodec {
  PolylineCodec._();

  static String encode(List<(double lat, double lng)> points) {
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final (lat, lng) in points) {
      final iLat = (lat * 1e5).round();
      final iLng = (lng * 1e5).round();
      _encodeValue(iLat - prevLat, buffer);
      _encodeValue(iLng - prevLng, buffer);
      prevLat = iLat;
      prevLng = iLng;
    }

    return buffer.toString();
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1F)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

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
