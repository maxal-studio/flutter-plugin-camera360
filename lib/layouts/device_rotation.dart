import 'dart:math';

import 'package:flutter/material.dart';

class DeviceRotation extends StatelessWidget {
  final double deviceRotation;
  const DeviceRotation({super.key, required this.deviceRotation});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: 4,
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 4,
                  height: 7,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                Container(
                  width: 4,
                  height: 7,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        Transform.rotate(
          angle: deviceRotation * pi / 180,
          child: Center(
            child: SizedBox(
              width: 4,
              height: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 4,
                    height: 7,
                    color: Colors.white,
                  ),
                  Container(
                    width: 4,
                    height: 7,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
