import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../route_generation/domain/entities/generated_route.dart';
import '../../../route_generation/presentation/providers/route_generation_provider.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  GoogleMapController? _mapController;
  bool _isRunning = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _distanceCovered = 0;
  LatLngPoint? _lastPosition;

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startRun() {
    setState(() {
      _isRunning = true;
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  void _pauseRun() {
    setState(() {
      _isRunning = false;
      _stopwatch.stop();
      _timer?.cancel();
    });
  }

  void _stopRun() {
    _pauseRun();
    _stopwatch.reset();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run Complete!'),
        content: Text(
          'Distance: ${(_distanceCovered / 1000).toStringAsFixed(2)} km\n'
          'Time: ${_formatDuration(_stopwatch.elapsed)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeGenerationProvider);
    final locationStream = ref.watch(locationStreamProvider);

    // Track distance
    locationStream.whenData((position) {
      if (_isRunning && _lastPosition != null) {
        _distanceCovered += GeoMath.haversine(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }
      _lastPosition = position;

      // Follow user on map
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    });

    return Scaffold(
      body: routeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (route) {
          if (route == null) {
            return const Center(child: Text('No route'));
          }
          return _buildNavigation(context, route);
        },
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, GeneratedRoute route) {
    return Stack(
      children: [
        // Full-screen map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              route.startPoint.latitude,
              route.startPoint.longitude,
            ),
            zoom: 16,
          ),
          polylines: _buildRoutePolylines(route),
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: LatLng(
                route.startPoint.latitude,
                route.startPoint.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('end'),
              position: LatLng(
                route.endPoint.latitude,
                route.endPoint.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),

        // Top bar with back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
        ),

        // Bottom control panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControlPanel(route),
        ),
      ],
    );
  }

  Set<Polyline> _buildRoutePolylines(GeneratedRoute route) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: route.fullPolyline
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        color: AppTheme.routeColor,
        width: 5,
      ),
    };
  }

  Widget _buildControlPanel(GeneratedRoute route) {
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavStat(
                (_distanceCovered / 1000).toStringAsFixed(2),
                'km',
              ),
              _buildNavStat(
                _formatDuration(_stopwatch.elapsed),
                'time',
              ),
              _buildNavStat(
                _calculatePace(),
                'min/km',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRunning) ...[
                _buildControlButton(
                  Icons.pause,
                  'Pause',
                  Colors.orange,
                  _pauseRun,
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  Icons.stop,
                  'Stop',
                  Colors.red,
                  _stopRun,
                ),
              ] else ...[
                _buildControlButton(
                  Icons.play_arrow,
                  _stopwatch.elapsed.inSeconds > 0 ? 'Resume' : 'Start',
                  AppTheme.secondaryColor,
                  _startRun,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
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

  Widget _buildControlButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _calculatePace() {
    if (_distanceCovered < 10) return '--:--';
    final paceSeconds = _stopwatch.elapsed.inSeconds / (_distanceCovered / 1000);
    final paceMinutes = (paceSeconds / 60).floor();
    final paceRemainder = (paceSeconds % 60).floor();
    return '$paceMinutes:${paceRemainder.toString().padLeft(2, '0')}';
  }
}
