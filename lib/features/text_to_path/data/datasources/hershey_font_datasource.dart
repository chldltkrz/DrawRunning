import 'dart:convert';

import 'package:flutter/services.dart';

class HersheyGlyph {
  final int charCode;
  final double width;
  final List<List<Offset>> strokes;

  const HersheyGlyph({
    required this.charCode,
    required this.width,
    required this.strokes,
  });
}

class HersheyFontDatasource {
  Map<int, HersheyGlyph>? _glyphCache;

  Future<Map<int, HersheyGlyph>> loadFont() async {
    if (_glyphCache != null) return _glyphCache!;

    final jsonString =
        await rootBundle.loadString('assets/fonts/hershey_simplex.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final characters = data['characters'] as Map<String, dynamic>;

    final glyphs = <int, HersheyGlyph>{};

    for (final entry in characters.entries) {
      final charCode = int.parse(entry.key);
      final charData = entry.value as Map<String, dynamic>;
      final width = (charData['width'] as num).toDouble();
      final strokesData = charData['strokes'] as List<dynamic>;

      final strokes = strokesData.map((strokeData) {
        final points = (strokeData as List<dynamic>).map((point) {
          final p = point as List<dynamic>;
          return Offset(
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          );
        }).toList();
        return points;
      }).toList();

      glyphs[charCode] = HersheyGlyph(
        charCode: charCode,
        width: width,
        strokes: strokes,
      );
    }

    _glyphCache = glyphs;
    return glyphs;
  }

  HersheyGlyph? getGlyph(int charCode) {
    return _glyphCache?[charCode];
  }
}
