import 'dart:math';

import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final Offset p1;
  final Offset p2;
  final Color color;
  final String type;
  final double strokeWidth;

  LinePainter(
      {required this.p1,
      required this.p2,
      required this.color,
      this.type = "normal", // normal | dashed
      this.strokeWidth = 1});

  // Draw dashed line
  void drawDashedLine(
      {required Canvas canvas,
      required Offset p1,
      required Offset p2,
      required int dashWidth,
      required int dashSpace,
      required Paint paint}) {
    // Get normalized distance vector from p1 to p2
    var dx = p2.dx - p1.dx;
    var dy = p2.dy - p1.dy;
    final magnitude = sqrt(dx * dx + dy * dy);
    dx = dx / magnitude;
    dy = dy / magnitude;

    // Compute number of dash segments
    final steps = magnitude ~/ (dashWidth + dashSpace);

    var startX = p1.dx;
    var startY = p1.dy;

    for (int i = 0; i < steps; i++) {
      final endX = startX + dx * dashWidth;
      final endY = startY + dy * dashWidth;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (type == "dashed") {
      drawDashedLine(
        canvas: canvas,
        p1: p1,
        p2: p2,
        dashWidth: 2,
        dashSpace: 3,
        paint: paint,
      );
    } else {
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
