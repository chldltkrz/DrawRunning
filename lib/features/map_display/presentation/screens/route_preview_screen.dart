import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../route_generation/domain/entities/generated_route.dart';
import '../../../route_generation/presentation/providers/route_generation_provider.dart';

class RoutePreviewScreen extends ConsumerStatefulWidget {
  const RoutePreviewScreen({super.key});

  @override
  ConsumerState<RoutePreviewScreen> createState() =>
      _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends ConsumerState<RoutePreviewScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeGenerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: routeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (route) {
          if (route == null) {
            return const Center(child: Text('No route generated'));
          }
          return _buildRoutePreview(context, route);
        },
      ),
    );
  }

  Widget _buildRoutePreview(BuildContext context, GeneratedRoute route) {
    final polylines = _buildPolylines(route);
    final markers = _buildMarkers(route);
    final bounds = _calculateBounds(route.fullPolyline);

    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(route.center.latitude, route.center.longitude),
            zoom: 14,
          ),
          polylines: polylines,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit map to route bounds
            if (bounds != null) {
              Future.delayed(const Duration(milliseconds: 500), () {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 60),
                );
              });
            }
          },
        ),

        // Bottom info sheet
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildInfoSheet(context, route),
        ),
      ],
    );
  }

  Set<Polyline> _buildPolylines(GeneratedRoute route) {
    final polylines = <Polyline>{};

    for (int i = 0; i < route.segments.length; i++) {
      final segment = route.segments[i];
      final isCharacter = segment.type == RouteSegmentType.character;

      polylines.add(Polyline(
        polylineId: PolylineId('segment_$i'),
        points: segment.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        color: isCharacter ? AppTheme.routeColor : AppTheme.connectorColor,
        width: isCharacter ? 5 : 3,
        patterns: isCharacter
            ? []
            : [PatternItem.dash(10), PatternItem.gap(5)],
      ));
    }

    return polylines;
  }

  Set<Marker> _buildMarkers(GeneratedRoute route) {
    return {
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(
          route.startPoint.latitude,
          route.startPoint.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(
          route.endPoint.latitude,
          route.endPoint.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End'),
      ),
    };
  }

  LatLngBounds? _calculateBounds(List<dynamic> points) {
    if (points.isEmpty) return null;

    double minLat = double.infinity, maxLat = double.negativeInfinity;
    double minLng = double.infinity, maxLng = double.negativeInfinity;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildInfoSheet(BuildContext context, GeneratedRoute route) {
    final meta = route.metadata;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Route text
          Text(
            '"${route.inputText}"',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                Icons.straighten,
                '${(meta.totalDistanceMeters / 1000).toStringAsFixed(1)} km',
                'Distance',
              ),
              _buildStat(
                Icons.timer,
                '${meta.estimatedDurationMinutes.toStringAsFixed(0)} min',
                'Est. Time',
              ),
              _buildStat(
                Icons.text_fields,
                '${(meta.characterDistanceMeters / meta.totalDistanceMeters * 100).toStringAsFixed(0)}%',
                'Text Path',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(routeGenerationProvider.notifier).reset();
                    context.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/navigation'),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Start Run'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
