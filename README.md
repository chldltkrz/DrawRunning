# draw_running

A new Flutter project.

## Getting Started

### Prerequisites

- Flutter SDK
- A Google Maps API key with Maps SDK for Android, Maps SDK for iOS, Roads API, and Directions API enabled

### Running the App

Pass your Google Maps API key via `--dart-define` at build time:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_KEY
```

For building a release:

```bash
flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_KEY
flutter build ios --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_KEY
```

### Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)
