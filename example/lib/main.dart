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
        body: Camera(
          userSelectedCameraKey: 0,
          onCaptureEnded: (data) {
            if (data['success'] == true) {
              XFile panorama = data['panorama'];
              print("Final image returned $panorama.toString()");
            } else {
              print("Final image failed");
            }
          },
          onCameraChanged: (cameraKey) {
            print("Camera changed ${cameraKey.toString()}");
          },
        ),
      ),
    );
  }
}
