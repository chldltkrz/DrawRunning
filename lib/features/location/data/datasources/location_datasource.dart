import 'package:geolocator/geolocator.dart';

import '../../../../shared/models/lat_lng_point.dart';

/// Custom exception types for granular error handling in the UI.
class LocationServiceDisabledError implements Exception {
  const LocationServiceDisabledError();
}

class LocationPermissionDeniedError implements Exception {
  const LocationPermissionDeniedError();
}

class LocationPermissionPermanentlyDeniedError implements Exception {
  const LocationPermissionPermanentlyDeniedError();
}

class LocationDatasource {
  Future<LatLngPoint> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledError();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedError();
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedError();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLngPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Stream<LatLngPoint> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((position) => LatLngPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ));
  }
}
