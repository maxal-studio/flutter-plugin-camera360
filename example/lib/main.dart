import 'package:camera_360/camera_360.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: CameraPage(),
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  Widget build(BuildContext context) {
    void displayPanoramaMessage(context, String message) {
      final snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Stack(
      children: [
        Camera(
          userSelectedCameraKey: 0,
          onCaptureEnded: (data) {
            if (data['success'] == true) {
              XFile panorama = data['panorama'];
              displayPanoramaMessage(context, 'Panorama saved!');
            } else {
              displayPanoramaMessage(context, 'Panorama failed!');
            }
          },
          onCameraChanged: (cameraKey) {
            displayPanoramaMessage(
                context, "Camera changed ${cameraKey.toString()}");
          },
        ),
      ],
    );
  }
}
