import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final paw = PawIconGenerator();
  await paw.generatePawIcon();
}

class PawIconGenerator {
  Future<void> generatePawIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 512.0; // High resolution for app icon
    
    // Draw background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF2196F3) // Blue background
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      bgPaint,
    );
    
    // Draw paw print
    final pawPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final centerX = size / 2;
    final centerY = size / 2;
    final scale = size / 200; // Scale for 512px
    
    // Main paw pad (bottom center, oval shape)
    final mainPadRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 30 * scale),
      width: 80 * scale,
      height: 50 * scale,
    );
    canvas.drawOval(mainPadRect, pawPaint);
    
    // Four toe pads (smaller circles arranged like a real paw)
    final toeRadius = 18 * scale;
    
    // Top left toe
    canvas.drawCircle(
      Offset(centerX - 40 * scale, centerY - 20 * scale),
      toeRadius,
      pawPaint,
    );
    
    // Top right toe
    canvas.drawCircle(
      Offset(centerX + 40 * scale, centerY - 20 * scale),
      toeRadius,
      pawPaint,
    );
    
    // Middle left toe
    canvas.drawCircle(
      Offset(centerX - 20 * scale, centerY - 45 * scale),
      toeRadius,
      pawPaint,
    );
    
    // Middle right toe
    canvas.drawCircle(
      Offset(centerX + 20 * scale, centerY - 45 * scale),
      toeRadius,
      pawPaint,
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.round(), size.round());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    
    // Note: This is a template - you would need to save this to assets/images/paw_icon.png
    print('Generated paw icon with ${pngBytes.length} bytes');
  }
}
