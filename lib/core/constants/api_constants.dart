class ApiConstants {
  ApiConstants._();

  // Replace with your actual Google Maps API key
  // For Dart-side HTTP calls (Roads API, Directions API)
  static const String googleMapsApiKey = 'YOUR_API_KEY_HERE';

  static const String roadsApiBaseUrl = 'https://roads.googleapis.com';
  static const String directionsApiBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  static const int roadsApiMaxPoints = 100;
  static const int roadsApiChunkSize = 95;
  static const int roadsApiChunkOverlap = 5;
}
