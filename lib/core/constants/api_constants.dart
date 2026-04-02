class ApiConstants {
  ApiConstants._();

  // Injected at build time via --dart-define=GOOGLE_MAPS_API_KEY=xxx
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String roadsApiBaseUrl = 'https://roads.googleapis.com';
  static const String directionsApiBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  static const int roadsApiMaxPoints = 100;
  static const int roadsApiChunkSize = 95;
  static const int roadsApiChunkOverlap = 5;
}
