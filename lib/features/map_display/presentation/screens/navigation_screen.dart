import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/geo_math.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../../../shared/models/lat_lng_point.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../../route_generation/domain/entities/generated_route.dart';
import '../../../route_generation/presentation/providers/route_generation_provider.dart';
import '../../../run_history/domain/entities/run_record.dart';
import '../../../run_history/presentation/providers/run_history_provider.dart';

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
  bool _listenerInstalled = false;

  void _installLocationListener() {
    if (_listenerInstalled) return;
    _listenerInstalled = true;
    ref.listen<AsyncValue<LatLngPoint>>(locationStreamProvider, (prev, next) {
      next.whenData((position) {
        if (_isRunning && _lastPosition != null) {
          setState(() {
            _distanceCovered += GeoMath.haversine(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
          });
        }
        _lastPosition = position;

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      });
    });
  }

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

  Future<void> _stopRun() async {
    _pauseRun();

    final elapsed = _stopwatch.elapsed;
    final distance = _distanceCovered;
    final durationSeconds = elapsed.inSeconds;
    final paceSecondsPerKm =
        distance >= 10 ? durationSeconds / (distance / 1000) : 0.0;

    // Save run record
    bool saved = false;
    final routeState = ref.read(routeGenerationProvider);
    final route = routeState.valueOrNull;
    if (route != null) {
      final encodedPolyline = PolylineCodec.encode(
        route.fullPolyline
            .map((p) => (p.latitude, p.longitude))
            .toList(),
      );
      final segmentsJson = jsonEncode(
        route.segments
            .map((s) => {
                  'type': s.type.name,
                  'characterLabel': s.characterLabel,
                  'pointCount': s.points.length,
                })
            .toList(),
      );

      final record = RunRecord(
        inputText: route.inputText,
        date: DateTime.now(),
        totalDistanceMeters: distance,
        durationSeconds: durationSeconds,
        paceSecondsPerKm: paceSecondsPerKm,
        routePolyline: encodedPolyline,
        segmentsJson: segmentsJson,
        startPoint: route.startPoint,
        endPoint: route.endPoint,
      );

      try {
        await ref.read(runHistoryProvider.notifier).addRun(record);
        saved = true;
      } catch (_) {
        saved = false;
      }
    }

    _stopwatch.reset();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(saved ? AppStrings.runComplete : AppStrings.runComplete),
        content: Text(
          '${AppStrings.distance}: ${(distance / 1000).toStringAsFixed(2)} km\n'
          '${AppStrings.time}: ${_formatDuration(elapsed)}'
          '${saved ? '' : '\n\n기록 저장에 실패했습니다.'}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: const Text(AppStrings.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeGenerationProvider);
    _installLocationListener();

    return Scaffold(
      body: routeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('${AppStrings.errorGeneric}: $e'),
        ),
        data: (route) {
          if (route == null) {
            return Center(child: Text(AppStrings.noRouteGenerated));
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
                AppStrings.km,
              ),
              _buildNavStat(
                _formatDuration(_stopwatch.elapsed),
                AppStrings.time,
              ),
              _buildNavStat(
                _calculatePace(),
                AppStrings.minPerKm,
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
                  AppStrings.pause,
                  Colors.orange,
                  _pauseRun,
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  Icons.stop,
                  AppStrings.stop,
                  Colors.red,
                  _stopRun,
                ),
              ] else ...[
                _buildControlButton(
                  Icons.play_arrow,
                  _stopwatch.elapsed.inSeconds > 0
                      ? AppStrings.resume
                      : AppStrings.start,
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
