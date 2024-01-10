import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraSelector extends StatefulWidget {
  final List<CameraDescription> cameras;
  final int selectedCameraKey;
  final void Function(int)? onCameraChanged;
  const CameraSelector({
    super.key,
    required this.cameras,
    required this.selectedCameraKey,
    this.onCameraChanged,
  });

  @override
  State<CameraSelector> createState() => _CameraSelectorState();
}

class _CameraSelectorState extends State<CameraSelector> {
  void cameraChanged(int cameraKey) {
    widget.onCameraChanged?.call(cameraKey);
  }

  // Camera keys
  static List<String> cameraKeys = <String>[];

  @override
  void initState() {
    super.initState();

    // Populate camera keys
    for (int cameraKey = 0; cameraKey < widget.cameras.length; cameraKey++) {
      cameraKeys.add(cameraKey.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(left: 10, right: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButton(
          dropdownColor: Colors.black.withOpacity(0.8),
          underline: const SizedBox(),
          icon: const ImageIcon(
            AssetImage(
              "images/arrow-down.png",
              package: 'camera_360',
            ),
            size: 10,
          ),
          onChanged: (String? value) {
            cameraChanged(int.parse(value!));
          },
          value: widget.selectedCameraKey.toString(),
          items: cameraKeys.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              alignment: AlignmentDirectional.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  value,
                  style: TextStyle(color: Color(0xff999999)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
