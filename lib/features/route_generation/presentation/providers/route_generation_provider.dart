import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../text_to_path/presentation/providers/text_path_provider.dart';
import '../../data/datasources/directions_api_datasource.dart';
import '../../data/datasources/roads_api_datasource.dart';
import '../../domain/entities/generated_route.dart';
import '../../domain/usecases/generate_full_route.dart';

// Dio instance
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
});

// API datasources
final roadsApiProvider = Provider<RoadsApiDatasource>((ref) {
  return RoadsApiDatasource(ref.watch(dioProvider));
});

final directionsApiProvider = Provider<DirectionsApiDatasource>((ref) {
  return DirectionsApiDatasource(ref.watch(dioProvider));
});

// Generate full route use case
final generateFullRouteProvider = Provider<GenerateFullRoute>((ref) {
  return GenerateFullRoute(
    ref.watch(roadsApiProvider),
    ref.watch(directionsApiProvider),
  );
});

// Generation step for progress display
final generationStepProvider = StateProvider<GenerationStep?>((ref) => null);
final generationProgressProvider = StateProvider<double>((ref) => 0);

// Generated route state
class RouteGenerationNotifier extends StateNotifier<AsyncValue<GeneratedRoute?>> {
  final Ref _ref;

  RouteGenerationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generateRoute(LatLngPoint userLocation) async {
    state = const AsyncValue.loading();

    try {
      if (ApiConstants.googleMapsApiKey.isEmpty) {
        state = AsyncValue.error(
          'Google Maps API 키가 설정되지 않았습니다.\n--dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY 로 빌드해 주세요.',
          StackTrace.current,
        );
        return;
      }

      final text = _ref.read(textInputProvider);
      final geoStrokes = _ref.read(geoStrokesProvider(userLocation));

      if (geoStrokes.isEmpty) {
        state = AsyncValue.error(
          'No text to generate route from',
          StackTrace.current,
        );
        return;
      }

      final generator = _ref.read(generateFullRouteProvider);
      final route = await generator.execute(
        text,
        geoStrokes,
        userLocation,
        onProgress: (step, progress) {
          _ref.read(generationStepProvider.notifier).state = step;
          _ref.read(generationProgressProvider.notifier).state = progress;
        },
      );

      state = AsyncValue.data(route);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
    _ref.read(generationStepProvider.notifier).state = null;
    _ref.read(generationProgressProvider.notifier).state = 0;
  }
}

final routeGenerationProvider =
    StateNotifierProvider<RouteGenerationNotifier, AsyncValue<GeneratedRoute?>>(
  (ref) => RouteGenerationNotifier(ref),
);
