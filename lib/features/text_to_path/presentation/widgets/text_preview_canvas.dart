import 'package:flutter/material.dart';

/// CustomPainter that renders Hershey font strokes as a real-time preview.
class TextPreviewCanvas extends StatelessWidget {
  final List<List<Offset>> strokes;

  const TextPreviewCanvas({super.key, required this.strokes});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StrokePainter(strokes: strokes),
      size: const Size(double.infinity, 120),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _StrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Find bounds of all strokes
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke) {
        if (point.dx < minX) minX = point.dx;
        if (point.dx > maxX) maxX = point.dx;
        if (point.dy < minY) minY = point.dy;
        if (point.dy > maxY) maxY = point.dy;
      }
    }

    if (minX == double.infinity) return;

    final strokeWidth = maxX - minX;
    final strokeHeight = maxY - minY;
    if (strokeWidth <= 0 || strokeHeight <= 0) return;

    // Calculate scale to fit within canvas with padding
    const padding = 16.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final scale = (availableWidth / strokeWidth)
        .clamp(0, availableHeight / strokeHeight)
        .toDouble();

    // Center offset
    final scaledWidth = strokeWidth * scale;
    final scaledHeight = strokeHeight * scale;
    final offsetX = (size.width - scaledWidth) / 2 - minX * scale;
    final offsetY = (size.height - scaledHeight) / 2 - minY * scale;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(
        stroke.first.dx * scale + offsetX,
        stroke.first.dy * scale + offsetY,
      );

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(
          stroke[i].dx * scale + offsetX,
          stroke[i].dy * scale + offsetY,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
