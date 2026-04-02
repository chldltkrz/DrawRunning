import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../location/data/datasources/location_datasource.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../route_generation/data/datasources/directions_api_datasource.dart';
import '../../../route_generation/data/datasources/roads_api_datasource.dart';
import '../../../route_generation/domain/usecases/generate_full_route.dart';
import '../../../route_generation/presentation/providers/route_generation_provider.dart';
import '../../../text_to_path/presentation/providers/text_path_provider.dart';
import '../../../text_to_path/presentation/widgets/text_preview_canvas.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _textController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStrokes = ref.watch(textStrokesProvider);
    final scale = ref.watch(routeScaleProvider);
    final estimatedLength = ref.watch(estimatedRouteLengthProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    final routeState = ref.watch(routeGenerationProvider);
    final fontAsync = ref.watch(fontInitProvider);

    // Listen for route generation completion or error
    ref.listen<AsyncValue>(routeGenerationProvider, (prev, next) {
      if (next is AsyncData && next.value != null) {
        context.push('/route-preview');
      } else if (next is AsyncError) {
        _showRouteError(next.error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppStrings.runHistory,
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: fontAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('${AppStrings.errorFontLoading}: $e'),
        ),
        data: (_) => _buildContent(
          context,
          textStrokes,
          scale,
          estimatedLength,
          locationAsync,
          routeState,
        ),
      ),
    );
  }

  void _showRouteError(Object error) {
    String message = AppStrings.errorRouteGeneration;

    if (error is DirectionsApiException || error is RoadsApiException) {
      final isTimeout = (error is DirectionsApiException && error.isTimeout) ||
          (error is RoadsApiException && error.isTimeout);
      message = isTimeout ? AppStrings.errorTimeout : AppStrings.errorApiFailure;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppStrings.retry,
          onPressed: () {
            final location = ref.read(currentLocationProvider).valueOrNull;
            if (location != null) {
              ref.read(routeGenerationProvider.notifier).generateRoute(location);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<List<Offset>> textStrokes,
    double scale,
    double estimatedLength,
    AsyncValue<LatLngPoint> locationAsync,
    AsyncValue routeState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text input
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: AppStrings.textInputLabel,
              hintText: AppStrings.textInputHint,
              suffixText:
                  '${_textController.text.length}/${AppConstants.maxTextLength}',
            ),
            maxLength: AppConstants.maxTextLength,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              ref.read(textInputProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),

          // Text preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: textStrokes.isEmpty
                ? const Center(
                    child: Text(
                      AppStrings.textPreviewPlaceholder,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : TextPreviewCanvas(strokes: textStrokes),
          ),
          const SizedBox(height: 16),

          // Scale slider
          Row(
            children: [
              const Icon(Icons.straighten, size: 20),
              const SizedBox(width: 8),
              const Text(AppStrings.routeSize),
              Expanded(
                child: Slider(
                  value: scale,
                  min: AppConstants.minScale,
                  max: AppConstants.maxScale,
                  divisions: 9,
                  label: _getScaleLabel(scale),
                  onChanged: (value) {
                    ref.read(routeScaleProvider.notifier).state = value;
                  },
                ),
              ),
            ],
          ),

          // Estimated length
          if (estimatedLength > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                AppStrings.estimatedRoute.replaceFirst(
                  '{km}',
                  (estimatedLength / 1000).toStringAsFixed(1),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

          // Mini map
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: locationAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildLocationError(e),
              data: (location) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(location.latitude, location.longitude),
                  zoom: AppConstants.defaultZoom,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generate button
          _buildGenerateButton(locationAsync, routeState),
        ],
      ),
    );
  }

  Widget _buildLocationError(Object error) {
    String title = AppStrings.locationUnavailable;
    String? message;
    bool showSettings = false;

    if (error is LocationServiceDisabledError) {
      title = AppStrings.locationServiceDisabled;
      message = AppStrings.locationServiceDisabledMessage;
    } else if (error is LocationPermissionPermanentlyDeniedError) {
      title = AppStrings.locationPermissionPermanentlyDenied;
      message = AppStrings.locationPermissionPermanentlyDeniedMessage;
      showSettings = true;
    } else if (error is LocationPermissionDeniedError) {
      title = AppStrings.locationPermissionDenied;
      message = AppStrings.locationPermissionDeniedMessage;
      showSettings = true;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => ref.refresh(currentLocationProvider),
                  child: const Text(AppStrings.retry),
                ),
                if (showSettings)
                  TextButton(
                    onPressed: () => _openAppSettings(),
                    child: const Text(AppStrings.openSettings),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    // Uses geolocator's built-in settings opener
    await Geolocator.openAppSettings();
  }

  Widget _buildGenerateButton(
    AsyncValue<LatLngPoint> locationAsync,
    AsyncValue routeState,
  ) {
    final text = ref.watch(textInputProvider);
    final isLoading = routeState is AsyncLoading;
    final canGenerate = text.isNotEmpty && locationAsync is AsyncData;
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    if (isLoading) {
      return _buildLoadingButton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  AppStrings.networkOffline,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: canGenerate && isOnline
              ? () {
                  final location =
                      (locationAsync as AsyncData<LatLngPoint>).value;
                  ref
                      .read(routeGenerationProvider.notifier)
                      .generateRoute(location);
                }
              : null,
          icon: const Icon(Icons.route),
          label: const Text(AppStrings.generateRoute),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingButton() {
    final step = ref.watch(generationStepProvider);
    final progress = ref.watch(generationProgressProvider);

    String stepText;
    double overallProgress;

    switch (step) {
      case GenerationStep.snappingToRoads:
        stepText = AppStrings.findingRoads;
        overallProgress = progress * 0.4;
        break;
      case GenerationStep.orderingStrokes:
        stepText = AppStrings.optimizingOrder;
        overallProgress = 0.4 + progress * 0.1;
        break;
      case GenerationStep.connectingRoute:
        stepText = AppStrings.connectingRoute;
        overallProgress = 0.5 + progress * 0.4;
        break;
      case GenerationStep.assembling:
        stepText = AppStrings.assembling;
        overallProgress = 0.9 + progress * 0.1;
        break;
      default:
        stepText = AppStrings.generating;
        overallProgress = 0;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: overallProgress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(overallProgress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: Text(stepText),
        ),
      ],
    );
  }

  String _getScaleLabel(double scale) {
    if (scale <= 10) return AppStrings.scaleSmall;
    if (scale <= 25) return AppStrings.scaleMedium;
    if (scale <= 40) return AppStrings.scaleLarge;
    return AppStrings.scaleXL;
  }
}
