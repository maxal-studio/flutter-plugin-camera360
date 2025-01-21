import 'package:camera_360/layouts/device_rotation.dart';
import 'package:camera_360/layouts/line_painter.dart';
import 'package:flutter/material.dart';

class OrientationHelpers extends StatefulWidget {
  // Helper Dot
  // Helper dot X position
  final double helperDotPosX;
  // Helper dot Y position
  final double helperDotPosY;
  // Helper dot radius
  final double helperDotRadius;
  // Helper dot color
  final Color helperDotColor;

  // Centered dot
  // Centered dot X position
  final double centeredDotPosX;
  // Centered dot Y position
  final double centeredDotPosY;
  // Centered dot radius
  final double centeredDotRadius;
  // Centered dot border size
  final double centeredDotBorder;
  // Centered dot color
  final Color centeredDotColor;
  // Device in correct position
  final bool deviceInCorrectPosition;
  // Device rotation
  final bool isDeviceRotationCorrect;
  // Device rotation deg
  final double deviceRotationDeg;
  // Is waiting to take photo
  final bool isWaitingToTakePhoto;
  // Time to wait before taking picture
  final int timeToWaitBeforeTakingPicture;

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
    required this.deviceInCorrectPosition,
    required this.isDeviceRotationCorrect,
    required this.deviceRotationDeg,
    required this.isWaitingToTakePhoto,
    required this.timeToWaitBeforeTakingPicture,
  });

  @override
  State<OrientationHelpers> createState() => _OrientationHelpersState();
}

class _OrientationHelpersState extends State<OrientationHelpers>
    // SingleTickerProviderStateMixin is required for animations
    with
        SingleTickerProviderStateMixin {
  // Controller for managing the progress animation
  late AnimationController _controller;
  // Animation object that handles the progress value from 0 to 1
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with the specified duration
    _controller = AnimationController(
      vsync:
          this, // vsync prevents offscreen animations from consuming resources
      duration: Duration(milliseconds: widget.timeToWaitBeforeTakingPicture),
    );
    // Create a linear animation that goes from 0 to 1
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(OrientationHelpers oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If device moved out of position, stop animation immediately
    if (!widget.deviceInCorrectPosition && oldWidget.deviceInCorrectPosition) {
      _controller.stop();
      _controller.reset();
      return;
    }

    // Check if we should start the animation
    if (widget.isWaitingToTakePhoto &&
        !oldWidget.isWaitingToTakePhoto &&
        widget.deviceInCorrectPosition) {
      _controller.reset();
      _controller.forward();
    }
    // Check if waiting was cancelled
    else if (!widget.isWaitingToTakePhoto && oldWidget.isWaitingToTakePhoto) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    // Clean up the animation controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

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

        // Helper dot
        Transform.translate(
          offset: Offset(widget.helperDotPosX, widget.helperDotPosY),
          child: CircleAvatar(
            radius: widget.helperDotRadius,
            backgroundColor: widget.helperDotColor,
          ),
        ),

        // Centered outlined dot
        Transform.translate(
          offset: Offset(widget.centeredDotPosX, widget.centeredDotPosY),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
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
              if (widget.isWaitingToTakePhoto && widget.isDeviceRotationCorrect)
                SizedBox(
                  width: widget.centeredDotRadius * 2,
                  height: widget.centeredDotRadius * 2,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _animation.value,
                        color: Colors.blue,
                        strokeWidth: 5,
                      );
                    },
                  ),
                ),
            ],
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
