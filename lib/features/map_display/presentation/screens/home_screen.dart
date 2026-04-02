import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../location/presentation/providers/location_provider.dart';
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

    // Listen for route generation completion
    ref.listen<AsyncValue>(routeGenerationProvider, (prev, next) {
      if (next is AsyncData && next.value != null) {
        context.push('/route-preview');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Run History',
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      body: fontAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Font loading error: $e')),
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
              labelText: 'Enter text to draw',
              hintText: 'e.g., HELLO',
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
                      'Type text above to see preview',
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
              const Text('Route Size'),
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
                'Estimated route: ${(estimatedLength / 1000).toStringAsFixed(1)} km',
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
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Location unavailable',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(currentLocationProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
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

  Widget _buildGenerateButton(
    AsyncValue<LatLngPoint> locationAsync,
    AsyncValue routeState,
  ) {
    final text = ref.watch(textInputProvider);
    final isLoading = routeState is AsyncLoading;
    final canGenerate = text.isNotEmpty && locationAsync is AsyncData;

    if (isLoading) {
      return _buildLoadingButton();
    }

    return ElevatedButton.icon(
      onPressed: canGenerate
          ? () {
              final location = (locationAsync as AsyncData<LatLngPoint>).value;
              ref
                  .read(routeGenerationProvider.notifier)
                  .generateRoute(location);
            }
          : null,
      icon: const Icon(Icons.route),
      label: const Text('Generate Route'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildLoadingButton() {
    final step = ref.watch(generationStepProvider);
    final progress = ref.watch(generationProgressProvider);

    String stepText;
    switch (step) {
      case GenerationStep.snappingToRoads:
        stepText = 'Finding roads...';
        break;
      case GenerationStep.orderingStrokes:
        stepText = 'Optimizing order...';
        break;
      case GenerationStep.connectingRoute:
        stepText = 'Connecting route...';
        break;
      case GenerationStep.assembling:
        stepText = 'Assembling...';
        break;
      default:
        stepText = 'Generating...';
    }

    return Column(
      children: [
        LinearProgressIndicator(value: progress),
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
    if (scale <= 10) return 'Small';
    if (scale <= 25) return 'Medium';
    if (scale <= 40) return 'Large';
    return 'XL';
  }
}
