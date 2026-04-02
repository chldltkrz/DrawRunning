import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/polyline_codec.dart';
import '../../domain/entities/run_record.dart';
import '../providers/run_history_provider.dart';

class RunDetailScreen extends ConsumerStatefulWidget {
  final int runId;

  const RunDetailScreen({super.key, required this.runId});

  @override
  ConsumerState<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends ConsumerState<RunDetailScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runsAsync = ref.watch(runHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (runs) {
          final run = runs.where((r) => r.id == widget.runId).firstOrNull;
          if (run == null) {
            return const Center(child: Text('Run not found'));
          }
          return _buildDetail(context, run);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, RunRecord run) {
    final decodedPoints = PolylineCodec.decode(run.routePolyline);
    final polylineLatLngs =
        decodedPoints.map((p) => LatLng(p.$1, p.$2)).toList();
    final bounds = _calculateBounds(polylineLatLngs);

    return Column(
      children: [
        // Map section
        Expanded(
          flex: 3,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                run.startPoint.latitude,
                run.startPoint.longitude,
              ),
              zoom: 14,
            ),
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineLatLngs,
                color: AppTheme.routeColor,
                width: 5,
              ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('start'),
                position: LatLng(
                  run.startPoint.latitude,
                  run.startPoint.longitude,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Start'),
              ),
              Marker(
                markerId: const MarkerId('end'),
                position: LatLng(
                  run.endPoint.latitude,
                  run.endPoint.longitude,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: 'End'),
              ),
            },
            zoomControlsEnabled: true,
            myLocationEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (bounds != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 60),
                  );
                });
              }
            },
          ),
        ),

        // Stats section
        _buildStatsSheet(context, run),
      ],
    );
  }

  Widget _buildStatsSheet(BuildContext context, RunRecord run) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = run.date;
    final dateStr =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
        '(${weekdays[d.weekday - 1]}) '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

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

          // Text drawn
          Text(
            '"${run.inputText}"',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                Icons.straighten,
                run.formattedDistance,
                'Distance',
              ),
              _buildStat(
                Icons.timer,
                run.formattedDuration,
                'Time',
              ),
              _buildStat(
                Icons.speed,
                '${run.formattedPace}/km',
                'Pace',
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

  LatLngBounds? _calculateBounds(List<LatLng> points) {
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Run'),
        content: const Text('Are you sure you want to delete this run record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(runHistoryProvider.notifier).deleteRun(widget.runId);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
