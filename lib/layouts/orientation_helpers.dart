import 'package:camera_360/layouts/device_rotation.dart';
import 'package:camera_360/layouts/line_painter.dart';
import 'package:flutter/material.dart';

class OrientationHelpers extends StatefulWidget {
  // Helper Dot
  final double helperDotPosX;
  final double helperDotPosY;
  final double helperDotRadius;
  final Color helperDotColor;
  // Centered dot
  final double centeredDotPosX;
  final double centeredDotRadius;
  final double centeredDotPosY;
  final double centeredDotBorder;
  final Color centeredDotColor;
  // Device rotation
  final bool isDeviceRotationCorrect;
  final double deviceRotationDeg;

  const OrientationHelpers({
    super.key,
    required this.helperDotPosX,
    required this.helperDotPosY,
    required this.helperDotRadius,
    required this.helperDotColor,
    required this.centeredDotPosX,
    required this.centeredDotRadius,
    required this.centeredDotPosY,
    required this.centeredDotBorder,
    required this.centeredDotColor,
    required this.isDeviceRotationCorrect,
    required this.deviceRotationDeg,
  });

  @override
  State<OrientationHelpers> createState() => _OrientationHelpersState();
}

class _OrientationHelpersState extends State<OrientationHelpers> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // This draws a line between two dots
        CustomPaint(
          painter: LinePainter(
              p1: Offset(
                widget.centeredDotPosX + widget.centeredDotRadius + 2,
                widget.centeredDotPosY + widget.centeredDotRadius + 2,
              ),
              p2: Offset(
                widget.helperDotPosX + widget.helperDotRadius + 2,
                widget.helperDotPosY + widget.helperDotRadius + 2,
              ),
              color: widget.helperDotColor,
              type: 'dashed',
              strokeWidth: 2),
        ),

        // Centered outlined dot
        Transform.translate(
          offset: Offset(widget.centeredDotPosX, widget.centeredDotPosY),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  width: widget.centeredDotBorder,
                  color: Colors.white,
                )),
            child: CircleAvatar(
              radius: widget.centeredDotRadius,
              backgroundColor: widget.centeredDotColor,
            ),
          ),
        ),

        // Helper dot
        Transform.translate(
          offset: Offset(widget.helperDotPosX, widget.helperDotPosY),
          child: CircleAvatar(
            radius: widget.helperDotRadius,
            backgroundColor: widget.helperDotColor,
          ),
        ),

        // Centered min dot
        Transform.translate(
          offset: Offset(widget.centeredDotPosX + widget.centeredDotRadius - 1,
              widget.centeredDotPosY + widget.centeredDotRadius - 1),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  width: widget.centeredDotBorder,
                  color: widget.helperDotColor,
                )),
            child: CircleAvatar(
              radius: 1,
              backgroundColor: widget.helperDotColor,
            ),
          ),
        ),

        // Draw Device Rotaion helper
        widget.isDeviceRotationCorrect
            ? Container()
            : DeviceRotation(deviceRotation: widget.deviceRotationDeg),
      ],
    );
  }
}
