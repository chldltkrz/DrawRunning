import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/lat_lng_point.dart';
import '../../data/datasources/location_datasource.dart';

final locationDatasourceProvider = Provider<LocationDatasource>((ref) {
  return LocationDatasource();
});

final currentLocationProvider = FutureProvider<LatLngPoint>((ref) async {
  final datasource = ref.watch(locationDatasourceProvider);
  return datasource.getCurrentLocation();
});

final locationStreamProvider = StreamProvider<LatLngPoint>((ref) {
  final datasource = ref.watch(locationDatasourceProvider);
  return datasource.getLocationStream();
});
