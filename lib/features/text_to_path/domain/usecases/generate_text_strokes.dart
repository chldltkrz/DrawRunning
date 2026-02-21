import 'dart:ui';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/hershey_font_datasource.dart';

/// Converts input text into pixel-space strokes using Hershey Simplex font.
class GenerateTextStrokes {
  final HersheyFontDatasource _fontDatasource;

  GenerateTextStrokes(this._fontDatasource);

  /// Returns a list of strokes in pixel coordinates, centered around origin.
  List<List<Offset>> execute(String text) {
    if (text.isEmpty) return [];

    final allStrokes = <List<Offset>>[];
    double cursorX = 0.0;
    const scaleFactor = 1.0; // Keep in Hershey units
    const letterSpacing = AppConstants.defaultLetterSpacing * scaleFactor;

    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i);
      var glyph = _fontDatasource.getGlyph(charCode);

      // Try uppercase fallback for lowercase
      if (glyph == null && charCode >= 97 && charCode <= 122) {
        glyph = _fontDatasource.getGlyph(charCode - 32);
      }

      if (glyph == null) {
        // Skip unsupported characters, advance cursor by space width
        cursorX += 10 * scaleFactor + letterSpacing;
        continue;
      }

      for (final stroke in glyph.strokes) {
        final translatedStroke = stroke.map((point) {
          return Offset(
            point.dx * scaleFactor + cursorX,
            point.dy * scaleFactor,
          );
        }).toList();
        allStrokes.add(translatedStroke);
      }

      cursorX += glyph.width * scaleFactor + letterSpacing;
    }

    if (allStrokes.isEmpty) return [];

    // Center the text around origin
    final totalWidth = cursorX - letterSpacing;
    final offsetX = totalWidth / 2;
    const offsetY = AppConstants.hersheyFontHeight / 2;

    return allStrokes.map((stroke) {
      return stroke.map((point) {
        return Offset(point.dx - offsetX, point.dy - offsetY);
      }).toList();
    }).toList();
  }
}
