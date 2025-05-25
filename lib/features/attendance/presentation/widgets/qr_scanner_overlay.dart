import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mytuition/config/theme/app_colors.dart';

class QRScannerOverlay extends CustomPainter {
  final Color borderColor;
  final Color scanLineColor;
  final double scanLinePosition;
  final bool showScanLine;

  QRScannerOverlay({
    required this.borderColor,
    required this.scanLineColor,
    required this.scanLinePosition,
    this.showScanLine = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Calculate scanner area size (70% of the smaller dimension)
    final scanAreaSize = min(screenWidth, screenHeight) * 0.7;

    // Define scanner area rect
    final scanRect = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw semi-transparent overlay
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw full screen background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, screenWidth, screenHeight), backgroundPaint);

    // Cut out the scan area
    canvas.drawRect(scanRect, Paint()..blendMode = BlendMode.clear);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(scanRect, borderPaint);

    // Draw corner markers
    final cornerLength = scanAreaSize * 0.1;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );

    // Draw scan line if enabled
    if (showScanLine) {
      final scanLinePaint = Paint()
        ..color = scanLineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final lineY = scanRect.top + (scanRect.height * scanLinePosition);
      canvas.drawLine(
        Offset(scanRect.left, lineY),
        Offset(scanRect.right, lineY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QRScannerOverlay oldDelegate) {
    return oldDelegate.scanLinePosition != scanLinePosition ||
        oldDelegate.showScanLine != showScanLine;
  }
}
