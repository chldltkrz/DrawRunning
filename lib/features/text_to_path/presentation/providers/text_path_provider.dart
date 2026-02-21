import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../data/datasources/hershey_font_datasource.dart';
import '../../domain/entities/geo_stroke.dart';
import '../../domain/usecases/generate_text_strokes.dart';
import '../../domain/usecases/project_strokes_to_geo.dart';

// Font datasource singleton
final hersheyFontProvider = Provider<HersheyFontDatasource>((ref) {
  return HersheyFontDatasource();
});

// Font initialization
final fontInitProvider = FutureProvider<void>((ref) async {
  final datasource = ref.watch(hersheyFontProvider);
  await datasource.loadFont();
});

// User text input
final textInputProvider = StateProvider<String>((ref) => '');

// Route scale (meters per Hershey unit)
final routeScaleProvider = StateProvider<double>(
  (ref) => AppConstants.defaultScale,
);

// Generate text strokes use case
final generateTextStrokesProvider = Provider<GenerateTextStrokes>((ref) {
  final fontDatasource = ref.watch(hersheyFontProvider);
  return GenerateTextStrokes(fontDatasource);
});

// Project strokes to geo use case
final projectStrokesToGeoProvider = Provider<ProjectStrokesToGeo>((ref) {
  return ProjectStrokesToGeo();
});

// Computed pixel strokes (recomputes on text change)
final textStrokesProvider = Provider<List<List<Offset>>>((ref) {
  final text = ref.watch(textInputProvider);
  if (text.isEmpty) return [];

  // Ensure font is loaded
  final fontAsync = ref.watch(fontInitProvider);
  if (fontAsync is! AsyncData) return [];

  final generateStrokes = ref.watch(generateTextStrokesProvider);
  return generateStrokes.execute(text);
});

// Computed geo strokes (recomputes on text, location, or scale change)
final geoStrokesProvider =
    Provider.family<List<GeoStroke>, LatLngPoint>((ref, center) {
  final pixelStrokes = ref.watch(textStrokesProvider);
  if (pixelStrokes.isEmpty) return [];

  final scale = ref.watch(routeScaleProvider);
  final projectToGeo = ref.watch(projectStrokesToGeoProvider);
  return projectToGeo.execute(pixelStrokes, center, scale);
});

// Estimated route length based on text and scale
final estimatedRouteLengthProvider = Provider<double>((ref) {
  final text = ref.watch(textInputProvider);
  final scale = ref.watch(routeScaleProvider);
  if (text.isEmpty) return 0;

  // Rough estimate: ~40 Hershey units per character on average
  // Each unit = scale meters
  const avgUnitsPerChar = 40.0;
  return text.length * avgUnitsPerChar * scale;
});
