import 'package:flutter/material.dart';

class CustomPawIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CustomPawIcon({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: PawPainter(color: color),
    );
  }
}

class PawPainter extends CustomPainter {
  final Color color;

  PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 100; // Scale based on size

    // Main paw pad (bottom center, oval shape)
    final mainPadRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 15 * scale),
      width: 35 * scale,
      height: 25 * scale,
    );
    canvas.drawOval(mainPadRect, paint);

    // Four toe pads (smaller circles arranged like a real paw)
    final toeRadius = 8 * scale;
    
    // Top left toe
    canvas.drawCircle(
      Offset(centerX - 18 * scale, centerY - 12 * scale),
      toeRadius,
      paint,
    );
    
    // Top right toe
    canvas.drawCircle(
      Offset(centerX + 18 * scale, centerY - 12 * scale),
      toeRadius,
      paint,
    );
    
    // Middle left toe
    canvas.drawCircle(
      Offset(centerX - 8 * scale, centerY - 22 * scale),
      toeRadius,
      paint,
    );
    
    // Middle right toe
    canvas.drawCircle(
      Offset(centerX + 8 * scale, centerY - 22 * scale),
      toeRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is! PawPainter || oldDelegate.color != color;
  }
}
