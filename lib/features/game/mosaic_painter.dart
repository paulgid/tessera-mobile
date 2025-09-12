import 'package:flutter/material.dart';
import '../../core/models/tile.dart';

class MosaicPainter extends CustomPainter {
  final Map<String, Tile> tiles;
  final int width;
  final int height;
  
  // Virtualization settings
  static const int bufferTiles = 5;
  
  MosaicPainter({
    required this.tiles,
    required this.width,
    required this.height,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final tileSize = size.width / width;
    
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade900,
    );
    
    // Draw tiles
    for (final tile in tiles.values) {
      _drawTile(canvas, tile, tileSize);
    }
  }
  
  void _drawTile(Canvas canvas, Tile tile, double tileSize) {
    final rect = Rect.fromLTWH(
      tile.x * tileSize,
      tile.y * tileSize,
      tileSize,
      tileSize,
    );
    
    // Base tile color
    final paint = Paint()
      ..color = tile.color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(rect, paint);
    
    // Draw claim overlay if claimed
    if (tile.isClaimed && tile.claimIntensity > 0) {
      final overlayPaint = Paint()
        ..color = Colors.white.withOpacity(tile.claimIntensity * 0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(rect, overlayPaint);
      
      // Draw pattern if available
      if (tile.pattern != null) {
        _drawPattern(canvas, rect, tile.pattern!);
      }
    }
    
    // Draw border for better visibility
    if (tileSize > 5) {
      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      canvas.drawRect(rect, borderPaint);
    }
  }
  
  void _drawPattern(Canvas canvas, Rect rect, String pattern) {
    final patternPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    switch (pattern) {
      case 'diagonal':
        canvas.drawLine(
          rect.topLeft,
          rect.bottomRight,
          patternPaint,
        );
        break;
      case 'cross':
        canvas.drawLine(
          rect.topLeft,
          rect.bottomRight,
          patternPaint,
        );
        canvas.drawLine(
          rect.topRight,
          rect.bottomLeft,
          patternPaint,
        );
        break;
      case 'dots':
        final center = rect.center;
        canvas.drawCircle(center, rect.width / 4, patternPaint);
        break;
      default:
        break;
    }
  }
  
  @override
  bool shouldRepaint(MosaicPainter oldDelegate) {
    return tiles != oldDelegate.tiles ||
           width != oldDelegate.width ||
           height != oldDelegate.height;
  }
}