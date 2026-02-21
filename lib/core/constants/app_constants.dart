class AppConstants {
  AppConstants._();

  static const String appName = 'Draw Running';

  // Hershey font constants
  static const double hersheyFontHeight = 21.0;
  static const double defaultLetterSpacing = 2.0;

  // Route scale (meters per Hershey unit)
  static const double minScale = 5.0;
  static const double defaultScale = 20.0;
  static const double maxScale = 50.0;

  // Route generation
  static const double densificationSpacingMeters = 80.0;
  static const double routeSmoothingMinSpacingMeters = 5.0;
  static const double runningPaceMinPerKm = 6.0;

  // Text input
  static const int maxTextLength = 10;

  // Map
  static const double defaultZoom = 14.0;
  static const double defaultLatitude = 37.5665; // Seoul
  static const double defaultLongitude = 126.9780;
}
